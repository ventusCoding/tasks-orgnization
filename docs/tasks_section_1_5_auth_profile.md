# Section 1.5 — Authentication, Profile & Account Lifecycle

> Milestones: M0/M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 1.2, 1.3, 1.4
> Architecture: arch §3.2 (Auth, API keys), §6.17 (session storage), §7.3 `profiles`, §7.6 (account-delete),
> §9.1 (time zones), ADR-015

## Goal

Sign in quickly and safely (email code first; Google, Apple and guest mode for v1.0), keep the session
secure and usable offline, create and maintain the user profile (time zone, week start, 12/24 h, locale)
that the whole app depends on, and support clean sign-out and full account deletion as required by the
App Store and Google Play.

## Scope

**In:** auth configuration, secure session storage, auth state & routing, email OTP UI, profile table &
repository, first-run essentials, zone tracking, sign-out & account switch, Google & Apple sign-in,
guest mode & upgrade, account deletion (client + Edge Function), profile screen, session edge cases,
email templates, anonymous cleanup, optional MFA.
**Out:** Onboarding tour & permission primers ([8.3] T8.3.11); settings screens ([8.3]); push token
registration ([7.4]).

## Progress

- [x] T1.5.01 — Supabase Auth configuration (email OTP, redirects, providers)
- [x] T1.5.02 — Secure session storage, auth state & router redirect
- [x] T1.5.03 — Email OTP sign-in UI
- [x] T1.5.04 — Profiles table, auto-creation trigger & repository
- [x] T1.5.05 — First-run essentials (zone, locale, week start, 12/24 h)
- [x] T1.5.06 — Current time-zone tracking & zone-change events
- [x] T1.5.07 — Sign-out
- [x] T1.5.08 — Account switch safety on shared devices
- [x] T1.5.09 — Google sign-in (native ID token)
- [x] T1.5.10 — Sign in with Apple (iOS native, Android web flow)
- [x] T1.5.11 — Guest mode (anonymous) & account upgrade
- [x] T1.5.12 — Account deletion (client flow + `account-delete` Edge Function)
- [x] T1.5.13 — Profile screen
- [x] T1.5.14 — Session edge cases (offline expiry, revoked device)
- [x] T1.5.15 — Localized auth email templates
- [ ] T1.5.16 — Stale anonymous users cleanup
- [ ] T1.5.17 — Optional multi-factor authentication (TOTP)

## Tasks

### T1.5.01 — Supabase Auth configuration (email OTP, redirects, providers)
**Priority:** P0 · **Size:** S · **Depends on:** [1.2]
**Description:** Enable email OTP (6-digit code; magic link as secondary), set site URL and allowed
redirect URLs for `everslot://auth-callback` (dev/prod), minimum password policy (if passwords are ever
enabled), rate limits; prepare Google and Apple provider settings (client ids) for P1 tasks; anonymous
sign-ins enabled in local/dev (CAPTCHA before production).
**Acceptance criteria:** local and cloud configs match (`config.toml` ↔ dashboard checklist).
**Notes:** `supabase/config.toml` verified (6-digit email OTP, `everslot://auth-callback` redirects, anonymous sign-ins, rate limits); manual linking enabled (guest upgrade) and a disabled Google provider placeholder added. Cloud-dashboard checklist (redirect URLs, Google/Apple ids, CAPTCHA, SMTP) goes into guide.md — client ids are `TODO(config)` dart-defines in `features/auth/data/auth_config.dart`.

### T1.5.02 — Secure session storage, auth state & router redirect
**Priority:** P0 · **Size:** M · **Depends on:** T1.5.01, [1.3] (router)
**Description:** Custom `LocalStorage` for `supabase_flutter` backed by `flutter_secure_storage` (session
never in plain SharedPreferences); `AuthRepository` + `authStateProvider` (signedOut / signingIn /
signedIn(user) / anonymous(user)); go_router redirect: unauthenticated → sign-in, authenticated without
profile essentials → first-run (T1.5.05), else shell; deep links preserved across the redirect.
**Acceptance criteria:** app restarts signed-in offline; token refresh happens silently online; a deep link
opened while signed out resumes after sign-in.
**Tests:** unit tests for redirect logic; storage adapter tests with a fake secure storage.
**Notes:** `SecureSessionStorage` / `SecurePkceStorage` (Keychain `first_unlock_this_device`) wired in bootstrap; `authStatusProvider` (signedOut/localOnly/anonymous/signedIn); router redirect = pure `AuthRedirect.resolve` (deep links kept in `?from`, open-redirect safe, onboarding guard); `AuthBinding` started at bootstrap so magic links/OAuth bind the session.

### T1.5.03 — Email OTP sign-in UI
**Priority:** P0 · **Size:** M · **Depends on:** T1.5.02, [1.3] (components, l10n)
**Description:** Screens: enter email → enter 6-digit code (auto-advance, paste support, resend with
countdown, change email) → signed in; magic-link fallback handled via deep link; localized errors (invalid
code, expired, rate limited, offline).
**Acceptance criteria:** full flow works against the local stack (Inbucket/Mailpit) and cloud; screen
reader friendly; RTL correct.
**Tests:** widget tests with a fake auth repository; integration test on local stack.
**Notes:** Single autofill-friendly code field (`oneTimeCode`, paste, Arabic-Indic digits, auto-submit) instead of 6 boxes; magic link completes through Supabase's deep-link handling + `AuthBinding`. Widget tests with a fake repository (EN + AR); the local-stack integration test waits for a configured Supabase project.

### T1.5.04 — Profiles table, auto-creation trigger & repository
**Priority:** P0 · **Size:** M · **Depends on:** [1.2] (T1.2.05), [1.4] (T1.4.06)
**Description:** Migration `app.profiles` (arch §7.3; `id = user_id`) wired with `app.enable_sync`; trigger
on `auth.users` insert creating the profile (defaults; `home_time_zone` from signup metadata when present);
Drift mirror; `ProfileRepository.watch()` / `update(...)` through `SyncWriter`.
**Acceptance criteria:** a new user gets exactly one profile row; profile edits sync across devices.
**Tests:** pgTAP (trigger, isolation); repository tests.
**Notes:** server table, auth trigger and pgTAP came with [1.2]; client side = `features/profile` (`Profile` model, `ProfileRepository.watch/read/update` through SyncWriter with validation, `profileProvider`). Two-device per-field merge covered by `test/features/profile/profile_repository_test.dart`.

### T1.5.05 — First-run essentials (zone, locale, week start, 12/24 h)
**Priority:** P0 · **Size:** S · **Depends on:** T1.5.04
**Description:** After the first sign-in on an account: detect device zone (`flutter_timezone`), locale,
week start (locale's first day of week), 12/24 h (`MediaQuery.alwaysUse24HourFormat`); show one compact
confirmation screen (editable) and write the profile. The full onboarding tour is [8.3] T8.3.11.
**Acceptance criteria:** second device on the same account skips this screen (profile already set).
**Tests:** unit tests for defaults per locale (en_US Sunday, fr_FR Monday, ar_TN Monday/Saturday per CLDR).
**Notes:** the confirmation screen is the first step of `OnboardingScreen` (language, searchable zone picker with the detected zone pinned, week start, 12/24 h preview); CLDR table in `FirstRunDefaults` (bare languages use likely regions; `ar_TN` = Monday per CLDR). Completion = `profiles.onboarding_completed_at`, so a second device of the account skips it (`needsOnboardingProvider`).

### T1.5.06 — Current time-zone tracking & zone-change events
**Priority:** P0 · **Size:** S · **Depends on:** T1.5.04, [1.3] (lifecycle)
**Description:** On start/resume (and Android `TIMEZONE_CHANGED` when available) compare the device zone
with the last known; on change: update `profiles.current_time_zone` (throttled), emit a
`TimeZoneChanged` event consumed by Today, planner views (floating tasks re-resolve) and notification
re-planning ([7.2]); optional prompt "You're in a new time zone — keep home zone for fixed tasks?".
**Acceptance criteria:** simulated travel (debug zone override) updates floating task times instantly and
leaves fixed-zone tasks at their absolute instants.
**Tests:** unit tests with fake zone provider.
**Notes:** `ZoneTracker` (`features/profile/application/zone_tracker.dart`, startup task) compares the device zone with the last zone *this device* saw (local_kv, so devices in different zones don't flip-flop), emits `zoneChangesProvider` events, writes `profiles.current_time_zone` at most every 10 min, and raises the "make it home?" banner (`SessionBannerHost`). Floating tasks re-resolve because planner providers watch `deviceZoneProvider` (refreshed on resume / `debugSet`). The Android `TIMEZONE_CHANGED` broadcast isn't wired (needs a native receiver) — resume detection covers it.

### T1.5.07 — Sign-out
**Priority:** P0 · **Size:** S · **Depends on:** T1.5.02, [1.4]
**Description:** If the outbox has pending changes: try a final push; if offline, warn ("N changes not
synced will be lost") with cancel/export options; then cancel local notifications, unregister push token
(when [7.4] exists), close realtime, wipe synced tables, caches and secure storage session, sign out.
**Acceptance criteria:** after sign-out no user data remains on disk (verified by listing DB tables & cache dirs).
**Tests:** integration test on local stack; unit tests for the pending-changes guard.
**Notes:** `SignOutService` (final push → pending guard with count → cleanups while the session is valid: push token nulled via `report_device_state`, local notifications cancelled → session end (sync engine + Broadcast disposed) → `LocalDataWiper.wipeAll` (every table incl. FTS, non-device `local_kv`, attachments/exports/imports/thumbnails dirs) → Supabase/Google sign-out, secure session removed); UI `runSignOutFlow` (guest warning, export / cancel / sign out anyway). `SyncWriter.run` now refuses writes without a user so no late background write survives the wipe. "Nothing left on disk" verified by listing tables & dirs in `test/features/auth/session_lifecycle_test.dart`; the local-stack integration test waits for a configured project.

### T1.5.08 — Account switch safety on shared devices
**Priority:** P0 · **Size:** S · **Depends on:** T1.5.07
**Description:** If a different user signs in on a device holding another user's local data (e.g. after an
interrupted sign-out), wipe before the first pull; `sync_state.user_id` guards every sync operation.
**Tests:** unit test: mismatched user id triggers wipe; no cross-user push possible.
**Notes:** `AuthBinding._bind`: owner null → `LocalAccount.claimForCloudUser` (re-derives user-scoped deterministic ids); owner ≠ user → optional backup hook (`beforeAccountWipeProvider`) then full wipe, before the first pull; the sync engine's guard (`LocalDataOwner.matches`) blocks any push/pull until the data is bound — tested (mismatch wipe, no cross-user push, same account keeps its outbox, claim of local-only data).

### T1.5.09 — Google sign-in (native ID token)
**Priority:** P1 · **Size:** M · **Depends on:** T1.5.02
**Description:** `google_sign_in` 7: configure Web client id as `serverClientId` + iOS client id; obtain ID
token (and access token) → `supabase.auth.signInWithIdToken(provider: google)`; per-flavor OAuth clients;
handle cancel/errors.
**Acceptance criteria:** works on iOS and Android dev/prod; linking to an existing email account follows
Supabase identity-linking rules (documented).
**Tests:** unit tests with fakes; manual device QA.
**Notes:** `GoogleSignInTokenSource` (google_sign_in 7: `initialize(serverClientId: web id, clientId: iOS id)`, `authenticate` → ID token + best-effort access token) → `signInWithIdToken(google)`; cancel/config errors map to stable codes; sign-in and linking offered only when `GOOGLE_WEB_CLIENT_ID` is set (TODO(config), see guide.md). Identity linking: Supabase links a verified Google e-mail to an existing e-mail account automatically; an unverified collision surfaces as `emailInUse`. Unit tests over a real `SupabaseClient` with a mock HTTP backend: `test/features/auth/supabase_auth_repository_test.dart`; device QA pending client ids.

### T1.5.10 — Sign in with Apple (iOS native, Android web flow)
**Priority:** P1 · **Size:** M · **Depends on:** T1.5.02
**Description:** iOS: native flow with nonce (SHA-256 hash to Apple, raw nonce to Supabase
`signInWithIdToken`); persist the user's name on first sign-in via `updateUser` (Apple sends it only
once); Android: web OAuth flow via deep link. Ops: the Apple client secret for the web flow **expires every
6 months** → runbook + calendar reminder ([9.2] T9.2.17).
**Acceptance criteria:** App Store guideline 4.8 satisfied (offered alongside Google); hidden-email relay works.
**Tests:** unit test for nonce handling; manual QA.
**Notes:** iOS/macOS native flow: `AppleNonce` (32 URL-safe random chars; SHA-256 hex to Apple, raw nonce to `signInWithIdToken(apple)`), the name Apple sends only once is saved with `updateUser` (`full_name`/`display_name`); Android: Supabase web OAuth (PKCE) back through `everslot://auth-callback` + `AuthBinding`. Enabled with `APPLE_SIGN_IN_ENABLED` (TODO(config): service id, key, 6-month client-secret rotation — runbook T9.2.17). Nonce and request tests in `test/features/auth/supabase_auth_repository_test.dart`; device QA pending configuration.

### T1.5.11 — Guest mode (anonymous) & account upgrade
**Priority:** P1 · **Size:** M · **Depends on:** T1.5.03
**Description:** "Continue without account" → `signInAnonymously` (CAPTCHA token via Turnstile/hCaptcha in
production; 30/h/IP server limit); a persistent but dismissible banner explains data can be lost if the app
is removed before upgrading; upgrade by adding email (`updateUser`) or linking Google/Apple
(`linkIdentity`, manual linking enabled) — same user id, so all data stays.
**Acceptance criteria:** guest data syncs normally and survives the upgrade; upgrade to an email already in
use shows a clear resolution path.
**Tests:** integration test (anonymous → email upgrade) on the local stack.
**Notes:** "Continue without account" → `signInAnonymously` (metadata; CAPTCHA token parameter wired, TODO(config) `CAPTCHA_SITE_KEY` widget); dismissible guest banner (`guestBannerProvider`, returns after 7 days, per-device `local_kv`); upgrade in Settings › Account: add an e-mail (`updateUser` + `email_change` code, same user id) or link Google/Apple (`linkIdentity*`); an e-mail already in use opens a resolution dialog (other e-mail, or export → sign in → import). Tests: repository (mock HTTP) and `test/features/auth/account_page_test.dart`; the local-stack integration test waits for a configured project.

### T1.5.12 — Account deletion (client flow + `account-delete` Edge Function)
**Priority:** P1 · **Size:** M · **Depends on:** T1.5.07, [1.2] (T1.2.09)
**Description:** Settings › Account › Delete account: explain consequences, offer export first ([8.3]),
re-authenticate (fresh OTP), call `account-delete` (verifies JWT; deletes the user's storage objects via
the Storage API, revokes Sign in with Apple tokens when linked, deletes devices/jobs, then
`auth.admin.deleteUser` → cascades all `app` rows), then local wipe. Public web page for deletion requests
(Google Play requirement) described in [9.2] T9.2.09.
**Acceptance criteria:** after deletion no rows or objects remain for the user id (verified by a service
query in tests); the function is idempotent.
**Tests:** Deno tests with mocks; integration test on the local stack; pgTAP verifying cascades.
**Notes:** Client flow (`AccountService.deleteAccount` + `runDeleteAccountFlow`): consequences + "export first", explicit acknowledgement, fresh e-mail code re-authentication (guests skip it), `app.request_account_deletion` then the `account-delete` Edge Function, then `SignOutService.endSession` (local wipe). The Edge Function, its Deno tests and the pgTAP cascade checks came with [1.2]. Fixed a race found here: a sync run in flight could re-insert pulled rows after the wipe — `SyncService.cancel()/whenIdle()` + page/push guards, awaited by `endSession` (`test/core/sync/sync_cancel_test.dart`). Web deletion URL = `ACCOUNT_DELETION_URL` (TODO(config)).

### T1.5.13 — Profile screen
**Priority:** P1 · **Size:** S · **Depends on:** T1.5.04, [2.2]
**Description:** Display name, avatar (attachment pipeline, square crop), email, linked providers (link/
unlink), home time zone, quick links to regional settings, sign-out, delete account.
**Tests:** widget tests; golden.
**Notes:** `AccountPage` (Settings › Account): header (initials avatar, name, e-mail / guest / local-only), guest upgrade card, sign-in methods with link/unlink (never the last one), display name, home & current zone, regional settings link, sign-out, delete account; goldens `test/features/profile/goldens/account_*`. Photo avatar NOT done: `attachments.owner_type` has no `profile` value and there is no avatar bucket policy (schema change needed — reported; `profiles.avatar_path` exists).

### T1.5.14 — Session edge cases (offline expiry, revoked device)
**Priority:** P1 · **Size:** M · **Depends on:** T1.5.02, [1.4] (T1.4.05)
**Description:** Refresh token expired while offline → app stays fully usable offline, writes keep queuing;
when online and refresh fails → non-blocking re-auth prompt that preserves the outbox; revoked device
(from registry) → sign out on next contact after a final export offer; clock skew handling for token
validation messages.
**Acceptance criteria:** no data loss in any of these paths (tested by scripted scenarios).
**Tests:** unit tests with fake auth errors; integration scenario tests.
**Notes:** Expired session offline → the app stays local-first (session and data kept, writes keep queuing), non-blocking "Sign in again" banner (`SessionIssue.reauthRequired`); a 401 tries a silent refresh first; revoked device → banner + Account card with export offer, sync stopped, sign-out rotates the device id. Clock skew: the client never validates JWT expiry itself (server-side checks + refresh on 401), so a wrong device clock only shifts auto-refresh timing. Scenario tests: `test/features/auth/session_edge_cases_test.dart`.

### T1.5.15 — Localized auth email templates
**Priority:** P1 · **Size:** S · **Depends on:** T1.5.01
**Description:** OTP / magic-link / email-change templates in EN, FR, AR (RTL-aware HTML), branded; locale
chosen from signup metadata; production SMTP configured in [9.2] T9.2.05.
**Tests:** template render check in local Mailpit for each locale.
**Notes:** `supabase/templates/{magic_link,confirmation,email_change,reauthentication}.html` wired in `supabase/config.toml`: one GoTrue template per type with EN/FR/AR branches on the sign-up metadata `locale` (missing/unknown → EN), Arabic branch `lang="ar" dir="rtl"`, code always LTR; subjects are static and trilingual (config subjects are not templated). The locale is the one sent at sign-up (a later language change does not update auth metadata). `test/features/auth/email_templates_test.dart` evaluates each locale branch; the Mailpit visual check needs `supabase start` (manual) and hosted projects need the files pasted in the dashboard (guide.md); production SMTP = T9.2.05.

### T1.5.16 — Stale anonymous users cleanup
**Priority:** P2 · **Size:** S · **Depends on:** T1.5.11, [1.2] (T1.2.12)
**Description:** Scheduled job deleting anonymous users inactive for > 90 days (via `auth.users.last_sign_in_at`
and devices' `last_seen_at`) — Supabase does not clean them up automatically.
**Tests:** pgTAP/Deno test on the selection query.

### T1.5.17 — Optional multi-factor authentication (TOTP)
**Priority:** P2 · **Size:** S · **Depends on:** T1.5.13
**Description:** Enroll/verify TOTP factors (Supabase Auth MFA) for users who want extra protection; AAL2
required for account deletion when enabled.
**Tests:** integration test on local stack.
