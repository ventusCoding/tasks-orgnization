# Section 7.4 — Push (FCM) & Server Dispatch

> Milestones: M2 (P1) · M3 (P2) · Depends on: 1.2, 1.4, 1.5, 7.1, 7.2, 7.3
> Architecture: §6.13 (pipeline steps 3, 4, 7, 8), §7.3 (`devices`, `notification_jobs`, `push_deliveries`),
> §7.5–7.7 (RPCs, Edge Functions, cron), §9.7 (FCM/APNs constraints), §13 ADR-005

## Goal

Make reminders reach the user **even when the device can't deliver them locally**: iOS beyond its 64
pending slots, devices that are stale, force-stopped or lack exact alarms, other devices of the same user,
and server-originated events — using Firebase Cloud Messaging. Devices plan (Dart) and upload jobs; the
server only claims due jobs, re-checks guards, writes the inbox and sends FCM to devices that are **not**
covering the instance locally, so the user gets every reminder exactly once per device.

## Scope

**In:** FCM client integration, device registry push fields, jobs/deliveries schema and the
`replace_notification_jobs` RPC, job upload from devices, SQL guard catalog, the FCM sender module, the
`push-dispatch` Edge Function, cron schedules and reaper, payload design, device-side push handling, silent
sync pushes, completion-elsewhere handling, multi-device policy, iOS collapse spike, E2E tests, monitoring
hooks, server-side planning fallback (P2), email digests (P2), last-active policy (P2).
**Out:** Planning and local scheduling ([7.2]); inbox UI ([7.3]); trigger semantics ([7.5]); store
compliance and alerting infrastructure ([9.2]).

## Progress

- [x] T7.4.01 — FCM client integration
- [x] T7.4.02 — Device registry: push fields, state reporting & token hygiene
- [x] T7.4.03 — Jobs & deliveries schema + `replace_notification_jobs` RPC
- [x] T7.4.04 — Job upload pipeline (device → server)
- [x] T7.4.05 — Guard evaluator catalog (SQL)
- [x] T7.4.06 — FCM sender module (`_shared/fcm.ts`)
- [x] T7.4.07 — `push-dispatch` Edge Function
- [x] T7.4.08 — Cron schedules, lease reaper & cleanup
- [x] T7.4.09 — Push payload design & size budget
- [x] T7.4.10 — Device-side push handling
- [x] T7.4.11 — Silent sync push (`sync-nudge`)
- [x] T7.4.12 — Completion elsewhere & cross-device acknowledgement
- [x] T7.4.13 — Multi-device policy & primary device
- [ ] T7.4.14 — iOS local-vs-push collapse spike
- [x] T7.4.15 — End-to-end push tests
- [x] T7.4.16 — Monitoring hooks & ops metrics
- [x] T7.4.17 — Server-side planning fallback
- [ ] T7.4.18 — Email channel for digests
- [x] T7.4.19 — Last-active device policy

## Tasks

### T7.4.01 — FCM client integration
**Priority:** P1 · **Size:** M · **Depends on:** [1.2] (Firebase projects, APNs key), [1.4] (device registry), [7.2] (capability service)
**Description:** Integrate `firebase_messaging` 16.x (with `firebase_core`, per-flavor FlutterFire options):
APNs registration (Push capability, Background Modes `remote-notification`), UIScene delegate setup as the
plugin documents for the iOS 27 SDK, token retrieval (`getAPNSToken` before `getToken` on iOS),
`onTokenRefresh`, and reuse of the notification permission already granted via [7.2] (never a second prompt).
**Implementation notes:** iOS foreground presentation options `alert: false, sound: false, badge: true`
when in-app banners are enabled (Android does not show notification messages in the foreground by default);
`deleteToken()` + server nulling on sign-out and account deletion ([1.5]).
**Acceptance criteria:** a fresh install on both platforms reports a token within 5 s of sign-in; token
refresh updates the server within one app session.
**Tests:** unit tests with a fake messaging port; manual QA on physical iOS device (APNs sandbox + prod).
**Notes:** Client side. FCM starts only when `env.firebaseEnabled`, `DefaultFirebaseOptions.isConfigured` and Supabase are all configured (real Firebase projects are placeholders for now). It reuses the notification permission from [7.2]. Tests use `FakePushMessagingPort`; manual QA on a physical iOS device is still to do.

### T7.4.02 — Device registry: push fields, state reporting & token hygiene
**Priority:** P1 · **Size:** S · **Depends on:** T7.4.01, [1.4]
**Description:** Extend `app.register_device` / `app.report_device_state` with `push_token`,
`push_token_updated_at`, `capabilities`, `local_coverage_until`, `schedule_rev`, local repeating rules and
foreground timestamps; refresh the token timestamp at least monthly (FCM staleness guidance); treat tokens
not refreshed for > 30 days on devices unseen for > 30 days as stale (skip sends, keep row); Android
registrations older than 270 days are re-fetched on next launch.
**Data model:** `devices.local_repeating_rules uuid[]` (from [7.2] T7.2.11), `devices.last_nudged_at
timestamptz` (T7.4.11); `last_seen_at` defined as *last foreground* (used by the 72-h rule and last-active policy).
**Acceptance criteria:** stale tokens are never sent to; revoked devices never receive pushes.
**Tests:** pgTAP for RPC ownership checks and staleness predicate.
**Notes:** Client side: push token, capabilities, coverage, `schedule_rev`, `local_repeating_rules` and `last_seen_at` (on resume) are reported through `DeviceStateReporter`, and deferred offline. The token is re-reported on every start; Android re-registers after 270 days. The RPCs and pgTAP belong to the server work (`20260922000150_create_device_rpcs.sql`).

### T7.4.03 — Jobs & deliveries schema + `replace_notification_jobs` RPC
**Priority:** P1 · **Size:** M · **Depends on:** [1.2], [7.1]
**Description:** Migrations for `private.notification_jobs` and `private.push_deliveries` (arch §7.2–7.3:
server-only tables live in the non-exposed `private` schema) and the RPC
`app.replace_notification_jobs(p_device_id, p_target_keys text[], p_jobs jsonb, p_source_rev bigint)`
(`security definer`, pinned `search_path`, verifies the caller owns the device).
**Implementation notes:**
- Per target: if a pending job for that target has `source_rev > p_source_rev` → return `stale` for the
  target (monotonic guard); else delete its pending jobs with `fire_at > now()` and insert the new ones
  (`on conflict (user_id, dedupe_key) do update` only while pending). `'*'` = all targets of the user.
- Caps: ≤ 3 000 pending jobs per user, horizon ≤ 14 days, payload ≤ 3.5 KB → typed errors.
- Indexes: `(fire_at) where status = 'pending'`, `(user_id, target_key) where status = 'pending'`,
  `(lease_until) where status = 'claimed'`; `unique (job_id, device_id)` on `push_deliveries`.
**Data model:** `private.notification_jobs.rule_id uuid`, `occurrence_key text`, `target_devices uuid[]`
(rule `conditions.devices`), `planned_by_device uuid`, `importance text`; extend `push_deliveries.outcome`
with `skipped_policy`, `skipped_stale_token`, `expired`; add `unique (job_id, device_id)`.
**Acceptance criteria:** a stale device (older `source_rev`) cannot overwrite a newer plan; replacing a
target is atomic (no window with zero jobs visible to the dispatcher).
**Tests:** pgTAP: ownership, monotonic guard, caps, atomic replacement under concurrent calls.
**Notes:** `private.notification_jobs` / `private.push_deliveries` (20260922000100) and `app.replace_notification_jobs` (20260922000160): owner check, per-user advisory lock, monotonic `source_rev` guard, 3 000-job / 14-day / 3.5 KB caps, pending-only upsert. pgTAP: `090_notifications` (ownership, guard, caps, `'*'`) and `156_job_replace_concurrency` (two dblink sessions: the older concurrent upload waits, then answers `stale`; one plan visible).

### T7.4.04 — Job upload pipeline (device → server)
**Priority:** P1 · **Size:** M · **Depends on:** T7.4.03, [7.2] (planner, replan orchestrator)
**Description:** After each **successful sync push** (so `source_rev` includes the device's own writes),
the replan orchestrator uploads jobs for its dirty targets: the planner is re-run with the **server
horizon (14 days, all instances, not only the local top-K)**, keeping instances with `deliver.system` or
`deliver.inbox`; content already rendered and redacted; ≤ 200 targets per call.
**Implementation notes:** persistent dirty-target set (local table) so uploads survive restarts/offline;
retry with backoff; the dirty set is cleared only on per-target `ok`; `stale` responses trigger a pull →
replan → re-upload.
**Acceptance criteria:** editing a task offline and reconnecting uploads its new jobs within 10 s of the
sync push; no upload happens before the corresponding sync push succeeded.
**Tests:** orchestrator tests with fake RPC (ordering push → upload, retries, stale handling).

### T7.4.05 — Guard evaluator catalog (SQL)
**Priority:** P1 · **Size:** M · **Depends on:** T7.4.03, [3.1], [4.1], [5.1]
**Description:** `private.notification_guards_ok(p_jobs jsonb) returns table(job_id, ok boolean, reason
text)` (service-only, not exposed through PostgREST) evaluating the guard vocabulary shared with the Dart
planner ([7.2] T7.2.06):
`task_occurrence_open {taskId, occurrenceKey}` (no done/skipped/cancelled record, task active),
`habit_period_open {habitId, occurrenceKey, goalType, target, op}` (no done/skip/excuse/fail state log;
for counts `sum(progress) < target`; habit not archived or paused on that date),
`checklist_item_status_in {itemId, statuses}`, `item_not_completed {itemId}`,
`quit_no_relapse_since {habitId, since}`, `inbox_not_acted {dedupeKey}` (stops nag chains acknowledged on
any device), `always`. Unknown kinds evaluate to `true` and are logged.
**Acceptance criteria:** batch evaluation of 500 jobs < 50 ms on realistic data; guards use ids/statuses only.
**Tests:** pgTAP per guard kind (true/false cases, deleted targets, pauses).
**Notes:** `private.notification_guards_ok` + `private.evaluate_guard` cover every kind (task_occurrence_open, habit_period_open, checklist_item_status_in, item_not_completed, quit_no_relapse_since, inbox_not_acted, always; unknown/malformed fail open and are logged) plus mutes. pgTAP per kind in `090_notifications`; `155_guard_perf` checks 500 mixed jobs < 50 ms on the local stack.

### T7.4.06 — FCM sender module (`_shared/fcm.ts`)
**Priority:** P1 · **Size:** M · **Depends on:** [1.2] (Edge Functions scaffold)
**Description:** Minimal, dependency-light FCM HTTP v1 client for the hosted runtime (Deno 2.1-compatible
— pinned `npm:`/`jsr:` imports, avoid newer APIs): service-account JWT (RS256 signed with `jose`) → OAuth token
(`https://www.googleapis.com/auth/firebase.messaging`) cached in module scope until ~5 min before expiry
and persisted in `private.fcm_token_cache` so cold instances don't mint a new token every run;
`send(message)` with ≥ 10 s timeout; typed results: `ok(messageId)`, `unregistered`, `invalidArgument`,
`senderIdMismatch`, `quotaExceeded(retryAfter ≥ 60 s)`, `unavailable`, `internal`, `thirdPartyAuthError`
(bad APNs credentials — alert ops); concurrency limiter (20–50 parallel requests; one request per token).
**Acceptance criteria:** token minted once per warm instance; CPU per 50 sends well under the 2 s limit.
**Tests:** `deno test` with mocked `fetch` for every error code and token caching/expiry.
**Notes:** `_shared/fcm.ts`: jose RS256 JWT → OAuth token cached per warm instance and now shared across instances via `private.fcm_token_cache` (`app.fcm_token_cache_get/put`, service role, never replaced by a shorter-lived token; migration 20261002100000, pgTAP `150_fcm_token_cache`); a rejected token skips the shared cache once; typed results for every FCM error; ≥ 10 s timeout; `FCM_BASE_URL` override for local E2E. Concurrency is bounded by the dispatcher (32 in flight). Deno tests with mocked fetch.

### T7.4.07 — `push-dispatch` Edge Function
**Priority:** P1 · **Size:** L · **Depends on:** T7.4.03, T7.4.05, T7.4.06, T7.4.09, [7.3] (convergence rules)
**Description:** Invoked by pg_cron via pg_net every 30 s with the cron secret; validates the secret in
constant time, responds `202` immediately and performs the work inside `EdgeRuntime.waitUntil` (pg_net
times out after 2 s).
**Implementation notes (per run, bounded by a wall-time budget):**
1. Claim: `private.claim_notification_jobs(limit)` → `UPDATE … SET status='claimed', lease_until=now()+2 min
   WHERE id IN (SELECT … WHERE status='pending' AND fire_at <= now() AND (next_retry_at IS NULL OR
   next_retry_at <= now()) ORDER BY fire_at LIMIT n FOR UPDATE SKIP LOCKED) RETURNING *`.
2. Expired (`now() > expires_at`) → `expired` (inbox row written with `late` only when configured).
3. Guards (T7.4.05) false → `skipped` (no inbox, no push).
4. Inbox upsert via RPC following [7.3] convergence rules (insert, or patch delivery fields only with
   server HLC stamps — per-field LWW keeps the user's read/acted state).
5. Devices: not revoked, push enabled, fresh token; apply multi-device policy (T7.4.13) and
   `target_devices`; **skip (`skipped_local`)** when `fire_at ≤ local_coverage_until` **and**
   `schedule_rev ≥ source_rev` **and** `last_seen_at` within 72 h **and** (rule not beyond coverage via
   repeating triggers) **and** the device has exact alarms or the job importance is below `high`;
   otherwise send (T7.4.09 payload).
6. Record `push_deliveries`; job → `sent`; failures → backoff (1, 2, 4, 8 min + jitter; `QUOTA_EXCEEDED`
   honours Retry-After), `failed` after 5 attempts; `unregistered`/invalid token → null the device token.
7. Respect FCM per-device limits (Android: 240 messages/min, 5 000/h) by coalescing bursts for the same
   device (same-minute jobs → one merged push) and never exceeding 50 in-flight requests.
8. Structured logs with counts only (no content); heartbeat update (T7.4.16).
**Acceptance criteria:** a job is pushed at most once per device; a covered device receives nothing; the
dispatcher lag stays < 60 s at 10 000 due jobs/hour in a load test.
**Tests:** `deno test` with mocked DB/FCM for each decision branch; integration run against local Supabase in CI.
**Notes:** `push-dispatch` (handler 202 + waitUntil, cron secret): claim → expiry → guards → inbox upsert → per-device decisions (coverage, policy, target_devices, stale token) → FCM → deliveries/backoff. Added burst coalescing: ≥ 3 same-minute jobs for one device become one `digest` push listing the titles (each job keeps its inbox row and a delivery). Deno tests per branch, a 10 000-job load test (≈ 80 ms processing overhead per run, FCM latency excluded) and the local E2E suite.

### T7.4.08 — Cron schedules, lease reaper & cleanup
**Priority:** P1 · **Size:** S · **Depends on:** T7.4.07, [1.2] (pg_cron, pg_net, Vault, `app.invoke_edge`)
**Description:** Register jobs: `push-dispatch` every **30 seconds** (second-level pg_cron syntax), reaper
every minute (`claimed` with `lease_until < now()` → `pending`, attempts + 1), daily cleanup per arch §7.7
(sent/skipped/expired jobs > 14 days, deliveries > 30 days). Keep total concurrent cron jobs ≤ 8 and each
run < 10 min (Supabase guidance).
**Implementation notes:** arch §7.7 describes a 10-min "stuck claimed > 5 min" release — this task replaces
it with the lease-based reaper every minute (update the architecture table when implementing).
**Acceptance criteria:** disabling the dispatcher for 5 min then re-enabling delivers all non-expired jobs
exactly once.
**Tests:** pgTAP for the reaper function; local cron smoke test.
**Notes:** Cron (20260922000180): push-dispatch every 30 s, minutely lease reaper (`private.release_expired_leases`: claimed with expired lease → pending, attempts + 1, failed after 5) + heartbeat, daily maintenance per arch §7.7. Reaper covered in `090_notifications`; the E2E suite checks a second run delivers nothing twice.

### T7.4.09 — Push payload design & size budget
**Priority:** P1 · **Size:** M · **Depends on:** T7.4.06, [7.2] (channels, categories, action catalog)
**Description:** One builder producing platform payloads from a job:
- **Android:** *data-only, high priority* (it always results in a visible notification, so FCM won't
  downgrade it) rendered by our handler with the right channel, actions, group and id derived from the
  dedupe key; `ttl` = remaining lateness. Measure delivery in Doze on ≥ 3 OEMs versus a notification-message
  variant and keep data-only unless it proves less reliable.
- **iOS:** alert push: `apns-push-type: alert`, `apns-priority: 10`, `apns-collapse-id` = dedupe key
  (40 hex chars ≤ 64 bytes), `apns-expiration` = `expires_at`, `aps {alert {title, body}, sound, category,
  thread-id, interruption-level, relevance-score, badge?}`.
- Custom data: `type` (`reminder | nag | digest | milestone | sync | cancel`), `dk`, `target`, `occ`,
  `deepLink`, `actions`, `channel`, `group`.
- Budget: ≤ 4 KB total (truncate body, drop optional fields first); content already localized/redacted.
**Acceptance criteria:** payload tests prove ≤ 4 KB for worst-case Arabic content; iOS actions appear via
the registered category.
**Tests:** unit tests (Deno) for builders and size budget; manual QA on devices.
**Notes:** Client part done: jobs carry the payload fields the builder needs (`type, title, body, deepLink, actions, channel, group, iosCategory, sound, interruptionLevel, relevance`; see `JobUploader.jobFor`). The builders and size budget are the server's (`_shared/fcm.ts`).
**Notes:** `buildAlertMessage` / `buildJobMessage`: android tag + apns-collapse-id = dedupe key (≤ 64 bytes), TTL / apns-expiration from `expires_at`, interruption level from importance, category / thread / channel, custom data (type, target, occ, deepLink, actions, channel, group); 4 KB budget with a worst-case Arabic test. Deviation: Android uses notification messages (OS-rendered, tag = dedupe key) instead of data-only — see T7.4.10; revisit after the Doze delivery measurements on devices.

### T7.4.10 — Device-side push handling
**Priority:** P1 · **Size:** L · **Depends on:** T7.4.01, T7.4.09, [7.2] (action handler, scheduler), [7.3] (banner, inbox)
**Description:** Handle every state:
- **Foreground** (`onMessage`): in-app banner + inbox upsert; no OS banner.
- **Android background** (`onBackgroundMessage`, top-level, separate isolate): `reminder`/`nag`/`digest`/
  `milestone` → drop if the target is already done locally, else show via the local notifications port
  using the same id (replacing and cancelling any pending local alarm for that dedupe key); `sync` → T7.4.11;
  `cancel` → remove tray entries by id/tag.
- **iOS**: alert pushes are shown by the OS; action responses from remote notifications must reach the
  shared action handler ([7.2] T7.2.14) — verify delegate coexistence between `firebase_messaging` and
  `flutter_local_notifications` and add a small native forwarding shim if needed.
- **Taps**: `getInitialMessage` / `onMessageOpenedApp` → deep link, mark inbox opened; stale targets show
  "Already done".
**Acceptance criteria:** a pushed reminder behaves exactly like a local one (same actions, same result);
no duplicate tray entry when both local and push fire on Android.
**Tests:** unit tests for handler routing; patrol tests with a local FCM send script; manual iOS QA.
**Notes:** The server sends Android *notification* messages (OS-rendered, tag = dedupe key), so the background handler only processes `sync` (pull flag) and `cancel` (tray cleanup). iOS delegate coexistence with `firebase_messaging` still needs device QA.

### T7.4.11 — Silent sync push (`sync-nudge`)
**Priority:** P1 · **Size:** M · **Depends on:** T7.4.06, [1.4] (`sync_heads`)
**Description:** Database webhook (or trigger + pg_net) on `app.sync_heads` updates → Edge Function
`sync-nudge` sends a data message `{type: 'sync', head}` to the user's **other** devices: Android normal
priority (≥ 60 s between nudges per device); iOS `content-available: 1`, `apns-push-type: background`,
`apns-priority: 5`, at most one per 20 min per device (Apple: 2–3/h); skip devices seen in the last 2 min
(Realtime covers them). Devices handle it in the background: pull → replan → coverage report.
**Data model:** `sync_heads.last_origin_device_id uuid` (skip the device that caused the change) and
`devices.last_nudged_at` (throttling).
**Acceptance criteria:** editing a task on the phone updates the tablet's local reminders within 2 min on
Android; iOS updates on the next allowed nudge or foreground.
**Tests:** Deno tests for throttling/origin skipping; device QA.
**Notes:** Device part done: `sync` pushes schedule a pull in the foreground and set a pending-pull flag in the background, which the next start or resume handles. The `sync-nudge` function is the server's.
**Notes:** Trigger `private.tg_sync_heads_nudge` on `app.sync_heads` (skips `last_origin_device_id`) → `sync-nudge`: data-only `{type: sync, head}`, Android normal priority ≥ 60 s apart, iOS background push ≤ 1 per 20 min, devices seen in the last 2 min skipped, `last_nudged_at` updated, invalid tokens dropped. Deno tests for throttling and origin skipping.

### T7.4.12 — Completion elsewhere & cross-device acknowledgement
**Priority:** P1 · **Size:** S · **Depends on:** T7.4.05, T7.4.11, [7.2] (delivered cleanup)
**Description:** When an instance is completed/acknowledged on one device: pending jobs fail their guard at
dispatch (no push), nag chains stop via `inbox_not_acted`, other devices receive a sync nudge → replan →
remove scheduled and delivered notifications for that target (Android by tag; iOS best-effort), and taps on
stale notifications show "Already done". Optional immediate `cancel` data push for Android devices when the
completion happens inside the lateness window of a fired reminder.
**Acceptance criteria:** marking *Done* on the phone removes the reminder from the Android tablet's tray
within 1 min and stops its nag chain.
**Tests:** E2E scenario in T7.4.15.
**Notes:** Device side: `cancel` pushes clear the tray at once; a sync nudge leads to pull, replan and removal of delivered notifications; taps on stale notifications show *Already done*. The server doesn't send `cancel` pushes yet (optional).

### T7.4.13 — Multi-device policy & primary device
**Priority:** P1 · **Size:** M · **Depends on:** T7.4.07, [8.3] (devices list)
**Description:** Settings › Notifications › *Deliver to*: **All devices** (default, Google-Calendar model),
**Primary device only** (pick from the devices list); per-device toggles (push / local reminders on this
device); rule-level device targeting (`conditions.devices`). The planner ([7.2] T7.2.07) decides local
scheduling with the same policy and the dispatcher applies it to pushes.
**Acceptance criteria:** with "Primary only", the tablet never shows reminders while the phone does,
including local ones.
**Tests:** planner policy tests; dispatcher decision tests.
**Notes:** Local scheduling follows the policy (`NotificationSettings.localSchedulingAllowed` and rule `conditions.devices`), covered by `policies.json` fixtures. The dispatcher side is server work.

### T7.4.14 — iOS local-vs-push collapse spike
**Priority:** P1 · **Size:** S · **Depends on:** T7.4.10
**Description:** On physical devices (current iOS versions incl. 26/27), verify whether an alert push whose
`apns-collapse-id` equals a delivered/pending local request identifier replaces it silently or re-alerts,
and confirm a Notification Service Extension cannot remove pending local requests. Record the outcome as a
decision-log note and tighten the coverage rule if needed (e.g. never push to a device that holds the
instance locally even when stale).
**Acceptance criteria:** written result with screenshots; coverage rule adjusted accordingly.
**Notes:** Not done: needs physical iOS devices.

### T7.4.15 — End-to-end push tests
**Priority:** P1 · **Size:** M · **Depends on:** T7.4.07, T7.4.10, [9.1] (sync/patrol harness)
**Description:** CI suite against local Supabase + locally served Edge Functions with an FCM mock endpoint
(base URL via env): covered device skipped; stale device (> 72 h) pushed; older `schedule_rev` pushed;
guard false skipped; expired dropped; `UNREGISTERED` nulls the token; `QUOTA_EXCEEDED` retried after
Retry-After; primary-only policy; stale `source_rev` upload rejected; nag stopped by `inbox_not_acted`;
inbox row single after local + server writes.
**Acceptance criteria:** suite green in CI in < 5 min.
**Notes:** `push-dispatch/e2e_test.ts` (opt-in `EVERSLOT_E2E=1`) runs the real dispatcher store against the local stack with a scripted FCM sender: covered device skipped, > 72 h device pushed, older schedule_rev pushed, guard false (nag acknowledged elsewhere) skipped, expired dropped, UNREGISTERED nulls the token, QUOTA_EXCEEDED retried after Retry-After, primary-only policy, stale source_rev rejected, single inbox row keeping the read state, no double delivery on a second run (~0.5 s). Wired into `backend.yml` after pgTAP.

### T7.4.16 — Monitoring hooks & ops metrics
**Priority:** P1 · **Size:** S · **Depends on:** T7.4.07
**Description:** `app.ops_health()` returns dispatcher lag (now − oldest due pending `fire_at`), pending/claimed
counts, sent/failed/expired in the last hour, invalid-token rate, last dispatcher and nudge heartbeat; used
by alerting in [9.2] T9.2.14.
**Data model:** `private.ops_heartbeats (name text primary key, last_run_at timestamptz, details jsonb)`.
**Tests:** pgTAP for the health function.
**Notes:** `app.ops_health()` (dispatcher lag, pending/claimed, last-hour sent/failed/expired, invalid-token rate, heartbeats) over `private.ops_heartbeats`; dispatcher and nudge write heartbeats. pgTAP in `100_purge_ops`.

### T7.4.17 — Server-side planning fallback
**Priority:** P2 · **Size:** L · **Depends on:** T7.4.07, [2.1]
**Description:** Daily Edge Function for users whose devices have not uploaded jobs for > 5 days: expand
RRULE-expressible task/habit rules with `rrule-temporal` (Temporal polyfill — hosted runtime ≈ Deno 2.1)
plus a small layer for windows/times-per-day, and insert jobs marked `planned_by = server` (never
overriding device plans with higher `source_rev`). Parity: run the shared `fixtures/recurrence` and a
subset of `fixtures/notifications/planner` in `deno test`; nightly differential fuzzing vs the Dart engine;
pin and record tz-database versions on both sides.
**Acceptance criteria:** an inactive user keeps receiving daily habit reminders by push; parity suite green.
**Tests:** Deno fixture runner; fuzz job in CI (nightly).
**Notes:** `plan-fallback` Edge Function (daily 02:30 UTC cron) + `app.fallback_candidates/load/replace_jobs` (migration 20261002110000, pgTAP `157_plan_fallback`): users with a push device and enabled rules but no device upload for 5 days get server-planned reminders for 14 days. `_shared/recurrence.ts` maps fixed rule JSON to RRULE and expands it with `rrule-temporal` 2.2.7 on `temporal-polyfill` 1.0.5 in floating wall clock, then applies our own gap/overlap rule; parity in `deno test` against `fixtures/recurrence` (149 cases incl. DST, RFC 5545 examples, bounds) and `rrule_pairs.json` (15). `plan-fallback/planner.ts` ports the server subset of the Dart planner (category/section/global defaults per trigger kind + own rules by notify_mode; `relative` start/end/period/slot incl. day-before-at-time, `not_done_by`; Dart-identical sha1 dedupe keys) with parity on 22 planner fixture cases. Deviations: base reminders only (no nags, quiet hours, caps, mutes), habit days at midnight (no day-start shift), quota / after-completion / window rules stay with devices, simple EN/FR/AR texts. Nightly differential fuzzing vs Dart is not set up (fixture parity runs in CI). Verified loading in `supabase functions serve` (edge-runtime 1.74.3, Deno 2.1.4).

### T7.4.18 — Email channel for digests
**Priority:** P2 · **Size:** M · **Depends on:** T7.4.07, [7.5] (digests)
**Description:** Optional, opt-in email delivery of digests (morning agenda, weekly review) through a
transactional email provider from an Edge Function; localized templates (EN/FR/AR, RTL), unsubscribe link,
bounce handling; never for individual reminders by default.
**Tests:** Deno template tests; provider sandbox test.

### T7.4.19 — Last-active device policy
**Priority:** P2 · **Size:** S · **Depends on:** T7.4.13
**Description:** Third policy *Last active device*: pushes go to the device with the most recent foreground;
local scheduling only on devices foregrounded within the last 12 h. Document the brief overlap when
switching devices.
**Tests:** planner/dispatcher decision tests.
**Notes:** Dispatcher already pushes only to the most recently foregrounded device (`policyDeviceIds`, Deno test). Device side: `NotificationSettings.localSchedulingAllowed` keeps local scheduling under *Last active device* only while this device was foregrounded within 12 h (`notifications.lastForegroundAt` in local_kv, stamped by foreground replans; unknown = keep scheduling). Overlap: after switching devices the previous one keeps its local reminders until its 12 h window lapses. Tests: `domain/device_policy_test.dart`.
