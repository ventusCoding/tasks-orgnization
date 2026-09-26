# Cost and quota monitoring (T9.2.18)

**Owner:** project lead. **When:** the first business day of each month (recurring calendar reminder), plus
the alerts below. Goal: no surprise bill and no quota hit — act at **80 %** of any quota.

## Quotas to watch

Supabase Pro plan as of 2026-09 — check supabase.com/pricing before relying on the numbers.

| Metric | Included (Pro) | Overage | 80 % mark |
|---|---|---|---|
| Database disk | 8 GB | $0.125 / GB | 6.4 GB |
| Egress | 250 GB | $0.09 / GB | 200 GB |
| File storage | 100 GB | $0.021 / GB | 80 GB |
| Monthly active users | 100 000 | $0.00325 / MAU | 80 000 |
| Edge Function invocations | 2 million | $2 / million | 1.6 million |
| Realtime peak connections | 500 | $10 / 1 000 | 400 |
| Realtime messages | 5 million | $2.50 / million | 4 million |
| Compute | Micro (credit included) | per size | CPU or RAM 80 % for days |

Everslot-specific drivers:

- **Edge invocations**: `push-dispatch` runs every 30 s (≈ 86 400 / month), uptime checks add 43 200 per
  1-minute monitor, and `sync-nudge` runs once per write burst of a user who has another push-capable device
  — the main variable (≈ active multi-device users × sync pushes per day × 30). If it grows too fast, raise
  the nudge throttle in `sync-nudge` rather than the plan.
- **Realtime**: one private channel per foreground app; peaks follow daily usage.
- **Egress**: initial syncs (full pulls) and attachment downloads; thumbnails are cached on devices.
- **Disk**: `activity_events` and `habit_logs` grow fastest; tombstones are purged after 90 days.
- **Firebase**: FCM and Crashlytics are free on the Spark plan; FCM limits (600 000 messages per minute
  per project, per-device rates) are far above our needs.
- **GitHub Actions**: macOS minutes count ×10 on private repositories (`release.yml` iOS job) — check the
  monthly minutes.
- Fixed costs: Supabase Pro (+ add-ons: PITR, custom domain), Apple Developer Program (yearly), Google Play
  registration (one-off), domain renewal, backup bucket, uptime monitor.

## Alerts at 80 %

- **Supabase**: keep the spend cap on (Organization › Billing › Cost control) until usage is understood;
  the Usage page shows every quota, but Supabase does not e-mail at 80 %, so run the weekly check below
  (a scheduled CI job or by hand) and alert yourself when a value passes its 80 % mark.
- **Google Cloud / Firebase** (only if the project moves to Blaze): Billing › Budgets & alerts, budget of a
  few dollars with alerts at 50 %, 80 % and 100 %.
- **GitHub**: Settings › Billing › spending limit for Actions, usage e-mails on.

Weekly check (SQL editor or `psql "$PROD_DB_URL"`):

```sql
select pg_size_pretty(pg_database_size(current_database())) as database_size;
select pg_size_pretty(coalesce(sum((metadata ->> 'size')::bigint), 0)) as storage_size
  from storage.objects;
select count(*) filter (where last_sign_in_at > now() - interval '30 days') as mau_approx,
       count(*) as users
  from auth.users;
select relname, pg_size_pretty(pg_total_relation_size(relid)) as size
  from pg_catalog.pg_statio_user_tables order by pg_total_relation_size(relid) desc limit 10;
```

Edge invocations per function over 30 days (Logs Explorer, time range "Last 30 days"; map ids to names on the
function pages):

```sql
select m.function_id, count(*) as invocations
from function_edge_logs cross join unnest(metadata) as m
group by m.function_id
order by invocations desc
```

MAU as counted by Supabase includes token refreshes, so it can exceed the approximation above.

## Monthly review checklist

- [ ] Organization › Usage: every metric against its quota; fill the log below.
- [ ] Organization › Billing › Invoices: the last invoice matches expectations; add-ons still needed.
- [ ] Reports › Database: CPU / RAM / disk IO — is the compute size right?
- [ ] `supabase inspect db table-sizes --linked`, `index-sizes`, `bloat`: unexpected growth or bloat?
- [ ] Retention jobs ran: `details` of the `daily_maintenance` heartbeat show purged tombstones, deleted
      jobs and deliveries (`select details from private.ops_heartbeats where name = 'daily_maintenance';`).
- [ ] Storage growth per week (`docs/ops/monitoring.md` § 5); `storage_deletions_pending` not growing.
- [ ] Edge invocations by function; `sync-nudge` share.
- [ ] Realtime peak connections (Reports › Realtime).
- [ ] Firebase / Google Cloud billing (if Blaze), GitHub Actions minutes, renewals due in the next 60 days
      (Apple Developer Program, domain, monitor, backup storage).
- [ ] Projection: which quota reaches 80 % first at the current growth, and when? Decide now: tune, add-on,
      compute upgrade or plan change.

## Log

| Month | DB | Storage | Egress | MAU | Edge calls | Realtime peak | Cost | Actions |
|---|---|---|---|---|---|---|---|---|
| | | | | | | | | |
