# Beta programs (T9.2.13)

**Owner:** project lead (release manager). **Trigger:** the first tag `v*` — `release.yml` uploads the AAB to
the Play internal track and the IPA to TestFlight. **Exit:** the go/no-go criteria at the end of this page.

## Timeline (count back from the public launch, week L)

| Week | Step |
|---|---|
| L−9 | Recruit testers (EN/FR/AR, Android and iOS, phones and tablets): the closed test takes time |
| L−8 | Internal: TestFlight *Internal* group + Play internal track; smoke test on your own devices |
| L−7 | Play closed test with ≥ 12 opted-in testers (aim for 20); TestFlight external group |
| L−7…L−2 | Weekly builds, feedback triage, crash-free and dispatcher monitoring |
| L−2 | Play: apply for production access (new personal accounts); App Store: submit 1.0 for review |
| L | Staged rollout (`docs/ops/release_checklist.md`) |

## TestFlight (iOS)

- **Internal group** "Internal": App Store Connect users only (up to 100), builds available right after
  processing, no review. Owner plus close collaborators.
- **External groups** (up to 10 000 testers, by e-mail or public link): "Friends & family" and, later,
  "Public beta" with a capped public link (e.g. 200). The first build of each version goes through Beta App
  Review (usually within a day).
- **Test information** (App Store Connect › TestFlight › Test Information, EN/FR/AR): beta description,
  feedback e-mail `[CONTACT EMAIL]`, marketing URL `https://YOUR_SITE_DOMAIN/en/`, privacy policy URL, and
  sign-in notes: "No account needed: tap *Continue without account*."
- **What to Test**: `release.yml` sets it from `tool/release_notes.dart --store`; edit it per build to point
  at the focus of the week (e.g. "reminders on a locked phone", "Arabic layout").
- Builds expire after 90 days; keep one build per week at most so testers update.
- Feedback arrives in App Store Connect › TestFlight › Feedback (screenshots and crash reports).

## Google Play (Android)

- **Internal testing** (up to 100 testers by e-mail list, no review wait): target of `fastlane android beta`.
- **Closed testing** (track `alpha`): `cd app/android && bundle exec fastlane closed` promotes the internal
  build. Testers join through a Google Group (create `everslot-beta@googlegroups.com`) or an e-mail list,
  open the opt-in link, accept, then install from Google Play. The first closed release is reviewed.
- **New personal developer accounts** (created after 13 November 2023) must run a closed test with at least
  **12 testers opted in for 14 consecutive days** before they can apply for production access — verify the
  current rule in Play Console Help ("App testing requirements for new personal developer accounts") when
  planning; it changed from 20 to 12 testers in December 2024 and Google also checks that testers really
  use the app. Organization accounts are exempt. A tester who opts out and back in restarts the 14 days.
- **Apply for production** (Play Console › Dashboard): answers about recruitment, feedback and changes
  made — keep notes during the beta (feedback table below) to answer precisely.
- The pre-launch report runs on closed-test builds (Test and release › Testing › Pre-launch report).
- Open testing is not planned (it needs a public listing).

## Testers

- Aim for 20+ on each platform: English, French and Arabic speakers (RTL layout), at least two tablets or
  iPads, one Samsung or Xiaomi phone (aggressive battery management) and one Android 7–9 device (API 24–28).
- Invitation and instruction texts: `docs/ops/support_templates.md` (T-10 Beta invitation).
- Ask testers to keep the app installed and use it a few minutes every day for 14 days (the Play rule
  counts continuous opt-in; real use makes the production-access answers credible).
- Testers' data follows the privacy policy; they can delete their account at any time.

## Feedback and triage

- Channels: TestFlight feedback, Play closed-test feedback, e-mail `[CONTACT EMAIL]` with the subject
  "Beta: …" (template T-10 gives the checklist of details to include).
- Weekly triage: each report becomes a GitHub issue labelled `beta` and a severity:
  - **P0** — data loss, sync divergence, crash on start, reminders not firing at all;
  - **P1** — a feature broken without workaround;
  - **P2** — broken with workaround or cosmetic in a key flow; **P3** — polish.
- Reply within 3 business days (support templates); tell testers which build fixes their report.
- Watch Crashlytics per build, `docs/ops/monitoring.md` signals and the sync error queries daily during the
  first week of each build.

## Exit criteria (go / no-go for production)

- [ ] Crash-free users ≥ 99.5 % over the last 7 days on the release candidate (Crashlytics), measured on at
      least 100 sessions per platform.
- [ ] No open P0 or P1 issue.
- [ ] `docs/qa/qa_checklist.md` executed on one Android and one iOS device for the release candidate, plus
      the accessibility and RTL walkthrough (`docs/qa/a11y.md`).
- [ ] Two-device sync verified on production; no burst of `rejected` / `integrity_refetch` results.
- [ ] Reminders delivered on locked phones (Android Doze and iOS) and pushed to a second device; dispatcher
      lag stayed under 3 minutes through the beta.
- [ ] Account deletion and data export tested end to end on production.
- [ ] Play production access granted (12 testers / 14 days); App Store 1.0 approved or ready to submit.
- [ ] Listings, screenshots and the website (privacy, terms, support, deletion) live in EN/FR/AR.

## Beta log

| Build | Date | Active testers (A / i) | Crash-free 7 d | Open P0/P1 | Notes / decision |
|---|---|---|---|---|---|
| | | | | | |
