# Section 8.1 — Today, Search & Quick Add

> Milestones: M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 2.3, 3.1–3.5, 4.1–4.3, 5.1–5.3, 7.3
> Architecture: §1 (navigation), §6.3, §6.4, §6.5 (FTS), §6.13

## Goal

Give the user one screen that answers *"what matters right now?"* across all sections, a global search
that finds anything (including deeply nested checklist items), and a universal quick-add that creates
any item type in two taps.

## Scope

**In:** Today home screen and its blocks, day progress header, overdue/roll-over, global search UI on
top of the FTS index (built in [2.3]), universal quick-add sheet, natural-language quick add (P2), command
palette (P2).
**Out:** The FTS index itself ([2.3]), home-screen widgets (8.2), stats dashboards (6.7).

## Progress

- [x] T8.1.01 — Today overview data provider
- [x] T8.1.02 — Today screen layout & block framework
- [x] T8.1.03 — Now / Next card
- [x] T8.1.04 — Today agenda block (tasks)
- [x] T8.1.05 — Overdue block & roll-over
- [x] T8.1.06 — Habits-due block with inline check-in
- [x] T8.1.07 — Quit counters block
- [x] T8.1.08 — Checklists block (pinned, due, follow-ups)
- [x] T8.1.09 — Pull-to-refresh & sync indicator
- [x] T8.1.10 — Universal quick-add sheet
- [x] T8.1.11 — Day progress header
- [x] T8.1.12 — Today customization (reorder/hide blocks)
- [x] T8.1.13 — Empty states & contextual hints
- [x] T8.1.14 — Global search screen
- [x] T8.1.15 — Search filters, recents & result actions
- [x] T8.1.16 — Search query syntax
- [x] T8.1.17 — Natural-language quick add
- [x] T8.1.18 — Command palette

## Tasks

### T8.1.01 — Today overview data provider
**Priority:** P0 · **Size:** M · **Depends on:** [3.2], [4.3], [5.2], [5.3]
**Description:** A single application-layer provider that assembles everything Today needs for the
current local day, reactive to DB changes and to the day rolling over at midnight (or `dayStartsAt`).
**Implementation notes:**
- `features/today/application/today_overview_provider.dart` → `Stream<TodayOverview>` combining:
  today's task occurrences (expanded via recurrence engine for today only, merged with
  `task_occurrences` records), overdue one-off tasks, habits due today with `PeriodResult`, active quit
  trackers, pinned checklists with progress, checklist items due today / follow-ups due, unread inbox count.
- Use a `DayBoundaryTicker` (core/time) that emits at local midnight / `dayStartsAt` and on time-zone change.
- Keep expansion bounded (today only) → budget < 50 ms on 200 tasks.
**Acceptance criteria:**
- Editing any task/habit/item updates the overview without manual refresh.
- At local midnight the overview switches to the new day automatically.
- Changing the device time zone recomputes "today" correctly for floating vs fixed-zone tasks.
**Tests:** unit tests with fake clock across midnight and a zone change; performance test with 200 tasks.
**Notes:** `todayOverviewProvider` (sync `Provider<TodayOverview>`; each section loads/fails independently, null = loading) over the planner contract (`plannerItemsProvider` for the logical day + next day, so Now/Next can look ahead), habit snapshots (`habitSnapshotProvider`), checklist board/card summaries, a read-only due/follow-up query in `today/data/` (the checklists feature has no "due today" API) and the inbox. `DayBoundaryTicker` lives in `features/today/application/` (not `core/time`, to stay in owned paths); it honours `dayStartMinutes`, re-checks on resume and at least hourly. 200 tasks resolve in ≈ 48 ms in a debug test run.

### T8.1.02 — Today screen layout & block framework
**Priority:** P0 · **Size:** M · **Depends on:** T8.1.01, [1.3]
**Description:** Scrollable Today screen built from independent **blocks** (Now/Next, Agenda, Overdue,
Habits, Quit, Checklists, Inbox highlights). Each block handles its own loading/empty state.
**Implementation notes:**
- `TodayBlock` interface: `id`, `titleKey`, `build(context, overview)`, `isEmpty(overview)`.
- `CustomScrollView` with slivers; blocks hidden when empty (configurable later in T8.1.12).
- Tablet/landscape: two-column masonry of blocks.
**Acceptance criteria:**
- Screen renders with any subset of data; no layout errors at text scale 2.0 and in RTL.
- First meaningful paint < 300 ms after tab switch with realistic data.
**Tests:** widget tests for empty/full states; goldens light/dark, LTR/RTL.
**Notes:** `TodayScreen` + `TodayBlock` (id, title, isLoading/isEmpty, build, empty) in `today/presentation/`; blocks follow `TodayLayout` order, each with loading / error / empty state, two columns on non-compact windows, wrapped in `SyncRefresh`. Goldens light/dark × LTR/RTL + empty; Arabic at text scale 2 has no layout errors. First-paint timing not measured on a device.

### T8.1.03 — Now / Next card
**Priority:** P0 · **Size:** S · **Depends on:** T8.1.02
**Description:** Top card showing the task in progress now (with remaining time progress bar) and the
next upcoming task (with countdown). Quick actions: Start/Stop timer, Done, Skip, Open.
**Implementation notes:** reuse occurrence actions from [3.2]; countdown ticks every 30 s while visible
(pause ticker when off-screen / app backgrounded).
**Acceptance criteria:** correct item at boundaries (task ending exactly now; overlapping tasks → show the
one that started last, with "+1 overlapping"); actions write occurrence records and update instantly.
**Tests:** unit tests for now/next selection incl. overlaps and all-day tasks; widget test for actions.
**Notes:** `NowNextCard` over `selectNowNext` (agenda + tomorrow's items): remaining-time bar, "+n overlapping", countdown; actions from `primaryActionsFor` through the planner's `runPrimaryAction` (start/pause/resume/stop timer, done, skip) + Open. Ticks every 30 s while mounted (no ticker under a fake clock).

### T8.1.04 — Today agenda block (tasks)
**Priority:** P0 · **Size:** M · **Depends on:** T8.1.02, [3.2]
**Description:** Compact chronological list of today's task occurrences with time, title, category
color, status, and inline Done/Skip. Tap opens the occurrence sheet; long-press offers reschedule.
**Implementation notes:** event-type (`tracking_mode = event`) items shown without checkbox; completed
items collapsed into a "Done (n)" group toggle; all-day items first.
**Acceptance criteria:** swipe right = done, swipe left = skip (configurable, undo snackbar); status
changes reflected in Planner views immediately.
**Tests:** widget tests (swipe actions, undo); golden.
**Notes:** `AgendaList`: all-day first, checkbox (events show an icon), configurable swipe start/end (done / skip / none) with the planner's undo snack, collapsed "Done (n)" group, tap = occurrence sheet, long press = reschedule sheet.

### T8.1.05 — Overdue block & roll-over
**Priority:** P0 · **Size:** S · **Depends on:** T8.1.04, [3.2]
**Description:** Lists unresolved past occurrences of `check` tasks (within a configurable look-back,
default 7 days) with bulk actions: *Roll over to today*, *Mark done*, *Skip*, *Reschedule…*.
**Acceptance criteria:** roll-over creates occurrence overrides (recurring) or moves the task (one-off)
and logs `rescheduled` activity events (feeds punctuality/postpone stats).
**Tests:** unit tests for the look-back query; widget test for bulk roll-over + undo.
**Notes:** `OverdueList` with per-row reschedule and bulk *Move to today* (same wall time today, via `PlannerService.reschedule`, which logs `rescheduled`), *Mark all done*, *Skip all*; the bulk command is one undo step (`UndoStack.squash`).

### T8.1.06 — Habits-due block with inline check-in
**Priority:** P0 · **Size:** M · **Depends on:** T8.1.02, [5.2]
**Description:** Habits due today with one-tap check-in (yes/no), +/− stepper for counts, quick timer for
durations, long-press for *not done / skip / excuse / note*. Shows progress ring and current streak.
**Acceptance criteria:** state identical to Habits tab after any action; "All habits done 🎉" state;
intraday-slot habits show the current slot.
**Tests:** widget tests for each goal type; unit test for due-today selection with quota schedules.
**Notes:** `HabitRow`: progress ring, streak, one-tap check-in, +step for counts (value sheet for durations/measurements — no separate timer here), next-slot hint, long press for not done / skip / excuse (with reason) / note & mood via `CheckInActions`; "All habits done 🎉".

### T8.1.07 — Quit counters block
**Priority:** P0 · **Size:** S · **Depends on:** T8.1.02, [5.3]
**Description:** Live clean-time counters (d h m s) per active quit tracker, money saved, next milestone;
buttons *Log craving* and *Log relapse*.
**Implementation notes:** one shared 1 Hz ticker only while visible; counters computed from
`quit_started_at` / last relapse (no DB writes per tick).
**Acceptance criteria:** counter keeps correct time across app background/foreground and DST changes.
**Tests:** unit test for elapsed formatting incl. DST; widget test with fake ticker.
**Notes:** `QuitRow` reuses `LiveCounter` (shared 1 Hz ticker, instants only), money saved, next day milestone, *Log craving* (quick) and *Log relapse* / *Log use* (reduce mode).

### T8.1.08 — Checklists block (pinned, due, follow-ups)
**Priority:** P0 · **Size:** S · **Depends on:** T8.1.02, [4.3]
**Description:** Pinned checklists with progress bars; items due today; waiting/blocked items whose
`follow_up_at` is today or past ("Check back on…").
**Acceptance criteria:** tapping an item opens its checklist focused on that item (deep link with `item=`);
completing from Today updates roll-ups.
**Tests:** widget tests; unit tests for due/follow-up queries.
**Notes:** `ChecklistsSummary`: pinned lists with progress, due items with a complete checkbox (`ChecklistService.changeStatus`, undo), waiting/blocked follow-ups; taps open the list focused on the item.

### T8.1.09 — Pull-to-refresh & sync indicator
**Priority:** P0 · **Size:** S · **Depends on:** [1.4]
**Description:** Pull-to-refresh on Today (and other tab roots) triggers push+pull; a subtle indicator
shows offline / syncing / error with a tap-through to Settings › Sync.
**Acceptance criteria:** refresh completes or fails gracefully offline (message, no spinner lock).
**Tests:** widget test with a fake sync service in each state.
**Notes:** `SyncIndicator` (in `AppBarActions`, so every tab root shows it: hidden when synced/local-only, spinner or initial-sync progress, cloud-off, warning with tap-through to Settings › Sync) and `SyncRefresh`/`refreshSync` (push+pull, 30 s cap, offline/error/local-only snackbars) in `features/settings/presentation/widgets/sync_indicator.dart`. TODO(integration): each tab root's owner wraps its main scrollable with `SyncRefresh` (Today is still a placeholder).

### T8.1.10 — Universal quick-add sheet
**Priority:** P0 · **Size:** M · **Depends on:** [3.1], [4.1], [5.1]
**Description:** The contextual **+** (and long-press on it) opens a sheet to create: Task, Checklist,
Checklist item (pick list), Habit, Quit tracker, Habit log / craving. Minimal fields with smart defaults
from context (selected date/slot in Planner, current checklist, etc.), "More options" opens the full editor.
**Acceptance criteria:** creating a task from a selected week-table slot pre-fills date/time/duration;
keyboard stays up for rapid entry ("Add & new"); works offline.
**Tests:** widget tests per type; integration test "create task from slot".
**Notes:** `showQuickAdd` / `QuickAddSheet` (`app/quick_add_sheet.dart`), opened by long press on the shell **+** (tap still opens the task editor): Task (date/time/duration chips, all-day, next half-hour default, `QuickAddContext` pre-fill), List, List item (pick list; new `ChecklistService.appendItems`), Habit (daily yes/no), Quit tracker (opens its editor), Check-in / craving; *Add & new* keeps the keyboard up; *More options* opens the full editor. The week table keeps its own slot quick-create.

### T8.1.11 — Day progress header
**Priority:** P1 · **Size:** S · **Depends on:** T8.1.02, [6.1]
**Description:** Header with date, greeting, and today's progress: tasks done/planned, habits done/due,
checklist items completed today, focus time; tapping opens Insights › Today.
**Acceptance criteria:** numbers match the corresponding stats metrics exactly (shared metric code).
**Tests:** unit test that header values equal metric registry outputs for a fixture day.
**Notes:** `TodayHeader` + `TodayProgress` (domain): greeting, date, tasks done/planned (checkbox occurrences, events excluded — the stats counting rule), habits resolved/due, checklist items completed today (new `TodayChecklistQueries.watchCompletedBetween`), focus = tracked minutes; tap opens Insights. Shares the rules, not the metric registry code.

### T8.1.12 — Today customization (reorder/hide blocks)
**Priority:** P1 · **Size:** M · **Depends on:** T8.1.02, T8.3.01
**Description:** Edit mode to reorder, hide and configure blocks (e.g. agenda: show completed; overdue
look-back days). Stored in `user_settings` (`today` key inside `appearance` or its own namespace).
**Acceptance criteria:** layout syncs across devices; reset-to-default available.
**Tests:** widget test for reorder; unit test for settings (de)serialization.
**Notes:** Customize sheet: reorder (drag handles), show/hide, show-when-empty, header, show completed, swipe actions, overdue look-back and recurring toggle, reset (keeps dismissed hints); saved to the synced `today` namespace via `todayLayoutWriterProvider`.

### T8.1.13 — Empty states & contextual hints
**Priority:** P1 · **Size:** S · **Depends on:** T8.1.02
**Description:** Friendly empty states per block with a primary action (e.g. "Plan your first task"),
dismissible hints for new features. Illustrations are vector, theme-aware, RTL-safe.
**Tests:** goldens for empty states.
**Notes:** Every block has an empty state with a primary action (plan a task, add a habit, open lists, start a quit tracker); dismissible swipe hint stored in `TodayLayout.dismissedHints`. Material icons rather than custom illustrations.

### T8.1.14 — Global search screen
**Priority:** P1 · **Size:** M · **Depends on:** [2.3] (FTS index)
**Description:** Search icon in the app bar opens a full-screen search over the FTS index: tasks,
checklists, checklist items (with breadcrumb path of ancestors), habits, notes/logs, inbox entries.
**Implementation notes:** debounce 150 ms; FTS5 `bm25` ranking + recency boost; highlight matches with
`snippet()`; group by type with "see all".
**Acceptance criteria:** results for 20 000 indexed rows in < 100 ms; Arabic and French diacritics
handled (unicode61 remove_diacritics); tapping opens the deep link.
**Tests:** DAO tests on seeded FTS data; widget tests for grouping/highlighting.
**Notes:** inbox entries joined the FTS index (schema v5, `notifications` source + rebuild).
`GlobalSearchQueries` enriches index hits (breadcrumb, link, category, tags, open/closed, day); quit
trackers link to `/quit/:id`. Titles are highlighted in Dart with `Collation` (prefix per word, original
text), bodies with FTS `snippet()`. Groups show 4 rows + *see all* (= kind filter). 20 000 rows: < 100 ms
enriched (test).

### T8.1.15 — Search filters, recents & result actions
**Priority:** P1 · **Size:** S · **Depends on:** T8.1.14
**Description:** Filter chips (type, status, category, tag, date range), recent searches (local only),
inline quick actions on results (complete item, check-in habit).
**Tests:** widget tests for filters and recents persistence.
**Notes:** kind chips narrow the index query; status/category/tag/date filter the enriched rows.
Recents (10, case-insensitive dedupe) live in `local_kv` (`search.recents`), never synced. Inline
actions: complete a checklist item (undo snackbar), check in a build habit.

### T8.1.16 — Search query syntax
**Priority:** P2 · **Size:** S · **Depends on:** T8.1.15
**Description:** Power syntax: `status:waiting tag:work due:<7d cat:health is:recurring "exact phrase"`.
Parser in pure Dart with helpful errors; chips mirror parsed tokens.
**Tests:** parser unit tests (valid/invalid inputs, localization of keywords EN/FR).
**Notes:** `SearchSyntax.parse` → `ParsedQuery` (terms, phrases, tokens with ranges, errors); keys
status/tag/cat/due/is/type with FR synonyms (statut, étiquette, catégorie, échéance, est, dans), accents
optional. Due: today/tomorrow/overdue, `<7d`/`>2w` (`j`/`s` in FR), ISO dates with `<`/`>`. Tokens
render as removable chips over the filter bar; unknown tag/category names match nothing. FTS
`matchExpression` now treats `"…"` as a phrase. Filter-only queries ask for a word (no FTS match).

### T8.1.17 — Natural-language quick add
**Priority:** P2 · **Size:** L · **Depends on:** T8.1.10, [2.1]
**Description:** Parse "Gym tomorrow 7pm for 1h every Mon and Wed #health !high" into a task with time,
duration, recurrence, category and priority; live-highlight recognized tokens; EN + FR first, AR later.
**Implementation notes:** deterministic pure-Dart grammar (no network); maps to recurrence JSON; show
the parsed interpretation before saving. (Optional LLM assist tracked in 9.3.)
**Acceptance criteria:** ≥ 95 % of a 200-phrase fixture parses to the expected structure.
**Tests:** fixture-driven parser tests.
**Notes:** `QuickParser` (planner domain, pure Dart, EN + FR vocabulary in one grammar): dates, times,
ranges, durations, recurrence (daily/weekly lists/every N/nth weekday/day of month/count/until),
`#category`, `!priority` and all-day; `"quoted"` text stays literal. Conservative defaults:
abbreviated weekdays need a connector, `at 1`–`at 6` mean pm, bare `7h` is a time. 241-phrase fixture
(`test/features/planner/fixtures/quick_parse.json`) passes 100 %. Quick add highlights recognized
tokens in the field, previews date / duration / recurrence description / category / priority, and can
be switched off; unknown categories are flagged, not created. `createAt` gained recurrence, category
and priority. AR vocabulary deferred (spec: "AR later").

### T8.1.18 — Command palette
**Priority:** P2 · **Size:** M · **Depends on:** T8.1.14
**Description:** Searchable list of actions ("New task at 9:00", "Go to next week", "Pause notifications 1 h",
"Open Insights › Habits") — reachable from search and a keyboard shortcut on tablets.
**Tests:** unit tests for action matching; widget test for execution of a navigation action.
**Notes:** `CommandMatching` (search domain) scores word starts > keywords > substrings > letters in
order, all words required, accent-insensitive. Palette (`app/command_palette.dart`): create (incl. a
live *New task "…" · date* entry when the query parses as a dated task), go-to (Today, this/next/previous
week, day, Lists, Habits, Insights + scopes, Inbox, Search, Settings › Notifications, Trash, categories,
tags) and actions (pause 1 h / until tomorrow ↔ resume, sync now, undo). Opens from the search app bar,
from a `>` query, and with Ctrl/⌘ + K in the shell.
