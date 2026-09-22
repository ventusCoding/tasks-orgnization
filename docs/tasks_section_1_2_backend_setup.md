# Section 1.2 — Backend Setup (Supabase + Firebase)

> Milestones: M0 (P0) · M2 (P1) · M3 (P2) · Depends on: 1.1
> Architecture: arch §3.2 (services & limits), §7 (backend), §6.6 (server side of sync), §11 (secrets), ADR-015

## Goal

A reproducible backend: a local Supabase stack for development and tests, linked cloud projects, the
`app` schema with the **generic sync plumbing every table will use** (per-user revision counter,
triggers, `app.enable_sync`, Broadcast nudge), RLS conventions proven by pgTAP, the private attachments
bucket, an Edge Functions workspace compatible with the hosted Deno 2.1 runtime, cron/net/Vault, and the
Firebase projects needed for FCM and Crashlytics.

## Scope

**In:** Supabase CLI & local stack, cloud projects & keys, migration conventions, baseline schema,
sync triggers/helper, pgTAP harness, storage bucket & policies, Edge Functions scaffold, pg_cron/pg_net/
Vault, Firebase projects per flavor, APNs key, Crashlytics, seed data, CI jobs for DB & functions.
**Out:** Feature tables (each section), sync RPCs & client engine ([1.4]), auth flows ([1.5]), push
dispatcher ([7.4]), production hardening ([9.2]).

## Progress

- [ ] T1.2.01 — Supabase CLI & local stack
- [ ] T1.2.02 — Cloud projects, API keys & linking
- [ ] T1.2.03 — Migration & SQL conventions
- [ ] T1.2.04 — Baseline migration: schemas, extensions, grants, helpers
- [ ] T1.2.05 — Sync plumbing: `sync_heads`, triggers, `app.enable_sync()`
- [ ] T1.2.06 — Realtime Broadcast authorization (`user:<uid>` private channel)
- [ ] T1.2.07 — pgTAP harness & CI database job
- [ ] T1.2.08 — Storage bucket `attachments` & policies
- [ ] T1.2.09 — Edge Functions workspace (Deno 2.1-compatible) & CI job
- [ ] T1.2.10 — Seed data & test users for local development
- [ ] T1.2.11 — App config table & minimum-version gate (server side)
- [ ] T1.2.12 — pg_cron + pg_net + Vault wiring (`app.invoke_edge`)
- [ ] T1.2.13 — Firebase projects per flavor (FlutterFire)
- [ ] T1.2.14 — APNs key & iOS push capabilities
- [ ] T1.2.15 — Crashlytics integration
- [ ] T1.2.16 — Database advisors & security baseline in CI
- [ ] T1.2.17 — Generated TypeScript types for Edge Functions

## Tasks

### T1.2.01 — Supabase CLI & local stack
**Priority:** P0 · **Size:** S · **Depends on:** [1.1]
**Description:** Install Docker + Supabase CLI (≥ 2.117), `supabase init`, configure `supabase/config.toml`:
Postgres 17, API schemas `["app"]` (+ `graphql_public` off), `extra_search_path`, auth site URL and
redirect URLs for dev deep links, email OTP enabled, anonymous sign-ins enabled (captcha later), storage
limits, realtime enabled.
**Acceptance criteria:** `supabase start` brings up the stack; `supabase status` prints URLs and keys
used by `env/dev.json` (local).
**Tests:** CI job starts the stack (T1.2.07).

### T1.2.02 — Cloud projects, API keys & linking
**Priority:** P0 · **Size:** S · **Depends on:** T1.2.01
**Description:** Create `everslot-prod` (and optionally `everslot-dev`) in a region close to the owner
(EU likely), enable the **new API keys** (publishable `sb_publishable_…` for the app, secret `sb_secret_…`
for server code) and asymmetric JWT signing; `supabase link`; store project refs in `supabase/README.md`
(no secrets). Plan note: Free for development, Pro before launch (idle pausing) — arch §3.2.
**Acceptance criteria:** `supabase db push --dry-run` works against the linked project; legacy
anon/service_role keys are not used anywhere.
**Tests:** manual verification checklist in `supabase/README.md`.

### T1.2.03 — Migration & SQL conventions
**Priority:** P0 · **Size:** S · **Depends on:** T1.2.01
**Description:** Document in `supabase/README.md`: file naming (`YYYYMMDDHHMMSS_<verb>_<object>.sql`),
one concern per migration, idempotent where possible, **expand → migrate → contract** for breaking
changes ([9.2] T9.2.08), comments on every table/column (`comment on …`), `text` + `CHECK` instead of
enums, `timestamptz` for instants, `timestamp` for wall-clock values, `COLLATE "C"` for sort keys, every
synced table created then wired with `select app.enable_sync('app.<table>')`, every migration paired
with pgTAP tests, no data backfills without a batch plan.
**Acceptance criteria:** conventions reviewed; a sample migration follows them.

### T1.2.04 — Baseline migration: schemas, extensions, grants, helpers
**Priority:** P0 · **Size:** M · **Depends on:** T1.2.03
**Description:** Create schemas `app` (exposed) and `private` (not exposed), extensions (`pg_cron`,
`pg_net`, `pgtap` for tests, `pgcrypto`), grants (usage on `app` to `authenticated`, nothing to `anon`
except `app.app_config` read), `revoke all on schema public from public`, helper functions:
`app.everslot_ns()` (namespace UUID constant, same as Dart `EVERSLOT_NS`), `app.uuid_v5(text)`,
`app.current_user_id()` (wraps `auth.uid()` with a clear error when null).
**Acceptance criteria:** `app.uuid_v5('x')` equals the Dart implementation for 20 fixture inputs.
**Tests:** pgTAP for helpers + a Dart test using the same fixture file (`fixtures/ids/uuid_v5.json`).

### T1.2.05 — Sync plumbing: `sync_heads`, triggers, `app.enable_sync()`
**Priority:** P0 · **Size:** M · **Depends on:** T1.2.04
**Description:** Implement the server side of arch §6.6: `app.sync_heads` (per-user revision counter),
`private.sync_meta`, trigger function `app.tg_sync_before_write()` (force/immutable `user_id`, immutable `id`
and `created_at`, next revision via the `sync_heads` upsert row lock, `server_updated_at`), statement-level
`app.tg_sync_broadcast()` (one `realtime.send` per statement with the new head), and
`app.enable_sync(regclass)` that adds/validates the common columns (incl. `field_clock jsonb`), creates
index `(user_id, rev)`, enables RLS, creates standard select/insert/update policies
(`user_id = (select auth.uid())`), and attaches both triggers.
**Implementation notes:** per-field LWW is applied by `app.sync_push` ([1.4]) — the trigger only
serializes, versions and broadcasts; server-side writers must also go through the trigger (never bypass).
**Acceptance criteria:** two concurrent transactions writing for the same user receive strictly increasing
revisions in commit order; different users don't block each other; direct `update` of `rev`/`user_id` by a
client is overridden.
**Tests:** pgTAP incl. a concurrency test using two sessions (dblink or `pg_background` if available,
otherwise a scripted psql test in CI).

### T1.2.06 — Realtime Broadcast authorization (`user:<uid>` private channel)
**Priority:** P0 · **Size:** S · **Depends on:** T1.2.05
**Description:** RLS policy on `realtime.messages` allowing `select` only when
`realtime.topic() = 'user:' || auth.uid()::text`; client never writes to the channel; document the
channel contract `{event: "sync", payload: {rev}}`.
**Acceptance criteria:** user B cannot join `user:<A>`; a write by A produces exactly one message per
statement on A's channel.
**Tests:** pgTAP for the policy; manual verification with two clients (script in `supabase/README.md`).

### T1.2.07 — pgTAP harness & CI database job
**Priority:** P0 · **Size:** M · **Depends on:** T1.2.05
**Description:** `supabase/tests/database/` with helpers (`tests.create_user(email)`,
`tests.authenticate_as(uid)` setting `request.jwt.claims` + role, `tests.clear_authentication()`), a
template isolation test, and CI job: `supabase/setup-cli` → `supabase start` → `supabase db reset` →
`supabase test db`.
**Acceptance criteria:** CI fails when any test fails; runs < 6 min.
**Tests:** the harness self-test.

### T1.2.08 — Storage bucket `attachments` & policies
**Priority:** P0 · **Size:** S · **Depends on:** T1.2.07
**Description:** Private bucket `attachments` with `file_size_limit` (25 MB default, ≤ plan maximum),
`allowed_mime_types` allow-list; policies on `storage.objects` for select/insert/update/delete where
`bucket_id = 'attachments' and (storage.foldername(name))[1] = auth.uid()::text` (upload = INSERT,
download = SELECT, overwrite = SELECT + UPDATE, delete = DELETE); resumable uploads enabled.
**Acceptance criteria:** user B cannot read or overwrite user A's objects; oversized/disallowed uploads rejected.
**Tests:** pgTAP on policies + storage integration test in [2.2] T2.2.10.

### T1.2.09 — Edge Functions workspace (Deno 2.1-compatible) & CI job
**Priority:** P0 · **Size:** M · **Depends on:** T1.2.02
**Description:** `supabase/functions/deno.json` (fmt/lint/test tasks, compiler options), `_shared/`
(`cors.ts`, `errors.ts` with typed error responses, `supabase.ts` admin client using the secret key from
env, `auth.ts` to verify user JWTs or the `CRON_SECRET` header, `log.ts` structured logging without PII),
a `health` function with tests. Imports use pinned `npm:`/`jsr:` specifiers; **no committed lockfile v5**
(hosted runtime is Deno 2.1-compatible while local Deno is newer). CI: `deno fmt --check`, `deno lint`,
`deno test -A` (using Deno 2.1.x in CI to match production).
**Acceptance criteria:** `supabase functions serve health` works locally; deploy to the linked project
succeeds; CI green.
**Tests:** Deno unit tests for `_shared` helpers.

### T1.2.10 — Seed data & test users for local development
**Priority:** P0 · **Size:** S · **Depends on:** T1.2.07
**Description:** `supabase/seed.sql` creating two confirmed test users (email/password for local only)
and minimal sample data once feature tables exist (extended by later tasks); documented credentials in
`supabase/README.md` (local stack only).
**Acceptance criteria:** `supabase db reset` yields a usable local environment; the sync engine ([1.4]) can
be developed against the seeded user before auth UI exists.

### T1.2.11 — App config table & minimum-version gate (server side)
**Priority:** P0 · **Size:** S · **Depends on:** T1.2.04
**Description:** `app.app_config` (public read) with `min_supported_build`, `recommended_build`,
`maintenance_message`; helper `app.assert_client_supported(build int)` used by `sync_push` ([1.4]).
Client UX lives in [9.2] T9.2.07.
**Tests:** pgTAP for read access and the assert helper.

### T1.2.12 — pg_cron + pg_net + Vault wiring (`app.invoke_edge`)
**Priority:** P1 · **Size:** M · **Depends on:** T1.2.09
**Description:** Store the functions base URL and `CRON_SECRET` in Vault; helper
`private.invoke_edge(fn text, body jsonb)` using `net.http_post` with the secret header; a heartbeat job
(`'1 minute'`) writing `private.ops_heartbeats` for monitoring; cleanup job for `cron.job_run_details`
(> 7 days); respect Supabase guidance (≤ 8 concurrent jobs, each ≤ 10 min).
**Acceptance criteria:** the heartbeat is visible in the Dashboard Cron UI; secrets never appear in
logs or `cron.job` definitions.
**Tests:** pgTAP for helper permissions (service role only).

### T1.2.13 — Firebase projects per flavor (FlutterFire)
**Priority:** P1 · **Size:** M · **Depends on:** [1.1] (flavors)
**Description:** Create `everslot-dev` and `everslot-prod` Firebase projects; register Android & iOS apps
per flavor; `flutterfire configure` per flavor → `firebase_options_dev.dart` / `_prod.dart`,
`google-services.json` per Android flavor directory, `GoogleService-Info.plist` per iOS configuration;
Analytics collection disabled (`FIREBASE_ANALYTICS_COLLECTION_ENABLED=false`).
**Acceptance criteria:** `Firebase.initializeApp` succeeds in both flavors; no analytics events sent.
**Tests:** bootstrap smoke test in both flavors.

### T1.2.14 — APNs key & iOS push capabilities
**Priority:** P1 · **Size:** S · **Depends on:** T1.2.13
**Description:** Create an APNs auth key (.p8), upload to both Firebase projects (Key ID, Team ID);
enable Push Notifications, Time Sensitive Notifications and Background Modes (remote notifications,
background fetch, background processing) capabilities; configure the UIScene-compatible notification
delegate (`configureNotificationCenterDelegate()` in AppDelegate).
**Acceptance criteria:** a test push from the Firebase console reaches a device (dev flavor).

### T1.2.15 — Crashlytics integration
**Priority:** P1 · **Size:** S · **Depends on:** T1.2.13, [1.3] (error handling)
**Description:** `firebase_crashlytics` wired to the global error handlers (release builds only), user
opt-out setting ([8.3]), no PII (user id hashed or omitted), dSYM/mapping upload in release builds ([9.2]).
**Acceptance criteria:** a forced test crash appears in the Crashlytics dashboard for the dev project.

### T1.2.16 — Database advisors & security baseline in CI
**Priority:** P1 · **Size:** S · **Depends on:** T1.2.07
**Description:** Run `supabase db lint` / security & performance advisors in CI (fail on errors); disable
unused auth providers; email confirmation on; minimum password length; rate limits reviewed; RLS on
every `app` table (enforced by [9.1] T9.1.06).
**Acceptance criteria:** CI fails on advisor errors; the security checklist in `supabase/README.md` is complete.

### T1.2.17 — Generated TypeScript types for Edge Functions
**Priority:** P1 · **Size:** S · **Depends on:** T1.2.09
**Description:** `supabase gen types typescript --local > supabase/functions/_shared/database.types.ts`
script; CI check that types are up to date after migrations.
**Acceptance criteria:** a migration without regenerated types fails CI with the regeneration command in the message.
