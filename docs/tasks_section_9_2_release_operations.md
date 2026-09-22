# Section 9.2 — Release, Store Compliance & Operations

> Milestones: M2 (P1) · M3 (P2) · Depends on: 1.1, 1.2, 7.4, 9.1
> Architecture: §7.1 (environments), §11 (CI/CD, secrets)

## Goal

Ship Everslot to the App Store and Google Play safely and repeatably, stay compliant with store policies,
and operate the backend (monitoring, backups, incidents, schema evolution) with confidence.

## Scope

**In:** app identity & assets, signing, fastlane + release CI, production Supabase/Firebase hardening,
privacy policy, store compliance forms, permission declarations, listings & screenshots, beta programs,
monitoring & alerting, backups/DR, force-update & schema-evolution policy, release checklist, support.
**Out:** Feature work; post-launch roadmap ([9.3]).

## Progress

- [ ] T9.2.01 — App identity: name, bundle ids, icons, splash
- [ ] T9.2.02 — Code signing (Android upload key, iOS certificates)
- [ ] T9.2.03 — fastlane lanes & build numbering
- [ ] T9.2.04 — Release CI workflow (apps + backend)
- [ ] T9.2.05 — Supabase production hardening
- [ ] T9.2.06 — Firebase production setup
- [ ] T9.2.07 — Force-update & minimum supported version
- [ ] T9.2.08 — Schema evolution & API versioning policy
- [ ] T9.2.09 — Privacy policy, terms & support pages
- [ ] T9.2.10 — Apple compliance (privacy labels, privacy manifest, account deletion, Sign in with Apple)
- [ ] T9.2.11 — Google Play compliance (Data safety, exact alarms, photo picker, health declaration, target API)
- [ ] T9.2.12 — Store listings, screenshots & localization
- [ ] T9.2.13 — Beta programs (TestFlight, Play closed testing)
- [ ] T9.2.14 — Monitoring & alerting
- [ ] T9.2.15 — Backups & disaster-recovery drill
- [ ] T9.2.16 — Release checklist & staged rollout
- [ ] T9.2.17 — Support & incident runbooks
- [ ] T9.2.18 — Cost & quota monitoring

## Tasks

### T9.2.01 — App identity: name, bundle ids, icons, splash
**Priority:** P1 · **Size:** M · **Depends on:** [1.1]
**Description:** Finalize the store name ("Everslot — Planner & Habits" or similar, ≤ 30 chars), bundle /
application ids (final before first upload — cannot change later), adaptive Android icon, iOS icon set
(incl. dark & tinted variants), native splash (`flutter_native_splash`), dev flavor badge.
**Acceptance criteria:** icons crisp on all densities; dev and prod installable side by side.

### T9.2.02 — Code signing (Android upload key, iOS certificates)
**Priority:** P1 · **Size:** M · **Depends on:** T9.2.01
**Description:** Android upload keystore (Play App Signing enabled), stored base64 in CI secrets with
`key.properties` generated at build time; iOS distribution certificate & profiles via fastlane `match`
(private repo) or App Store Connect API key + automatic signing.
**Acceptance criteria:** clean CI runner produces signed AAB and IPA; no signing material in the repo.

### T9.2.03 — fastlane lanes & build numbering
**Priority:** P1 · **Size:** M · **Depends on:** T9.2.02
**Description:** Lanes: `android beta|production`, `ios beta|release`; version name from git tag, build
number from CI run number; changelog from conventional commits; dSYM/mapping upload to Crashlytics.
**Acceptance criteria:** `fastlane ios beta` uploads to TestFlight; `fastlane android beta` to the internal track.

### T9.2.04 — Release CI workflow (apps + backend)
**Priority:** P1 · **Size:** M · **Depends on:** T9.2.03, [1.1]
**Description:** `release.yml` on tag `v*`: run full CI → build/sign → upload to tracks → create GitHub
release with artifacts; separate job `deploy-backend` (protected environment, manual approval):
`supabase db push` (migrations) then `supabase functions deploy`, then smoke checks (RPC ping, dispatcher health).
**Acceptance criteria:** backend deploys before apps that need it; failed migration stops the pipeline.

### T9.2.05 — Supabase production hardening
**Priority:** P1 · **Size:** M · **Depends on:** [1.2]
**Description:** Paid plan (no idle pausing), region close to users, custom SMTP for auth emails
(branded OTP/magic-link templates EN/FR/AR), auth rate limits, allowed redirect URLs, JWT expiry, leaked-
password protection / CAPTCHA on sign-up if abuse appears, database password rotation, network
restrictions where possible, Vault secrets, cron job list verified, `pg_stat_statements` enabled.
**Acceptance criteria:** checklist in `docs/ops/supabase_prod.md` completed and signed off.

### T9.2.06 — Firebase production setup
**Priority:** P1 · **Size:** S · **Depends on:** [1.2]
**Description:** Prod Firebase project, APNs auth key (prod), FCM API enabled, service account with minimal
role for FCM send only, Crashlytics enabled with symbol upload; analytics collection disabled.
**Acceptance criteria:** push to a prod TestFlight build works; service account key stored only as Edge secret.

### T9.2.07 — Force-update & minimum supported version
**Priority:** P1 · **Size:** M · **Depends on:** [1.4]
**Description:** `app.app_config` (public read) with `min_supported_build`, `recommended_build`, message;
the app checks on start and before sync; below minimum → blocking update screen (store link), sync paused
to protect data; below recommended → dismissible banner. `sync_push` also rejects clients below minimum.
**Acceptance criteria:** bumping `min_supported_build` blocks old builds within one app start.
**Tests:** unit tests for version comparison; pgTAP for the RPC check.

### T9.2.08 — Schema evolution & API versioning policy
**Priority:** P1 · **Size:** S · **Depends on:** T9.2.07
**Description:** Document and enforce **expand → migrate → contract**: new columns nullable/defaulted;
never rename/drop in one release; old clients must keep syncing (unknown columns ignored by old
`jsonb_populate_record`, new columns defaulted); breaking changes ship new RPC versions (`sync_push_v2`) and
remove old ones only after `min_supported_build` passes them. JSON value schemas (`"v"`) follow the same rule.
**Acceptance criteria:** `docs/ops/schema_evolution.md`; CI job runs the previous release's sync tests
against the new schema.

### T9.2.09 — Privacy policy, terms & support pages
**Priority:** P1 · **Size:** M · **Depends on:** —
**Description:** Static site (e.g. GitHub Pages) with privacy policy (data collected: account email, content
you create, device push tokens, crash diagnostics; storage location/region; processors: Supabase, Google
Firebase; retention; export/deletion; contact), terms, support/FAQ, account-deletion instructions URL, and
the `apple-app-site-association` / `assetlinks.json` files ([8.2]). Available in EN/FR/AR.
**Acceptance criteria:** URLs live and linked from app ([8.3]) and store listings.

### T9.2.10 — Apple compliance (privacy labels, privacy manifest, account deletion, Sign in with Apple)
**Priority:** P1 · **Size:** S · **Depends on:** T9.2.09, [1.5]
**Description:** App Privacy "nutrition label" answers; `PrivacyInfo.xcprivacy` for the app (required-reason
APIs used, e.g. UserDefaults, file timestamps) and verification that all plugins ship manifests; in-app
account deletion reachable from Settings; Sign in with Apple offered alongside Google; usage strings
(camera, photos, notifications rationale, Face ID) localized; export compliance (standard encryption only).
**Acceptance criteria:** Xcode privacy report generated without missing reasons; review notes prepared
(demo account credentials).

### T9.2.11 — Google Play compliance (Data safety, exact alarms, photo picker, health declaration, target API)
**Priority:** P1 · **Size:** S · **Depends on:** T9.2.09, [7.2]
**Description:** Data safety form; **exact alarm** permission declaration matching our use (calendar-style
reminders; `USE_EXACT_ALARM` only if Play accepts the calendar use case, else `SCHEDULE_EXACT_ALARM` with
user grant + fallback); use the system **photo picker** (no broad `READ_MEDIA_*` permissions);
foreground-service type declarations if a timer service is used; Health apps declaration (quit/habit
features — declare accurately); target the API level Play requires at submission time; `POST_NOTIFICATIONS`
rationale.
**Acceptance criteria:** pre-launch report clean of policy warnings; permissions list in the release AAB
matches the declarations.

### T9.2.12 — Store listings, screenshots & localization
**Priority:** P1 · **Size:** M · **Depends on:** T9.2.01, [8.3] (sample data)
**Description:** Title, subtitle/short description, full description, keywords (EN/FR/AR), category
(Productivity), age rating questionnaires; screenshots generated by an integration test using demo data
for phone & tablet sizes in 3 languages, framed; optional preview video.
**Acceptance criteria:** assets reproducible by one script; text reviewed by native speakers.

### T9.2.13 — Beta programs (TestFlight, Play closed testing)
**Priority:** P1 · **Size:** S · **Depends on:** T9.2.04
**Description:** TestFlight internal + external groups (beta review), Play internal and **closed testing**
track. New personal Play developer accounts must run a closed test with a minimum number of opted-in
testers for a minimum continuous period before production access (currently 12 testers / 14 days —
verify at the time) → recruit testers early. Feedback via TestFlight / email form.
**Acceptance criteria:** beta exit criteria from [9.1] met (crash-free ≥ 99.5 %, no P0/P1 bugs open).

### T9.2.14 — Monitoring & alerting
**Priority:** P1 · **Size:** M · **Depends on:** [7.4], T9.2.05
**Description:** Crashlytics velocity alerts; Supabase log drains/Log Explorer saved queries (RPC errors,
auth failures); **dispatcher health**: `max(now() - fire_at)` of pending due jobs exposed via a
`app.ops_health()` function + external uptime check (alert if lag > 3 min or cron silent > 5 min); Edge
Function error rate; FCM invalid-token rate; storage growth.
**Acceptance criteria:** an injected failure (disabled cron) raises an alert within 10 minutes.

### T9.2.15 — Backups & disaster-recovery drill
**Priority:** P1 · **Size:** S · **Depends on:** T9.2.05
**Description:** Enable daily backups / PITR per plan; document restore procedure; quarterly drill restoring
into a staging project and running the sync suite against it; storage bucket backup approach documented.
**Acceptance criteria:** documented RPO/RTO; one successful drill before launch.

### T9.2.16 — Release checklist & staged rollout
**Priority:** P1 · **Size:** S · **Depends on:** T9.2.04
**Description:** `docs/ops/release_checklist.md`: version bump, changelog, migrations reviewed (expand/contract),
QA checklist run, store notes localized, staged rollout (Play 5 % → 20 % → 50 % → 100 %; App Store phased
release), rollback plan (halt rollout, hotfix, backend feature flag).
**Acceptance criteria:** checklist used for v1.0 and stored with results.

### T9.2.17 — Support & incident runbooks
**Priority:** P1 · **Size:** S · **Depends on:** T9.2.14
**Description:** Runbooks: push outage, sync errors spike, stuck migrations, auth email delivery failure,
data-loss report handling (export/restore steps), account deletion requests by email, the **6-monthly
Sign in with Apple client-secret rotation** (Android web flow, [1.5] T1.5.10); support inbox and response
templates (EN/FR/AR).
**Acceptance criteria:** each runbook has an owner, a trigger and step-by-step commands; the Apple secret
rotation has a calendar reminder 30 days before expiry.

### T9.2.18 — Cost & quota monitoring
**Priority:** P2 · **Size:** S · **Depends on:** T9.2.14
**Description:** Monthly review of Supabase usage (DB size, egress, storage, function invocations, realtime
connections), FCM quotas, and projections vs plan limits; alerts at 80 % of any quota.
