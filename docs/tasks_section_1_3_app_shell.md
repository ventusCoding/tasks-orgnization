# Section 1.3 — App Shell, Core Utilities & Design System

> Milestones: M0 (P0) · M2 (P1) · M3 (P2) · Depends on: 1.1
> Architecture: arch §5 (layout), §6.1–6.4 (layers, modules, Riverpod, navigation), §6.14 (design
> system, i18n, RTL, a11y), §6.15 (errors & logging), §9.2 (ids), §9.4 (ordering), §9.8 (feature flags)

## Goal

The skeleton every feature plugs into: layered folders with enforced boundaries, a deterministic
bootstrap, core utilities (clock, ids, fractional ordering, lifecycle, connectivity), typed routing with a
5-tab shell and a single deep-link parser, the Everslot design system (tokens, components, pickers with
1-minute precision), light/dark themes, EN/FR/AR localization with RTL, accessibility baseline, error
handling/logging, and a dev-only debug menu.

## Scope

**In:** everything above.
**Out:** Database & sync ([1.4]); auth screens ([1.5]); recurrence picker ([2.1]); feature screens.

## Progress

- [x] T1.3.01 — Layer skeleton & import boundaries
- [x] T1.3.02 — Bootstrap sequence
- [x] T1.3.03 — Core utilities: clock, ids (v7/v5), fractional index
- [x] T1.3.04 — App lifecycle & connectivity services
- [x] T1.3.05 — Error model, global handlers & logging
- [ ] T1.3.06 — Routing: typed routes, 5-tab shell, modal editors
- [x] T1.3.07 — Deep-link parser (single source for all entry points)
- [x] T1.3.08 — Design tokens & themes (light/dark, category palette)
- [x] T1.3.09 — Typography & bundled fonts (Latin + Arabic)
- [ ] T1.3.10 — Core components v1
- [x] T1.3.11 — Pickers: date, time (1-min), duration, color, icon
- [ ] T1.3.12 — App scaffold: bottom bar, app bar actions, contextual FAB, adaptive layout
- [x] T1.3.13 — Localization (EN/FR/AR) & formatting helpers
- [x] T1.3.14 — RTL baseline
- [x] T1.3.15 — Accessibility baseline
- [x] T1.3.16 — Feature flags & dev debug menu (incl. time travel)
- [x] T1.3.17 — Haptics & sound service
- [x] T1.3.18 — Motion & page transitions
- [x] T1.3.19 — Tablet/landscape layout foundations

## Tasks

### T1.3.01 — Layer skeleton & import boundaries
**Priority:** P0 · **Size:** S · **Depends on:** [1.1]
**Description:** Create `app/lib/{app,core,design_system,features,l10n}` and the feature module template
(arch §6.2) for every planned feature; enforce boundaries: `domain/` may not import Flutter, Drift,
Supabase or other features' `data/`; `presentation/` may not import `data/`.
**Implementation notes:** a small analyzer plugin rule or a CI script (`tool/check_imports.dart`) that
scans imports per layer and fails with actionable messages.
**Acceptance criteria:** a deliberate forbidden import fails CI with the offending file and rule.
**Tests:** script unit tests with sample files.
**Notes:** `tool/check_imports.dart` (CI step "Import boundaries") also runs the RTL grep checks of
T1.3.14; `app/test/tool/check_imports_test.dart` runs it over all of `app/lib`, so a violation anywhere
fails the app test suite too. Opt-outs: `// boundary-ok <reason>` / `// rtl-ok <reason>`.

### T1.3.02 — Bootstrap sequence
**Priority:** P0 · **Size:** M · **Depends on:** T1.3.01, T1.3.05
**Description:** `bootstrap(Flavor)`: `WidgetsFlutterBinding.ensureInitialized` → logging → env validation
→ timezone database init (`timezone/data/latest_all.dart`) + device zone → Firebase init (if configured,
P1) → Supabase init (publishable key; custom secure session storage from [1.5]) → Drift database open
([1.4]) → `ProviderScope` with overrides → `runApp` inside a guarded zone. Splash stays until the first
frame of the shell is ready.
**Acceptance criteria:** cold start to first frame < 1.5 s on a mid-range Android (profile); a failure in
any step shows a recoverable error screen (dev: details; prod: friendly message + retry).
**Tests:** unit tests of the ordered init list with fakes; failure-path widget test.
**Notes:** `bootstrap(Flavor)` is now an ordered list of named steps (`startup/bootstrap_steps.dart`: logging → environment → time zones → Firebase (optional) → Supabase (optional, secure session storage) → database → session → providers → startup tasks) run by `BootstrapRunner` inside a guarded zone (`bootstrap.dart`); plugins, the database file and `runApp` sit behind `BootstrapPlatform` so tests use fakes. A required step that throws returns a `BootstrapFailure` and the app shows `BootstrapErrorApp` (self-contained, EN/FR/AR: dev flavor shows step + error + stack with a copy button, prod a friendly message; Retry resumes at the failed step and never repeats finished ones); optional steps are logged and skipped (local-only mode). Per-step timings are logged ("bootstrap finished in N ms") for the cold-start budget; the native launch screen stays until `runApp`, which only runs after all steps succeeded, so no half-initialised frame is drawn. Not measurable here: the < 1.5 s profile-mode cold start on a mid-range Android. Tests: `test/startup/bootstrap_test.dart`.

### T1.3.03 — Core utilities: clock, ids (v7/v5), fractional index
**Priority:** P0 · **Size:** M · **Depends on:** T1.3.01
**Description:** `core/time/clock.dart` (`Clock` interface, `SystemClock`, `FakeClock`, `clockProvider`);
`core/ids/` (UUIDv7 generator, UUIDv5 with `EVERSLOT_NS`, helpers for every deterministic id in arch §9.2);
`core/ordering/` (fractional indexing vendored from `fractional_indexing_dart`, API: `between(a, b)`,
`nBetween(a, b, n)`, validation of key charset/length; byte-order comparison helper).
**Acceptance criteria:** v5 ids match the SQL `app.uuid_v5` fixtures; fractional keys stay sorted under
10 000 random inserts and remain ≤ 64 chars in realistic sequences.
**Tests:** fixture tests (`fixtures/ids/uuid_v5.json`), property tests for ordering.
**Notes:** `Clock` (`SystemClock`, `TravelClock` for the debug time offset, `FakeClock`, `clockProvider`), `Ids` (UUIDv7 + UUIDv5 in `EVERSLOT_NS` with a helper per deterministic id of arch §9.2) and `FractionalIndex` (`between`, `nBetween`, `isValid`, plus `compare`/`compareRows` byte-order helpers and the 64-char `isOversized` budget). Tests: `test/core/{ids,fractional_index,clock}_test.dart` — the 20 shared UUIDv5 vectors of `fixtures/ids/uuid_v5.json` (also asserted in SQL by `supabase/tests/database/010_helpers.test.sql`), the rocicorp reference vectors, 10 000 random inserts (sorted, valid, ≤ 64 chars). Bugs found and fixed: `Ids.builtinProfile` used `user|notification_profile|code` while the server seed/migration derive `user|profile|code` (built-in notification profiles would have diverged between client and server); `FractionalIndex.between` threw a `RangeError` when the lower key was shorter than the common prefix (JS `slice` clamps, Dart `substring` throws) — found by the random-insert property test.

### T1.3.04 — App lifecycle & connectivity services
**Priority:** P0 · **Size:** S · **Depends on:** T1.3.03
**Description:** `AppLifecycleService` (resume/pause/detached streams, debounced) and
`ConnectivityService` (online/offline with actual reachability check to the Supabase host) exposed as
providers; used by sync, notification replanning and Today.
**Tests:** unit tests with fake platform streams.
**Notes:** `AppLifecycleService` (debounced `onResume`, `onPause`, `onDetached`, raw `states`, `onReturn` with time away) and `ConnectivityService` (platform signal + reachability probe of the Supabase host) behind providers. The five lifecycle streams are synchronous broadcast controllers so one transition reaches listeners in order across streams (the checkpoint's async controllers interleaved them). Tests: `test/core/lifecycle_test.dart`, `test/core/platform/connectivity_service_test.dart`.


### T1.3.05 — Error model, global handlers & logging
**Priority:** P0 · **Size:** M · **Depends on:** T1.3.01
**Description:** Sealed `AppException` hierarchy (network, auth, validation, conflict, storage,
permission, notFound, unsupportedVersion, unknown) with localized message keys; mappers from Supabase/
Drift/platform exceptions; `FlutterError.onError` + `PlatformDispatcher.instance.onError` routing to a
reporter (console in debug; Crashlytics sink added in [1.2] T1.2.15); `logging` root listener with
levels and a ring buffer viewable in the debug menu; strict "no PII in logs" helper (ids only).
**Acceptance criteria:** an uncaught async error is logged once, reported (release) and does not crash
the UI; every `AppException` renders a localized message.
**Tests:** unit tests for mappers; widget test for error rendering.
**Notes:** `AppException` (sealed) carries an `AppErrorKind` (network, auth, validation, conflict, storage, permission, notFound, unsupportedVersion, notConfigured, unknown) and `isRetryable`; `toAppException` (`core/errors/error_mapper.dart`) maps Supabase Auth / PostgREST / Functions / Storage, the sync API, Drift + SQLite (unique/PK → conflict, disk/IO/corruption → storage) and `dart:io` / `http` / platform errors — messages hold codes only, never row values; the original is `cause`. `ErrorState.messageFor` renders every kind localized (EN/FR/AR, new `errorConflict`/`errorStorage`) and unknown foreign errors get the generic "Please try again." (never raw exception text); `FriendlyErrorWidget` replaces the release-mode grey box. `GlobalErrorHandlers` (`FlutterError.onError`, `PlatformDispatcher.onError`, the bootstrap zone) logs each error once (identity dedupe), reports to an `ErrorReporter` in release only (`CrashlyticsErrorReporter`, opt-out via `privacy.crashReporting`, texts scrubbed) and always swallows it. `LogSafe` (ids-only helper + scrubbing of e-mails, JWTs, bearer tokens, keys, secret URL parameters) is applied to every `AppLog` record (ring buffer of 500, console in debug, external sink); `AppLog.init` is idempotent. Tests: `test/core/errors/*`, `test/design_system/error_state_test.dart`.

### T1.3.06 — Routing: typed routes, 5-tab shell, modal editors
**Priority:** P0 · **Size:** M · **Depends on:** T1.3.02
**Description:** `go_router` 18 + `go_router_builder` typed routes; `StatefulShellRoute.indexedStack` with
branches Today · Plan · Lists · Habits · Insights (placeholder screens); top-level routes for Inbox,
Search, Settings, editors as full-screen modal routes on phones (sheets on tablets); auth redirect hook
(placeholder until [1.5]); restoration of the last tab.
**Acceptance criteria:** each tab keeps its own navigation stack; Android back behaves (tab history, then
exit); iOS swipe-back works on pushed routes.
**Tests:** router unit tests (redirects, typed route building); widget test switching tabs.

### T1.3.07 — Deep-link parser (single source for all entry points)
**Priority:** P0 · **Size:** S · **Depends on:** T1.3.06
**Description:** Pure `DeepLinkParser` for `everslot://` URIs and canonical paths in arch §6.4 → typed
`AppLocation`; used by notifications, widgets, share, search and external links ([8.2]); rejects
unknown/oversized parameters.
**Acceptance criteria:** every canonical path parses and round-trips with the builders ([2.3] T2.3.12).
**Tests:** table tests + fuzz test (random strings never throw).
**Notes:** the parser returns router path strings (go_router consumes paths), not a typed `AppLocation`;
the fuzz test found that malformed percent-encoding threw `FormatException` — `parse` now returns null.
Tests: `app/test/core/routing/deep_links_test.dart` (table, fuzz, builder ↔ parser property test).

### T1.3.08 — Design tokens & themes (light/dark, category palette)
**Priority:** P0 · **Size:** M · **Depends on:** T1.3.01
**Description:** `design_system/tokens/`: color roles (light/dark), **16-color category palette** (contrast
validated, color-blind-safe ordering), status colors (todo, ongoing, waiting, blocked, completed,
cancelled, missed, skipped) always paired with icons, spacing (4-pt grid), radii, elevation, motion
durations/curves, opacity; exposed as `ThemeExtension`s on Material 3 themes built with `material_ui`;
optional dynamic color (Android 12+) that never overrides category colors.
**Acceptance criteria:** switching light/dark/system updates instantly; tokens are the only source of colors
in feature code (lint/grep check for raw `Color(0x…)` outside design_system).
**Tests:** contrast unit test for every text/background pair; goldens for the palette sheet.
**Notes:** `design_system/tokens.dart`: spacing, radii, motion, `Elevation`, `Opacities`, `AppShadows`, `BrandColors`, `DataVizColors` (Okabe–Ito chart series + tones, moved out of `chart_theme.dart`), 16-color `CategoryPalette` + `CategoryColors`, `AppColors` ThemeExtension (semantic + 8 status colors, always shown with icons). Light/dark/system switch instantly (Settings › Appearance). Optional Android 12+ dynamic color (`dynamic_color` 2.1, Appearance › Wallpaper colors, off by default) replaces only the Material scheme — category/status/chart colors are tokens. `tool/check_imports.dart` rule `raw-color` rejects `Color(0x…)`/`Color.fromARGB` outside `design_system/` (`// color-ok` opt-out); the 30 existing hits moved to tokens. Tests: `color_contrast_test.dart` (every theme text/background pair ≥ 4.5:1; status colors ≥ 3:1 as icons and ≥ 4.5:1 as text via `readableOn` — the light cancelled/skipped grey was 2.4:1 and is now `0xFF858C99`), palette sheet goldens (`palette_golden_test.dart`, light/dark).


### T1.3.09 — Typography & bundled fonts (Latin + Arabic)
**Priority:** P0 · **Size:** S · **Depends on:** T1.3.08
**Description:** Bundle Inter (Latin) and Noto Sans Arabic (variable or 3 weights) as assets with licenses;
type scale (display → caption) with tabular figures for times/numbers; locale-aware font fallback so
Arabic text uses Noto Sans Arabic automatically; no runtime font downloads.
**Acceptance criteria:** mixed Arabic/Latin strings render with correct fonts and baselines; times align
in columns (tabular numbers).
**Tests:** goldens EN/AR at text scale 1.0 and 2.0.
**Notes:** Inter (400/500/600/700, latin + latin-ext) and Noto Sans Arabic (400–700) bundled under `assets/fonts` with their OFL texts (registered in the licenses page at bootstrap); `ThemeData.fontFamily` Inter with `fontFamilyFallback` Noto Sans Arabic, so Arabic glyphs switch automatically; `AppTypography.tabular` / `AppTheme.tabular` for times and counters. flutter_test does not load app fonts, so `test/support/fonts.dart` loads them for typography goldens. Tests: `typography_test.dart` (Inter is proportional, tabular digits equal width, Arabic via fallback = Noto metrics, theme families) + goldens EN/AR × 1.0/2.0.


### T1.3.10 — Core components v1
**Priority:** P0 · **Size:** L · **Depends on:** T1.3.08, T1.3.09
**Description:** Buttons (primary/secondary/text/icon), inputs (text, multiline, search), list tiles,
chips (filter/choice/input), status pill, progress ring & bar (incl. status-split bar), bottom-sheet
scaffold (drag handle, sticky actions, keyboard-safe), dialogs (confirm/destructive), snackbars with
**Undo**, empty/error/loading states, section headers, segmented control, swipe-action row, avatar,
badge. All themed via tokens, RTL-safe, with semantics.
**Acceptance criteria:** a component gallery screen (dev flavor) shows every component in light/dark, LTR/RTL.
**Tests:** widget tests for interactive behaviour; goldens for each component.

### T1.3.11 — Pickers: date, time (1-min), duration, color, icon
**Priority:** P0 · **Size:** M · **Depends on:** T1.3.10, T1.3.13
**Description:** Date picker (week start aware, quick chips: today/tomorrow/next week), **time picker with
1-minute precision** and 12/24 h (wheel + keyboard entry), duration picker (1 min … 365 days, quick
presets 5/15/30/45/60/90 min), time-range picker (start/end or start/duration), color picker (category
palette + custom with contrast warning), icon picker (curated Material Symbols with EN/FR/AR keywords).
**Acceptance criteria:** entering 07:03 by keyboard works in both 12/24 h; durations format per locale;
pickers usable with screen readers.
**Tests:** widget tests per picker; unit tests for parsing/formatting.
**Notes:** `design_system/pickers/pickers.dart` (same call signatures as before, so the 36 call sites are unchanged): `pickDate` — sheet with Today/Tomorrow/Next week chips and a month grid starting on the user's week start (`DatePickerPanel`, 48 dp cells labelled with the long date, range limits); `pickTime` — text entry (`parseTimeInput`: "07:03", "703", "7.03", "7h03", "7:03 pm", "7 م", Arabic-Indic digits) plus hour/minute(/AM-PM) wheels in 1-minute steps (`TimeWheels`, hidden from screen readers — the field is the accessible path); `pickDuration` — locale-formatted presets (5/15/30/45/60/90 min …) + steppers; `pickTimeRange` — start/end or start + preset, ends after midnight wrap; `pickColor` — palette, "no color", custom hex with a low-contrast warning (< 3:1 on the surface); `pickIcon` — EN/FR/AR keyword search. Tests: `test/design_system/pickers_test.dart` (parsing table, 07:03 typed in 12 h and 24 h, wheels, week starts, ranges, semantics, colors). Tests that drove Material's pickers were updated to the new keys; `task_detail_test` "Arabic RTL and text scale 2.0" hung 10 min in tearDown on `main` already (DB close waiting on a query started by the scroll under fake async) — it now unmounts and settles first.


### T1.3.12 — App scaffold: bottom bar, app bar actions, contextual FAB, adaptive layout
**Priority:** P0 · **Size:** M · **Depends on:** T1.3.06, T1.3.10
**Description:** Shell scaffold with bottom navigation (5 tabs, badges), top app bar actions (Search,
Inbox with unread badge placeholder, Profile/Settings), a contextual **+** whose action depends on the
active tab (long-press = universal quick-add, [8.1]), safe areas, and breakpoints (compact < 600 dp,
medium 600–840, expanded > 840) switching to a navigation rail on tablets.
**Acceptance criteria:** works in portrait/landscape, phones and tablets; bottom bar hides on scroll where
appropriate; RTL mirrors layout.
**Tests:** widget tests at 3 breakpoints; goldens.

### T1.3.13 — Localization (EN/FR/AR) & formatting helpers
**Priority:** P0 · **Size:** M · **Depends on:** T1.3.02
**Description:** gen-l10n with ARB files in `app/lib/l10n` generating into `lib/` (no synthetic
`flutter_gen`), EN as template, FR and AR from day one; locale resolution (system → saved override);
`context.l10n` extension; `intl` helpers for dates, times (profile 12/24 h), numbers, currencies, relative
times, ICU plurals (Arabic zero/one/two/few/many/other); optional Arabic-Indic digits setting.
**Acceptance criteria:** switching locale at runtime updates strings, formats and direction; CI fails on
missing keys or placeholder mismatches.
**Tests:** unit tests for plural/format helpers per locale; CI l10n check script.
**Notes:** `tool/check_l10n.dart` (run by `app/test/tool/check_l10n_test.dart` in the app suite, so CI fails)
checks that every ARB part area ships EN/FR/AR with the same keys, valid ICU (plural/select need `other`),
declared placeholders and preserved plural/select arguments. `AppFormat` gained the optional Arabic-Indic
digits (`arabicDigits:`, from `UserPreferences.useArabicDigits`), honours an explicit 12 h preference in every
locale and localizes end-of-day in 12 h mode. Tests: `app/test/design_system/formatting_test.dart`.

### T1.3.14 — RTL baseline
**Priority:** P0 · **Size:** S · **Depends on:** T1.3.13
**Description:** Only directional APIs (`EdgeInsetsDirectional`, `AlignmentDirectional`,
`PositionedDirectional`, `start/end`); directional icons mirrored (back, chevrons, indent/outdent) while
non-directional ones (clock, check) are not; bidi helpers for mixed content (e.g. Arabic title with Latin
times); lint/grep check for non-directional insets in features.
**Acceptance criteria:** all shell screens pass an RTL golden review.
**Tests:** RTL goldens; grep-based CI check.
**Notes:** grep-based check = `tool/check_imports.dart` RTL rules (`Positioned`, `EdgeInsets.only/fromLTRB`,
`Alignment.*Left/Right`, `TextAlign.left/right`). Bidi helpers: `BidiText` (`design_system/bidi.dart`: LTR/RTL/
first-strong isolates). The repo has no golden files (Ahem/font rendering differs between macOS and the Ubuntu
CI), so RTL is verified structurally in widget tests (`app/test/design_system/rtl_test.dart`: mirroring of
directional icons, start/end placement, runtime locale switch) — goldens can be added on a pinned CI runner.

### T1.3.15 — Accessibility baseline
**Priority:** P0 · **Size:** S · **Depends on:** T1.3.10
**Description:** Semantics helpers (labels/hints/values for custom widgets), 48 dp minimum targets, focus
order, text scale support up to 2.0 without clipping, `MediaQuery.disableAnimations` honoured via a
`reduceMotion` provider, live-region announcements helper for async results ("Task completed").
**Acceptance criteria:** Flutter accessibility guidelines pass on the component gallery.
**Tests:** `meetsGuideline` checks (tap targets, labels, contrast) in widget tests.
**Notes:** `ReduceMotionScope` (`design_system/motion.dart`, mounted at the app root) joins the in-app `appearance.reduceMotion` setting to the OS flag, so `context.reduceMotion` / `AppMotion.reduced` honour both; `announce()` is the live-region helper. `app/test/design_system/accessibility_test.dart` runs `androidTapTargetGuideline`, `iOSTapTargetGuideline`, `labeledTapTargetGuideline` and `textContrastGuideline` on the component gallery (light/LTR, dark/RTL, Arabic, text scale 2.0). Fixes found by it: interactive `TagChip`s dropped compact density (40 → 48 dp targets), `StatusPill` text/icon now ≥ 4.5:1 on its own tint, `PriorityBadge` no longer announces its label twice, color swatches 44 → 48 dp.

### T1.3.16 — Feature flags & dev debug menu (incl. time travel)
**Priority:** P1 · **Size:** M · **Depends on:** T1.3.03, T1.3.05
**Description:** `FeatureFlags` (compile-time defaults from env + runtime overrides in dev); debug menu
(dev flavor only, hidden gesture): flags, **time travel** (offset the injected `Clock` to test recurrences,
day rollover, notifications), zone override, log viewer, DB inspector entry, "reset local data", sync
diagnostics link, component gallery.
**Acceptance criteria:** debug menu is absent from prod builds (tree-shaken); time travel affects all
clock consumers consistently.
**Tests:** unit test that prod flavor exposes no debug routes.
**Notes:** `DebugMenuScreen` (`features/dev`): environment & config warnings, feature flags (env defaults + run-time overrides, dev only), time travel (`timeTravelProvider` shifts the one shared `TravelClock` — every clock consumer moves together, nothing is rebuilt), sticky zone override (`DeviceZoneController.debugSet/debugClear`), log viewer (`AppLog.recent`, level filter, copy), local DB inspector (row counts, first rows), sync diagnostics (T1.4.18), component gallery, reset local data. Hidden gesture: long-press the Settings title (and the version in About). Prod: route absent at run time and `Env.devToolsCompiled` (const, false with `FLAVOR=prod`) makes the menu dead code for tree-shaking. Tests: `test/features/dev/`. Shared edits: `core/time/clock.dart` (TravelClock), `core/providers.dart` (clock/time travel, zone override, flag toggle guard), `core/env/env.dart`, `app/router.dart`.

### T1.3.17 — Haptics & sound service
**Priority:** P1 · **Size:** S · **Depends on:** T1.3.02
**Description:** Central `Haptics` service (`selectionClick` for snaps, `mediumImpact` for lifts,
`success` for completions) respecting a user setting and OS settings; short UI sounds (check-in
completion) off by default.
**Tests:** unit tests with a fake platform channel.
**Notes:** `core/platform/haptics.dart`: `hapticsProvider` (`Haptics.selection/lift/light/success/warning/denied`, `play(HapticEvent)`) over a replaceable `HapticsOutput` (`HapticFeedback` incl. success/warning/error notifications; OS feedback settings apply on top); honours `appearance.haptics` (default on) and `appearance.sounds` (default off, completion click) read at each event; `hapticsEnabledProvider` for features with their own haptics (planner grid, checklists completion T4.3.12 should switch to it). Toggles live in Settings › Accessibility (T8.3.12). Tests with a mocked platform channel: `test/core/platform/haptics_test.dart`.

### T1.3.18 — Motion & page transitions
**Priority:** P1 · **Size:** S · **Depends on:** T1.3.06
**Description:** Consistent transitions (shared-axis for tab-internal navigation, fade-through between
tabs, container transform for opening items), all disabled/replaced by fades when reduce motion is on.
**Tests:** widget test verifying reduced-motion path.
**Notes:** `design_system/motion.dart`: `AppMotion.sharedAxisRoute/fadeThroughRoute/containerRoute` (+ go_router `sharedAxisPage`/`fadeThroughPage`), `SharedAxisTransition` (mirrored in RTL), `FadeThroughTransition`, `FadeThroughSwitcher`, `SharedAxisPageTransitionsBuilder` for `ThemeData.pageTransitionsTheme`. No `animations` dependency: the container transform is approximated by a scaled shared-axis zoom. Reduced motion → cross-fade (routes) or no animation (switcher/implicit durations). Tests: `app/test/design_system/motion_test.dart`.

### T1.3.19 — Tablet/landscape layout foundations
**Priority:** P1 · **Size:** S · **Depends on:** T1.3.12
**Description:** `AdaptiveLayout` helpers (window size classes, two-pane scaffold with list/detail),
keyboard shortcuts infrastructure (`Shortcuts`/`Actions`) for tablets with keyboards; full multi-pane
screens are [9.3] T9.3.01.
**Tests:** widget tests at expanded width.
**Notes:** `design_system/adaptive.dart`: `WindowSizeClass` (+ `context.windowSize`), `AdaptiveBuilder` (uses the available width), `TwoPaneScaffold` (list/detail, start-edge list pane, single-pane back handling) and the shortcut infrastructure (`AppShortcuts.defaults` with Ctrl and ⌘ variants, intents Undo/Redo/OpenSearch/OpenCommandPalette/NewItem, `AppShortcutScope` that steps aside while a text field has focus). Tests: `app/test/design_system/adaptive_test.dart`.

