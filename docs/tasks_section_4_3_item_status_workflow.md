# Section 4.3 — Item Status Workflow, Preview Mode & Roll-ups

> Milestones: M1 (P0) · M2 (P1) · Depends on: 1.3, 2.3, 4.1, 4.2
> Architecture: §6.10 (derived roll-ups), §7.3 (`checklist_items`, `activity_events`), §8.6 (checklist settings)

## Goal

Deliver the user's core requirement for Lists: *"When previewing it I can mark it completed
(checkbox), or make it waiting (with a reason note), blocked (with a note), or ongoing."*
Every status change is quick, carries an optional or required note, is kept in history (for stats
in [6.4]), and rolls progress up through the tree.

## Status model

| Status | Meaning | Control | Reason note | Counts toward progress | `completed_at` |
|---|---|---|---|---|---|
| `todo` | Not started (default) | Empty checkbox | — | yes (open) | null |
| `ongoing` | In progress | "In progress" icon | optional | yes (open) | null |
| `waiting` | Waiting for someone or something | Clock icon | prompted (optional unless required) | yes (open) | null |
| `blocked` | Cannot proceed | Stop icon | prompted (optional unless required) | yes (open) | null |
| `completed` | Done | Checked box | optional outcome note | yes (done) | set |
| `cancelled` | Won't do | Struck-through icon | optional | **excluded** | null |

## Scope

**In:**
- status model & transition service;
- reason & follow-up sheet;
- all entry points and gestures;
- visuals & accessibility;
- status history timeline;
- derived progress roll-ups;
- parent auto-complete / cascade rules;
- preview (run) mode;
- Keep-style list commands;
- due dates & follow-ups (P1);
- staleness indicators (P1);
- completion celebration (P1).

**Out:**
- cross-list smart views and the kanban board ([4.5]);
- reminders for due items and follow-ups ([7.5]);
- flow metrics such as time in status and cycle time ([6.4]).

## Progress

- [x] T4.3.01 — Status model & transition service
- [x] T4.3.02 — Reason & follow-up sheet
- [x] T4.3.03 — Status entry points & gestures
- [x] T4.3.04 — Status visuals & accessibility
- [x] T4.3.05 — Status history timeline
- [x] T4.3.06 — Progress roll-ups (derived)
- [x] T4.3.07 — Parent auto-complete & cascade rules
- [x] T4.3.08 — Preview (run) mode
- [x] T4.3.09 — Keep-style list commands
- [x] T4.3.10 — Due dates & follow-ups
- [x] T4.3.11 — Staleness & age indicators
- [x] T4.3.12 — Completion celebration & "list done" state

## Tasks

### T4.3.01 — Status model & transition service
**Priority:** P0 · **Size:** M · **Depends on:** [4.1], [2.3] (activity events)
**Description:** Pure domain logic plus an application service that applies status transitions
consistently from every entry point.
**Implementation notes:**
- `StatusTransition(from, to, note?, followUpAt?, cause)` updates the row as follows:
  - `status`;
  - `status_note` = the new note, or null;
  - `status_changed_at` = now;
  - `completed_at`: set when entering `completed`, cleared when leaving it;
  - `follow_up_at`: set or kept for `waiting`/`blocked`, cleared for other statuses unless the user keeps it.
- Each transition writes an activity event `status_changed` with payload
  `{from, to, note, followUpAt, cause: user|auto_rollup|cascade|reset|bulk|import, opId}`.
- Any status can move to any other. Re-selecting the same status with a new note is recorded as
  `status_note_changed`.
- Settings used:
  - `requireReasonFor`: default `[]`, meaning the note is prompted but optional. The user can make
    notes required for `waiting` and/or `blocked`.
  - `defaultNewItemStatus`.
- The service applies changes through `ChecklistItemsRepository.apply` ([4.1]). Cascades
  (T4.3.07) are included in the same op group.
**Acceptance criteria:**
- All 36 from→to combinations produce correct fields and events.
- `completed_at` is never left set on a non-completed item.
**Tests:** transition matrix unit tests; event payload tests.

### T4.3.02 — Reason & follow-up sheet
**Priority:** P0 · **Size:** M · **Depends on:** T4.3.01, [1.3] (date/time pickers)
**Description:** Captures *why* an item is waiting or blocked, and when to check back.
**Implementation notes:**
- Opens when switching to `waiting` or `blocked`. For other statuses it is available through *Add note…*.
- Multi-line note field, keyboard up immediately. For `waiting`, the placeholder is
  "Waiting on whom / what?".
- Quick chips offer recent reasons for that status, taken from the last 20 `status_changed` events.
- Follow-up quick picks: *Later today*, *Tomorrow 09:00*, *In 3 days*, *Next week*, *Custom…*.
- A *Skip* button appears when the note is not required.
- The sheet is fully usable with a hardware keyboard.
**Acceptance criteria:**
- Setting "Waiting · supplier reply · tomorrow" takes two taps plus typing.
- A required note blocks *Save* with an inline hint.
**Tests:** widget tests for required vs optional notes, quick chips and follow-up picks.

### T4.3.03 — Status entry points & gestures
**Priority:** P0 · **Size:** S · **Depends on:** T4.3.01, [4.2]
**Description:** Every way a status can change goes through the same service.
**Implementation notes:**
- **Tap the checkbox:** open statuses → `completed`; `completed` → `todo` (reopen).
- **Long-press the status control, or use the row menu:** status sheet with the 6 statuses and an
  optional note.
- **Preview mode swipes** ([4.2] T4.2.10): right = complete, left = menu.
- **Other sources:**
  - kanban drop ([4.5]);
  - bulk selection ([4.2]);
  - notification actions *Done* / *Mark waiting* ([7.2]);
  - Today checklists block ([8.1]).
- **Feedback:**
  - haptic `successNotification` on complete;
  - undo snackbar for swipe, bulk and cascade-affecting changes;
  - accessible announcement ("Marked waiting").
**Tests:** one widget test per entry point (tap, long-press, swipe); undo test.

### T4.3.04 — Status visuals & accessibility
**Priority:** P0 · **Size:** S · **Depends on:** T4.3.01, [1.3] (design tokens)
**Description:** Statuses must be distinguishable without relying on color.
**Implementation notes:**
- Design-system status tokens: icon, color (light/dark), pattern and localized label for each status.
- Pills show the age since `status_changed_at`, e.g. "Waiting · 4 d" or "Blocked · 2 h". Ages are
  relative and localized with plurals.
- Completed items are struck through; cancelled items are struck through and muted.
- Directional icons mirror in RTL.
- Contrast is ≥ 4.5:1 for pill text in both themes.
**Tests:** goldens for all statuses (light/dark, LTR/RTL); contrast guideline tests.
**Notes:** Goldens: preview gallery of every status, light/dark × LTR/RTL + text scale 2.0; contrast guideline test for every pill at every escalation level in both themes. The design-system pill targets exactly 4.5:1 and renders 4.48 for To do / In progress, so status pills pre-shade to 4.6 (`StatusStyle.pillColor`). Completed rows are struck through in `onSurfaceVariant`; cancelled are struck through and muted. The progress header and pills no longer overflow at 400 dp / text scale 2.0.

### T4.3.05 — Status history timeline
**Priority:** P0 · **Size:** S · **Depends on:** T4.3.01
**Description:** An item's full story, shown in the item details sheet ([4.2] T4.2.15).
**Implementation notes:**
- A chronological list of `status_changed` events with their notes.
- Also shows: time spent in each status, the device that made each change (from `origin_device_id`
  → device name), and summarized edits and moves.
- Totals per status link to the flow metrics in [6.4] (time in status, cycle time).
**Tests:** widget test with fixture events; unit test for durations (including an open current interval).
**Notes:** Devices are shown as this / another device (device names need the device registry).

### T4.3.06 — Progress roll-ups (derived)
**Priority:** P0 · **Size:** M · **Depends on:** [4.2] (ChecklistTree)
**Description:** Progress and status summaries per node. Computed, never stored.
**Implementation notes:**
- A pure `RollupCalculator` over `ChecklistTree` produces for each node:
  - countable leaves (cancelled excluded) and completed leaves;
  - leaf status counts (todo / ongoing / waiting / blocked / completed);
  - progress: in `leaves` mode, completed leaves ÷ countable leaves; in `children` mode, completed
    direct children ÷ countable direct children;
  - `hasBlockedDescendant`, `hasWaitingDescendant`, `oldestOpenAge`.
- A leaf's progress is its own state.
- Where it is displayed:
  - x/y badge + status-split bar on collapsed parents;
  - progress header;
  - board cards ([4.1]);
  - descendant badges ("2 blocked below").
- On a single change, recompute only the path to the root.
**Acceptance criteria:** a full roll-up of 5 000 items takes < 5 ms; an incremental update < 1 ms.
**Tests:** unit tests for both modes, cancelled items, empty parents and all-cancelled branches;
property test comparing incremental with full recomputation.

### T4.3.07 — Parent auto-complete & cascade rules
**Priority:** P0 · **Size:** M · **Depends on:** T4.3.01, T4.3.06
**Description:** Keep parents consistent with their children, following the checklist settings (arch §8.6).
**Implementation notes:**
- **`autoCompleteParent`** (default on): when the last countable child becomes `completed`, the
  parent becomes `completed` with `cause = auto_rollup`. This applies recursively up the tree.
- **`completeChildrenWithParent`** (`ask | always | never`, default `ask`): completing a parent with
  open descendants asks "Also complete 5 open sub-items?".
- **Reopen:** while `autoCompleteParent` is on, a completed parent reopens to `todo`
  (`cause = cascade`) when:
  - one of its children becomes non-completed, or
  - a new child is added under it.
- Cancelled children are ignored. A parent whose children are all cancelled does not auto-complete.
- All cascades belong to the triggering op group and are undone with it.
**Tests:** cascade chains 10 levels deep; ask/always/never; undo restores all affected rows.

### T4.3.08 — Preview (run) mode
**Priority:** P0 · **Size:** M · **Depends on:** T4.3.03, T4.3.06, [4.2] (screen scaffold)
**Description:** The "preview" the user asked for: go through a list and mark statuses without any
risk of editing the text.
**Implementation notes:**
- **Rows:**
  - read-only text with larger status targets;
  - item notes and attachment strips inline (collapsible; setting);
  - status pills with ages.
- **Progress header:** x/y, %, status-split bar and counts ("2 blocked · 1 waiting").
- **Filter chips:** All · Open · Ongoing · Waiting · Blocked · Completed.
- **Controls:**
  - *Hide completed* toggle;
  - *Jump to next open item* button;
  - focus mode ([4.2] T4.2.13) is supported.
- Toggle Edit ⇄ Preview in the app bar. The default is per checklist (`defaultOpenMode`).
**Acceptance criteria:** any item can be marked completed / ongoing / waiting (with note) / blocked
(with note) in ≤ 2 taps plus typing.
**Tests:** widget tests; patrol integration test that marks all four statuses with notes and checks
the rows and history.
**Notes:** The patrol integration test needs a device run ([9.1]); widget tests mark statuses with notes and check rows and history.

### T4.3.09 — Keep-style list commands
**Priority:** P0 · **Size:** S · **Depends on:** T4.3.01, [4.2]
**Description:** The list-level commands Keep users expect, in the checklist overflow menu.
**Implementation notes:**
- **Uncheck all:** `completed` → `todo`; other statuses are unchanged. Asks for confirmation when
  more than 10 items would change.
- **Delete completed items:** tombstones completed leaves and fully completed subtrees. Undoable.
- **Reset all statuses:** everything goes to `todo` and notes are cleared. Asks for confirmation.
- **Hide checkboxes:** toggles `settings.hideCheckboxes`. Rows render as bullets and the progress
  UI hides; statuses stay reachable through the menu.
- **Sort completed to bottom:** toggles `settings.sortCompletedToBottom`. This is view-level only;
  stored order is untouched.
- Each command is one op group with `cause = bulk`.
**Tests:** unit tests per command; undo tests.

### T4.3.10 — Due dates & follow-ups
**Priority:** P1 · **Size:** M · **Depends on:** T4.3.02, [1.3] (date/time pickers)
**Description:** Optional per-item due dates and check-back times.
**Implementation notes:**
- **Due date:** `due_local` + `time_zone` (floating by default); the time part is optional.
- **Due chip states:** overdue (red), today, tomorrow, or a date.
- **Follow-up chip** (`follow_up_at`) on waiting/blocked items; overdue follow-ups are highlighted
  ("Check back").
- **Where the data is used:**
  - sorting and filtering ([4.5]);
  - Today's checklists block ([8.1]);
  - item reminders ([7.5]).
**Tests:** unit tests classifying due states across time zones and midnight; widget tests.

### T4.3.11 — Staleness & age indicators
**Priority:** P1 · **Size:** S · **Depends on:** T4.3.04
**Description:** Surface forgotten work.
**Implementation notes:**
- Open items unchanged for at least `settings.staleAfterDays` (default 14) get a subtle *stale* marker.
- Waiting/blocked pill colors escalate after 3 and 7 days (thresholds configurable).
- Board cards get a badge ("3 stale").
- **Data model:** `staleAfterDays` in arch §8.6 ([4.1] T4.1.03).
**Tests:** unit tests for thresholds; golden for the escalated pills.
**Notes:** Escalation uses the 3/7-day defaults (not user-configurable yet); golden not added.

### T4.3.12 — Completion celebration & "list done" state
**Priority:** P1 · **Size:** S · **Depends on:** T4.3.06
**Description:** When every countable item is completed, show a short celebration and a
"List completed" state.
**Implementation notes:**
- The celebration respects reduce-motion and the haptics setting.
- The "List completed" state offers actions: *Reset* ([4.5] resettable lists / T4.3.09),
  *Archive*, *Keep*.
**Tests:** widget test; reduce-motion test.
**Notes:** One heavy haptic per completion; the badge pops in unless reduce-motion is on. The banner stacks its actions under the message (fits 360 dp at text scale 2.0). No in-app haptics preference exists yet — TODO(integration) to gate the haptic on it; the system setting applies meanwhile.
