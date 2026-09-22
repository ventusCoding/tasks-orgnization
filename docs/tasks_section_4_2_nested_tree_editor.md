# Section 4.2 — Nested Tree Editor

> Milestones: M1 (P0) · M2 (P1) · Depends on: 1.3, 2.3, 4.1
> Architecture: §6.10 (checklist tree engine), §9.4 (fractional ordering), §6.14 (RTL, accessibility),
> §6.3 (state management)

## Goal

An outliner-grade editor for **infinitely nested** checklist items. Every row is text. Any row can
get sub-rows, and those sub-rows can have sub-rows, without limit. Users must be able to create rows
very fast, restructure with touch or keyboard, and keep deep trees usable through collapse and
focus/zoom. Undo must cover every change, and huge lists must stay smooth.

## Scope

**In:** `ChecklistTree` model; pure structural and subtree operations; the visible flattened list;
local UI state; the checklist screen scaffold with Edit/Preview modes; the item row; inline editing
and keyboard flow; touch gestures; drag & drop reorder/reparent; collapse/expand; focus mode with
breadcrumbs; undo/redo; the item details sheet; multi-select & bulk actions (P1); copy/paste of
subtrees (P1); accessibility (P1); performance hardening (P1).
**Out:** status semantics, preview-mode marking and roll-ups ([4.3]); the attachments UI ([4.4]);
alternative views, templates, import/export ([4.5]).

> Package note: `flutter_fancy_tree_view` is discontinued — do not use it. The tree is rendered as a
> **flattened DFS list** in a lazy `SliverList` with our own drag logic. `two_dimensional_scrollables`
> `TreeView` was considered, but depth-by-horizontal-offset dragging is simpler on a flat list.

## Progress

- [ ] T4.2.01 — ChecklistTree domain model
- [ ] T4.2.02 — Structural operations (pure)
- [ ] T4.2.03 — Subtree operations: delete & duplicate (pure)
- [ ] T4.2.04 — Promote to checklist & sort children
- [ ] T4.2.05 — Visible list builder (collapse, focus, filters)
- [ ] T4.2.06 — Local UI state (collapse, mode, focus, scroll)
- [ ] T4.2.07 — Checklist screen scaffold (Edit / Preview)
- [ ] T4.2.08 — Item row widget
- [ ] T4.2.09 — Inline editing & keyboard flow
- [ ] T4.2.10 — Touch structure gestures & swipe actions
- [ ] T4.2.11 — Drag & drop reorder / reparent
- [ ] T4.2.12 — Collapse & expand (single, all, to level N)
- [ ] T4.2.13 — Focus (zoom) mode with breadcrumbs
- [ ] T4.2.14 — Undo / redo for tree edits
- [ ] T4.2.15 — Item details sheet
- [ ] T4.2.16 — Multi-select & bulk actions
- [ ] T4.2.17 — Copy, cut & paste subtrees
- [ ] T4.2.18 — Tree accessibility
- [ ] T4.2.19 — Performance hardening for huge lists

## Tasks

### T4.2.01 — ChecklistTree domain model
**Priority:** P0 · **Size:** M · **Depends on:** [4.1]
**Description:** Pure-Dart immutable tree built from the flat item rows of one checklist. Everything
else in the section builds on it.
**Implementation notes:**
- `ChecklistTree.build(List<ChecklistItem>)` produces:
  - a children map keyed by parent (`null` = root), sorted by `(sort_key, id)`. The id tie-break
    makes two devices that generated the same fractional key concurrently still order siblings
    identically everywhere;
  - depth and DFS index per node;
  - ancestors (O(depth)), descendants (O(subtree)), leaf flag.
- Defensive handling (local pending moves can mix with pulled rows):
  - **Orphans:** a live child whose parent is missing or tombstoned is surfaced as a root item flagged
    `orphan`. The UI shows a "Recovered" marker and offers *Move to…*.
  - **Cycles:** detected with a visited-set DFS and broken at the member with the smallest id, which
    is treated as root and flagged. A warning is logged; the builder never throws.
- Memoized by `(checklistId, max(updated_at), rowCount)`.
**Acceptance criteria:** building 5 000 items / depth 50 takes < 10 ms (release, mid-range device);
identical output on any device for the same rows.
**Tests:** unit tests covering orphans, cycles, duplicate keys and deep chains; property tests on random forests.

### T4.2.02 — Structural operations (pure)
**Priority:** P0 · **Size:** L · **Depends on:** T4.2.01, [1.3] (fractional index util)
**Description:** All structure edits are pure functions `(tree, args) → TreeChange`. A `TreeChange`
holds the row inserts/updates, the activity events, the inverse change (for undo) and a focus hint
(which row and cursor position gets focus next).
**Implementation notes:**
- **Insert:** `insertAfter`, `insertBefore`, `insertFirstChild`.
- **Enter:** if the row is expanded and has children, the new row becomes its **first child**;
  otherwise it becomes the **next sibling**. Text after the cursor moves into the new row.
- **Merge** (Backspace at the start of a non-empty row):
  - the text is appended to the previous visible row;
  - the merged row's children become the target's last children;
  - its attachments are re-owned by the target.
  - Not allowed across the focus root.
- **Indent:** the row becomes the last child of its previous sibling. With no previous sibling it is
  a no-op with a "denied" haptic. Contiguous selected siblings indent together.
- **Outdent:** the row becomes the next sibling of its parent, and its following siblings stay under
  the old parent (Workflowy/Dynalist semantics). A no-op at root level or directly under the focus root.
- **Move:** `moveUp`/`moveDown` among siblings. `moveTo(item, newParent, index)` is cycle-safe:
  it rejects a `newParent` inside the item's own subtree.
- New `sort_key`s are generated between neighbours; other siblings are never renumbered.
**Acceptance criteria:** every operation is exactly reversible through its inverse; after 10 000 random
operations the invariants hold (no cycles, every live item reachable, strict sibling order).
**Tests:** unit tests per operation; property tests with random op sequences.

### T4.2.03 — Subtree operations: delete & duplicate (pure)
**Priority:** P0 · **Size:** M · **Depends on:** T4.2.02
**Description:** Operations that touch whole subtrees.
**Implementation notes:**
- **`deleteSubtree`:** tombstones the item, all its descendants, their attachment rows and
  `entity_tags` under one `opId`, so Trash ([8.3]) can restore "deleted together".
- **`duplicateSubtree`:**
  - copies get new UUIDv7 ids with the same relative order, inserted right after the original;
  - option: reset statuses to `todo`;
  - attachment **rows** are copied and point at the same storage objects (arch §6.7); tags are copied.
- `bulkStatusChange` helper used by [4.3] (returns one `TreeChange`).
**Acceptance criteria:** duplicating 1 000 rows takes < 100 ms; all copies have fresh ids.
**Tests:** unit tests (counts, order, fresh ids, attachments copied by reference, undo).

### T4.2.04 — Promote to checklist & sort children
**Priority:** P1 · **Size:** M · **Depends on:** T4.2.03, [4.1]
**Description:** Two restructuring helpers.
**Implementation notes:**
- **`promote(item)`** runs as one op group:
  - creates a new checklist titled with the item's text, inheriting color and category;
  - the item's children become root items there, with `checklist_id` updated for the whole subtree;
  - the item's attachments become checklist-level attachments;
  - the original row is tombstoned, or kept as a plain row if the user chooses.
- **`sortChildren(parent | root, by, direction)`** sorts by alphabetical (locale-aware collation),
  status, due, priority or recently changed. It rewrites only that sibling group's `sort_key`s,
  evenly spaced.
**Tests:** unit tests; collation tests (French accents, Arabic).

### T4.2.05 — Visible list builder (collapse, focus, filters)
**Priority:** P0 · **Size:** M · **Depends on:** T4.2.01
**Description:** Turns the tree plus UI state into the rows the list actually renders.
**Implementation notes:**
- Output: `List<VisibleRow>`. Each row has the item, its depth relative to the focus root,
  `hasChildren`, `collapsed`, a roll-up summary ([4.3]), `isAncestorContext` and `isOrphan`.
- **Inputs:**
  - focus root (default: checklist root);
  - collapsed set (local);
  - filters: text, status set, hide completed, has attachments, due soon;
  - `sortCompletedToBottom` (view-level, per sibling group; stored order is untouched).
- **Filtered views** show matches plus their ancestors as dimmed context rows, temporarily expanded
  (this expansion is not persisted).
- O(n) rebuild, memoized on (tree version, UI-state version).
**Acceptance criteria:** 5 000 items build in < 8 ms; each filter keystroke produces results in < 16 ms.
**Tests:** unit tests for each filter × focus × collapse combination.

### T4.2.06 — Local UI state (collapse, mode, focus, scroll)
**Priority:** P0 · **Size:** S · **Depends on:** [4.1] (`ui_node_state`, `ui_checklist_state`)
**Description:** Per-device view state.
**Implementation notes:**
- Collapsed flags live in `ui_node_state`. Rows are expanded by default. A child added under a
  collapsed parent stays hidden and the parent shows a "+1" hint.
- `ui_checklist_state` stores mode (edit/preview), focus item, view type, scroll offset and last opened.
- None of this syncs, by design: collapsing on the phone doesn't change the tablet.
**Tests:** DAO tests; restore-on-reopen widget test.

### T4.2.07 — Checklist screen scaffold (Edit / Preview)
**Priority:** P0 · **Size:** M · **Depends on:** T4.2.05, T4.2.06, [1.3]
**Description:** The screen hosting one checklist.
**Implementation notes:**
- Route `/lists/:id?item=&focus=&mode=` ([4.1] T4.1.06).
- **App bar:**
  - title (editable in edit mode);
  - **Edit ⇄ Preview** toggle. The default comes from settings `defaultOpenMode`; new lists open in Edit;
  - overflow menu: collapse controls, sort & filter ([4.5]), list settings ([4.1]), share/export ([4.5]),
    duplicate/move ([4.1]), Insights ([6.4]), delete.
- **Header:** body note (collapsible), progress header ([4.3]), labels (P1), linked-task chip ([4.5]).
- **Body:** lazy `SliverList` of `VisibleRow`s with an "Add item" row at the end. Keyboard-aware
  scrolling keeps the active row visible above the keyboard toolbar.
**Acceptance criteria:** a 5 000-item list shows its first frame in < 300 ms; reopening restores the
scroll position and focus root.
**Tests:** widget tests; goldens (edit and preview).

### T4.2.08 — Item row widget
**Priority:** P0 · **Size:** M · **Depends on:** T4.2.07
**Description:** One row, in edit and preview variants.
**Implementation notes:**
- **Indentation:** hairline guides per level, mirrored in RTL. Visual indentation caps at 8 levels;
  deeper rows keep the capped indent and show a depth badge (e.g. "L12").
- **Leading:**
  - collapse chevron for parents (48 dp target);
  - status control: checkbox for todo/completed; icons for ongoing/waiting/blocked/cancelled ([4.3]);
  - a bullet when `hideCheckboxes` is on.
- **Text:** multi-line auto-growing `TextField` in edit mode. In preview mode, read-only rich text with tappable links.
- **Trailing / below the text:**
  - status pill with age, e.g. "Waiting · 4 d" ([4.3]);
  - child progress "3/7" + status-split micro bar when collapsed;
  - attachment strip or count ([4.4]);
  - due and follow-up chips ([4.3], P1);
  - bell icon when the item has its own reminder rules.
- **Completed** rows: strikethrough + reduced opacity. **Cancelled** rows: strikethrough + muted + pill.
**Acceptance criteria:** minimum row height 48 dp; no overflow at text scale 2.0; row rebuilds only
when its own data changes.
**Tests:** goldens: every status × edit/preview × LTR/RTL × depth 0/3/12.

### T4.2.09 — Inline editing & keyboard flow
**Priority:** P0 · **Size:** L · **Depends on:** T4.2.02, T4.2.08
**Description:** Fast, outliner-style text entry.
**Implementation notes:**
- **Keys:**
  - **Enter:** new row per T4.2.02 (split at the cursor).
  - **Line break inside a row:** Shift+Enter, or the toolbar "line break" button.
  - **Backspace at the start:** an empty row is deleted and focus moves to the end of the previous
    row; a non-empty row is merged into the previous one.
  - **↑/↓** on the first/last line of a row moves focus to the neighbouring row.
- **Soft-keyboard toolbar:** indent, outdent, move up, move down, status menu ([4.3]), attach ([4.4]),
  due date ([4.3]), details sheet, hide keyboard.
- **Hardware shortcuts:**
  - Tab / Shift+Tab: indent / outdent;
  - Alt/Option+↑/↓: move;
  - Ctrl/Cmd+Enter: toggle complete;
  - Ctrl/Cmd+.: collapse/expand;
  - Ctrl/Cmd+Z / Shift+Ctrl/Cmd+Z: undo/redo.
- **Performance:**
  - text controllers exist only for visible rows;
  - drafts are held in memory and written to Drift with a 400 ms debounce, plus on blur and app pause;
  - one `updated` activity event per editing session;
  - IME composition (Arabic, accented French) is never interrupted by rebuilds.
- Pasting multi-line text opens the import dialog ([4.5]).
**Acceptance criteria:** typing at 60 wpm in a 5 000-item list stays jank-free; killing the app right
after blur loses no characters.
**Tests:** widget tests driving key events and focus moves; IME composition test where the test framework supports it.

### T4.2.10 — Touch structure gestures & swipe actions
**Priority:** P0 · **Size:** M · **Depends on:** T4.2.02, T4.2.08
**Description:** Restructure and mark items with one finger. Swipes mean different things per mode.
**Implementation notes:**
- **Edit mode** (Apple Notes style): swipe right = indent, swipe left = outdent. The depth change is
  animated and gives haptic feedback. The threshold is 56 dp. Directions mirror in RTL (swiping
  toward the reading direction indents).
- **Preview mode** (Workflowy style): swipe right = complete, swipe left = action menu (status,
  details, focus, move, delete).
- Both mappings are configurable in Settings › Lists.
- **Data model:** `user_settings.checklists.swipeActions`
  (`{ "edit": {"right": "indent", "left": "outdent"}, "preview": {"right": "complete", "left": "menu"} }`)
  (arch §8.5).
**Tests:** widget tests for both modes in LTR and RTL; settings override test.

### T4.2.11 — Drag & drop reorder / reparent
**Priority:** P0 · **Size:** L · **Depends on:** T4.2.02, T4.2.07
**Description:** Drag an item together with its subtree to any position and depth.
**Implementation notes:**
- **Lift:** long-press the handle (edit mode) or the row (preview mode). The subtree collapses while
  dragging and a count badge shows how many items are carried.
- **Target:** the vertical position picks the gap; the horizontal offset picks the depth, between the
  allowed min (depth of the next row) and max (depth of the row above + 1). A drop-indicator line is
  drawn at the target depth.
- **During the drag:**
  - hovering a collapsed parent for 600 ms auto-expands it;
  - auto-scroll near the edges, speed ∝ proximity;
  - dropping into the item's own subtree is impossible;
  - haptic tick on each depth change.
- The drop commits one undoable move ([2.3] command stack).
- P1: dropping onto a breadcrumb (T4.2.13) moves the item under that ancestor.
- Drop-target resolution is a pure function `(visibleRows, pointer, rowHeights) → (parent, index, depth)`.
**Acceptance criteria:** dragging through 500 rows with auto-scroll stays at 60 fps; parent and order
are correct after drops in both LTR and RTL.
**Tests:** unit tests for drop-target resolution; widget tests with gesture simulation.

### T4.2.12 — Collapse & expand (single, all, to level N)
**Priority:** P0 · **Size:** S · **Depends on:** T4.2.06
**Description:** Keep big trees scannable.
**Implementation notes:**
- Tap the chevron to toggle one row. Long-press the chevron to collapse/expand the whole subtree.
- Overflow menu: *Expand all*, *Collapse all*, *Expand to level 1–9* (Checkvist-style).
- Collapsed parents show x/y progress and the status bar ([4.3]). State is local per device.
**Tests:** unit tests (visible list after "expand to level N"); widget test.

### T4.2.13 — Focus (zoom) mode with breadcrumbs
**Priority:** P0 · **Size:** M · **Depends on:** T4.2.05, T4.2.07
**Description:** Makes infinite nesting practical: any item can become the root of the view and be
edited at full width.
**Implementation notes:**
- Entry: tap the bullet (edit mode), or *Focus* in the row menu (any mode).
- The focused item shows as a large header with its text and note.
- A breadcrumb bar (*Checklist › A › B › …*) scrolls horizontally with a middle ellipsis; tapping
  a crumb zooms out to that level. The back gesture zooms out one level.
- Deep link `?item=<id>&focus=1`. The focus root is remembered per checklist (local).
- Search results ([4.1] T4.1.13) and smart views ([4.5]) open items in focus mode.
**Acceptance criteria:** focusing a depth-30 item shows its subtree with normal indentation, and all
editing works there.
**Tests:** widget tests; deep-link parser tests.

### T4.2.14 — Undo / redo for tree edits
**Priority:** P0 · **Size:** M · **Depends on:** T4.2.02, T4.2.03, [2.3] (command stack)
**Description:** No edit in the tree is ever irreversible within the session.
**Implementation notes:**
- Every `TreeChange` pushes a command holding its inverse. Text edits are grouped per editing session.
- Edit mode has undo/redo buttons in the toolbar. Destructive operations (delete, move, bulk, list
  commands) also show an undo snackbar.
- The redo stack clears on any new edit. Stacks are per checklist and cleared on leaving the screen;
  the last destructive snackbar survives navigation for its display time.
**Acceptance criteria:** undoing 50 random steps returns the tree row-for-row to its original state.
**Tests:** property test: random ops, then undo all → equals original.

### T4.2.15 — Item details sheet
**Priority:** P0 · **Size:** M · **Depends on:** T4.2.08
**Description:** Full editor for one item, opened from the row menu, the toolbar or a long-press in preview.
**Implementation notes:**
- **Fields:**
  - text;
  - note (long description; Markdown-lite in P1 via [4.1] T4.1.11);
  - status + reason + follow-up ([4.3]);
  - due date/time with zone mode ([4.3], P1);
  - priority; labels (P1, [2.3]);
  - attachments ([4.4]);
  - status history timeline ([4.3]);
  - metadata: created / edited / completed times.
- **Actions:** Focus, Duplicate, Move to…, Promote to checklist (P1), Delete.
- **Reminders** section: placeholder listing rules and "Add reminder"; wired to the rule editor in
  [7.1], catalog in [7.5].
- **Insights** link to item stats ([6.4]).
- The status, attachment and due sections become active as [4.3]/[4.4] land.
**Tests:** widget tests; save/cancel behaviour with undo.

### T4.2.16 — Multi-select & bulk actions
**Priority:** P1 · **Size:** M · **Depends on:** T4.2.11, T4.2.14
**Description:** Operate on many rows at once.
**Implementation notes:**
- Long-press enters selection mode with checkboxes and drag handles. Tap to toggle; drag along the
  handles to select a range; *Select subtree*.
- Bulk actions: set status ([4.3]), indent/outdent, move to (parent or checklist), duplicate, delete,
  copy as text, add label (P1).
- Each bulk action is one op group and one undo step.
**Tests:** widget tests; unit tests that bulk ops produce one op group.

### T4.2.17 — Copy, cut & paste subtrees
**Priority:** P1 · **Size:** S · **Depends on:** T4.2.03
**Description:** An internal clipboard for subtrees, plus the system clipboard as indented text / Markdown.
**Implementation notes:**
- The internal clipboard keeps structure, optionally statuses, and attachments by reference.
- It works across checklists; *cut* is implemented as a move.
**Tests:** unit tests for paste at various depths; cross-checklist paste test.

### T4.2.18 — Tree accessibility
**Priority:** P1 · **Size:** M · **Depends on:** T4.2.08
**Description:** Screen-reader users can read and restructure trees without dragging.
**Implementation notes:**
- Semantics label example: "Buy milk, level 3, item 2 of 5, collapsed, 4 sub-items, waiting 4 days: supplier reply".
- Custom semantic actions: indent, outdent, move up, move down, expand/collapse, change status, focus, open details.
- Logical focus order; large-text support; reduce-motion disables drag animations.
**Tests:** semantics tests; TalkBack/VoiceOver script entry in the [9.1] accessibility audit.

### T4.2.19 — Performance hardening for huge lists
**Priority:** P1 · **Size:** M · **Depends on:** T4.2.09, T4.2.11
**Description:** Meet the arch §9.6 budget for 5 000 items at depth 12+ and survive a 20 000-item stress list.
**Implementation notes:**
- Rows are memoized on `(id, updated_at, depth, collapsed, rollupVersion)`, with a `RepaintBoundary` per row.
- A single-row edit never rebuilds the list.
- Above 10 000 items, the tree and visible list are built in a background isolate.
- Use Drift `watch` only on the open checklist.
**Acceptance criteria:**
- Open < 300 ms; scroll at 60 fps.
- Structural op → next frame < 16 ms.
- The 20 000-item list stays usable (no ANR).
**Tests:** performance scenario with thresholds in the [9.1] suite.
