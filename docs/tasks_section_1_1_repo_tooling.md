# Section 1.1 — Repository, Tooling & CI Skeleton

> Milestones: M0 (P0) · M2 (P1) · M3 (P2) · Depends on: — (first section)
> Architecture: arch §3 (stack & versions), §5 (repository layout), §11 (config, CI), ADR-014

## Goal

A clean, reproducible monorepo where anyone (human or Claude Code) can clone, run one bootstrap command
and get: the pinned Flutter SDK, the Flutter app (dev/prod flavors) and two pure-Dart packages in one pub
workspace, code generation, strict lints, environment configuration and a CI pipeline that formats,
analyzes and tests every change.

## Scope

**In:** git init & conventions, SDK upgrade + FVM pin, pub workspace + melos scripts, Flutter app scaffold
(iOS/Android, SwiftPM, UIScene, `material_ui`), pure packages, lints, codegen, flavors, env config, CI
skeleton, local scripts, hooks, dependency automation, versioning.
**Out:** Supabase/Firebase setup ([1.2]); app architecture code ([1.3]); release pipelines ([9.2]).

## Progress

- [ ] T1.1.01 — Initialize repository & conventions
- [ ] T1.1.02 — Upgrade Flutter & pin it with FVM
- [ ] T1.1.03 — Pub workspace root + melos scripts
- [ ] T1.1.04 — Scaffold the Flutter app (`app/`)
- [ ] T1.1.05 — iOS project setup: SwiftPM, UIScene, deployment target
- [ ] T1.1.06 — Android project setup: SDK levels, Gradle/AGP/Kotlin, namespaces
- [ ] T1.1.07 — Pure-Dart packages skeletons
- [ ] T1.1.08 — Strict analysis: very_good_analysis + riverpod_lint plugin
- [ ] T1.1.09 — Code generation setup
- [ ] T1.1.10 — Flavors (dev / prod) & entrypoints
- [ ] T1.1.11 — Environment configuration (`--dart-define-from-file`)
- [ ] T1.1.12 — CI skeleton (GitHub Actions)
- [ ] T1.1.13 — Local developer scripts & IDE launch configs
- [ ] T1.1.14 — Git hooks (format/analyze/commit message)
- [ ] T1.1.15 — Dependency update automation
- [ ] T1.1.16 — Versioning & changelog tooling
- [ ] T1.1.17 — Contributor docs (README, CONTRIBUTING, PR template)

## Tasks

### T1.1.01 — Initialize repository & conventions
**Priority:** P0 · **Size:** S · **Depends on:** —
**Description:** `git init` on `main`, add `.gitignore` (Flutter/Dart, `.dart_tool`, `build/`, generated
`*.g.dart`/`*.freezed.dart`/`*.drift.dart`, iOS Pods/SwiftPM caches, Android `.gradle`/`local.properties`,
`env/*.json` except `env/example.json`, `*.jks`/`*.keystore`/`key.properties`, `google-services.json` and
`GoogleService-Info.plist` **only if** the team decides not to commit them (recommended: commit dev,
keep prod out), Supabase `.branches`/`.temp`, Deno caches, `.fvm/flutter_sdk`), `.editorconfig`,
`.gitattributes` (LF), root `README.md` stub linking to `CLAUDE.md` and `docs/README.md`.
**Implementation notes:** trunk-based flow: short-lived branches `feat/T3.4.07-pinch-zoom`, PRs into
`main`, squash merge with conventional-commit titles.
**Acceptance criteria:** `git status` clean after a full build; no secrets or generated files tracked.
**Tests:** CI secret scan (added in [9.1] T9.1.12) passes on the initial commit.

### T1.1.02 — Upgrade Flutter & pin it with FVM
**Priority:** P0 · **Size:** S · **Depends on:** T1.1.01
**Description:** The machine currently has Flutter 3.38.9 / Dart 3.10.8; the stack requires **Flutter
3.47.5 / Dart 3.13.4** (arch §3.1). Install FVM, `fvm use 3.47.5` (writes `.fvmrc`), document the upgrade
policy (upgrade within 4 weeks of a new stable, in a dedicated PR with full CI + manual smoke test).
**Implementation notes:** all scripts call `fvm flutter` / `fvm dart`; IDE settings point to `.fvm/flutter_sdk`.
**Acceptance criteria:** `fvm flutter --version` prints 3.47.5 in the repo; `flutter doctor` clean for
iOS & Android toolchains (Xcode 27 command line tools, Android SDK 36, Java 17).
**Tests:** CI reads the version from `.fvmrc` (T1.1.12).

### T1.1.03 — Pub workspace root + melos scripts
**Priority:** P0 · **Size:** S · **Depends on:** T1.1.02
**Description:** Root `pubspec.yaml` with `environment: sdk: ^3.13.0`, `workspace: [app, packages/*]`
(glob members), one shared lockfile, and melos 8 configuration **inside the root pubspec** (`melos:`)
with scripts: `gen`, `gen:watch`, `analyze` (`dart analyze --fatal-infos`), `format`, `format:check`,
`test` (dart test for pure packages, flutter test for app), `test:coverage`, `outdated`, `clean`.
**Implementation notes:** members declare `resolution: workspace`; keep melos optional — every script
also works with plain `fvm dart run` commands documented in `CLAUDE.md`.
**Acceptance criteria:** `fvm dart pub get` at the root resolves all members; `melos run analyze` and
`melos run test` run across all packages.
**Tests:** CI job uses these scripts.

### T1.1.04 — Scaffold the Flutter app (`app/`)
**Priority:** P0 · **Size:** M · **Depends on:** T1.1.03
**Description:** `fvm flutter create --org <reverse-domain> --project-name everslot --platforms ios,android
app`, remove counter boilerplate, add the dependency set of arch §3.1 at the verified versions (only
what M0 needs; others added by their tasks), switch imports to `package:material_ui/material_ui.dart`
(and `cupertino_ui` where used), create the folder skeleton of arch §5 with README stubs.
**Implementation notes:** bundle/application id placeholder from arch §14 (final before first store
upload); app display name "Everslot" (dev: "Everslot Dev"); **do not** add `sqlite3_flutter_libs`
(SQLite comes via `sqlite3` build hooks).
**Acceptance criteria:** app builds and runs on an iOS simulator and an Android emulator showing a
placeholder screen; `dart analyze` clean.
**Tests:** a smoke widget test pumping the root widget.

### T1.1.05 — iOS project setup: SwiftPM, UIScene, deployment target
**Priority:** P0 · **Size:** S · **Depends on:** T1.1.04
**Description:** iOS deployment target 15.0; Swift Package Manager integration enabled (CocoaPods only if
a plugin still requires it); **UIScene lifecycle** adopted (SceneDelegate) per the Flutter migration
guide — mandatory for apps built with Xcode 27; background modes placeholders (remote notifications,
background fetch/processing) added later by their tasks; `ITSAppUsesNonExemptEncryption = NO`.
**Acceptance criteria:** clean build with Xcode 27; app launches (no "fails to launch" UIScene error);
plugin registration works after scene connection.
**Tests:** CI iOS build job (T1.1.12, macOS runner, no signing).

### T1.1.06 — Android project setup: SDK levels, Gradle/AGP/Kotlin, namespaces
**Priority:** P0 · **Size:** S · **Depends on:** T1.1.04
**Description:** `minSdk 24`, `compileSdk`/`targetSdk 36`, Java 17, AGP 9.1, Gradle 9.3.1, Kotlin Gradle
Plugin 2.4 (versions per arch §3.1), Kotlin DSL build files, `namespace` set, R8 enabled for release with
keep rules placeholder, core library desugaring enabled (required by notification plugins).
**Acceptance criteria:** `fvm flutter build apk --flavor dev` succeeds; release build minifies without
missing-class errors.
**Tests:** CI Android build job.

### T1.1.07 — Pure-Dart packages skeletons
**Priority:** P0 · **Size:** S · **Depends on:** T1.1.03
**Description:** `packages/everslot_recurrence` and `packages/everslot_metrics`: pure Dart (no Flutter),
`resolution: workspace`, `lib/src/` + barrel file, `test/` with a sample test, `analysis_options.yaml`
inheriting the root, README describing purpose & public API policy (only barrel exports are public).
**Acceptance criteria:** `dart test` runs in each package; importing Flutter in them fails analysis
(dependency not declared).
**Tests:** sample unit tests.

### T1.1.08 — Strict analysis: very_good_analysis + riverpod_lint plugin
**Priority:** P0 · **Size:** S · **Depends on:** T1.1.03
**Description:** Root `analysis_options.yaml` including `very_good_analysis` 11, `strict-casts`,
`strict-inference`, `strict-raw-types`, excludes for generated files, and `riverpod_lint` enabled under
`plugins:` (new analyzer plugin system — not `custom_lint`). Project-specific rules: `avoid_print`,
`public_member_api_docs` off for app code (on for pure packages).
**Acceptance criteria:** `melos run analyze` passes with `--fatal-infos`; a deliberate `print()` fails CI.
**Tests:** CI analyze job.

### T1.1.09 — Code generation setup
**Priority:** P0 · **Size:** S · **Depends on:** T1.1.08
**Description:** `build_runner` 2.16 with `build.yaml` options for freezed 4, json_serializable
(field rename snake_case, explicit-null handling), riverpod_generator, drift_dev (named parameters,
`store_date_time_values_as_text: true`), go_router_builder; scripts `melos run gen` / `gen:watch`
(`--workspace` builds). Policy: generated files are **not committed**; CI and bootstrap run `gen`.
**Acceptance criteria:** fresh clone → bootstrap → `gen` → analyze clean in < 3 min on CI.
**Tests:** CI step ordering (gen before analyze/test).

### T1.1.10 — Flavors (dev / prod) & entrypoints
**Priority:** P0 · **Size:** M · **Depends on:** T1.1.05, T1.1.06
**Description:** Android `productFlavors { dev { applicationIdSuffix ".dev" } prod {} }` with flavor-specific
app names/icons; iOS build configurations + schemes `dev`/`prod` with bundle id suffix and display names;
Dart entrypoints `lib/main_dev.dart` / `lib/main_prod.dart` calling `bootstrap(Flavor.x)`; a small "DEV"
corner banner in dev.
**Acceptance criteria:** dev and prod installable side by side on the same device; `Flavor.current`
available to code.
**Tests:** unit test for flavor → config mapping.

### T1.1.11 — Environment configuration (`--dart-define-from-file`)
**Priority:** P0 · **Size:** S · **Depends on:** T1.1.10
**Description:** `env/example.json` (committed) with `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`,
`FLAVOR`, feature toggles; real `env/dev.json` / `env/prod.json` gitignored. Typed `Env` class reading
`String.fromEnvironment`, validated at startup with a clear error screen in dev if missing.
**Implementation notes:** never put secret keys in env files for the app (arch §11); document how to get
local values from `supabase status`.
**Acceptance criteria:** running without an env file shows a readable configuration error (dev), never a crash loop.
**Tests:** unit tests for `Env` validation.

### T1.1.12 — CI skeleton (GitHub Actions)
**Priority:** P0 · **Size:** M · **Depends on:** T1.1.09, T1.1.11
**Description:** `.github/workflows/ci.yml` on PRs and `main`: checkout → read `.fvmrc` →
`subosito/flutter-action` with cache → `dart pub get` → `melos run gen` → `format:check` → `analyze` →
`test` (with coverage artifact) → Android debug build (dev flavor) → iOS build `--no-codesign` on macOS
(nightly/`main` only to save minutes). Concurrency group cancels superseded runs. Supabase and Deno jobs
are added by [1.2].
**Acceptance criteria:** a PR with a failing test or unformatted file is blocked; typical run < 12 min.
**Tests:** open a test PR that breaks formatting (must fail).

### T1.1.13 — Local developer scripts & IDE launch configs
**Priority:** P1 · **Size:** S · **Depends on:** T1.1.12
**Description:** `tool/bootstrap.sh` (FVM install check, pub get, gen, Supabase start hint),
`tool/reset_local_backend.sh` (db reset + seed), `tool/new_migration.sh <name>`; VS Code
`launch.json` for dev/prod flavors with env files; Android Studio run configurations documented.
**Acceptance criteria:** a new machine goes from clone to running app with ≤ 3 commands (documented).

### T1.1.14 — Git hooks (format/analyze/commit message)
**Priority:** P1 · **Size:** S · **Depends on:** T1.1.12
**Description:** `lefthook` (or plain `.githooks/`) — pre-commit: `dart format` on staged Dart files +
`deno fmt` on staged TS; commit-msg: conventional-commit check with optional `Refs: T…` trailer.
**Acceptance criteria:** hooks install via bootstrap; can be skipped consciously with `--no-verify`.

### T1.1.15 — Dependency update automation
**Priority:** P1 · **Size:** S · **Depends on:** T1.1.12
**Description:** Dependabot (or Renovate) for pub (grouped minor/patch weekly), GitHub Actions, and npm
specifiers in Edge Functions; major bumps as separate PRs with changelog links; `melos run outdated`
monthly review noted in the release checklist ([9.2]).
**Acceptance criteria:** update PRs open automatically, run full CI, and never auto-merge major versions.

### T1.1.16 — Versioning & changelog tooling
**Priority:** P1 · **Size:** S · **Depends on:** T1.1.14
**Description:** SemVer app version in `app/pubspec.yaml` (`MAJOR.MINOR.PATCH+BUILD`), build number
from CI; changelog generated from conventional commits (melos version or release-please) into
`CHANGELOG.md`; tags `vX.Y.Z` trigger release workflows ([9.2]).
**Acceptance criteria:** a dry-run release produces the next SemVer version and a changelog grouped by type.

### T1.1.17 — Contributor docs (README, CONTRIBUTING, PR template)
**Priority:** P2 · **Size:** S · **Depends on:** T1.1.13
**Description:** Root README (what/why/how to run), `CONTRIBUTING.md` (workflow, task IDs, DoD),
`.github/pull_request_template.md` (task IDs, screenshots light/dark/RTL, tests run, docs updated).
