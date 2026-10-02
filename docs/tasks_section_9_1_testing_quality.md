# Section 9.1 — Testing, Performance & Quality Gates

> Milestones: M0/M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 1.1, 1.2, 1.4 (and everything it verifies)
> Architecture: §9.6 (performance budgets), §10 (testing strategy), §7.4 (RLS)

## Goal

Make quality automatic: every layer has the right kind of tests, CI blocks regressions (correctness,
coverage, performance, accessibility, security), and a repeatable manual QA script exists for releases.
Many P0 items here are **infrastructure used from the first feature onward** — do them early in the P0 pass
(they are listed in Section 9 only to keep all quality work in one place).

## Scope

**In:** test infrastructure (builders, fakes, fixtures, goldens, patrol), sync convergence suite,
recurrence/time-zone torture tests, performance suite, memory/battery checks, accessibility and RTL
audits, security review, DB performance review, chaos tests, QA checklist, quality dashboards.
**Out:** Feature-specific tests (they live with each feature task).

## Progress

- [ ] T9.1.01 — Coverage gates & test commands in CI
- [ ] T9.1.02 — Test data builders, fakes & fixture loaders
- [ ] T9.1.03 — Sync convergence test suite (two clients)
- [ ] T9.1.04 — Recurrence & time-zone torture tests
- [ ] T9.1.05 — Golden test infrastructure (themes, RTL, text scale)
- [ ] T9.1.06 — pgTAP RLS completeness check
- [ ] T9.1.07 — Integration test harness (patrol)
- [ ] T9.1.08 — Performance test suite & budgets in CI
- [ ] T9.1.09 — Memory, leaks & battery audit
- [ ] T9.1.10 — Accessibility audit
- [ ] T9.1.11 — Localization & RTL QA
- [ ] T9.1.12 — Security review
- [ ] T9.1.13 — Database & query performance review
- [ ] T9.1.14 — Manual QA checklist & beta test plan
- [ ] T9.1.15 — Chaos & robustness tests
- [ ] T9.1.16 — Quality dashboard

## Tasks

### T9.1.01 — Coverage gates & test commands in CI
**Priority:** P0 · **Size:** S · **Depends on:** [1.1] (CI skeleton)
**Description:** Standard `melos` scripts (`test`, `test:coverage`, `test:golden`, `test:integration`) and CI
gates: pure packages ≥ 95 % lines, app `domain/` + `application/` ≥ 80 %, overall app ≥ 60 %.
**Implementation notes:** merge lcov per package; exclude generated files (`*.g.dart`, `*.freezed.dart`,
`*.drift.dart`); publish HTML report as CI artifact; fail PR on drop > 1 % vs main.
**Acceptance criteria:** a PR lowering coverage below a gate fails with a readable message.
**Tests:** CI dry run on a branch that deletes a test (must fail).

### T9.1.02 — Test data builders, fakes & fixture loaders
**Priority:** P0 · **Size:** M · **Depends on:** [1.3], [1.4]
**Description:** `app/test/support/`: fluent builders for every entity (`aTask().recurringWeekly(MO, TU)...`),
`FakeClock`, `FakeZoneProvider`, in-memory `AppDatabase` factory, `FakeSupabaseSyncApi`, fake notification
platform adapter, fixture loader for `fixtures/**.json`, `pumpApp()` helper with providers/locale/theme.
**Acceptance criteria:** a new widget test needs ≤ 5 lines of setup; builders produce valid entities by default.
**Tests:** self-tests for builders (valid by construction).

### T9.1.03 — Sync convergence test suite (two clients)
**Priority:** P0 · **Size:** L · **Depends on:** [1.4]
**Description:** Integration tests running **two headless clients** (separate Drift DBs + device ids, same
user) against the local Supabase stack in CI, asserting both DBs converge to the same state.
**Scenarios (minimum):** concurrent edits same row (LWW by `updated_at`); edit vs delete; offline edits on
both then reconnect; same occurrence marked done on both (deterministic id); habit day toggled on both;
checklist item moved on A while edited on B; reorder with fractional keys on both; outbox coalescing of
rapid edits; pull pagination across > 3 pages; clock-skewed client (+2 days) gets clamped; tombstone purge
→ forced full resync; 5 000-row initial sync; network failure mid-push (idempotent retry).
**Acceptance criteria:** all scenarios green in CI in < 5 min; a flaky test is a bug, not a retry.
**Tests:** this task *is* the test suite (tagged `@Tags(['sync'])`).

### T9.1.04 — Recurrence & time-zone torture tests
**Priority:** P0 · **Size:** M · **Depends on:** [2.1]
**Description:** Fixture + property tests for the recurrence engine and time utilities: DST gaps/overlaps
(Europe/Paris, America/New_York, Australia/Lord_Howe 30-min DST, Asia/Tehran, Africa/Tunis), Feb 29 yearly,
31st monthly, `bySetPos` negatives, week starts (MO/SA/SU), `until` inclusive edge, `count` with exdates,
1-minute windows across midnight, floating vs fixed zones after a travel zone change.
**Implementation notes:** property tests with seeded random rules: output sorted, unique keys, within
[from, to), respects until/count/exdates, `nextAfter(x)` equals first of `between(x, …)`.
**Acceptance criteria:** ≥ 300 fixture cases + 10 000 random property iterations green in < 30 s.
**Tests:** this task is the suite.

### T9.1.05 — Golden test infrastructure (themes, RTL, text scale)
**Priority:** P1 · **Size:** M · **Depends on:** T9.1.02
**Description:** `alchemist` configuration with bundled fonts, a `goldenMatrix()` helper generating
light/dark × LTR/RTL × text scale 1.0/2.0 variants, CI-stable rendering (platform goldens vs CI goldens).
**Acceptance criteria:** golden diffs are uploaded as CI artifacts; updating goldens is one command.
**Tests:** sample goldens for design-system components.

### T9.1.06 — pgTAP RLS completeness check
**Priority:** P0 · **Size:** S · **Depends on:** [1.2]
**Description:** A pgTAP test that enumerates every table in schema `app` and asserts: RLS enabled, required
policies exist, sync triggers attached (for synced tables), `(user_id, rev)` index exists; plus cross-user
isolation tests (user A cannot select/insert/update B's rows or storage objects).
**Acceptance criteria:** adding a table without `app.enable_sync`/policies fails CI.
**Tests:** this task is the suite.

### T9.1.07 — Integration test harness (patrol)
**Priority:** P1 · **Size:** M · **Depends on:** T9.1.02, [1.1]
**Description:** Patrol setup for both flavors; helpers for sign-in with a seeded test user, granting
notification/exact-alarm/photo permissions, tapping notifications; Android emulator job in CI;
iOS simulator run documented for local use.
**Acceptance criteria:** smoke flows per section pass: create task in week table → reminder fires → tap
opens occurrence; nested checklist create/indent/status; habit check-in; quit relapse.
**Tests:** the smoke suite.
**Notes:** Partial (still open): patrol 4.10.0 + Android runner/orchestrator, `patrol:` config, `patrol_test/support/e2e.dart` (boot in local-only mode with the provider container exposed, skip setup, grant notifications, poll the shade), the `android-e2e` CI job and the guide (§8, incl. iOS steps). The notification flow (T7.2.22) passes; checklist / habit / quit smoke flows and sign-in with a seeded cloud user are still to write.

### T9.1.08 — Performance test suite & budgets in CI
**Priority:** P1 · **Size:** L · **Depends on:** T9.1.07, [3.4], [3.5], [4.2], [6.1]
**Description:** `flutter drive --profile` scenarios with generated large datasets measuring the budgets in
arch §9.6 (week table 1-min slots with 2 000 tiles, day list 1 440 rows, 5 000-item checklist, habit stats
30 × 5 years, cold start, initial sync of 50 000 rows); timeline summaries stored as artifacts; thresholds
enforced (fail on > 10 % regression vs baseline).
**Acceptance criteria:** baseline recorded on a reference Android device/emulator config; report shows
p50/p90/p99 frame build/raster times.
**Tests:** the perf suite.

### T9.1.09 — Memory, leaks & battery audit
**Priority:** P1 · **Size:** M · **Depends on:** T9.1.08
**Description:** `leak_tracker` enabled in widget tests; DevTools memory profiling of long sessions
(scroll weeks for 5 min); tickers/timers/streams disposed; background work frequency (workmanager,
realtime reconnects) reviewed for battery; Android vitals thresholds noted.
**Acceptance criteria:** no leaks reported in tests; memory stable (< 10 % growth) over 5-min scroll session.

### T9.1.10 — Accessibility audit
**Priority:** P1 · **Size:** M · **Depends on:** most UI sections
**Description:** TalkBack & VoiceOver walkthrough of every screen (script in `docs/qa/a11y.md`), automated
guideline checks in widget tests (`textContrastGuideline`, `androidTapTargetGuideline`,
`iOSTapTargetGuideline`, `labeledTapTargetGuideline`), charts' tabular alternatives, time-grid navigation
by screen reader (list alternative), text scale 200 %.
**Acceptance criteria:** zero guideline failures; every issue found is fixed or ticketed with priority.

### T9.1.11 — Localization & RTL QA
**Priority:** P1 · **Size:** M · **Depends on:** [1.3] (i18n)
**Description:** CI check for missing/unused ARB keys and placeholder mismatches; pseudo-locale (+40 % length,
accents) run; Arabic review (numerals setting, date formats, plural forms, mirrored grid & gestures,
bidi text in mixed content); French review (typographic spaces, 24 h default).
**Acceptance criteria:** no truncation at +40 % length on key screens; native-speaker review sign-off for FR & AR.

### T9.1.12 — Security review
**Priority:** P1 · **Size:** M · **Depends on:** T9.1.06
**Description:** Checklist based on OWASP MASVS: secrets scanning (gitleaks) in CI; no service/secret keys
in the app bundle (grep release build); JWT/session storage in secure storage; deep-link parameter
validation; Edge Functions validate auth / cron secret; storage policies; dependency audit
(`dart pub outdated`, `osv-scanner`); rate limits on auth; privacy of logs/crash reports.
**Acceptance criteria:** written report in `docs/qa/security_review.md`; all high findings fixed before v1.0.

### T9.1.13 — Database & query performance review
**Priority:** P1 · **Size:** S · **Depends on:** [1.4], [6.1]
**Description:** `EXPLAIN (ANALYZE, BUFFERS)` for `sync_pull`, `sync_push`, dispatcher claim query with
realistic volumes (1 M rows across users); SQLite `EXPLAIN QUERY PLAN` for Today, week range, stats
aggregates; add/adjust indexes; document in the migration notes.
**Acceptance criteria:** `sync_pull` page < 50 ms server time at 1 M rows; local range query < 10 ms.

### T9.1.14 — Manual QA checklist & beta test plan
**Priority:** P1 · **Size:** S · **Depends on:** —
**Description:** `docs/qa/qa_checklist.md`: per-section manual scripts (incl. multi-device sync, offline,
time-zone travel simulation, DST day, notification delivery on locked phone, OEM battery savers), and the
beta plan (tester groups, feedback channel, exit criteria).
**Acceptance criteria:** checklist executed once per release candidate with results recorded.

### T9.1.15 — Chaos & robustness tests
**Priority:** P2 · **Size:** M · **Depends on:** T9.1.03
**Description:** Kill app during push/pull and during attachment upload; toggle airplane mode repeatedly;
device clock jumps (±1 day); zone change while a timer runs; storage full; DB migration interrupted.
**Acceptance criteria:** no data loss or duplicate rows; app recovers on next launch.

### T9.1.16 — Quality dashboard
**Priority:** P2 · **Size:** S · **Depends on:** T9.1.01, T9.1.08
**Description:** Single CI summary page (coverage trend, perf trend, flaky test list, open a11y issues) for
release decisions.
