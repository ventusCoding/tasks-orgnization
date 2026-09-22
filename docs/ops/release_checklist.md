# Release checklist (T9.2.16)

Copy this list into the release PR and tick every line.

## Before tagging
- [ ] Version bumped in `app/pubspec.yaml` (`MAJOR.MINOR.PATCH+BUILD`), CHANGELOG updated.
- [ ] All migrations follow expand → migrate → contract (`docs/ops/schema_evolution.md`); none drops or renames in the same release.
- [ ] `melos run analyze`, `melos run test`, backend `supabase test db`, `deno test` all green.
- [ ] Manual QA script executed on one Android and one iOS device (`docs/qa/qa_checklist.md`).
- [ ] Accessibility & RTL spot checks (`docs/qa/a11y.md`).
- [ ] Store notes written in EN/FR/AR.
- [ ] `app_config.min_supported_build` reviewed (bump only if old builds can't sync).

## Rollout
- [ ] Tag `vX.Y.Z` → `release.yml` deploys backend (approval) then uploads AAB/IPA.
- [ ] Play: internal → closed → production staged 5 % → 20 % → 50 % → 100 % (watch Crashlytics & ANRs 24 h each).
- [ ] App Store: TestFlight → phased release.
- [ ] Monitor dispatcher lag (`private.ops_health()`), sync errors, crash-free rate ≥ 99.5 %.

## Rollback
- Halt the staged rollout; ship a hotfix build; disable risky features with feature flags; never roll back
  migrations — ship a forward fix.
