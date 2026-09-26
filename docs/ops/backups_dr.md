# Backups and disaster recovery (T9.2.15)

**Owner:** project lead. **Drill:** quarterly, and once before launch (acceptance criterion). Records go in
the drill log at the end.

## What must survive

| Asset | Where it lives | Backed up by |
|---|---|---|
| App data, Auth users, Vault, cron jobs | Supabase Postgres | Supabase backups / PITR, weekly dump |
| Attachment files | Supabase Storage bucket `attachments` | **not** in database backups: nightly copy (§ 3) |
| Schema, functions, config | git (`supabase/`) | the repository |
| Edge secrets, API keys | Supabase and CI secrets | re-issued; password manager if not re-issuable |
| Device data | each device (offline-first copy) | not a backup: see "post-restore resync" |

The privacy policy promises that backups are overwritten **within 30 days**: never configure a retention
longer than 30 days anywhere below.

## 1. Targets

| | At launch (daily backups) | With point-in-time recovery |
|---|---|---|
| RPO database | 24 h | ≈ 2 min (WAL archived every 2 minutes) |
| RPO files | 24 h (nightly copy) | 24 h |
| RTO | 4 h | 2 h |

Switch on point-in-time recovery (7 days) when there are more than ~1 000 weekly active users or paying
users, whichever comes first (Project Settings › Add-ons; needs Small compute or larger).

## 2. Database backups

- Pro plan: daily backups kept 7 days — Database › Backups › *Scheduled backups*. Check after the first
  night that one is listed.
- Point in time (when enabled): Database › Backups › *Point in time*, retention 7 days (14 or 28 allowed by
  the add-on; stay ≤ 28 days).
- Independent weekly logical dump (protects against losing the project itself), e.g. from a CI job with
  `SUPABASE_DB_URL` as secret, stored encrypted in the backup bucket of § 3 with 30-day expiry:

  ```bash
  supabase db dump --db-url "$SUPABASE_DB_URL" -f roles.sql --role-only
  supabase db dump --db-url "$SUPABASE_DB_URL" -f schema.sql
  supabase db dump --db-url "$SUPABASE_DB_URL" -f data.sql --use-copy --data-only
  tar czf "everslot-db-$(date +%F).tgz" roles.sql schema.sql data.sql   # then encrypt + upload
  ```

## 3. Storage bucket backup

Database backups contain only the `storage.objects` rows, not the files. Copy the bucket every night to an
external S3-compatible bucket (e.g. Backblaze B2 or AWS S3, same jurisdiction as the Supabase region) with
**versioning on** and a lifecycle rule that deletes non-current versions after **30 days**, so files deleted
by users disappear from the backup within the promised window.

```ini
# rclone.conf — built from CI secrets at run time, never committed
[supabase]
type = s3
provider = Other
endpoint = https://<YOUR_PROJECT_REF>.storage.supabase.co/storage/v1/s3
region = <SUPABASE_REGION_CODE>
access_key_id = <S3_ACCESS_KEY_ID>          # Storage › Settings › S3 connection
secret_access_key = <S3_SECRET_ACCESS_KEY>

[backup]
type = s3
provider = <PROVIDER>
endpoint = <BACKUP_ENDPOINT>
access_key_id = <BACKUP_KEY_ID>
secret_access_key = <BACKUP_SECRET>
```

```bash
rclone sync supabase:attachments backup:everslot-attachments --checksum --fast-list   # nightly
rclone copy backup:everslot-attachments supabase:attachments --checksum   # restore (or one prefix)
```

The Supabase S3 keys bypass RLS: keep them only as CI secrets of the backup job, enable server-side
encryption on the backup bucket and give its credentials to nobody else.

## 4. Restore drill (quarterly, into staging)

1. **Staging project** `everslot-staging`, same region, only the owner as member, no Firebase secrets.
2. **Restore the database** — Database › Backups › *Restore to a new project* when the plan offers it;
   otherwise restore the latest weekly dump:

   ```bash
   psql --single-transaction --variable ON_ERROR_STOP=1 --file roles.sql --file schema.sql \
     --command 'SET session_replication_role = replica' --file data.sql --dbname "$STAGING_DB_URL"
   ```

3. **Restore files**: copy a sample user prefix (or everything) from the backup bucket into staging.
4. **Checks** (note each result in the drill log):
   - row counts per table against production at backup time:
     `select t, (xpath('/row/c/text()', query_to_xml(format('select count(*) as c from app.%I', t), false,
      true, '')))[1]::text::int from app.synced_tables() t;`
   - `select jsonb_pretty(private.ops_health());` answers; `cron.job` lists the three jobs;
   - the pgTAP suite runs against staging: `supabase test db --db-url "$STAGING_DB_URL"` (tests run in
     transactions and roll back; tests that expect the local seed users are noted, not fixed);
   - `supabase functions deploy --project-ref <STAGING_REF>`, then `health` answers `ok`;
   - a dev build pointed at staging (`env/staging.json`) signs in with a staging-only test account and two
     devices converge (manual sync check of `docs/qa/qa_checklist.md`).
5. **Measure** the RTO (start of step 2 → checks green) and the RPO (age of the backup used).
6. **Clean up**: the staging copy holds real personal data — never connect real users' devices to it and
   delete the restored data (or the project) within 7 days of the drill.

## 5. Production restore (disaster)

1. Declare the incident; set the in-app message if the app shows it:

   ```sql
   update app.app_config set value = to_jsonb('Sync is paused for maintenance.'::text)
    where key = 'maintenance_message';
   ```

2. Choose the point: newest backup (or PITR timestamp) before the damage.
3. Database › Backups › *Restore* (in place; the project is unavailable while it runs). Restoring to a new
   project instead would need a new app build, because the Supabase URL is compiled into the app — a custom
   domain (Supabase add-on) removes that constraint and is worth enabling before launch.
4. Re-apply migrations newer than the backup: `supabase db push` (from the release tag).
5. Check secrets and schedules: Vault `functions_base_url` / `cron_secret`, Edge secrets, the three cron
   jobs (`docs/ops/supabase_prod.md` § 6–7).
6. **Post-restore resync — known gap (owner: sync/backend).** The sync protocol assumes revisions only grow
   (arch §6.6). A restore rewinds `app.sync_heads`, so devices whose cursor is above the restored head would
   skip the next changes. Until a scripted procedure exists and has passed a drill (for example: raise every
   user's head revision above the pre-incident value, re-stamp rows and force a full resync through the
   purge watermark, with clients ending the resync at the returned head), the safe lever is to revoke every
   device (`app.devices.revoked_at`): apps then offer an export, sign out and resync cleanly from the server
   ([1.5] T1.5.14). Changes made after the backup point are lost (RPO).
7. Files: copy objects missing since the backup from the storage backup; objects uploaded after the backup
   whose rows were lost become orphans — enqueue them for deletion after checking.
8. Clear the message (`value = 'null'::jsonb`), tell users what happened (support template T-9), write the
   post-mortem.

## Drill log

| Date | Backup used (age) | RTO measured | Checks | Issues / follow-ups | By |
|---|---|---|---|---|---|
| | | | | | |
