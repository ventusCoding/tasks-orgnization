# Everslot backend (Supabase)

Everything server-side lives here: Postgres schema (migrations), RLS, sync RPCs, notification pipeline,
pg_cron schedules, Storage policies and the Edge Functions. Source of truth for names and columns:
`docs/architecture.md` §6.6 (sync), §6.13 (notifications), §7 (backend).

> **No cloud project is configured in this repository.** Everything runs locally with the CLI. Values to
> fill in when the cloud projects exist are written as placeholders: `<YOUR_PROJECT_REF>`,
> `<CRON_SECRET>`, `<BASE64_OF_FIREBASE_SERVICE_ACCOUNT_JSON>`. Every function and job degrades gracefully
> when a secret is missing (see [Placeholders & secrets](#placeholders--secrets)).

## Contents

- [How it works](#how-it-works)
- [Layout](#layout)
- [Run it locally](#run-it-locally)
- [Seeded test users](#seeded-test-users)
- [RPC contracts](#rpc-contracts)
- [Realtime channel](#realtime-channel)
- [Notification jobs, guards and mutes](#notification-jobs-guards-and-mutes)
- [Edge Functions](#edge-functions)
- [Scheduled jobs](#scheduled-jobs)
- [Placeholders & secrets](#placeholders--secrets)
- [Migration & SQL conventions](#migration--sql-conventions)
- [Decisions & deviations](#decisions--deviations)

## How it works

```
 device (Drift + outbox) ──sync_push──▶ app.* tables ──tg_sync_before_write──▶ rev = ++sync_heads.head_rev
        ▲                                   │                                   (row lock = per-user order)
        │                                   └─tg_sync_broadcast_* (statement)─▶ realtime.send {"rev"} on user:<uid>
        └──────────sync_pull(since=rev)──────┘                                  sync_heads trigger ─▶ sync-nudge (FCM data)
 device planner ──replace_notification_jobs──▶ private.notification_jobs ◀──claim── push-dispatch (pg_cron, 30 s)
                                                                          guards ─▶ app.notifications (inbox) ─▶ FCM
```

- **Schemas.** `app` is the only schema exposed through PostgREST (`config.toml`: `api.schemas = ["app"]`);
  `private` holds server-only tables and internals (no client grants at all). `public` is unused.
- **Synced tables.** Every table of arch §7.3 carries the common columns (`id, user_id, created_at,
  updated_at, deleted_at, rev, field_clock, server_updated_at, origin_device_id`) and is wired with
  `select app.enable_sync('app.<table>')`, which validates those columns and attaches the `(user_id, rev)`
  index, RLS (select/insert/update own rows, **no delete** — deletes are soft), the row trigger and the
  statement Broadcast triggers. `app.synced_tables()` lists them (27 tables).
- **Revisions.** `app.tg_sync_before_write()` upserts `app.sync_heads` for the row owner; the row lock
  serializes a user's write transactions, so `rev` order equals commit order and the pull cursor never
  skips a row. Different users never block each other (pgTAP `110_concurrency`). Clients cannot choose
  `user_id`, `rev`, `server_updated_at`, `id` or `created_at` (forced / kept by the trigger); server writers
  (service role, pg_cron, `postgres`) may supply `user_id`. A no-op update keeps its revision.
- **Conflicts.** `app.sync_push` applies per-field last-writer-wins with hybrid logical clocks stored in
  `field_clock`; operation groups are atomic (savepoint + `SET CONSTRAINTS ALL IMMEDIATE`).
- **Integrity.** Parent references are `DEFERRABLE INITIALLY DEFERRED`, plus deferred constraint triggers:
  checklist tree (`DL001` parent in another checklist, `DL002` cycle), same-owner references (`DL003`).
  Immediate triggers: `activity_events` append-only (`DL004`), occurrence id =
  `uuid_v5(task_id || '|' || occurrence_key)` (`DL005`), immutable occurrence keys (`DL006`), attachment
  paths under `{user_id}/` (`DL007`).
- **Soft-delete cascades.** Tombstoning a checklist / item / task / habit tombstones its items,
  descendants, occurrences, time entries, logs and attachments in the same transaction, carrying the
  parent's `deleted_at` clock (a newer restore wins). Restores are not cascaded.
- **Retention.** Tombstones older than 90 days are hard-deleted nightly (children first; still-referenced
  rows are skipped). Each purge raises the owner's **purge watermark**; a device whose cursor is below it
  does a full resync. Unreferenced attachment objects are queued in `private.storage_deletions` and
  removed through the Storage API by `storage-purge`.
- **Notifications** — plan on device, dispatch on server (ADR-005): devices upload planned jobs; every
  30 s `push-dispatch` claims due jobs, re-checks guards and mutes in SQL, writes the inbox row
  (`id = uuid_v5(dedupe_key)`) and pushes through FCM to the devices that do not cover the job locally.

## Layout

```
supabase/
  config.toml                 CLI config (T1.2.01): API schema app, email OTP, anonymous sign-ins, PG 17…
  migrations/                 ordered SQL migrations (YYYYMMDDHHMMSS_<verb>_<object>.sql)
    …010_create_baseline      schemas, extensions (guarded), grants, uuid_v5, current_user_id, tz cache
    …020_create_sync_plumbing sync_heads, sync_meta, triggers, app.enable_sync, Realtime authorization
    …030_create_app_config    app_config (public read) + app.assert_client_supported
    …040 … …100               all arch §7.3 tables (identity, organization, planner, checklists,
                              history/files, habits/goals, notifications + private jobs/deliveries)
    …110_create_soft_delete_cascades
    …120_create_storage_attachments   private bucket (25 MB, MIME allow-list) + storage.objects policies
    …130_create_sync_rpcs     sync_push, sync_pull, fetch_rows, hlc_at, purge_watermark
    …140_create_ops_helpers   private.invoke_edge (pg_net + Vault), heartbeats
    …150_create_device_rpcs   register_device, report_device_state, revoke_device
    …160_create_notification_rpcs  replace_notification_jobs, claim, guards, reaper, dispatch_* wrappers
    …170_create_purge_account_ops  purge_now, purge_tombstones, account deletion, ops_health, maintenance
    …180_create_cron_jobs     pg_cron schedules (guarded) + sync-nudge webhook trigger
  seed.sql                    two local users + sample data (local only)
  tests/database/*.test.sql   pgTAP (491 assertions)
  functions/                  Edge Functions (Deno 2.1-compatible) + deno tests
fixtures/ids/uuid_v5.json     20 UUIDv5 vectors shared with the Dart implementation
```

## Run it locally

Requirements: Docker, Supabase CLI ≥ 2.117 (`brew install supabase/tap/supabase`, or the release binary
from GitHub), Deno ≥ 2.1 for the function tests.

```bash
supabase start                      # first run pulls images; prints URLs + local keys (supabase status)
supabase db reset                   # re-applies every migration + seed.sql
supabase test db                    # pgTAP suite (supabase/tests/database)
supabase db lint --local --schema app,private --level warning --fail-on error

cd supabase/functions
deno fmt --check && deno lint && deno task check && deno test -A   # 61 unit tests, no network needed
cp .env.example .env                # optional: CRON_SECRET / FCM_SERVICE_ACCOUNT for local serving
supabase functions serve --env-file supabase/functions/.env        # from the repo root
```

Local endpoints (defaults): API `http://127.0.0.1:54321` (REST `…/rest/v1`, functions `…/functions/v1`),
Postgres `postgresql://postgres:postgres@127.0.0.1:54322/postgres`, Mailpit (OTP e-mails)
`http://127.0.0.1:54324`. The app's `env/dev.json` uses `SUPABASE_URL=http://127.0.0.1:54321` (or the LAN
IP from a device) and the local `sb_publishable_…` key printed by `supabase status`. REST calls must send
`Accept-Profile: app` / `Content-Profile: app` (supabase-js: `createClient(url, key, {db: {schema: 'app'}})`).

Local cron → Edge Functions is off by default (no Vault secrets). To exercise it, run in SQL:

```sql
select vault.create_secret('http://kong:8000/functions/v1', 'functions_base_url');  -- from the db container
select vault.create_secret('<LOCAL_CRON_SECRET>', 'cron_secret');                  -- = CRON_SECRET in functions/.env
```

## Seeded test users

`supabase/seed.sql` (local stack only — never run against a cloud project):

| E-mail | Password | User id | Data |
|---|---|---|---|
| `test1@everslot.local` | `password123` | `11111111-1111-4111-8111-111111111111` | settings, 3 categories, 3 tasks (1 recurring + occurrence), 1 checklist with nested items, habit section, build habit + quit tracker with logs, notification profiles + rule |
| `test2@everslot.local` | `password123` | `22222222-2222-4222-8222-222222222222` | empty (isolation checks) |

Sign in with `POST /auth/v1/token?grant_type=password` or `supabase.auth.signInWithPassword(...)`.

## RPC contracts

All RPCs live in schema `app` (`POST /rest/v1/rpc/<name>` with `Content-Profile: app`, or
`supabase.schema('app').rpc(...)`). Client RPCs need a user JWT. JSON rows use snake_case column names;
`timestamptz` → ISO 8601 with offset, `timestamp` (wall clock) → `"YYYY-MM-DDTHH:MM:SS"`, `date` →
`"YYYY-MM-DD"`, `numeric`/`bigint` → JSON numbers, arrays → JSON arrays.

**API errors** are PostgREST errors with a stable `code`:
`HTTP <status>  {"code": "<code>", "message": "…", "details": "<JSON text or null>", "hint": "…"}`
(raised by `app.raise_api_error`). Not signed in → SQLSTATE `28000` `not_authenticated`.

### `app.sync_push(p_device_id uuid, p_schema int, p_build int, p_changes jsonb) returns jsonb`

Security invoker (RLS applies). `p_changes` is an array of **≤ 500** changes:

```json
{"id": "<change uuid>", "g": "<op group uuid>", "t": "<table name>", "op": "insert" | "patch",
 "row_id": "<uuid>", "fields": {"<column>": <value>, "...": "..."}, "clock": {"<column>": "<hlc>"}}
```

HLC strings are fixed width and compare correctly with `COLLATE "C"`:
`"<15-digit zero-padded unix ms>:<5-digit counter>:<device id>"`, e.g. `"001790071200000:00000:<device>"`.

Returns:

```json
{"results": [{"id": "<change id>", "status": "applied" | "partial" | "stale" | "rejected",
              "stale_fields": ["..."], "code": null | "...", "message": null | "..."}],
 "head": <head_rev>}
```

Semantics:

1. `p_build < app_config.min_supported_build` → error `unsupported_client` (HTTP 426; nothing applied,
   keep the outbox). Also whole-call errors: `invalid_request` (400), `too_many_changes` (413),
   `device_revoked` (403, the row of `p_device_id` is revoked). Transient database errors (deadlock,
   serialization, lock timeout) fail the call → retry.
2. Changes are grouped by `g` (a change without `g` is its own group) and groups are applied in order of
   first appearance, changes of a group in array order. Each group runs in its own
   `BEGIN … EXCEPTION … END` block that starts with `SET CONSTRAINTS ALL DEFERRED` and ends with
   `SET CONSTRAINTS ALL IMMEDIATE`. `results` keep the input order.
3. Allow-lists: `t` must be a synced table (`app.synced_tables()`), every key of `fields` a column of it.
   `user_id`, `rev`, `server_updated_at`, `field_clock` are server-managed → `forbidden_column`.
   `fields.id` is accepted only if equal to `row_id`. `origin_device_id` is always set to `p_device_id`
   (a client value is ignored). Every field needs a well-formed clock (`invalid_clock`).
4. Clocks more than 5 minutes in the future are clamped to `now() + 5 min` (the counter and device suffix
   are kept).
5. Row missing → **insert** (for `insert` and `patch`) with `field_clock` = the clock map; omitted columns
   take their defaults (`created_at` → now, `updated_at` → `created_at`, `tasks.series_id` → `id`).
6. Row exists → **per-field LWW**: a field is applied when `clock[field] > field_clock[field]`, or with an
   equal clock when the value differs; `field_clock` is updated for applied fields. Older clocks go to
   `stale_fields`. An exact replay (same clock, same value) is a no-op. If nothing applies the status is
   `stale` and **no update happens (no revision bump)** → retries are idempotent.
7. A rejected group rolls back entirely; every change of the group is `rejected`:

| `code` | Meaning | Client action |
|---|---|---|
| `integrity_refetch` | constraint violated when the group ended: CHECK/FK/unique, `DL001`–`DL007` (cycle, parent in another checklist, cross-user reference, append-only, occurrence id, …), including an id owned by another user | refetch the rows with `app.fetch_rows` and overwrite the local copies |
| `unknown_table` / `unknown_column` / `forbidden_column` / `invalid_change` / `invalid_clock` | the offending change | mark failed (client bug) |
| `group_rejected` | another change of the same group was invalid (see its code) | mark failed |
| `invalid_value` | a value cannot be cast (`22xxx`) | mark failed |
| `forbidden` | RLS denied the write | mark failed |
| `server_error` | anything else | mark failed, report |

`p_schema` is the client payload schema version (1 today; reserved for evolution, T9.2.08).

### `app.sync_pull(p_since bigint, p_limit int default 1000) returns jsonb`

Security invoker. For each synced table: `user_id = auth.uid() and rev > p_since order by rev limit
p_limit`; union, sort by `rev`, keep the first `p_limit` (clamped to 1…5000).

```json
{"changes": [{"t": "<table>", "r": {"id": "…", "user_id": "…", "rev": 42, "field_clock": {…}, "…": "…"}}],
 "next": <max rev returned, or p_since when empty>,
 "more": <bool>,
 "purge_watermark": <bigint>}
```

Rows are complete (all columns incl. `field_clock`, `rev`, `server_updated_at`, tombstones with
`deleted_at`). Full resync when `cursor < purge_watermark`. The watermark alone: `app.purge_watermark()`.

### `app.fetch_rows(p_table text, p_ids uuid[]) returns jsonb`

Targeted refetch after `integrity_refetch` (≤ 1000 ids, caller's rows only):
`{"t": "<table>", "rows": [<row json>…], "missing": ["<id not on the server>"…]}` — delete `missing` rows
locally. Unknown table → `unknown_table` (400).

### Devices (security definer, own rows only; `app.devices` is not synced)

```
app.register_device(p_id uuid, p_platform text, p_model text, p_os_version text, p_app_version text,
                    p_app_build int, p_locale text, p_time_zone text, p_device_name text default null)
    → {"revoked": bool}
app.report_device_state(p_id uuid, p_state jsonb) → {"revoked": bool}   (+ "registered": false if unknown id)
app.revoke_device(p_id uuid) → {"revoked": true}                          (device_not_found 404)
```

- `p_platform` ∈ `ios | android | web | macos | windows | linux`. `register_device` sets
  `last_seen_at = now()`; a revoked id stays revoked (`{"revoked": true}` → sign out, new device id).
  A device id previously registered by another account is transferred with its push state reset.
- `p_state` keys (only the keys present are updated): `last_seen_at` (last **foreground**, capped at now),
  `time_zone`, `capabilities` (object: `notifications, exactAlarm, timeSensitive, alarmKit,
  fullScreenIntent, badge`), `push_token` (null clears; sets `push_token_updated_at`; the same token is
  removed from any other device row), `push_enabled`, `local_notifications_enabled`,
  `local_coverage_until`, `schedule_rev`, `local_repeating_rules` (uuid array).

### `app.replace_notification_jobs(p_device_id uuid, p_source_rev bigint, p_target_keys text[], p_jobs jsonb) returns jsonb`

Security definer, `search_path` pinned, caller must own the (non-revoked) device. Atomically (one
advisory lock per user) deletes the caller's **pending future** jobs of `p_target_keys` (`'*'` = every
target) and inserts `p_jobs`:

```json
{"dedupe_key": "<sha1 hex>", "target_key": "task:<id>", "fire_at": "<iso>", "expires_at": "<iso>|null",
 "payload": {…}, "guard": {…}|[…]|null, "rule_id": "<uuid>|null", "occurrence_key": "…|null",
 "target_devices": ["<device uuid>"]|null, "importance": "min|low|default|high|urgent"}
```

Returns `{"status": "ok", "replaced": <n>, "upserted": <n>}`, or `{"status": "stale", "stale_targets":
[…]}` (nothing changed) when a pending job of one of the targets has a higher `source_rev` → pull,
re-plan, re-upload. Jobs already due but not yet claimed are kept; a job with an existing `dedupe_key` is
updated only while pending (sent/skipped jobs are never resurrected). Errors: `device_not_registered`,
`device_revoked` (403), `invalid_request` (400), `invalid_job` (422: missing keys or target not listed),
`job_beyond_horizon` (422, > 14 days), `job_payload_too_large` (413, > 3.5 KB), `job_cap_exceeded`
(429, > 3000 pending per user).

### Trash, account, config

- `app.purge_now(p_entity_type text, p_ids uuid[]) → {"purged": n, "skipped": n}` — Trash › Delete
  forever. `p_entity_type` ∈ `task | checklist | checklist_item | habit | attachment` or any synced table
  name except `profiles`. Only the caller's **tombstoned** rows (live or foreign ids are skipped), with
  their tombstoned descendants (occurrences, time entries, items, runs, logs, pauses, revisions,
  attachments). Raises the purge watermark; queues unreferenced storage objects.
- `app.request_account_deletion() → {"status": "requested"}` — records the request, clears push tokens,
  cancels pending jobs and pings `account-delete`. The client then calls the `account-delete` function
  with its access token (the daily job retries lost requests).
- `app.app_config` (anon/authenticated read): `min_supported_build`, `recommended_build`,
  `maintenance_message`. `app.assert_client_supported(build)` raises `unsupported_client` (426).
- Helpers: `app.uuid_v5(text)` (EVERSLOT_NS `6f1c9a52-7c1e-4d3b-9a8e-2b5f0e4c7d11`, vectors in
  `fixtures/ids/uuid_v5.json`), `app.everslot_ns()`, `app.current_user_id()`, `app.is_valid_time_zone()`,
  `app.hlc_at(ts, counter, node)`.

### Service-role RPCs (Edge Functions only; not executable by `anon`/`authenticated`)

| RPC | Used by | Purpose |
|---|---|---|
| `app.dispatch_claim(p_limit, p_lease_seconds)` | push-dispatch | `private.claim_notification_jobs` (`FOR UPDATE SKIP LOCKED` + lease) → jobs + `sent_device_ids` |
| `app.dispatch_guards(p_jobs)` | push-dispatch | `private.notification_guards_ok` → `[{job_id, ok, reason}]` |
| `app.dispatch_upsert_inbox(p_items)` | push-dispatch | `[{job, late}]` → inbox rows (`id = uuid_v5(dedupe_key)`) |
| `app.dispatch_devices(p_user_ids)` | push-dispatch | `{user_id: {policy, devices}}` (policy from `user_settings.notifications`) |
| `app.dispatch_complete(p_results)` | push-dispatch | deliveries, job status/backoff, invalid tokens, inbox `delivered_via` |
| `app.ops_heartbeat(p_name, p_details)` | functions | heartbeat row |
| `app.ops_health()` | uptime checks | dispatcher lag, job/delivery counts, invalid-token rate, heartbeats |
| `app.account_delete_prepare(p_user_id)` | account-delete | delete devices + jobs |
| `app.storage_purge_claim(p_limit)` / `app.storage_purge_done(p_ids, p_errors)` | storage-purge | drain `private.storage_deletions` |

## Realtime channel

Private Broadcast channel `user:<uid>` (join with `private: true`). Policy on `realtime.messages`: a user
may only **receive** its own topic; nobody can send (only `tg_sync_broadcast` does, once per statement and
user). Event `sync`, payload `{"rev": <new head>, "id": "<message uuid>"}` → debounce a pull when
`rev > cursor`. Broadcast is not durable: pull on start/resume/connectivity/timer too.

Manual two-client check (T1.2.06): sign in as test1 in one client and test2 in another, both subscribe to
`user:11111111-1111-4111-8111-111111111111` with `private: true`; write a row as test1 → only the test1
client receives `sync` (test2's join is refused by the policy).

## Notification jobs, guards and mutes

**Job payload** (rendered, localized and redacted on the device; ≤ 3.5 KB):

```json
{"type": "reminder|nag|digest|milestone|streak|system", "title": "…", "body": "…",
 "section": "planner|checklists|habits|quit|system", "sourceType": "task", "sourceId": "<uuid>",
 "deepLink": "everslot://…", "actions": ["done", "snooze"], "channel": "<android channel id>",
 "group": "<thread/group>", "iosCategory": "<registered UNNotificationCategory>", "sound": "default|none|<key>",
 "interruptionLevel": "passive|active|time-sensitive", "relevance": 0.5,
 "system": true, "inbox": true, "latenessMinutes": 15, "inboxWhenExpired": false, "data": {}}
```

`system: false` = inbox only, `inbox: false` = push only. `category` of the inbox row = `type`
(default `reminder`).

**Guards** (`guard` is one object or an array that must all pass; evaluated in SQL at dispatch time):

| `kind` | Parameters | Fails with |
|---|---|---|
| `always` | — | — |
| `task_occurrence_open` | `taskId`, `occurrenceKey` | `task_inactive` (deleted / not `active`), `occurrence_closed` (done/skipped/cancelled) |
| `habit_period_open` | `habitId`, `occurrenceKey`, `target?`, `op?` (`gte`/`lte`/`eq`) | `habit_inactive`, `habit_paused` (incl. vacation mode), `period_done` (done/skip/excuse/fail log), `target_reached` (sum of progress ≥ target) |
| `checklist_item_status_in` | `itemId`, `statuses` | `item_status_changed` |
| `item_not_completed` | `itemId` | `item_completed` |
| `quit_no_relapse_since` | `habitId`, `since` | `habit_inactive`, `relapsed` (relapse/restart log since) |
| `inbox_not_acted` | `dedupeKey` | `acted` (acted or dismissed on any device — stops nag chains) |
| unknown kind / malformed | — | passes (fail open, logged) |

**Mutes** (`app.notification_mutes`, active while not deleted and `until` is null or in the future):
`global`, `section` (matches `payload.section`), `rule` (`target_id` = job `rule_id`), or a target id that
equals the job target (`target_key` = `<type>:<uuid>`) or one of its containers: a checklist item's
ancestors and checklist, a task's series, the category of a task/checklist/habit. Muted → `guard:muted`.

**Dispatch decision per device** (`push-dispatch/decisions.ts`): revoked devices are ignored; a device
already pushed for the job is never pushed again; `target_devices` and the multi-device policy
(`user_settings.notifications.multiDevicePolicy`: `all` | `primary` + `primaryDeviceId` | `last_active`)
→ `skipped_policy`; **covered locally** → `skipped_local` when local notifications are on,
`fire_at ≤ local_coverage_until` (or the rule is in `local_repeating_rules`), `schedule_rev ≥ source_rev`,
`last_seen_at` within 72 h, and (importance below `high` or the device can fire exact alarms / is iOS);
push disabled → `skipped_policy`; no token or token + device stale for 30 days → `skipped_stale_token`;
otherwise **send**. Job outcome: `sent`; `skipped` with reason `guard:<reason>`, `covered_locally`,
`no_devices`, `policy` or `push_not_configured`; `expired` (after `expires_at`, never delivered);
`retry` → pending again with backoff 1/2/4/8 min ±20 % (QUOTA_EXCEEDED: Retry-After, ≥ 60 s), `failed`
after 5 attempts; `UNREGISTERED`/invalid token → `token_invalid` + token cleared. Deliveries are logged in
`private.push_deliveries` (unique per job × device).

## Edge Functions

Deno 2.1-compatible (hosted runtime; local `supabase functions serve` uses edge-runtime "compatible with
Deno v2.1.4"): fully pinned `npm:`/`jsr:` specifiers in `_shared/deps.ts`, no import map, `"lock": false`
(no lockfile is committed). All functions set `verify_jwt = false` in `config.toml` and authenticate
callers themselves (`_shared/auth.ts`: user JWT via Auth, or the `x-cron-secret` header compared in
constant time; fails closed when `CRON_SECRET` is unset).

| Function | Caller | Behaviour |
|---|---|---|
| `health` | anyone (GET/POST) | `{"status":"ok", checks: {supabase_configured, fcm_configured, cron_secret_configured}}`; with `x-cron-secret` also calls `app.ops_health()` |
| `push-dispatch` | pg_cron every 30 s (`x-cron-secret`) | answers **202** `{"accepted": true, "push_configured": bool}` immediately; work runs in `EdgeRuntime.waitUntil`: claim → expiry/lateness → guards → inbox upsert → per-device decision → FCM → deliveries → job status; loops over batches within a 25 s budget; heartbeat `push_dispatch` |
| `sync-nudge` | `app.sync_heads` trigger via pg_net (`x-cron-secret`, `{"type":"sync_head","user_id","head_rev","origin_device_id"}`) | data-only `{"type":"sync","head":"<rev>"}` to the user's other devices (skips the origin device, devices foregrounded in the last 2 min, throttle 60 s Android / 20 min iOS); Android `NORMAL` priority, iOS `content-available` background push |
| `account-delete` | the user (Bearer access token) or the daily retry (`x-cron-secret` + `{"user_id"}`) | removes every object under `attachments/<uid>/`, devices and jobs, then `auth.admin.deleteUser` (cascades every app row). Idempotent: `{"deleted": true, "already_deleted": bool, "objects_deleted": n}` |
| `storage-purge` | daily job (`x-cron-secret`) | deletes queued unreferenced attachment objects through the Storage API |

`_shared/`: `cors.ts`, `errors.ts` (typed `{"error": {code, message}}` responses), `log.ts` (JSON logs,
sensitive keys redacted), `env.ts`, `supabase.ts` (admin client; `SUPABASE_SECRET_KEY`, falling back to
`SUPABASE_SERVICE_ROLE_KEY`), `auth.ts`, `fcm.ts` (service-account JWT signed with `jose` → OAuth token
cached in module scope until ~5 min before expiry; HTTP v1 send; `android.notification.tag` =
`apns-collapse-id` = dedupe key; TTL / `apns-expiration`; error mapping; 4 KB payload budget),
`background.ts`, `types.ts`. Tests: `*_test.ts` next to the code (`deno test -A`, fetch/DB mocked).

## Scheduled jobs

| pg_cron job | Schedule | Work |
|---|---|---|
| `everslot-push-dispatch` | `30 seconds` | `private.invoke_edge('push-dispatch')` (no-op without Vault secrets) |
| `everslot-minutely` | `* * * * *` | lease reaper (`claimed` past `lease_until` → `pending`, attempts + 1, `failed` at 5) + heartbeats |
| `everslot-daily` | `0 3 * * *` | purge tombstones > 90 days (+ watermarks, storage queue); delete finished jobs > 14 days and deliveries > 30 days; clear push tokens of devices unseen 120 days; clean `cron.job_run_details` > 7 days; tombstone inbox rows > 90 days; delete anonymous users inactive > 90 days without data (T1.5.16); retry pending account deletions; trigger `storage-purge`; refresh the time-zone cache |

Plus the `tg_sync_heads_nudge` trigger (the "database webhook" of `sync-nudge`): at most one call per
transaction and user, only when another push-capable device exists. Every step records a heartbeat in
`private.ops_heartbeats`; `app.ops_health()` exposes dispatcher lag and heartbeat ages for alerting.

## Placeholders & secrets

Nothing secret is in the repo. When the cloud projects exist (T1.2.02):

```bash
supabase link --project-ref <YOUR_PROJECT_REF>
supabase db push --dry-run && supabase db push
supabase functions deploy --project-ref <YOUR_PROJECT_REF>
supabase secrets set --project-ref <YOUR_PROJECT_REF> \
  FCM_SERVICE_ACCOUNT=<BASE64_OF_FIREBASE_SERVICE_ACCOUNT_JSON> \
  CRON_SECRET=<CRON_SECRET> \
  SUPABASE_SECRET_KEY=sb_secret_<...>
```

```sql
-- Vault (SQL editor of the cloud project) — lets pg_cron/pg_net call the functions:
select vault.create_secret('https://<YOUR_PROJECT_REF>.supabase.co/functions/v1', 'functions_base_url');
select vault.create_secret('<CRON_SECRET>', 'cron_secret');
```

- `FCM_SERVICE_ACCOUNT`: Firebase console → Project settings → Service accounts → Generate new private
  key, then `base64 -i service-account.json` (raw JSON also accepted). Never commit the file.
- Auth: enable the new API keys (publishable key in the app, secret key only in functions) and asymmetric
  JWT signing; site URL / redirect `everslot://auth-callback`; Apple/Google providers
  (`SUPABASE_AUTH_EXTERNAL_APPLE_*` placeholders in `config.toml`).
- Record project refs here (no secrets): prod `<YOUR_PROJECT_REF>`, dev `<YOUR_DEV_PROJECT_REF>`.

| Missing piece | Behaviour |
|---|---|
| `FCM_SERVICE_ACCOUNT` | push-dispatch still writes inbox rows and marks jobs `skipped` / `push_not_configured`; sync-nudge answers `{"skipped": "push_not_configured"}`; health reports `fcm_configured: false` |
| `CRON_SECRET` (function env) | cron-only endpoints answer 401 (fail closed) |
| Vault `functions_base_url` / `cron_secret`, or pg_net | `private.invoke_edge` returns NULL: no dispatch / nudge / purge calls |
| pg_cron | schedules are skipped by the migration (notice) |
| `realtime` / `storage` schemas | Broadcast becomes a no-op; policies / bucket are skipped |
| `SUPABASE_URL` / secret key in a function | 503 `not_configured` |

## Migration & SQL conventions

- File names `YYYYMMDDHHMMSS_<verb>_<object>.sql`, one concern per migration, idempotent where possible
  (`if not exists`, `create or replace`, guarded `do` blocks); breaking changes follow
  expand → migrate → contract (T9.2.08); no data backfill without a batch plan.
- `comment on` every table (and non-obvious columns); `text` + `CHECK` instead of enums; `timestamptz`
  for instants, `timestamp` for wall-clock values (+ IANA `time_zone`), `date` for local dates; sort keys
  `text collate "C"`; ARGB colors as `integer`.
- Every synced table is created with the common columns and wired with
  `select app.enable_sync('app.<table>')`; the RLS completeness test (`020_rls_completeness`) fails when a
  table misses RLS, policies, triggers or the `(user_id, rev)` index, or when it is not in the expected list.
- Functions are not executable by `PUBLIC` by default (`alter default privileges … revoke execute`):
  every RPC is granted explicitly; security-definer functions pin `search_path = ''`.
- Every migration is paired with pgTAP tests; `supabase db lint` must stay clean.

Security baseline (T1.2.16): RLS on every `app` table (tested); `private` has no client grants;
anon can only read `app.app_config` and call three helpers (tested); storage is path-scoped per user
(tested); clients cannot send on Realtime; e-mail confirmations on, minimum password length 8; secrets only
in function secrets / Vault.

## Decisions & deviations

- **Broadcast triggers:** Postgres forbids transition tables on multi-event triggers, so
  `app.tg_sync_broadcast()` is attached twice per table (`tg_sync_broadcast_insert` / `_update`).
- **Purge watermark is per user** (`private.sync_meta` key `purge_watermark:<user_id>`), because
  revisions are per-user counters; `sync_pull` returns the caller's value.
- **Parent foreign keys** (items → checklist/parent, occurrences/time entries → task, logs/pauses/revisions
  → habit, tags, categories, profiles, sections) are `NO ACTION DEFERRABLE INITIALLY DEFERRED` instead of
  cascading: rows are soft-deleted, purges delete children first, and only `auth.users` deletion cascades.
- **Idempotent replay:** an equal clock with an equal value is a no-op (`stale`); `clock > field_clock`,
  or an equal clock with a different value, applies (the literal `>=` rule would bump revisions on every
  retry).
- **Server-managed fields are rejected, not dropped** (`forbidden_column`); `origin_device_id` is always
  the pushing device. Whole-call refusals (`unsupported_client`, `device_revoked`, `too_many_changes`) are
  PostgREST errors rather than per-change results, so the outbox is kept intact.
- `app.revoke_device` returns `{"revoked": true}`; `app.report_device_state` adds `"registered": false`
  for an unknown device id instead of raising.
- **Checklist CHECKs follow arch §7.3** (note ≤ 50 000 chars, sort key `^[0-9A-Za-z]{1,128}$`) where
  T4.1.01 says 100 000 / 256.
- Not in §7.3 but needed: `private.time_zone_names` (fast IANA check for CHECK constraints),
  `private.account_deletion_requests`, `private.storage_deletions` + `storage-purge`,
  `notification_mutes.target_type` vocabulary, `notifications.delivered_via` values
  (`local | push | inbox | inbox_only`), service-role `app.dispatch_*` wrappers (the `private` schema is
  not exposed through the API), `app.ops_health()` wrapper of `private.ops_health()`.
- `private.fcm_token_cache` (arch §7.2 example, T7.4.06) is not created: the OAuth token is cached in
  module scope only (one mint per warm instance).
- The lease reaper runs every minute (T7.4.08) instead of the 10-minute "stuck claimed" release of arch §7.7.
- `@supabase/supabase-js` is pinned to 2.116.0: 2.117.0 was younger than Deno's default 24 h
  minimum-dependency-age policy when this was written.
