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

<!-- README part 2 -->
