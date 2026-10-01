# Section 4.5 — Checklist Views, Templates, Recurring Lists & Import/Export

> Milestones: M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 2.1, 2.3, 3.1, 4.1–4.4
> Architecture: §6.10 (tree engine), §7.3 (`checklists.reset_rule`, `reset_mode`, `last_reset_key`,
> `is_template`, `checklist_runs`), §8.1 (recurrence rule), §9.2 (UUIDv5 ids)

## Goal

Everything beyond the outline editor:
- cross-list **smart views** (Waiting / Blocked / Ongoing / Follow-ups), so no waiting item is forgotten;
- alternative views of a checklist: kanban by status, gallery, mind map;
- **templates** and **resettable / recurring** checklists (routines);
- import and export of nested lists (indented text, Markdown, OPML), so data can come in and go out freely.

## Scope

**In:** smart views; per-checklist view switcher; kanban by status; gallery; templates; resettable
lists with run history; import parser and UX; export (text formats P1, PDF P2); in-list sort &
filter; link to a planner task; Insights entry; mind map (P2); flat all-items table (P2);
mirrors (P2); split panes (P2).
**Out:** the outline editor ([4.2]); statuses & roll-ups ([4.3]); stats computations ([6.4]);
reminders for follow-ups and resets ([7.5]); share-into-app ([8.2]).

## Progress

- [x] T4.5.01 — Smart views: Waiting, Blocked, Ongoing, Follow-ups due
- [x] T4.5.02 — Checklist view switcher
- [x] T4.5.03 — Kanban-by-status view
- [x] T4.5.04 — Gallery view
- [x] T4.5.05 — Templates
- [x] T4.5.06 — Resettable / recurring checklists with run history
- [x] T4.5.07 — Import parser (indented text, Markdown, OPML)
- [x] T4.5.08 — Import UX (paste, file, note → items)
- [x] T4.5.09 — Export & share (Markdown, OPML, plain text)
- [x] T4.5.10 — PDF export / print
- [x] T4.5.11 — In-list sort & filter
- [x] T4.5.12 — Link checklist ↔ planner task
- [x] T4.5.13 — Checklist Insights entry points
- [x] T4.5.14 — Mind map view (synced with the outline)
- [x] T4.5.15 — Flat all-items table
- [x] T4.5.16 — Mirrors (live item copies)
- [x] T4.5.17 — Split panes

## Tasks

### T4.5.01 — Smart views: Waiting, Blocked, Ongoing, Follow-ups due
**Priority:** P0 · **Size:** M · **Depends on:** [4.3], [4.2] (focus deep link), [4.1] (DAOs, routes)
**Description:** A GTD-style "waiting for" register across **all** non-archived checklists, plus the
same view for Blocked and Ongoing items and for follow-ups that are due.
**Implementation notes:**
- **Each row shows:**
  - item text;
  - checklist title + breadcrumb path;
  - status note;
  - age since `status_changed_at` ("waiting 4 d");
  - follow-up date, highlighted when overdue.
- **Sorting and grouping:** sort by age, follow-up or checklist; toggle grouping by checklist.
- **Inline actions:** change status (sheet from [4.3]), set/clear follow-up, open in checklist
  (focus mode on the item).
- **Entry points:**
  - the chips row on the Lists board, with counts ([4.1] T4.1.07);
  - routes `/lists/smart/waiting|blocked|ongoing|follow_ups`.
- The Today screen reuses the follow-ups query ([8.1]).
**Acceptance criteria:** chip counts equal the DAO aggregates; queries over 20 000 items take < 50 ms;
status changes update the view live.
**Tests:** DAO tests (statuses, archived excluded, tombstones excluded); widget tests.

### T4.5.02 — Checklist view switcher
**Priority:** P1 · **Size:** S · **Depends on:** [4.2]
**Description:** Switch how one checklist is displayed: **Outline** (default; edit/preview),
**Kanban**, **Gallery**, **Mind map** (P2).
**Implementation notes:**
- The choice is remembered per checklist in `ui_checklist_state.view_type` (local).
- Focus root and filters carry across views where meaningful.
**Tests:** widget test; state persistence test.

### T4.5.03 — Kanban-by-status view
**Priority:** P1 · **Size:** M · **Depends on:** T4.5.02, [4.3]
**Description:** Columns: *To do · Ongoing · Waiting · Blocked · Completed*. *Cancelled* is hidden
by default and can be toggled.
**Implementation notes:**
- **Cards show:** item text, breadcrumb path, note excerpt, age, first attachment thumbnail, child progress.
- **Scope toggle:** leaves only (default) / all items / direct children of the focus root.
- **Dragging a card to another column** runs the status transition. The reason sheet opens for
  waiting/blocked.
- **Order within a column** follows outline order. There is no manual in-column reordering in v1,
  so no extra data is needed.
- **Layout:** snapping horizontal scroll on phones; landscape and tablets show all columns.
**Tests:** widget tests (render, drop → transition, reason sheet); golden.
**Notes:** No manual in-column ordering (outline order), as specified; phones page through the columns, ≥ 900 dp shows all.

### T4.5.04 — Gallery view
**Priority:** P1 · **Size:** M · **Depends on:** T4.5.02, [4.4]
**Description:** Items with images appear as cards in a grid, like Notion or Tana cards. Each card
has the first image as cover, plus the text and status.
**Implementation notes:**
- The *Only items with images* filter is on by default.
- Tapping a card opens its item details.
- Reuses the grid component from [4.4] T4.4.07.
**Tests:** widget tests; golden.

### T4.5.05 — Templates
**Priority:** P1 · **Size:** M · **Depends on:** [4.1], [4.2] (duplicate subtree)
**Description:** Reusable checklist blueprints.
**Implementation notes:**
- **Save as template:** a deep copy with `is_template = true`, statuses reset, notes kept,
  attachments by reference.
- **Templates screen** (`/lists/templates`): list, rename, edit, delete.
- **New from template:** a deep copy with `is_template = false`, also offered from the FAB long-press
  on the board.
- **Built-in localized templates** (EN/FR/AR) ship as JSON assets with nesting: packing list, morning
  routine, weekly review, groceries by aisle, moving house, project kickoff.
- **Data model (recommended):** `checklists.template_id uuid null` to record where a list came
  from (useful for stats such as "runs of template X").
**Tests:** copy unit tests; asset parsing tests; widget test for New-from-template.
**Notes:** Built-in templates ship as Dart constants (per-locale indented Markdown parsed by the import parser, `domain/builtin_templates.dart`) instead of JSON assets: same content, compile-time checked, no asset loading. Save as template / new from template are repository deep copies (`template_id` recorded); the templates screen lists, renames, edits and deletes.

### T4.5.06 — Resettable / recurring checklists with run history
**Priority:** P1 · **Size:** L · **Depends on:** [2.1] (recurrence builder & engine), [4.3]
**Description:** Routine lists that reset on a schedule, e.g. a morning routine every day or a
weekly review every Sunday. Item order is always preserved. Each finished period is kept as a
`checklist_runs` snapshot for history and stats.
**Implementation notes:**
- **Settings › Repeat:**
  - `reset_rule`: recurrence builder from [2.1] (daily, weekdays, weekly on…, monthly, custom);
  - `reset_mode`: `all_to_todo` | `completed_to_todo`;
  - a chip on the list: "Resets every day at 05:00 · next in 3 h".
- **Reset planner** (pure) + service. It runs:
  - at app start and resume;
  - after each pull;
  - before opening the checklist;
  - in the [1.4] periodic background task.
- **One reset, step by step:**
  1. Find the latest due occurrence key `k` with `k > last_reset_key`.
  2. If a `checklist_runs` row with id `v5(checklist_id|k)` already exists, skip. This makes resets
     idempotent across devices.
  3. Otherwise, in one op group:
     - insert the run: `started_at` = previous reset instant, `ended_at` = occurrence instant,
       totals, and a snapshot of item statuses and notes;
     - update item statuses per `reset_mode` (`sort_key`s untouched);
     - set `last_reset_key = k`;
     - write activity events with `cause = reset`.
- **Backdating rule:** reset writes use `updated_at` = the **occurrence instant**, not now. Any user
  edit made after the reset time on another device therefore wins under last-writer-wins.
  - **Data model:** this rule applies to all time-triggered system writes (arch §6.6, [1.4] T1.4.19).
- **Missed resets:** after several missed periods, only the latest reset is applied. The skipped
  periods are not recorded as runs; stats treat them as gaps.
- **Manual "Reset now":** creates a run with key `manual:<uuidv7>`.
- Reminders for resets are in [7.5]; run statistics are in [6.4].
**Acceptance criteria:**
- Two devices that are offline both reset at the same key → a single run row and identical item states.
- A completion made on device A after the reset time is not undone when device B's late reset syncs.
**Tests:** planner unit tests (keys, idempotency, missed periods, DST); repository tests; two-client
convergence scenario ([9.1]).
**Notes:** Uses the shared recurrence picker (`RecurrencePickerMode.checklistReset`) and the `RecurrenceService` engine; resets run at start, on resume, after pulls and when a list opens. The two-client convergence scenario belongs to the [9.1] suite.

### T4.5.07 — Import parser (indented text, Markdown, OPML)
**Priority:** P1 · **Size:** M · **Depends on:** [4.2] (tree operations)
**Description:** A pure parser that turns external nested lists into an `ImportTree`.
**Implementation notes:**
- **Indentation:** tabs or 2–4 spaces, detected relatively and tolerant of mixing.
- **Bullets:** `-`, `*`, `•`, `+`, and numbered `1.` / `1)`.
- **Markdown task lists:** `- [ ]` → todo, `- [x]` → completed. Headings become parents; blank
  lines are ignored.
- **OPML 1.0/2.0:** `outline@text`, `_note`, `_complete` (Workflowy/Dynalist conventions), and a
  custom `_status` read back from our own export.
- **Limits:** 10 000 lines; warnings for anything skipped.
- **Output:** a tree plus warnings, converted into one `TreeChange` inserted at a chosen target
  (new checklist or under an item), as a single op group.
**Tests:** fixture files: Workflowy, Dynalist, Checkvist, Keep text export, Obsidian Markdown,
Arabic text, malformed input.

### T4.5.08 — Import UX (paste, file, note → items)
**Priority:** P1 · **Size:** M · **Depends on:** T4.5.07
**Description:** Three ways in.
**Implementation notes:**
- **Paste:** pasting multi-line text into an item or a new list opens an import dialog. It previews
  the tree and offers *Split into N items (keep nesting)* or *Keep as one item*.
- **Import file:** `.txt`, `.md` or `.opml` via the file picker, or shared into the app ([8.2]),
  creates a new checklist.
- **Convert note body to items:** Keep's "show checkboxes". Each body line becomes an item and
  indentation becomes nesting.
**Tests:** widget tests for each path; undo of an import.
**Notes:** Paste and file imports preview the tree (indented, first 12 rows) with *Split into N items (keep nesting)* / *Keep as one item*; the file source is `importFileReaderProvider` (system picker by default). Sharing a file into the app arrives with [8.2]. Fixed: the import dialog disposed its text controller while animating out.

### T4.5.09 — Export & share (Markdown, OPML, plain text)
**Priority:** P1 · **Size:** M · **Depends on:** [4.2]
**Description:** Export a whole checklist or a branch (the focus root).
**Implementation notes:**
- **Markdown:**
  - nested `- [ ]` / `- [x]`;
  - other statuses as `- [ ] ⏳ text — waiting: reason` (glyphs: ▶ ongoing, ⏳ waiting, ⛔ blocked,
    ✖ cancelled);
  - notes as indented paragraphs;
  - attachment file names listed.
- **OPML:** `_complete`, `_note`, `_status`.
- **Plain indented text.**
- Output goes to the clipboard or the share sheet.
- Every export round-trips through T4.5.07.
**Tests:** golden text outputs; round-trip test (export → import → identical structure and statuses).
**Notes:** Clipboard or share sheet (`share_plus`); the Markdown export lists attachment file names.

### T4.5.10 — PDF export / print
**Priority:** P2 · **Size:** M · **Depends on:** T4.5.09
**Description:** A printable PDF.
**Implementation notes:**
- Status glyphs, notes, optional image thumbnails, RTL layout.
- Page breaks try to keep small subtrees together.
- Uses the `pdf` + `printing` packages → add them to arch §3 when implemented.
**Tests:** text extraction from the generated PDF; RTL fixture.
**Notes:** *PDF* format of the share/export sheet (whole list or branch; notes and image thumbnails optional) → *Print…* or *Share…* (`PdfOutput`, `printing`). `buildChecklistPdf` draws vector status glyphs in the status colors, status reasons, notes, thumbnails from the attachment cache (unreadable ones skipped), page numbers, RTL direction from the locale. Page breaks: `pdfBlocks` keeps subtrees of ≤ 12 items in one `Inseparable` block; larger ones break between children. Tests extract text from uncompressed output (`checklist_pdf_test.dart`, incl. the Arabic RTL fixture) plus the sheet flow (`pdf_export_sheet_test.dart`).

### T4.5.11 — In-list sort & filter
**Priority:** P1 · **Size:** S · **Depends on:** [4.2] (visible list builder)
**Description:** View-level sorting and filtering. The stored order is never changed.
**Implementation notes:**
- **Sort within sibling groups:** manual (outline order), alphabetical, status, due, priority, recently changed.
- **Filters:** status set, has attachments, due soon, text.
- Saved per checklist in `ui_checklist_state` (local). A clear "Sorted by … · Reset" banner is shown
  while active.
**Tests:** unit tests on the visible list; widget test for the banner.
**Notes:** Sorting (manual, A–Z, status, due, priority, recent; ascending/descending) applies per sibling group on the visible list only; undated / never-changed items stay last in both directions. Sort and filter persist per list in the local UI state and restore on open; the banner resets both.

### T4.5.12 — Link checklist ↔ planner task
**Priority:** P1 · **Size:** S · **Depends on:** [3.1] (task editor & `tasks.linked_checklist_id`)
**Description:** Connect a list to the Planner.
**Implementation notes:**
- From the checklist menu:
  - *Schedule as task* creates a task with `linked_checklist_id` and the list's title, then opens the task editor;
  - *Link to existing task…* links an existing task.
- The header chip shows linked task(s), found by querying tasks by `linked_checklist_id`. Tapping it
  opens the task.
- The task tile shows the list's progress ([3.1]).
- The link is stored only on `tasks`, never duplicated.
**Tests:** DAO test; widget tests for both directions.
**Notes:** Through the planner's application API (`plannerServiceProvider.createTask` / `linkChecklist`): *Schedule as task* creates an unscheduled task named after the list and opens its editor; *Link to existing task…* picks from the backlog + the next 60 days of occurrences; header chips open the task. TODO(integration): a planner query by `linked_checklist_id` would also list tasks whose occurrences are further away. The task tile's list progress is the planner side (T3.1.16).

### T4.5.13 — Checklist Insights entry points
**Priority:** P1 · **Size:** S · **Depends on:** [6.4]
**Description:** An *Insights* action in the checklist menu and the item details sheet opens the
checklist or item stats in [6.4].
**Implementation notes:** the header shows a tiny summary, e.g. "12 done this week · 2 blocked".
**Tests:** navigation widget test.
**Notes:** Entry points: list menu → `/insights/checklist/<id>`, item details → `/insights/item/<id>` (the Insights routes call checklist items `item`; the old `checklistItem` link did not resolve), and the header's "N done this week" button (completions since the user's week start, zone-aware). The blocked / waiting counts stay as header pills.

### T4.5.14 — Mind map view (synced with the outline)
**Priority:** P2 · **Size:** L · **Depends on:** T4.5.02
**Description:** A live visualization of the same tree, similar to MindNode's map/outline sync.
**Implementation notes:**
- Horizontal tree layout with curved connectors, status colors and progress rings on parents.
- Pan and zoom; collapse nodes; *focus mode* dims other branches.
- Tapping a node focuses it in the outline.
- Editing inside the map (add child, rename inline) comes later.
- Export the map as an image.
**Tests:** layout algorithm unit tests (no overlaps, deterministic); goldens.
**Notes:** *Mind map* in the view switcher: pure tidy-tree layout (`MindMapLayout`, fixed-size nodes, RTL mirrored), `InteractiveViewer` pan/zoom, curved connectors, status borders and progress rings, collapse shared with the outline, the focused branch dims the others, tapping a node reveals and highlights it in the outline, *Export as image* shares a PNG. In-map editing is deferred as the task says.

### T4.5.15 — Flat all-items table
**Priority:** P2 · **Size:** M · **Depends on:** T4.5.01
**Description:** A spreadsheet-style table of items across all checklists.
**Implementation notes:**
- Columns: text, checklist, path, status, age, due, follow-up, priority, attachments.
- Sort and filter; bulk status changes.
**Tests:** widget tests; DAO test.
**Notes:** Board menu → *All items (table)*: `TableView` with pinned header and select + item columns (RTL mirrored), header taps sort (pure `ItemTableQuery`, missing values last), status chips and a text filter (item, list or path), multi-select with a status change applied as one operation per list. Items of archived / template / deleted lists are excluded; capped at 20 000 rows.

### T4.5.16 — Mirrors (live item copies)
**Priority:** P2 · **Size:** L · **Depends on:** [4.2]
**Description:** Show the same item in several places, like Workflowy mirrors.
**Implementation notes:**
- A mirror renders the original's text, status and children live. Edits made through a mirror edit
  the original.
- Deleting the original turns its mirrors into plain copies.
- Stats count originals only.
- **Data model:** `checklist_items.mirror_of_id uuid null references app.checklist_items(id)`,
  plus a server trigger forbidding a mirror inside its original's subtree, and local cycle guards.
**Tests:** rendering/edit-through unit tests; pgTAP for the trigger; cycle tests.
**Notes:** Schema v3 adds `checklist_items.mirror_of_id` (migration `20261001120000_add_checklist_mirrors.sql`: FK + same-owner trigger + DL003 `checklist_mirror_cycle` guard, pgTAP `146`; Drift step + `migration_v3_test`). *Mirror to…* (item menu) adds a row showing the original's text/status (`watchItems` joins the original) with a live preview of its children (`MirrorPreview`, tap toggles); status, text and field edits on a mirror go to the original (`ChecklistService` redirects, one undo step). Mirrors never get children nor sit inside their original's subtree (editor guards + server). Rollups, card summaries, smart counts/lists and stats skip mirrors. Deleting the original (item or whole list) turns mirrors into plain copies with copies of its children; *Unlink mirror* does the same on demand. Deviation: children render as a compact preview (≤ 5 lines + "More in the original…") rather than fully editable nested rows.

### T4.5.17 — Split panes
**Priority:** P2 · **Size:** M · **Depends on:** [4.2]
**Description:** On tablets and in landscape, show two branches or two checklists side by side, as
in Workflowy Panes.
**Implementation notes:** drag items between panes to move them (the [4.2] move operation / [4.1]
move-between-checklists).
**Tests:** widget tests (both panes editable; move across panes).
**Notes:** *Open side by side…* (list menu, width ≥ 700 dp) opens `SplitChecklistsScreen` with two different lists, each a full editable pane with its own snack bars; a row drag released over the other pane moves the row and its subtree to the end of that list (one undoable operation). Two branches of the *same* list side by side would need per-pane editor state (the editor is keyed by list) — not done.
