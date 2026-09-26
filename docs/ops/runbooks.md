# Runbooks (T9.2.17)

Each runbook has an **owner** (the hat to wear — today the project lead wears all of them), a **trigger**
and numbered **steps** with the exact commands. Alerts come from `docs/ops/monitoring.md`; replies to users
use the templates of `docs/ops/support_templates.md`.

**Support inbox:** `[CONTACT EMAIL]`. First answer within 3 business days (EN/FR/AR); data-protection
requests (access, deletion) within one month at most.

Common setup — secrets come from the password manager and are never pasted into tickets, chat or logs:

```bash
export REF=<YOUR_PROJECT_REF>                          # project reference, not secret
export PROD_DB_URL='<session pooler connection string>'  # Dashboard › Connect
export CRON_SECRET='<value from the password manager>'   # = Edge secret CRON_SECRET = Vault cron_secret
psql "$PROD_DB_URL"                                    # the SQL below runs as postgres
```

## 1. Push outage (dispatcher lag, silent cron, FCM errors)

**Owner:** backend. **Trigger:** monitoring alert (lag > 3 min, `cron` or `push_dispatch` heartbeat older
than 5 min, invalid-token rate > 0.30, more than 100 failed jobs in an hour) or several users report missing
reminders on their other devices.

1. See which check fails:
   `curl -s -H "x-cron-secret: $CRON_SECRET" https://$REF.supabase.co/functions/v1/health | jq .checks`
2. Cron jobs:

   ```sql
   select jobid, jobname, schedule, active from cron.job order by jobname;
   select j.jobname, d.status, d.start_time, d.return_message
     from cron.job_run_details d join cron.job j using (jobid)
    order by d.start_time desc limit 20;
   ```

   Inactive job → `select cron.alter_job(job_id := <jobid>, active := true);`. Failing → read
   `return_message`.
3. Calls from the database to the functions:

   ```sql
   select name from vault.decrypted_secrets
    where name in ('functions_base_url', 'cron_secret');          -- names only, never the values
   select id, status_code, error_msg, created from net._http_response order by created desc limit 20;
   ```

   `401` → the Vault `cron_secret` and the Edge secret `CRON_SECRET` differ: set both again (runbook 8).
   `5xx` → function logs (`monitoring.md` § 4 d).
4. FCM results of the last hour:

   ```sql
   select outcome, error_code, count(*) from private.push_deliveries
    where created_at > now() - interval '1 hour' group by 1, 2 order by 3 desc;
   ```

   - `THIRD_PARTY_AUTH_ERROR` or APNs errors → APNs key revoked: upload a new `.p8`
     (`docs/ops/firebase_prod.md` § 2).
   - `UNAUTHENTICATED` / `PERMISSION_DENIED` → sender key deleted or role missing: rotate it
     (`firebase_prod.md` § 4); `health` must show `fcm_configured: true`.
   - `QUOTA_EXCEEDED` → retried with back-off automatically; look for a loop that sends too much.
   - `UNREGISTERED` burst → tokens are cleared automatically; check token handling in the last app release.
5. Provider status: status.supabase.com, status.firebase.google.com, developer.apple.com/system-status.
6. While it is broken: local notifications still fire on every device; cross-device pushes, silent sync
   nudges and inbox rows for uncovered devices wait. Jobs past their `expires_at` are dropped, so there is no
   flood after recovery.
7. Verify: `dispatcher_lag_seconds` below 60, heartbeats fresh, `jobs.pending_due` draining.
8. Longer than an hour: set the maintenance message (`backups_dr.md` § 5, step 1) and answer reports with
   T-8.

## 2. Sync errors spike

**Owner:** backend. **Trigger:** Logs Explorer queries (a)/(b) show three times the usual errors on
`/rest/v1/rpc/sync_push` or `sync_pull`, Crashlytics non-fatals about sync, or users report a sync error in
*Settings › Sync & data*.

1. Find the codes: `monitoring.md` § 4 queries (a) and (b).
2. By code:
   - `unsupported_client` (426): expected after raising `min_supported_build`; otherwise check
     `select key, value from app.app_config;` and restore the previous value.
   - `device_revoked` (403): a user revoked a device — expected.
   - `too_many_changes` (413), `invalid_request` (400), `invalid_clock`, `unknown_column`: client bug →
     hotfix the app (runbook 10).
   - `integrity_refetch` bursts: find the constraint (`DL001`–`DL007` in `postgres_logs.event_message`) and
     the app version that sends those groups.
   - `server_error`, deadlocks `40P01`, serialization `40001`, timeouts `57014`: database load →
     `supabase inspect db long-running-queries --linked`, `supabase inspect db blocking --linked`, Reports ›
     Query performance.
3. Is anyone syncing? `select user_id, head_rev, updated_at from app.sync_heads order by updated_at desc
   limit 20;`
4. A migration broke an RPC: ship a forward-fix migration — never roll back (`docs/ops/schema_evolution.md`).
   Clients keep their outbox and retry by themselves.
5. An app build corrupts data: halt the rollout and, once the fix is in the stores, block the bad build:
   `update app.app_config set value = '<FIRST_GOOD_BUILD>'::jsonb where key = 'min_supported_build';`
6. Verify: error rate back to its baseline for an hour; affected users' `head_rev` moving again.

## 3. Stuck or failed migration

**Owner:** backend. **Trigger:** the *Deploy backend* job of `release.yml` fails at `supabase db push` or
runs for more than 10 minutes, or someone applied SQL by hand.

`supabase db push` applies each pending file in its own transaction and records it in
`supabase_migrations.schema_migrations`; a failing file rolls back and later files do not run. The app jobs
of `release.yml` start only after the backend job succeeds, so no app ships against a half-migrated schema.

1. Do not re-run blindly: read the job log (file and error).
2. Hanging → find what it waits for:

   ```bash
   supabase inspect db blocking --linked
   supabase inspect db locks --linked
   supabase inspect db long-running-queries --linked
   ```

   ```sql
   select pid, state, wait_event_type, wait_event, now() - query_start as age, left(query, 100) as query
     from pg_stat_activity
    where datname = current_database() and state <> 'idle'
    order by age desc;
   ```

3. A long transaction blocks it (a job, an open SQL editor session): `select pg_cancel_backend(<pid>);`, then
   `select pg_terminate_backend(<pid>);` if needed. Re-run the failed job.
4. It failed on an error: fix forward. A file never applied anywhere may be corrected in a PR; a file already
   applied on another environment is never edited — add a new migration instead.
5. History out of step (e.g. a fix run by hand in the SQL editor):

   ```bash
   supabase migration list --linked                                 # local vs remote
   supabase migration repair --status applied <VERSION> --linked    # only after checking the schema!
   supabase migration repair --status reverted <VERSION> --linked
   ```

6. Prevention: start risky DDL with `set lock_timeout = '5s';`, split backfills into batches
   (expand → migrate → contract), and run `supabase db push --dry-run` against production in the release PR.
7. Verify: `supabase migration list --linked` shows nothing pending, the smoke check of `release.yml` passes,
   `health` answers `ok`.

## 4. Auth e-mails not delivered

**Owner:** backend. **Trigger:** users report that no code arrives; Logs Explorer query (c) shows SMTP
errors or `429` on `/otp`; bounce alerts from the SMTP provider.

1. Auth logs (`monitoring.md` § 4 c): SMTP errors in `msg`, rate-limit `429`s.
2. Legitimate volume above the limit: Authentication › Rate Limits › e-mails per hour.
3. SMTP provider dashboard: incidents, suppression list (hard bounces), quota, domain verification. DNS:
   `dig +short TXT YOUR_SITE_DOMAIN`, `dig +short TXT _dmarc.YOUR_SITE_DOMAIN` and the DKIM selector record.
4. Apple relay addresses (`@privaterelay.appleid.com`) need the sender registered in *Sign in with Apple for
   Email Communication* (`store_compliance.md`).
5. Send yourself a code in EN, FR and AR from the app with a test account.
6. Meanwhile users can sign in with Google or Apple, or continue as a guest and link later (template T-3).
7. Verify: codes arrive within a minute and the logs stay clean for an hour.

## 5. Data-loss report

**Owner:** project lead. **Trigger:** a user reports missing or reverted data (first reply: T-5).

1. Ask for the account e-mail, the approximate time, what is missing, the app version and whether another
   device still shows it; ask them not to sign out or reinstall on such a device, and to send an export
   (*Settings › Sync & data*) from each device.
2. Find the user and the history — never copy user content into tickets:

   ```sql
   select id from auth.users where lower(email) = lower('<EMAIL>');
   select entity_type, entity_id, event_type, occurred_at,
          payload ->> 'opId' as op_id, payload ->> 'cause' as cause
     from app.activity_events
    where user_id = '<USER_ID>' and event_type in ('deleted', 'moved', 'status_changed', 'reset')
    order by occurred_at desc limit 50;
   ```

3. In the Trash (deleted less than 30 days ago): guide the user to restore it.
4. Tombstoned but not purged (less than 90 days): restore on the server with a fresh clock so every device
   accepts the change, including the children deleted in the same operation (same `op_id`):

   ```sql
   update app.checklist_items                    -- same pattern for tasks, checklists, habits, habit_logs…
      set deleted_at = null,
          field_clock = field_clock || jsonb_build_object('deleted_at', app.hlc_at(now()))
    where user_id = '<USER_ID>' and deleted_at is not null
      and id = any ('{<ID_1>,<ID_2>}'::uuid[]);
   ```

5. Purged (older than 90 days) or overwritten: restore the backup into staging (`backups_dr.md` § 4), copy
   the rows back with fresh clocks and the files from the storage backup.
6. A field "went back": per-field last-writer-wins by HLC decided it; compare the row's `field_clock` with the
   user's story (device clock far off?) and explain.
7. Close with the user; if a bug is involved, open an issue labelled `data-loss` (P0).

## 6. Account deletion request by e-mail

**Owner:** project lead. **Trigger:** an e-mail asking to delete an account (the deletion page tells users
how). **Deadline:** 30 days (privacy policy); aim for 3 business days.

1. The request must come from the account's address (or the Apple relay address that forwards to the user).
   Otherwise answer with T-6a and do not reveal whether an account exists.
2. Find the account:

   ```sql
   select id, created_at, last_sign_in_at, is_anonymous
     from auth.users where lower(email) = lower('<EMAIL>');
   ```

3. Delete it — idempotent; removes the storage objects, devices and jobs, then the Auth user, which cascades
   every app row:

   ```bash
   curl -fsS -X POST "https://$REF.supabase.co/functions/v1/account-delete" \
     -H "x-cron-secret: $CRON_SECRET" -H "content-type: application/json" \
     -d '{"user_id":"<USER_ID>"}'
   # → {"deleted":true,"already_deleted":false,"objects_deleted":<n>}
   ```

4. Verify (both must return 0):

   ```sql
   select count(*) from auth.users where id = '<USER_ID>';
   select count(*) from storage.objects where bucket_id = 'attachments' and name like '<USER_ID>/%';
   ```

5. Sign in with Apple users: until token revocation ships (`store_compliance.md`, blocking item 1), tell
   them they can also remove Everslot under Settings › their name › Sign in with Apple on their iPhone.
6. Confirm with T-6b. Keep only the request e-mail and the date as proof; delete the rest of the thread.

## 7. Sign in with Apple client-secret rotation (every 6 months)

**Owner:** project lead. **Trigger:** the calendar reminder **30 days before expiry** (create it right after
each rotation: "Rotate the Apple client secret — expires on <DATE>"), or Apple sign-in on Android failing
with `invalid_client`.

Android signs in with Apple through Supabase's web flow, which needs a client secret: a JWT signed with the
Sign in with Apple key (`AuthKey_<KEY_ID>.p8`), valid for at most 6 months. iOS native sign-in does not use
it.

1. Collect the Team ID, the Key ID (Apple Developer › Keys, key with *Sign in with Apple*), the Services ID
   (the web client id) and the `.p8` from the password manager.
2. Generate the secret with Deno (already used for the Edge Functions):

   ```bash
   deno run --allow-read - <<'TS'
   import { importPKCS8, SignJWT } from "npm:jose@6";
   const key = await importPKCS8(await Deno.readTextFile("AuthKey_<KEY_ID>.p8"), "ES256");
   const now = Math.floor(Date.now() / 1000);
   console.log(await new SignJWT({})
     .setProtectedHeader({ alg: "ES256", kid: "<KEY_ID>" })
     .setIssuer("<TEAM_ID>").setSubject("<SERVICES_ID>").setAudience("https://appleid.apple.com")
     .setIssuedAt(now).setExpirationTime(now + 180 * 24 * 3600)
     .sign(key));
   TS
   ```

3. Supabase: Authentication › Sign In / Providers › Apple › *Secret Key (for OAuth)* → paste and save. Once
   token revocation uses it, also `supabase secrets set --project-ref $REF APPLE_CLIENT_SECRET=<JWT>`.
4. Verify: Sign in with Apple on an Android build works.
5. Record the new expiry below and move the calendar reminder to 30 days before it.

| Issued | Expires (issued + 180 days) | Reminder on | By |
|---|---|---|---|
| | | | |

## 8. Secret exposure or routine rotation

**Owner:** backend. **Trigger:** a secret was pasted somewhere, a device holding secrets is lost, someone
with access leaves, or the quarterly rotation of `CRON_SECRET`.

- `CRON_SECRET` (Edge secret and Vault must match):

  ```bash
  NEW=$(openssl rand -base64 48 | tr -d '\n=+/')
  supabase secrets set --project-ref $REF CRON_SECRET="$NEW"
  psql "$PROD_DB_URL" -c "select vault.update_secret(
    (select id from vault.secrets where name = 'cron_secret'), '$NEW');"
  ```

  Then update the uptime monitor's header. Verify `health` with the new value and 2xx responses in
  `net._http_response` (runbook 1, step 3).
- FCM sender key: `docs/ops/firebase_prod.md` § 4 (rotation).
- Supabase secret key: Project Settings › API Keys › new secret key → `supabase secrets set
  SUPABASE_SECRET_KEY=<new>` → check `health` and one push → delete the old key.
- Publishable key: public by design; rotating it needs an app release — only if it is abused.
- Database password: Project Settings › Database › reset, then the CI secret `SUPABASE_DB_PASSWORD`.
- Apple keys (APNs, Sign in with Apple): revoke and recreate in Apple Developer › Keys, then
  `firebase_prod.md` § 2 and runbook 7.
- Storage S3 keys: Storage › Settings › S3 connection → revoke, create, update the backup job secrets.
- Signing: Android upload key → Play Console › App integrity › request an upload key reset; iOS
  certificates → revoke and regenerate with `fastlane match` (T9.2.02).
- Write down what leaked, where, and when each secret was rotated.

## 9. Restore from backup

Drill: `docs/ops/backups_dr.md` § 4. Production restore: § 5 (including the post-restore resync gap).

## 10. Bad release in the wild

**Owner:** release manager. **Trigger:** crash-free users below 99.5 % for the new version, a Crashlytics
velocity alert, or a P0 bug.

1. Stop the spread: Play Console › Test and release › Production › *Halt rollout*; App Store Connect › the
   version › *Pause phased release*.
2. Server-side issue: fix forward (runbook 2 or 3); risky server behaviour can be disabled by a feature flag.
3. Data at risk: once the fixed build is in the stores, raise `min_supported_build` above the bad build
   (runbook 2, step 5) — old builds stop syncing and show the update screen.
4. Hotfix: branch, fix, tag, staged rollout again (`docs/ops/release_checklist.md`).
5. Tell affected users (template T-8) and write the post-mortem.
