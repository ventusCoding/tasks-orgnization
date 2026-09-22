# Runbooks (T9.2.17)

## Push outage
1. Check `select * from private.ops_health();` (dispatcher lag, pending jobs, last cron run).
2. Check Edge Function logs for `push-dispatch` (FCM auth errors → rotate `FCM_SERVICE_ACCOUNT`).
3. Local notifications keep working on devices; only cross-device/backup pushes are affected.

## Sync errors spike
1. Crashlytics/logs: look for `unsupported_client`, `integrity_refetch`, RLS errors.
2. `select * from app.sync_heads order by updated_at desc limit 20;` to see activity.
3. If a migration broke `sync_push`, ship a forward-fix migration; clients retry automatically.

## Auth emails not delivered
Check SMTP provider status and Supabase Auth logs; temporarily enable magic link fallback.

## Data-loss report
1. Ask the user for an export (Settings › Data › Export) from every device.
2. Inspect `activity_events` for the entity; restore from tombstones (Trash) or PITR if needed.

## Account deletion request by email
Run the `account-delete` Edge Function for the user id (service role) and confirm by email.

## Sign in with Apple secret rotation (every 6 months)
Generate a new client secret JWT from the Apple key and update it in Supabase Auth › Providers › Apple.
Calendar reminder 30 days before expiry.

## Restore
Restore a backup/PITR into a staging project, run `supabase test db` and the sync suite against it,
then follow Supabase's restore procedure for production.
