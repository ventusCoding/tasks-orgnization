# Section 2.3 — Shared Primitives

> Milestones: M0/M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 1.3, 1.4, 2.1
> Architecture: arch §7.3 (categories, tags, entity_tags, saved_views, activity_events), §9.1 (time),
> §9.2 (ids), §9.4 (ordering), §6.5 (FTS)

## Goal

Build once the small cross-cutting pieces every section needs: categories, tags, priorities, the
color & icon system, the append-only activity log (history + stats + undo/restore grouping), an undo/redo
command stack, app-level time & calendar utilities, saved views, a shared filter model, the global search
index, and entity deep-link builders.

## Scope

**In:** the primitives above with their storage, repositories, reusable widgets and tests.
**Out:** Feature-specific use of them (each section); search UI ([8.1]); stats on activity data ([6.x]).

## Progress

- [x] T2.3.01 — Categories (table, repository, management UI)
- [x] T2.3.02 — Default categories on first run
- [x] T2.3.03 — Priorities model & visual language
- [x] T2.3.04 — Color & icon system for user entities
- [x] T2.3.05 — Activity events (append-only log) & `ActivityLogger`
- [x] T2.3.06 — Undo/redo command stack
- [ ] T2.3.07 — App time & calendar utilities
- [ ] T2.3.08 — Saved views (table + repository)
- [x] T2.3.09 — Shared filter model & filter bar
- [ ] T2.3.10 — Tags (table, entity tags, picker, management)
- [ ] T2.3.11 — Global search index (SQLite FTS5)
- [ ] T2.3.12 — Entity deep-link builders & cross-entity links

## Tasks

### T2.3.01 — Categories (table, repository, management UI)
**Priority:** P0 · **Size:** M · **Depends on:** [1.4], [1.3]
**Description:** `app.categories` (name, color, icon, sort_key, archived_at) with `enable_sync`, Drift
mirror, `CategoriesRepository`, a category picker (search, create inline) and a management screen
(create, rename, recolor, change icon, reorder by drag, archive, delete with reassignment prompt).
**Implementation notes:** name unique per user among non-deleted rows (case-insensitive; enforced in the
repository and by a partial unique index `lower(name)`); archived categories stay on existing items but are
hidden from pickers; deleting asks to reassign or clear on affected items (one transaction + activity events).
**Acceptance criteria:** used by tasks, habits and checklists; reorder syncs; deletion never leaves dangling
`category_id` values.
**Tests:** pgTAP (isolation, unique index); repository tests; widget tests for picker & management.
**Notes:** Name rules in `CategoryNames` (validation codes → EN/FR/AR messages; renames validated too). Delete asks to move the items to another category or remove it from them; `CategoriesRepository.delete` rewrites every referencing task/habit/checklist and logs one `updated` event each plus the category `deleted` event in one operation (one undo). `pickCategory` has search, inline create (`add()` returns the id), `exclude`/`allowNone`. Arabic wording harmonized to "فئة/الفئات" (other features already used it). Tests: `app/test/features/organization/categories_{repository,widgets}_test.dart`; pgTAP `supabase/tests/database/120_organization.test.sql` (unique `lower(name)` index) written but not run locally (no Docker on this machine) — isolation is covered by `030_isolation`.

### T2.3.02 — Default categories on first run
**Priority:** P0 · **Size:** S · **Depends on:** T2.3.01
**Description:** Seed localized defaults once per account (Work, Personal, Health, Study, Home, Social) with
distinct palette colors and icons, using deterministic ids `uuidv5(user_id | 'default-category' | key)` so
two devices seeding offline converge instead of duplicating.
**Acceptance criteria:** first sign-in on two offline devices → after sync exactly 6 categories.
**Tests:** convergence test in the sync suite ([9.1]).
**Notes:** Verified: `ensureProfileAndDefaults` (startup) seeds the 6 localized defaults with deterministic ids `Ids.defaultCategory`; two-device convergence to exactly 6 in `app/test/features/organization/organization_convergence_test.dart` (`@Tags(['sync'])`).

### T2.3.03 — Priorities model & visual language
**Priority:** P0 · **Size:** S · **Depends on:** [1.3]
**Description:** Priority 0–4 (None, Low, Medium, High, Urgent) value object with localized labels, icon
(flag variants), color tokens, sort order, and a compact picker; used by tasks and checklist items.
**Acceptance criteria:** color is never the only signal (icon + label); accessible names.
**Tests:** widget test; golden of all levels light/dark.
**Notes:** Value object `Priority` (`features/organization/domain/priority.dart`: 0–4, urgent-first sort) + `PriorityStyle` (localized labels, flag icons, colors; `foreground()` keeps labels/flags ≥ 4.5:1 in both themes), `PriorityBadge` (one accessible name) and `PrioritySelector`. The repo has no golden files (platform-dependent rendering): levels are verified by widget tests in EN/FR/AR, light/dark readability and contrast tests (`app/test/design_system/priority_and_patterns_test.dart`, `color_contrast_test.dart`).

### T2.3.04 — Color & icon system for user entities
**Priority:** P0 · **Size:** S · **Depends on:** [1.3] (tokens)
**Description:** The 16-color category palette (ARGB storage), automatic readable foreground color
(contrast ≥ 4.5:1), light/dark variants from one stored color, color-blind-safe pattern option for the time
grid, and an icon catalog (curated Material Symbols subset with search keywords in EN/FR/AR).
**Acceptance criteria:** any palette color yields legible text on tiles in both themes (automated contrast test).
**Tests:** unit test computing contrast for every palette entry × theme.
**Notes:** Palette, light/dark variants and icon catalog existed; added `CategoryColors.readableOn` (automatic readable foreground ≥ 4.5:1) and `design_system/patterns.dart` (16 distinct color-blind-safe textures for the palette, `CategoryPatternPainter`, setting `appearance.categoryPatterns` via `categoryPatternsEnabledProvider`). Contrast test for every palette entry × theme: `app/test/design_system/color_contrast_test.dart`. TODO(integration): planner-views paints `CategoryPatternPainter.forCategory` over grid tiles when the setting is on; the toggle belongs to Settings › Appearance.

### T2.3.05 — Activity events (append-only log) & `ActivityLogger`
**Priority:** P0 · **Size:** M · **Depends on:** [1.4]
**Description:** `app.activity_events` (arch §7.3) with an update-blocking trigger (only `deleted_at` may
change), Drift mirror, and `ActivityLogger` used inside repository transactions. Documented event catalog
per entity type: `created`, `updated` (changed field names), `status_changed` (`from`, `to`, `note`),
`rescheduled` (`fromStart`, `toStart`, `fromDuration`, `toDuration`, `scope`), `moved` (`fromParent`,
`toParent`), `completed`, `reopened`, `skipped` (`reason`), `deleted`, `restored`, `attachment_added`,
`attachment_removed`. Every user command writes one `operation_id` into all its events (grouped undo,
"restore everything deleted together").
**Implementation notes:** keep payloads small (no full rows); index `(user_id, entity_type, entity_id,
occurred_at)`; history timeline widget (reusable) renders localized sentences from events.
**Acceptance criteria:** status history, reschedule history and Trash grouping read only from this table;
update attempts on events are rejected server-side (pgTAP).
**Tests:** pgTAP immutability; unit tests for payload builders; widget test for the timeline.
**Notes:** Table, append-only trigger and pgTAP immutability (`070_domain_constraints`) came with the foundation; `WriteTx.logEvent` adds `opId`/`cause`. Added `shared/activity/`: event catalog + payload contracts (`ActivityEventTypes`, `ActivityPayloads` — small payloads, clipped texts, time-field before/after only), `ActivityLogger` (`tx.activity.statusChanged(...)`, application layer so feature data layers may use it), `ActivityRepository` (per entity incl. children and event-type filters, per operation, delete operations grouped for the Trash) behind `activityRepositoryProvider`/`entityActivityProvider`/`deleteOperationsProvider`, and `ActivityTimeline(entityType:, entityId:)` rendering EN/FR/AR sentences for the whole catalog. Features that already call `tx.logEvent` directly keep compatible payloads. Tests: `app/test/shared/activity/`.

### T2.3.06 — Undo/redo command stack
**Priority:** P0 · **Size:** M · **Depends on:** T2.3.05
**Description:** In-memory, per-session command stack: each user command records forward/inverse row
changes (applied through repositories so outbox + activity events stay correct). Snackbar "Undo" for
destructive or large changes; redo where meaningful (tree editor, time-grid drags).
**Implementation notes:** commands carry their `operation_id`; stack cleared on sign-out; max depth 50;
inverse of a delete = restore (clears `deleted_at` of the same operation's rows).
**Acceptance criteria:** undoing a subtree delete restores all descendants exactly; undoing a drag restores
the original start/duration and logs a compensating `rescheduled` event.
**Tests:** unit tests for command inversion; integration test in the checklist editor.
**Notes:** `UndoStack` (core/undo, max depth 50, redo invalidated by new commands) now clears on sign-out/account switch (`undoStackProvider` listens to `currentUserIdProvider`) and exposes `redoLabel`. Keyboard undo/redo with "Undone: …/Redo" feedback: `GlobalShortcuts` (`shared/shortcuts/`, mounted at the app root; also Ctrl/⌘+F search). Deviation: undo reverts through `SyncWriter.revert`, which tombstones the operation's own activity events (append-only: only `deleted_at` changes) instead of logging a compensating `rescheduled` event — history and punctuality stats then show the net effect, and redo brings the events back; changing that belongs to `SyncWriter.revert` (core/sync). The checklist-editor integration test is the checklists feature's. Tests: `app/test/shared/undo/undo_stack_test.dart`.

### T2.3.07 — App time & calendar utilities
**Priority:** P0 · **Size:** M · **Depends on:** [2.1] (core types)
**Description:** `core/time` built on the recurrence package types: `Clock` + `FakeClock`, current-zone
provider (device zone via `flutter_timezone`, change detection), `dayStartsAt`-aware "logical day"
computation, week helpers bound to the profile's week start, instant ↔ local conversions for fixed/floating
values, and formatting helpers (time 12/24 h, relative "in 5 min / 3 d ago", durations "1 h 20 min",
date ranges) localized EN/FR/AR (with optional Arabic-Indic digits).
**Acceptance criteria:** one source for "today", "this week", "now" across the app; all helpers covered with
DST and zone-change tests.
**Tests:** unit tests incl. DST days, week starts MO/SA/SU, `dayStartsAt = 04:00` edge (03:59 vs 04:00).

### T2.3.08 — Saved views (table + repository)
**Priority:** P0 · **Size:** S · **Depends on:** [1.4]
**Description:** `app.saved_views` (section, name, view_type, config JSON arch §8.3, is_default, sort_key)
with repository, versioned config codec per view type, and "reset to defaults".
**Acceptance criteria:** Planner/Lists/Habits/Insights persist view presets through it; configs sync; a
config from a newer app version with unknown keys is preserved.
**Tests:** codec round-trip; repository tests.

### T2.3.09 — Shared filter model & filter bar
**Priority:** P0 · **Size:** M · **Depends on:** T2.3.01, T2.3.03
**Description:** `EntityFilter` value object (categories, tags, priorities, statuses, text, date range,
has-attachments, recurring/non-recurring) with a pure predicate and SQL builder for Drift queries, plus a
reusable filter bar (chips, active-filter count, clear all) used by planner views, lists board, habits and stats.
**Acceptance criteria:** the same filter produces identical results via predicate and SQL (property test).
**Tests:** property test predicate vs SQL on generated data; widget test for the bar.
**Notes:** `shared/filters/`: `EntityFilter` (domain, JSON = arch §8.3 `filters`), `EntityFilterSql` + `FilterColumns` presets for tasks/checklists/items/habits (data), `FilterBar` (presentation: pinned count badge and "Clear all", scrolling chips, no fixed height). Status labels/icons for hosts: `EntityStatusStyle.filterOptions` (`shared/status/`). Property test predicate ≡ SQL on generated multilingual data (`app/test/shared/filters/`).

### T2.3.10 — Tags (table, entity tags, picker, management)
**Priority:** P1 · **Size:** M · **Depends on:** T2.3.09
**Description:** `app.tags` + `app.entity_tags` (deterministic ids `uuidv5(tag_id|entity_type|entity_id)`),
tag picker with inline create, tag chips on tasks/checklists/items/habits, management (rename, recolor,
merge two tags, delete).
**Acceptance criteria:** tagging the same entity on two offline devices converges to one link; merge
rewrites links in one operation (undoable).
**Tests:** convergence test; repository tests; widget tests.

### T2.3.11 — Global search index (SQLite FTS5)
**Priority:** P1 · **Size:** M · **Depends on:** [1.4]
**Description:** Local-only FTS5 table `search_index(entity_type, entity_id, parent_id, title, body)`
maintained by SQLite triggers on tasks, checklists, checklist items, habits and habit-log notes; tokenizer
`unicode61 remove_diacritics 2`; Arabic normalization (alef/ya/ta-marbuta variants, tatweel removal)
applied to indexed text and queries; rebuild command for migrations.
**Acceptance criteria:** 20 000 rows searchable in < 100 ms; results rank by bm25 + recency; tombstoned rows
removed from the index.
**Tests:** DAO tests with multilingual fixtures (EN/FR accents/AR variants).

### T2.3.12 — Entity deep-link builders & cross-entity links
**Priority:** P1 · **Size:** S · **Depends on:** [1.3] (deep-link parser)
**Description:** Typed builders for every canonical path in arch §6.4 (`Links.task(id, occ)`,
`Links.checklistItem(checklistId, itemId)`, …) used by notifications, widgets, search and share; a
`LinkedEntityChip` widget rendering a link to another entity (e.g. task ↔ checklist) with live title/status.
**Acceptance criteria:** builder output always round-trips through the parser (property test).
**Tests:** property test builder ↔ parser; widget test for the chip.
