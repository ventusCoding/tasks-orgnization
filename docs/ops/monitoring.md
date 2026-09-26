# Monitoring and alerting (T9.2.14)

**Owner:** project lead (on call). **Acceptance:** an injected failure (disabled cron job) raises an alert
within 10 minutes (drill in § 2.3). Each alert links to a runbook in `docs/ops/runbooks.md`.

## 1. Signals and thresholds

`ops` = `app.ops_health()` (via the `health` Edge Function, § 2); `LE` = Supabase Logs Explorer (§ 4).

| Signal | Source | Warn | Alert | Runbook |
|---|---|---|---|---|
| `dispatcher_lag_seconds` (oldest due pending job) | ops | > 120 s | > 180 s twice | Push outage |
| `heartbeats.cron.age_seconds` (minutely job) | ops | > 150 s | > 300 s | Push outage |
| `heartbeats.push_dispatch.age_seconds` | ops | > 120 s | > 300 s | Push outage |
| `heartbeats.daily_maintenance.age_seconds` | ops | > 26 h | > 50 h | Push outage (cron) |
| `jobs.pending_due` | ops | > 100 | > 1 000 | Push outage |
| `jobs.failed_last_hour` | ops | > 10 | > 100 | Push outage |
| `invalid_token_rate_last_hour` (≥ 50 attempts) | ops | > 0.10 | > 0.30 | Push outage |
| `account_deletions_pending` | ops | > 0 for 1 h | > 0 for 24 h | Account deletion |
| `storage_deletions_pending` | ops | grows 3 days | — | Data-loss / storage |
| Edge Function 5xx rate | LE (d), (e) | > 1 % / hour | > 5 % / hour | Push outage, Sync errors |
| RPC / database errors | LE (a), (b) | 3 × the 7-day baseline | `server_error` bursts | Sync errors spike |
| Auth failures (OTP, verify, refresh) | LE (c) | 3 × baseline | e-mail send errors | Auth e-mails |
| Crash-free users (7 days) | Crashlytics | < 99.5 % | velocity alert | halt the rollout |
| Database size, storage size | § 5 SQL, Usage | 70 % of quota | 80 % of quota | `cost_quotas.md` |

## 2. Uptime checks

### 2.1 Liveness (public)

Any uptime service, every minute: `GET https://<YOUR_PROJECT_REF>.supabase.co/functions/v1/health`, expect
HTTP 200 and the body to contain `"status":"ok"`; alert after two failures. No secret involved; it proves the
Edge runtime and the project answer.

### 2.2 Dispatcher and cron (authorised)

The same URL with the header `x-cron-secret: <CRON_SECRET>` adds `checks.db` and `checks.ops` (the
`app.ops_health()` snapshot). Assert every minute, alert after two consecutive failures:

```bash
curl -fsS -H "x-cron-secret: $CRON_SECRET" "https://$REF.supabase.co/functions/v1/health" | jq -e '
  .checks.db == "ok"
  and .checks.ops.dispatcher_lag_seconds < 180
  and (.checks.ops.heartbeats.cron.age_seconds // 1e9) < 300
  and (.checks.ops.heartbeats.push_dispatch.age_seconds // 1e9) < 300'
```

Use a monitor that supports custom headers and JSON (or keyword) assertions — for example Better Stack,
Checkly or UptimeRobot — or run the script from any scheduler that can page you. GitHub Actions `schedule`
runs can start many minutes late, so use them only as a secondary check.

> **Security.** `CRON_SECRET` also authorises the cron-only endpoints: `push-dispatch`, `sync-nudge`,
> `storage-purge` and `account-delete` **for any user id**. Store it only in a monitor with encrypted secrets
> and 2FA, limit who can read it, rotate it quarterly (runbook *Secret exposure*). Follow-up (owner:
> backend): give `health` its own read-only secret (e.g. `HEALTH_SECRET`) so monitors never hold
> `CRON_SECRET`.

### 2.3 Drill (acceptance test, repeat quarterly)

```sql
-- 1. Stop the minutely job: the "cron" heartbeat stops moving.
select cron.alter_job(job_id := (select jobid from cron.job where jobname = 'everslot-minutely'),
                      active := false);
-- 2. Wait for the alert (≈ 6–7 minutes with a 1-minute monitor), note the times, then restore:
select cron.alter_job(job_id := (select jobid from cron.job where jobname = 'everslot-minutely'),
                      active := true);
```

Repeat with `everslot-push-dispatch` while a job is due (a reminder planned on a device that does not cover
it) to see the lag alert. Record: date, job, disabled at, alerted at, restored at.

## 3. Crashlytics alerts

- Firebase console › Project settings › **Alerts** › Crashlytics: new fatal issues, regressed issues,
  velocity alerts and trending stability issues by e-mail to the owner (each member opts in).
- **Velocity alerts** tab: default 1 % of sessions and 25 users; during the beta use 1 % and the minimum of
  10 users so small cohorts still trigger.
- Optional: Project settings › Integrations › Slack (or Jira/PagerDuty).
- Release gate: crash-free users ≥ 99.5 % per version (dashboard filter by version).

## 4. Logs Explorer saved queries

Supabase dashboard › Logs & Analytics › Logs Explorer: paste, run, *Save query* with the name in bold. The
dialect is BigQuery SQL; choose the time range in the picker (e.g. last 24 hours). If a field is missing,
check the source's schema in the side panel — log schemas evolve. Supabase does not alert on these queries:
review them daily in launch weeks, or send the logs to an alerting tool with a log drain (plan-dependent).

**(a) RPC and database errors by code** — API errors are raised with SQLSTATE `PGRST` and a JSON message
(`app.raise_api_error`). Expected noise: `unsupported_client` after a minimum-build bump, `device_revoked`.
Investigate `server_error`, deadlocks `40P01`, serialization failures `40001`, statement timeouts `57014`.

```sql
select
  regexp_extract(event_message, r'"code"\s*:\s*"([a-z_]+)"') as api_code,
  parsed.error_severity,
  parsed.sql_state_code,
  count(*) as errors
from postgres_logs
  cross join unnest(metadata) as m
  cross join unnest(m.parsed) as parsed
where parsed.error_severity in ('ERROR', 'FATAL', 'PANIC')
group by api_code, parsed.error_severity, parsed.sql_state_code
order by errors desc
limit 50
```

**(b) Failing REST and RPC calls by path**

```sql
select
  request.path,
  response.status_code,
  count(*) as calls
from edge_logs
  cross join unnest(metadata) as m
  cross join unnest(m.request) as request
  cross join unnest(m.response) as response
where response.status_code >= 400
  and request.path like '/rest/v1/%'
group by request.path, response.status_code
order by calls desc
limit 50
```

**(c) Auth failures** — look for `/otp` 429 (rate limits), `/verify` 4xx (expired or wrong codes), SMTP
errors in `msg`, bursts of refresh-token errors.

```sql
select
  metadata.path,
  metadata.status,
  metadata.msg,
  count(*) as events
from auth_logs
  cross join unnest(metadata) as metadata
where metadata.level = 'error'
   or safe_cast(metadata.status as int64) >= 400
group by metadata.path, metadata.status, metadata.msg
order by events desc
limit 50
```

**(d) Edge Function errors** — failing invocations, then the error lines our functions log as JSON
(`{"level":"error","event":"push_dispatch.failed",…}`, `_shared/log.ts`). The function page in the dashboard
shows the id of each function.

```sql
select
  m.function_id,
  response.status_code,
  count(*) as invocations
from function_edge_logs
  cross join unnest(metadata) as m
  cross join unnest(m.response) as response
where response.status_code >= 500
group by m.function_id, response.status_code
order by invocations desc
```

```sql
select
  regexp_extract(event_message, r'"event":"([^"]+)"') as event,
  count(*) as lines
from function_logs
  cross join unnest(metadata) as m
where m.level = 'error' or regexp_contains(event_message, r'"level":"error"')
group by event
order by lines desc
```

**(e) Edge Function error rate per hour**

```sql
select
  timestamp_trunc(function_edge_logs.timestamp, hour) as hour,
  count(*) as calls,
  round(countif(response.status_code >= 500) / count(*), 4) as error_rate
from function_edge_logs
  cross join unnest(metadata) as m
  cross join unnest(m.response) as response
group by hour
order by hour desc
```

## 5. SQL checks (SQL editor or `psql "$PROD_DB_URL"`)

```sql
select jsonb_pretty(private.ops_health());
select name, now() - last_run_at as age, details from private.ops_heartbeats order by name;
select status, count(*) from private.notification_jobs group by status order by 2 desc;
select outcome, error_code, count(*) from private.push_deliveries
 where created_at > now() - interval '1 hour' group by 1, 2 order by 3 desc;
select j.jobname, d.status, d.start_time, d.return_message
  from cron.job_run_details d join cron.job j using (jobid)
 where d.status <> 'succeeded' order by d.start_time desc limit 20;
-- Storage growth per week and database size (weekly):
select date_trunc('week', created_at) as week, count(*) as objects,
       pg_size_pretty(sum((metadata ->> 'size')::bigint)) as added
  from storage.objects where bucket_id = 'attachments' group by 1 order by 1 desc limit 12;
select pg_size_pretty(pg_database_size(current_database())) as database_size;
-- Recently active devices without a push token (FCM/APNs registration problems):
select platform, count(*) from app.devices
 where revoked_at is null and push_token is null and last_seen_at > now() - interval '7 days'
 group by platform;
```

## 6. On call

- Alerts go to the owner's e-mail and phone (monitor app push). Acknowledge alert-level signals within
  1 hour in waking hours; warn-level signals the next business day.
- Local notifications keep working during backend incidents, so most incidents degrade cross-device
  delivery and sync rather than stopping the app.
- After a P0 incident, add a short post-mortem (what, impact, cause, fix, follow-ups) to the release PR or an
  issue labelled `incident`.
