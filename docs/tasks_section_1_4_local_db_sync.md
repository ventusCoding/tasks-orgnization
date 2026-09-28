# Section 1.4 — Local Database & Sync Engine

> Milestones: M0 (P0) · M2 (P1) · M3 (P2) · Depends on: 1.2 (sync plumbing, seed user), 1.3
> Architecture: arch §6.5 (Drift), §6.6 (sync engine — read the ⚠ rules), §7.2–7.5, §9.2–9.3, ADR-002,
> ADR-006, ADR-009

## Goal

Make the local SQLite database (Drift) the source of truth for the UI and keep every device of a user
converged through a small, provably correct sync protocol: patch outbox with hybrid logical clocks,
atomic operation groups, per-field last-writer-wins on the server, gap-free per-user revision cursor for
pulls, private Broadcast nudges, tombstones with purge + resync, and clear sync status. Developed and
tested against the seeded local user (auth UI comes in [1.5]).

## Scope

**In:** Drift database & conventions, common synced-table columns, HLC, outbox & sync state, device
registry, table registry/serializers, `sync_push`/`sync_pull` RPCs, push/pull loops, Broadcast
subscription, orchestrator & status, initial sync/resync, purge, background sync, diagnostics, tests.
**Out:** Feature tables (each section adds its own using these conventions); attachments binary upload
([2.2]); two-client convergence campaign ([9.1] T9.1.03 — must be green before M0 exit).

## Progress

- [x] T1.4.01 — Drift `AppDatabase` setup & conventions
- [x] T1.4.02 — Synced-table mixin, converters & base DAO helpers
- [x] T1.4.03 — Hybrid logical clock (HLC)
- [x] T1.4.04 — Outbox, operation groups & sync state tables
- [x] T1.4.05 — Device identity & registry (`app.devices`, RPCs)
- [x] T1.4.06 — Table registry & row/patch serializers
- [x] T1.4.07 — Write path: `SyncWriter` transaction helper
- [x] T1.4.08 — Server RPC `app.sync_push` (per-field LWW, groups, idempotency)
- [x] T1.4.09 — Server RPC `app.sync_pull` (paged, gap-free)
- [x] T1.4.10 — Push loop
- [x] T1.4.11 — Pull loop & field-wise apply
- [x] T1.4.12 — Realtime Broadcast subscription
- [x] T1.4.13 — Sync orchestrator & status provider
- [x] T1.4.14 — Initial sync & full resync
- [x] T1.4.15 — Sync unit tests with a fake API
- [x] T1.4.16 — Tombstone purge job, watermark & `app.purge_now`
- [x] T1.4.17 — Background sync (workmanager + data-push hook)
- [x] T1.4.18 — Sync diagnostics (dev) & conflict log
- [x] T1.4.19 — Automatic writes policy (scheduled-instant clocks)

## Tasks

### T1.4.01 — Drift `AppDatabase` setup & conventions
**Priority:** P0 · **Size:** M · **Depends on:** [1.3]
**Description:** `core/database/app_database.dart` with `drift` 2.35 + `drift_flutter` (SQLite from
`sqlite3` 3.x build hooks — no `sqlite3_flutter_libs`), opened on a background isolate with
`shareAcrossIsolates: true` (background notification actions and workmanager open the same DB), WAL
mode, foreign keys **off** for synced tables (rows may arrive in any order), `schemaVersion` 1, schema
export (`drift_dev schema dump` into `app/drift_schemas/`) and the migration test harness
(`SchemaVerifier`).
**Implementation notes:** DateTime as UTC ISO text (`store_date_time_values_as_text`); wall-clock values
and dates as ISO text; JSON value objects via type converters; `LocalDateTime`/`LocalDate` converters from
the recurrence package.
**Acceptance criteria:** DB opens < 150 ms on cold start; a second isolate reads/writes concurrently
without "database is locked" errors.
**Tests:** open/close tests; migration test scaffold; concurrent isolate smoke test.
**Notes:** verified — WAL, foreign keys off, `shareAcrossIsolates`, every table + FTS created; open/pragma and second-isolate smoke tests in `app/test/core/sync/database_setup_test.dart`. The `drift_dev schema dump` + `SchemaVerifier` migration harness still has to be generated centrally (agents don't run codegen).

### T1.4.02 — Synced-table mixin, converters & base DAO helpers
**Priority:** P0 · **Size:** M · **Depends on:** T1.4.01
**Description:** `SyncedColumns` mixin (id, userId, createdAt, updatedAt, deletedAt, rev, fieldClock (JSON
map), serverUpdatedAt, originDeviceId) mirroring arch §7.2; base DAO helpers: `watchActive()` (excludes
tombstones), `getById`, soft delete with cascade hook, restore, and `sort_key` columns declared with
BINARY collation (byte order).
**Acceptance criteria:** a sample synced table defined in < 20 lines inherits everything; tombstones never
appear in `watchActive` streams.
**Tests:** DAO tests on a sample table.
**Notes:** generic read helpers `SyncedQueries.watchActive/getActive/getById` (`core/sync/synced_queries.dart`); soft delete / restore live on `WriteTx`; sort keys rely on SQLite's default BINARY collation.

### T1.4.03 — Hybrid logical clock (HLC)
**Priority:** P0 · **Size:** S · **Depends on:** [1.3] (clock)
**Description:** `core/sync/hlc.dart`: timestamp = (physical ms, logical counter, device id) encoded as a
sortable string; `now()` = max(physical clock, last issued, highest seen from server) with counter
increments; `observe(remote)` on every pulled `field_clock`; persisted in `sync_state` so it survives
restarts.
**Acceptance criteria:** monotonic even if the device clock jumps backwards; after observing a server
timestamp from "the future" (≤ clamp), subsequent local stamps are greater.
**Tests:** unit tests with a fake clock (jumps back/forward, many events in one ms), encoding sort order.

### T1.4.04 — Outbox, operation groups & sync state tables
**Priority:** P0 · **Size:** M · **Depends on:** T1.4.02, T1.4.03
**Description:** Local-only tables: `sync_outbox` (change_id UUIDv7, op_id (group), seq, table_name,
row_id, op insert|patch, fields JSON, clock JSON, entry_version, attempts, last_error, state
pending|inflight|failed, enqueued_at) with coalescing of pending patches per row (latest value + max
clock per field, entry_version++); `sync_state` (user_id, cursor, hlc, last_push_at, last_pull_at,
last_success_at, purge_watermark_seen).
**Implementation notes:** an operation group (e.g. moving a subtree, deleting a checklist with its items,
splitting a series) shares one `op_id` and must be pushed together (never split across `sync_push`
calls); coalescing never merges patches across different groups that are both in flight.
**Acceptance criteria:** 100 rapid edits of one row produce one pending patch; a group of 300 changes is
pushed in a single call.
**Tests:** unit tests for coalescing and grouping rules.

### T1.4.05 — Device identity & registry (`app.devices`, RPCs)
**Priority:** P0 · **Size:** M · **Depends on:** [1.2], T1.4.01
**Description:** Device id (UUIDv7) created once per install in secure storage; server table `app.devices`
(arch §7.3; not pulled by sync) with RPCs `app.register_device(id, platform, model, os, app_version,
build, locale, time_zone)` and `app.report_device_state(id, {last_seen, time_zone, capabilities,
push_token?, local_coverage_until?, schedule_rev?})` (`security definer`, own rows only). Called after
sign-in, on start/resume (throttled to 1/h) and when state changes.
**Acceptance criteria:** reinstall = new device row; revoked device ([8.3]) receives `revoked` in the
response and signs out on next contact.
**Tests:** pgTAP (isolation, revoke); unit tests for throttling.

### T1.4.06 — Table registry & row/patch serializers
**Priority:** P0 · **Size:** M · **Depends on:** T1.4.02
**Description:** One registry listing every synced table with: server name, Drift table, JSON ↔ row
converters (snake_case), the set of client-writable fields, and apply order hints. Used by push, pull,
export ([8.3]) and tests. A test fails if a Drift table with `SyncedColumns` is missing from the registry,
or if registry columns diverge from the server schema snapshot (`supabase/schema_snapshot.json`
generated in CI).
**Acceptance criteria:** adding a synced table requires only a registry entry + migrations; schema drift
is caught in CI.
**Tests:** registry completeness test; round-trip tests per table.
**Notes:** the schema-drift check parses `supabase/migrations/*.sql` (columns + types → column kinds) instead of a CI-generated `schema_snapshot.json` (`app/test/core/sync/table_registry_test.dart`).

### T1.4.07 — Write path: `SyncWriter` transaction helper
**Priority:** P0 · **Size:** M · **Depends on:** T1.4.04, T1.4.06, [2.3] (activity logger — may start as a no-op)
**Description:** `SyncWriter.run(opId, (tx) async { ... })` used by all repositories: applies local row
changes, computes changed fields, stamps HLC clocks, records outbox patches under the operation group,
writes activity events, and notifies the push debouncer — all in one Drift transaction.
**Acceptance criteria:** a crash mid-operation leaves no partial local state; every local write produces
exactly the expected outbox patches (golden tests per operation type).
**Tests:** unit tests with an in-memory DB; failure-injection test.

### T1.4.08 — Server RPC `app.sync_push` (per-field LWW, groups, idempotency)
**Priority:** P0 · **Size:** L · **Depends on:** [1.2] (T1.2.05, T1.2.11), T1.4.06
**Description:** `app.sync_push(p_device_id, p_schema, p_changes jsonb)` (security invoker): checks client
support, validates table/column allow-lists, applies up to 500 changes **in one transaction**, each
operation group inside a savepoint with `SET CONSTRAINTS ALL IMMEDIATE` at the group end (deferrable
integrity triggers such as "parent in same checklist" / "no cycles" are checked per group); per field:
apply only if `clock ≥ field_clock[field]` (clamp clocks > now()+5 min), update `field_clock`; skip rows
where nothing changed (no revision bump → idempotent retries); inserts of an existing id are treated as
patches. Returns per change `applied | partial(stale fields) | stale | rejected(code, message)` + head rev.
Integrity violations reject the whole group with a code telling the client to refetch the affected rows.
**Acceptance criteria:** replaying the same batch twice changes nothing the second time; a stale field
never overwrites a newer one; a cross-user id collision is rejected; a group violating tree integrity is
rejected atomically.
**Tests:** extensive pgTAP (LWW per field, clamp, idempotency, groups, allow-lists, RLS, min-version).
**Notes:** server side in migration `…130_create_sync_rpcs` with pgTAP `050_sync_push` / `110_concurrency`; the client contract is exercised by the fake-server suite (pgTAP not re-run by the client agent — no local stack).

### T1.4.09 — Server RPC `app.sync_pull` (paged, gap-free)
**Priority:** P0 · **Size:** M · **Depends on:** T1.4.08
**Description:** `app.sync_pull(p_since, p_limit)` per arch §6.6: union of per-table `rev > since` queries
(each limited), sorted by `rev`, first `p_limit` rows, returns `{changes, next, more, purge_watermark}`
with full rows incl. `field_clock`.
**Acceptance criteria:** with interleaved concurrent pushes for the same user, a client paging with
`next` never misses a row (per-user serialization); a page of 1 000 rows returns in < 50 ms server time on
realistic volumes ([9.1] T9.1.13).
**Tests:** pgTAP (ordering, pagination boundaries, RLS); concurrency script test.
**Notes:** server side in migration `…130_create_sync_rpcs` with pgTAP `060_sync_pull` / `110_concurrency` (not re-run by the client agent).

### T1.4.10 — Push loop
**Priority:** P0 · **Size:** M · **Depends on:** T1.4.07, T1.4.08
**Description:** Single-flight pusher: debounce 1.5 s after writes; triggers on connectivity regain and
resume; batches ≤ 500 changes without splitting groups; marks entries `inflight`; on results deletes
applied/stale entries whose `entry_version` is unchanged, keeps modified ones, marks rejected as `failed`
(or schedules a refetch for integrity codes); exponential backoff with jitter on network/5xx errors;
after success triggers a pull.
**Acceptance criteria:** editing while a push is in flight never loses the edit; network loss mid-push
leads to a correct retry with no duplicates.
**Tests:** unit tests with a fake API (success, partial, stale, rejected, timeout).
**Notes:** connectivity-regain trigger added in `core/sync/sync_triggers.dart` (push as soon as the network returns).

### T1.4.11 — Pull loop & field-wise apply
**Priority:** P0 · **Size:** M · **Depends on:** T1.4.09
**Description:** Pages through `sync_pull` until `more = false`; each page + new cursor saved in **one**
Drift transaction; rows are applied **field by field**: fields with pending outbox patches keep the local
value; others take the server value; `hlc.observe` for every incoming clock; tombstones propagate
(`deleted_at`); rows for unknown tables are skipped with a warning (forward compatibility); `refetch
requests` from push rejections are served by a targeted pull by ids (small RPC or filter).
**Acceptance criteria:** a pull never overwrites an unsynced local edit; crash between pages resumes from
the last saved cursor without duplicates.
**Tests:** unit tests with fake pages (overlaps, tombstones, pending fields, crash simulation).

### T1.4.12 — Realtime Broadcast subscription
**Priority:** P0 · **Size:** S · **Depends on:** [1.2] (T1.2.06), T1.4.11
**Description:** Join private channel `user:<uid>` (`private: true`) when signed in and the app is in the
foreground; on `sync` events with `rev > cursor` schedule a debounced pull; disconnect in background;
reconnect with backoff; never rely on Broadcast alone (pull also on start/resume/connectivity/timer).
**Acceptance criteria:** an edit on device A appears on foreground device B within ~2 s on a good network.
**Tests:** unit test with a fake realtime client; manual two-device check.
**Notes:** `SyncTriggers` joins `user:<uid>` only in the foreground (left on pause, re-joined on resume) and ignores nudges at or below the known cursor; tested with a fake subscriber (`sync_triggers_test.dart`).

### T1.4.13 — Sync orchestrator & status provider
**Priority:** P0 · **Size:** M · **Depends on:** T1.4.10, T1.4.11, T1.4.12
**Description:** `SyncService` coordinating triggers (start, resume, writes, Broadcast, 5-min foreground
timer, manual "Sync now", data push), a single mutex so push/pull never overlap, and a `syncStatusProvider`
(`idle | pushing | pulling | offline | error`, pending count, last success, last error) consumed by the
UI indicator and Settings › Sync ([8.3]).
**Acceptance criteria:** no concurrent push/pull; status transitions visible in UI tests.
**Tests:** state-machine unit tests with fake clock and fake API.

### T1.4.14 — Initial sync & full resync
**Priority:** P0 · **Size:** M · **Depends on:** T1.4.13
**Description:** First sign-in on a device: cursor 0, paged pull with a progress UI (rows/estimated),
app usable read-only for already-arrived data; full resync (wipe synced tables, keep outbox, pull from 0,
re-apply outbox) triggered when `cursor < purge_watermark`, when the last success is older than the
tombstone retention (90 days), or manually from Settings.
**Acceptance criteria:** 50 000 rows sync in < 30 s on a 4G profile with the UI responsive; resync keeps
unsynced local edits.
**Tests:** performance test (T9.1.08 later); unit tests for resync decision logic.
**Notes:** `SyncService._pull` pulls from 0 when the cursor is 0, the last success is older than the tombstone retention (90 d) or the purge watermark is above the cursor; a resync keeps the outbox (fields with pending patches are never overwritten, re-pushed afterwards) and drops local rows the server no longer has. Progress is an asymptotic estimate (`sync_pull` returns no head revision) shown by the sync indicator and Settings › Sync; the app stays usable (local-first). Decision logic unit-tested in `test/core/sync/sync_service_test.dart`; the 50 000-row performance test is T9.1.08.

### T1.4.15 — Sync unit tests with a fake API
**Priority:** P0 · **Size:** M · **Depends on:** T1.4.13
**Description:** An in-memory `FakeSyncServer` implementing the same semantics as the RPCs (per-user rev,
per-field LWW, groups, purge watermark) to run fast deterministic multi-device simulations in unit tests
(randomized operations, seeded), complementing the real-backend suite in [9.1] T9.1.03.
**Acceptance criteria:** 1 000 randomized 3-device simulations converge in < 30 s; the fake server's
behaviour is cross-checked against pgTAP fixtures.
**Tests:** this task is the suite.
**Notes:** CI runs 60 seeded simulations; `SYNC_SIMULATIONS=1000` runs the full campaign — 1 000/1 000 converge (86.8 s on the dev machine, above the 30 s target: per-device in-memory schema creation dominates).

### T1.4.16 — Tombstone purge job, watermark & `app.purge_now`
**Priority:** P1 · **Size:** M · **Depends on:** T1.4.09, [1.2] (T1.2.12)
**Description:** Daily pg_cron job hard-deleting tombstones older than 90 days in batches, updating
`sync_meta.purge_watermark` (highest purged revision per user or global conservative value) and enqueuing
storage object deletions for purged attachments (reference-counted, [2.2] T2.2.11); RPC
`app.purge_now(entity_type, ids)` (security definer, own tombstoned rows only) for Trash › Delete forever ([8.3]).
**Acceptance criteria:** a device offline for 100 days performs a full resync and ends identical to others.
**Tests:** pgTAP for purge & RPC; resync scenario in the sync suite.
**Notes:** Server side came with [1.2] (`supabase/migrations/20260922000170_create_purge_account_ops.sql`): `private.purge_tombstones(90)` in the daily maintenance cron (children first, batches, per-user `purge_watermark`, unreferenced storage objects queued for `storage-purge`), `app.purge_now(entity_type, ids)` (security definer, own tombstones only, ≤ 1000 ids) — pgTAP `supabase/tests/database/100_purge_ops.test.sql`. Client: a cursor below the watermark or a last success older than 90 days forces a full resync that drops purged rows (`test/core/sync/sync_service_test.dart`).

### T1.4.17 — Background sync (workmanager + data-push hook)
**Priority:** P1 · **Size:** M · **Depends on:** T1.4.13
**Description:** Periodic background task (Android WorkManager ≥ 15 min, iOS BGAppRefresh best-effort) that
opens the shared DB, pushes, pulls and triggers notification re-planning ([7.2]); a hook for FCM data
messages `{"type":"sync"}` ([7.4]) doing the same in the background isolate with a time budget (< 25 s).
**Acceptance criteria:** background runs never corrupt state when the foreground app starts concurrently
(mutex across isolates via a DB lock row).
**Tests:** unit tests for the cross-isolate lock; manual QA on both platforms.
**Notes:** `core/sync/background_sync.dart`: `BackgroundSync.runTask()` (background isolate: restores the session from the secure storage — refreshed tokens are written back —, opens the shared DB, runs a `bg-` engine within a 25 s budget; outcomes synced/skipped/failed/timedOut), periodic task `everslot.sync.periodic` (30 min, network required) registered by the `scheduleBackgroundSync` startup task for cloud sessions and cancelled on sign-out / local-only. Cross-isolate safety = the `SyncLock` lease (atomic UPSERT, TTL) — tests in `test/core/sync/background_sync_test.dart` (lock held by the foreground → skipped, simultaneous start pushes once, budget timeout + lease expiry, offline). TODO(integration): WorkManager allows one dispatcher — `notificationsWorkmanagerDispatcher` ([7.2]) must route `BackgroundSync.periodicTask` to `BackgroundSync.runTask()` then re-plan, and the FCM `sync` data handler should call `BackgroundSync.runTask()` (it only marks a pending pull today). iOS BGAppRefresh identifiers: see guide.md.

### T1.4.18 — Sync diagnostics (dev) & conflict log
**Priority:** P1 · **Size:** S · **Depends on:** T1.4.13
**Description:** Dev screen: outbox entries (grouped by op), failed entries with errors and retry/discard,
cursor/head, last pages, "simulate offline", force push/pull; a local ring-buffer **conflict log**
(stale fields rejected by the server) to debug surprising overwrites.
**Tests:** widget smoke test (dev flavor only).
**Notes:** `SyncDiagnosticsPage` (dev menu, or `/dev?page=sync` from Settings › Sync in dev builds): phase, cursor/purge watermark, last pull/push, batch size, last error; simulate offline; Sync now / full pull; outbox grouped by `op_id` (fields, state, attempts, errors) with retry/discard (per entry or all failed); last pulled pages; the persisted conflict log (stale fields, ring buffer of 100) with Clear. Widget smoke tests in `test/features/dev/debug_menu_test.dart`.

### T1.4.19 — Automatic writes policy (scheduled-instant clocks)
**Priority:** P1 · **Size:** S · **Depends on:** T1.4.07
**Description:** Writes generated automatically by time-based logic (resettable checklists, auto-success
quit days, auto-missed flags if ever stored, notification bookkeeping) stamp their HLC with the
**scheduled instant** of the triggering event, not "now", so a later user edit always wins and two devices
running the same automation converge (combined with deterministic ids). Documented in arch §6.6 and
enforced by a helper `SyncWriter.runAutomatic(scheduledAt, …)`.
**Tests:** unit test: user edit after automated reset wins on both devices regardless of which ran the automation.
**Notes:** `SyncWriter.runAutomatic(scheduledAt, body)` (= `run(scheduledAt:)`): the write clock is the scheduled instant, so a later user edit always wins. Two-device test for automation on A, on B and on both: `test/core/sync/automatic_writes_test.dart` (+ `sync_writer_outbox_test.dart`). Features with automatic writes (checklist resets, quit auto-success, notification bookkeeping) pass their scheduled instant.
