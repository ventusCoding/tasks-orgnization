# Section 4.1 — Checklist Model & Lists Board

> Milestones: M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 1.2, 1.3, 1.4, 2.2, 2.3
> Architecture: §6.10 (tree engine), §7.3 (checklists, checklist_items, checklist_runs, attachments),
> §8.6 (checklist settings), §9.2 (ids), §9.3 (trash), §9.4 (fractional ordering)

## Goal

Build the data foundation of the **Lists** tab and its home screen: a Google-Keep-like board of cards.
Each card is a checklist whose items nest infinitely ([4.2]), a plain note (body text, no items), or
both. The server must never store an invalid tree, multi-row operations must sync atomically, and
the board must stay fast and pleasant with hundreds of cards.

## Scope

**In:** server & local schema for checklists/items/runs with integrity rules; domain entities and
settings; repositories with operation groups; tree-aware sync conflict handling; Lists routes and
deep links; the board (masonry grid / list, Pinned & Others, card rendering); creating and editing
checklists and note cards; colors; pin/reorder/archive/delete with undo; Markdown-lite body (P1);
labels, search and filters (P1); duplicate & move between checklists (P1); board view config (P1);
cover image (P2).
**Out:** item editing & tree operations ([4.2]), statuses & roll-ups ([4.3]), item attachments UI
([4.4]), alternative views, templates, recurring lists, import/export ([4.5]), stats ([6.4]),
reminders ([7.1], [7.5]), the Trash screen ([8.3]).

## Progress

- [ ] T4.1.01 — Server schema: checklists, checklist_items, checklist_runs
- [ ] T4.1.02 — Local schema: Drift tables, DAOs & UI-state tables
- [ ] T4.1.03 — Domain entities & checklist settings value object
- [ ] T4.1.04 — Repositories, write rules & operation groups
- [ ] T4.1.05 — Tree-aware sync conflict handling
- [ ] T4.1.06 — Lists routes & deep links
- [ ] T4.1.07 — Lists board screen
- [ ] T4.1.08 — Checklist card widget
- [ ] T4.1.09 — Create & edit checklists and note cards
- [ ] T4.1.10 — Pin, reorder, archive & delete with undo
- [ ] T4.1.11 — Markdown-lite body rendering
- [ ] T4.1.12 — Labels on checklists & label drawer
- [ ] T4.1.13 — Board search & filters
- [ ] T4.1.14 — Duplicate checklist
- [ ] T4.1.15 — Move items between checklists
- [ ] T4.1.16 — Board view configuration (synced)
- [ ] T4.1.17 — Checklist cover image

## Tasks

### T4.1.01 — Server schema: checklists, checklist_items, checklist_runs
**Priority:** P0 · **Size:** M · **Depends on:** [1.2] (`app.enable_sync`, pgTAP harness)
**Description:** One migration creating the three tables exactly as arch §7.3, wired with
`app.enable_sync(...)`, CHECK constraints, indexes and integrity triggers so the server can never
hold an invalid tree (wrong-checklist parent or cycle).
**Implementation notes:**
- Indexes: `checklist_items (user_id, checklist_id) where deleted_at is null`;
  `checklist_items (checklist_id, parent_id, sort_key)`;
  `checklists (user_id, is_pinned, sort_key) where deleted_at is null`;
  `checklist_runs unique (checklist_id, occurrence_key)`.
- CHECKs: status in the 6 values; `completed_at is not null` ⇔ `status = 'completed'`;
  `char_length(text) <= 10000`, `note <= 100000`, `title <= 500`, `body <= 100000`;
  `sort_key ~ '^[0-9A-Za-z]{1,256}$'`; `reset_mode` in allowed values.
- Integrity as **`CONSTRAINT TRIGGER … DEFERRABLE INITIALLY DEFERRED`**, so rows are checked at
  commit and a whole subtree move passes no matter what order its rows arrive in:
  1. a non-null `parent_id` must point to an item (live or tombstoned) with the same `checklist_id`
     and `user_id` → `raise exception using errcode = 'DL001'` (`checklist_parent_mismatch`);
  2. no cycles: walk ancestors with a bounded recursive CTE (depth ≤ 10 000) → `DL002` (`checklist_cycle`).
- `sync_push` must apply each operation group inside a savepoint and run
  `SET CONSTRAINTS ALL IMMEDIATE` at the end of the group. A violation then rolls back only that
  group, whose rows are reported as `rejected(checklist_cycle | checklist_parent_mismatch)`.
  The other groups in the batch still apply.
- **Data model:** [1.4] `sync_push` input carries an op-group id per change (`"g": "<opId>"`)
  and applies groups atomically with the savepoint + immediate-constraints pattern above.
**Acceptance criteria:**
- `supabase db reset` applies cleanly; the RLS completeness check ([9.1]) passes for all 3 tables.
- In one transaction, a 3-level subtree moves to another checklist, rows written child-first, and commits.
- A cycle or cross-checklist parent is rejected with the stable error codes.
**Tests:** pgTAP: RLS isolation (user A vs B); cycle rejection; parent-mismatch rejection; the
deferred child-first subtree move; tombstone-only update allowed; `completed_at` invariant.

### T4.1.02 — Local schema: Drift tables, DAOs & UI-state tables
**Priority:** P0 · **Size:** M · **Depends on:** T4.1.01, [1.4]
**Description:** Drift mirrors of the three tables, DAOs for every query the Lists section needs,
and the local-only UI-state tables.
**Implementation notes:**
- Synced tables use the shared `SyncedTable` mixin from [1.4]. JSON converters cover `settings`
  (T4.1.03) and `reset_rule` (recurrence JSON from [2.1]).
- Local-only tables (never synced):
  - `ui_node_state(node_id PK, checklist_id, collapsed bool, updated_at)`;
  - `ui_checklist_state(checklist_id PK, mode 'edit'|'preview', focus_item_id, view_type,
    sort_json, filter_json, scroll_offset, last_opened_at)`.
- **Data model:** local-only `ui_checklist_state` (arch §6.5).
- DAOs:
  - `watchBoard({archived, filter})`;
  - `watchChecklist(id)`;
  - `watchItems(checklistId)`: all live rows ordered by `parent_id, sort_key, id`;
  - `cardSummaries(ids)`: one aggregate query returning status counts and the first rows for
    visible cards (no N+1 queries);
  - `itemsByStatus(statuses)` across lists (smart views, [4.5]);
  - `subtreeIds(itemId)` via `WITH RECURSIVE`.
**Acceptance criteria:** schema version bumped and migration test green; `watchItems` for
5 000 rows < 30 ms; `subtreeIds` correct for a depth-50 chain.
**Tests:** in-memory Drift DAO tests; Drift migration test.

### T4.1.03 — Domain entities & checklist settings value object
**Priority:** P0 · **Size:** S · **Depends on:** T4.1.02
**Description:** Pure-Dart domain types for the section.
**Implementation notes:**
- `freezed` types: `Checklist`, `ChecklistItem`, `ChecklistRun`, `ResetMode`.
- `ItemStatus` enum with helpers `isOpen`, `isCountable` (cancelled = false), `isTerminal`.
- `ChecklistSettings` v1 JSON with the arch §8.6 keys, plus:
  - `hideCheckboxes` (bool, default false);
  - `defaultOpenMode` (`edit | preview`, default `preview` for existing lists);
  - `staleAfterDays` (int, default 14).
- Value objects: `ChecklistTitle` and `ItemText` (trim trailing whitespace, keep inner newlines,
  enforce the DB limits).
- **Data model:** `hideCheckboxes`, `defaultOpenMode`, `staleAfterDays` (arch §8.6).
**Acceptance criteria:** unknown JSON keys survive a round trip; missing keys fall back to defaults.
**Tests:** JSON round-trip and upgrade tests; value-object validation tests.

### T4.1.04 — Repositories, write rules & operation groups
**Priority:** P0 · **Size:** M · **Depends on:** T4.1.03, [2.3] (activity events, undo stack)
**Description:** Application-facing repositories. Every multi-row change is one transaction and
one sync operation group.
**Implementation notes:**
- `ChecklistsRepository`:
  - `create` (new cards go to the top of their section via a fractional key before the current first);
  - `update`, `setPinned`, `archive`, `unarchive`;
  - `delete`: tombstones the checklist, all its items, their attachments and `entity_tags`, sharing one `opId`;
  - `restore(opId)`.
- `ChecklistItemsRepository.apply(TreeChange)` is the only write path for item changes coming from
  the tree engine ([4.2]) and the status service ([4.3]).
- Every write is one Drift transaction: rows + outbox entries (with `op_id`) + `activity_events`.
  Payload conventions: `opId`, `cause` (`user | auto_rollup | cascade | reset | bulk | import`),
  `from`/`to`, and `fromParent`/`toParent`/`fromChecklist`/`toChecklist` for moves.
- Text edits are coalesced into a single `updated` event per editing session.
- **Data model:** [1.4] local `sync_outbox.op_id` column and op-group-aware batching:
  `sync_push` must never split one group across calls, even if the group exceeds the normal 500-row batch.
**Acceptance criteria:**
- Deleting a checklist with 1 000 items takes one transaction, < 200 ms.
- `restore(opId)` restores exactly what that operation deleted, and nothing deleted earlier.
**Tests:** repository tests (in-memory Drift); op-group batching test with a fake sync API.

### T4.1.05 — Tree-aware sync conflict handling
**Priority:** P0 · **Size:** M · **Depends on:** T4.1.04, [1.4]
**Description:** Two offline devices can make moves that conflict, e.g. A moves X under Y while B
moves Y under X. The server rejects the second group. The losing device must then fall back to the
server state without losing data.
**Implementation notes:**
- On `rejected(checklist_cycle | checklist_parent_mismatch)` for a group, the client:
  1. drops that group's pending outbox entries;
  2. pulls the affected rows immediately;
  3. overwrites the local rows;
  4. pushes the inverse change onto the undo stack as a no-op marker;
  5. shows a non-blocking notice: "A move conflicted with a change on another device and was undone."
- The local tree builder tolerates transient cycles and orphans ([4.2] T4.2.01).
- **Data model:** [1.4] reject policy for integrity violations: "refetch and overwrite local",
  not "mark failed and retry".
**Acceptance criteria:** the X/Y cross-move scenario converges on both devices to the structure pushed
first; no item is lost or duplicated.
**Tests:** unit test of the reject→revert path with a fake API; scenario added to the two-client
convergence suite ([9.1]).

### T4.1.06 — Lists routes & deep links
**Priority:** P0 · **Size:** S · **Depends on:** [1.3] (router, deep-link parser)
**Description:** Register the Lists routes in the shell and the shared deep-link parser.
**Implementation notes:**
- Routes:
  - `/lists` (board), `/lists/archive`, `/lists/templates` (used by [4.5]);
  - `/lists/smart/:kind` (`waiting | blocked | ongoing | follow_ups`);
  - `/lists/:checklistId`, with query params `item`, `focus=1` and `mode=edit|preview`.
- Invalid or deleted ids go to a friendly "not found" page. A tombstoned checklist offers its Trash entry.
**Acceptance criteria:** every route opens from a cold start and from a notification payload.
**Tests:** parser unit tests (valid, invalid, fuzzed); router widget test.

### T4.1.07 — Lists board screen
**Priority:** P0 · **Size:** M · **Depends on:** T4.1.02, T4.1.06, [1.3]
**Description:** The Keep-like home of the Lists tab.
**Implementation notes:**
- App bar:
  - search entry (P1, T4.1.13);
  - grid/list toggle;
  - labels & filter drawer (P1);
  - overflow menu: Archive, Templates ([4.5]), Trash ([8.3]).
- Smart-view chips row: *Waiting n · Blocked n · Ongoing n · Follow-ups n*, linking to [4.5]; hidden when all are 0.
- Sections **Pinned** and **Others**:
  - masonry grid: 2 columns on phones, 3–4 on tablets. Use `SliverMasonryGrid` from
    `flutter_staggered_grid_view` (arch §3).
  - list mode: single-column full-width cards.
- FAB: tap = new checklist; long-press = new checklist / new note / from template ([4.5]).
- Pull-to-refresh triggers sync ([8.1]). Empty state has "Create your first list".
- The layout choice is stored locally until T4.1.16 syncs it.
**Acceptance criteria:** 500 cards scroll at 60 fps; RTL mirrors column order; text scale 2.0 has no overflow.
**Tests:** widget tests; goldens grid/list × light/dark × LTR/RTL.

### T4.1.08 — Checklist card widget
**Priority:** P0 · **Size:** M · **Depends on:** T4.1.07
**Description:** Card rendering rules for the board.
**Implementation notes:**
- **Background:** derived from the stored ARGB color through a Material 3 tonal palette: tone ≈ 90–95
  in light mode, ≈ 25–30 in dark. Any color adapts to dark mode automatically.
- **Content, top to bottom:**
  - title (max 2 lines);
  - body excerpt (max 3 lines, Markdown stripped);
  - first 6 visible rows at depth ≤ 2, with indentation, status glyphs and completed items struck
    through, then "+N more";
  - progress "7/12" with a mini status-split bar ([4.3] roll-ups);
  - badges ("2 blocked · 1 waiting"), due chip, repeat icon ([4.5]), bell if custom reminders exist,
    labels (P1);
  - attachment thumbnail: cover, or the first image ([4.4]).
- **Data loading:** each card's data comes from one `cardSummaries` batch per visible viewport.
- **Staged rollout:** the progress and thumbnail slots render empty until [4.3]/[4.4] land.
**Acceptance criteria:** card height adapts to content; no N+1 queries during scroll (verified in a DAO call-count test).
**Tests:** goldens: note-only, checklist-only, mixed, very long text, Arabic, dark mode.

### T4.1.09 — Create & edit checklists and note cards
**Priority:** P0 · **Size:** M · **Depends on:** T4.1.04, T4.1.07
**Description:** Creating and editing the checklist "header" (everything except items), including
Keep-style **note cards** (body text, optionally no items).
**Implementation notes:**
- **New checklist:** opens in edit mode with the title focused; Enter moves to the first item ([4.2]).
- **New note:** focuses the body field. The "add item" affordance stays available, so a note can gain items later.
- **Header fields:**
  - title;
  - body (plain multi-line text with auto-linked URLs in P0);
  - color: a palette of 12 Keep-like hues + "default", added to design tokens in [1.3] if missing;
  - category ([2.3]);
  - pin;
  - a settings sheet covering §8.6 + T4.1.03 keys: progress mode, auto-complete parents,
    complete-children-with-parent, required reasons, sort completed to bottom, hide checkboxes,
    default open mode.
- A new card left completely empty (no title, body or items) is discarded without any write.
**Acceptance criteria:** creating then leaving an empty card writes nothing; header edits sync;
settings changes are undoable.
**Tests:** widget tests (create checklist, create note, discard empty); repository tests.

### T4.1.10 — Pin, reorder, archive & delete with undo
**Priority:** P0 · **Size:** M · **Depends on:** T4.1.07
**Description:** Card-level organization.
**Implementation notes:**
- **Pin/unpin:** moves the card between sections and keeps relative order.
- **Reorder:** long-press lifts a card; drag to reorder within its section; fractional `sort_key`;
  haptic `mediumImpact` on lift and a tick on each slot change.
- **Archive/unarchive:** Archive screen lists archived cards with the same card widget.
- **Delete:** tombstones via T4.1.04 with an undo snackbar; long-term recovery lives in Trash ([8.3]).
- Card context menu: Pin, Color, Archive, Duplicate (P1), Move items… (P1), Delete.
**Acceptance criteria:** reorder persists and syncs; undo restores the exact previous state including items.
**Tests:** widget tests for drag reorder and undo; repository tests.

### T4.1.11 — Markdown-lite body rendering
**Priority:** P1 · **Size:** S · **Depends on:** T4.1.09
**Description:** Render card bodies and item notes with lightweight Markdown: bold, italic,
strikethrough, headings, links, bullet lists, inline code.
**Implementation notes:** use the shared `MarkdownLite` component. If [3.1] hasn't built it yet,
build it in `design_system/markdown_lite` so both sections share one implementation. Editing stays
plain text with a small formatting toolbar.
**Tests:** rendering tests incl. RTL and mixed-direction (Arabic + Latin) text.

### T4.1.12 — Labels on checklists & label drawer
**Priority:** P1 · **Size:** M · **Depends on:** T4.1.07, [2.3] (tags)
**Description:** Keep-style labels, implemented as tags via `entity_tags` (`entity_type = 'checklist'`).
**Implementation notes:**
- Label picker with inline create; the drawer lists labels with counts.
- Tapping a label filters the board.
- Rename, merge and delete delegate to [2.3]. Label chips appear on cards.
**Tests:** DAO tests (filter by tag); widget tests.

### T4.1.13 — Board search & filters
**Priority:** P1 · **Size:** M · **Depends on:** T4.1.07, [2.3] (FTS index, filter model)
**Description:** Search inside the Lists tab and filter the board.
**Implementation notes:**
- Search covers titles, bodies and item text through the FTS index. Results show matching cards,
  plus matching items with their breadcrumb path.
- Tapping an item opens its checklist focused on that item ([4.2] focus mode).
- Filter chips combine with AND: color, label, has waiting/blocked, has attachments, has due date,
  repeating, template, pinned.
**Acceptance criteria:** 20 000 indexed items return results in < 100 ms; matching ignores Arabic
and French diacritics.
**Tests:** FTS DAO tests; widget tests.

### T4.1.14 — Duplicate checklist
**Priority:** P1 · **Size:** M · **Depends on:** T4.1.10, [4.2] (duplicate-subtree operation)
**Description:** Deep-copy a whole checklist.
**Implementation notes:**
- The copy gets a new checklist, all items with new UUIDv7s (same structure and order), and copies of the tags.
- Attachment **rows** are copied and reference the **same** storage objects (arch §6.7).
- Option: "Reset all statuses to todo".
- Localized title "Copy of …". The whole copy is one op group.
**Acceptance criteria:** copying 2 000 items takes < 500 ms and leaves the original untouched; if the
original is later purged, the copy's files still load.
**Tests:** repository test; attachment shared-reference test.

### T4.1.15 — Move items between checklists
**Priority:** P1 · **Size:** M · **Depends on:** T4.1.05, [4.2] (move operation)
**Description:** "Move to…" for one or more subtrees: pick a target checklist, then optionally a
target parent in a mini tree picker.
**Implementation notes:**
- Updates `checklist_id` for every descendant, plus `parent_id`/`sort_key` for the moved roots,
  in one op group.
- Writes `moved` activity events with `fromChecklist`/`toChecklist`.
- Statuses, notes and attachments are unchanged.
**Acceptance criteria:** the moved subtree keeps its order and data; the server's deferred integrity
triggers accept the move; the other device shows it after sync.
**Tests:** repository test; pgTAP deferred-trigger test (T4.1.01); convergence scenario ([9.1]).

### T4.1.16 — Board view configuration (synced)
**Priority:** P1 · **Size:** S · **Depends on:** T4.1.07, [2.3] (saved views)
**Description:** Persist the board layout as a saved view (`section = 'checklists'`,
`view_type = 'lists_board'`) so it follows the user across devices.
**Implementation notes:** config v1:

```jsonc
{
  "v": 1,
  "layout": "grid",        // grid | list
  "density": "comfortable",
  "showBody": true,
  "rowsPerCard": 6,
  "sort": "manual",        // manual | recently_edited | title
  "showSmartChips": true
}
```
**Tests:** config JSON round-trip; widget test applying a config.

### T4.1.17 — Checklist cover image
**Priority:** P2 · **Size:** S · **Depends on:** T4.1.08, [4.4]
**Description:** Choose a cover (`cover_attachment_id`) from the checklist's attachments. It shows
full-width at the top of the card and in the gallery view ([4.5]).
**Tests:** widget test; fallback when the cover attachment is deleted.
