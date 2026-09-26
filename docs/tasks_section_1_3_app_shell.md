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
- [ ] T1.3.02 — Bootstrap sequence
- [ ] T1.3.03 — Core utilities: clock, ids (v7/v5), fractional index
- [ ] T1.3.04 — App lifecycle & connectivity services
- [ ] T1.3.05 — Error model, global handlers & logging
- [ ] T1.3.06 — Routing: typed routes, 5-tab shell, modal editors
- [x] T1.3.07 — Deep-link parser (single source for all entry points)
- [ ] T1.3.08 — Design tokens & themes (light/dark, category palette)
- [ ] T1.3.09 — Typography & bundled fonts (Latin + Arabic)
- [ ] T1.3.10 — Core components v1
- [ ] T1.3.11 — Pickers: date, time (1-min), duration, color, icon
- [ ] T1.3.12 — App scaffold: bottom bar, app bar actions, contextual FAB, adaptive layout
- [ ] T1.3.13 — Localization (EN/FR/AR) & formatting helpers
- [ ] T1.3.14 — RTL baseline
- [ ] T1.3.15 — Accessibility baseline
- [ ] T1.3.16 — Feature flags & dev debug menu (incl. time travel)
- [ ] T1.3.17 — Haptics & sound service
- [ ] T1.3.18 — Motion & page transitions
- [ ] T1.3.19 — Tablet/landscape layout foundations

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

### T1.3.03 — Core utilities: clock, ids (v7/v5), fractional index
**Priority:** P0 · **Size:** M · **Depends on:** T1.3.01
**Description:** `core/time/clock.dart` (`Clock` interface, `SystemClock`, `FakeClock`, `clockProvider`);
`core/ids/` (UUIDv7 generator, UUIDv5 with `EVERSLOT_NS`, helpers for every deterministic id in arch §9.2);
`core/ordering/` (fractional indexing vendored from `fractional_indexing_dart`, API: `between(a, b)`,
`nBetween(a, b, n)`, validation of key charset/length; byte-order comparison helper).
**Acceptance criteria:** v5 ids match the SQL `app.uuid_v5` fixtures; fractional keys stay sorted under
10 000 random inserts and remain ≤ 64 chars in realistic sequences.
**Tests:** fixture tests (`fixtures/ids/uuid_v5.json`), property tests for ordering.

### T1.3.04 — App lifecycle & connectivity services
**Priority:** P0 · **Size:** S · **Depends on:** T1.3.03
**Description:** `AppLifecycleService` (resume/pause/detached streams, debounced) and
`ConnectivityService` (online/offline with actual reachability check to the Supabase host) exposed as
providers; used by sync, notification replanning and Today.
**Tests:** unit tests with fake platform streams.

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

### T1.3.09 — Typography & bundled fonts (Latin + Arabic)
**Priority:** P0 · **Size:** S · **Depends on:** T1.3.08
**Description:** Bundle Inter (Latin) and Noto Sans Arabic (variable or 3 weights) as assets with licenses;
type scale (display → caption) with tabular figures for times/numbers; locale-aware font fallback so
Arabic text uses Noto Sans Arabic automatically; no runtime font downloads.
**Acceptance criteria:** mixed Arabic/Latin strings render with correct fonts and baselines; times align
in columns (tabular numbers).
**Tests:** goldens EN/AR at text scale 1.0 and 2.0.

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

### T1.3.14 — RTL baseline
**Priority:** P0 · **Size:** S · **Depends on:** T1.3.13
**Description:** Only directional APIs (`EdgeInsetsDirectional`, `AlignmentDirectional`,
`PositionedDirectional`, `start/end`); directional icons mirrored (back, chevrons, indent/outdent) while
non-directional ones (clock, check) are not; bidi helpers for mixed content (e.g. Arabic title with Latin
times); lint/grep check for non-directional insets in features.
**Acceptance criteria:** all shell screens pass an RTL golden review.
**Tests:** RTL goldens; grep-based CI check.

### T1.3.15 — Accessibility baseline
**Priority:** P0 · **Size:** S · **Depends on:** T1.3.10
**Description:** Semantics helpers (labels/hints/values for custom widgets), 48 dp minimum targets, focus
order, text scale support up to 2.0 without clipping, `MediaQuery.disableAnimations` honoured via a
`reduceMotion` provider, live-region announcements helper for async results ("Task completed").
**Acceptance criteria:** Flutter accessibility guidelines pass on the component gallery.
**Tests:** `meetsGuideline` checks (tap targets, labels, contrast) in widget tests.

### T1.3.16 — Feature flags & dev debug menu (incl. time travel)
**Priority:** P1 · **Size:** M · **Depends on:** T1.3.03, T1.3.05
**Description:** `FeatureFlags` (compile-time defaults from env + runtime overrides in dev); debug menu
(dev flavor only, hidden gesture): flags, **time travel** (offset the injected `Clock` to test recurrences,
day rollover, notifications), zone override, log viewer, DB inspector entry, "reset local data", sync
diagnostics link, component gallery.
**Acceptance criteria:** debug menu is absent from prod builds (tree-shaken); time travel affects all
clock consumers consistently.
**Tests:** unit test that prod flavor exposes no debug routes.

### T1.3.17 — Haptics & sound service
**Priority:** P1 · **Size:** S · **Depends on:** T1.3.02
**Description:** Central `Haptics` service (`selectionClick` for snaps, `mediumImpact` for lifts,
`success` for completions) respecting a user setting and OS settings; short UI sounds (check-in
completion) off by default.
**Tests:** unit tests with a fake platform channel.

### T1.3.18 — Motion & page transitions
**Priority:** P1 · **Size:** S · **Depends on:** T1.3.06
**Description:** Consistent transitions (shared-axis for tab-internal navigation, fade-through between
tabs, container transform for opening items), all disabled/replaced by fades when reduce motion is on.
**Tests:** widget test verifying reduced-motion path.

### T1.3.19 — Tablet/landscape layout foundations
**Priority:** P1 · **Size:** S · **Depends on:** T1.3.12
**Description:** `AdaptiveLayout` helpers (window size classes, two-pane scaffold with list/detail),
keyboard shortcuts infrastructure (`Shortcuts`/`Actions`) for tablets with keyboards; full multi-pane
screens are [9.3] T9.3.01.
**Tests:** widget tests at expanded width.
