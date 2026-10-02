# Section 7.5 — Notification Catalog per Section & Global Controls

> Milestones: M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 3.2, 4.3, 5.1, 5.2, 5.3, 6.1, 7.1, 7.2, 7.3, 8.3
> Architecture: §6.13, §8.2 (triggers), §8.5 (notifications settings), §9.7 (off-peak digests)

## Goal

Define exactly **what** can notify the user in each section — Planner, Checklists, Habits, Quit — and the
global controls that keep it humane (quiet hours, pause, mutes, per-section switches). Every trigger here
is a *rule* the user can add, edit, disable or re-time freely ([7.1]); the defaults only give a sensible
start. The user's example is the first acceptance test: *"notify me X minutes before a task starts and
again when it starts."*

## Scope

**In:** trigger semantics, default content, actions, guards and acceptance tests for: planner reminders
(start/end offsets, all-day, overdue, up-next, timer end), checklist reminders (chosen time, follow-up,
due, status age, structural events), habit reminders (scheduled, not-done-by, streak at risk, quota pace,
milestones, inactivity), quit notifications (milestones, pledge/review, craving support, encouragement),
digests, the Notifications settings page and global controls, mutes, notification statistics (P2), smart
reminders (P2), status-change triggers (P2).
**Out:** Rule storage/editors ([7.1]); planning/scheduling mechanics ([7.2]); inbox ([7.3]); push ([7.4]);
live timer surfaces and widget refreshes ([8.2]); hide-content privacy option ([8.3] T8.3.10); location
(arrive/leave) triggers ([9.3] T9.3.10).

## Trigger catalog (summary)

| Section | Trigger (spec type → anchor) | Default | Guard | Default actions | Pri |
|---|---|---|---|---|---|
| Planner | relative → `start` (−N min … at start) | 10 min before + at start | `task_occurrence_open` | Start · Snooze · Skip | P0 |
| Planner | relative → `end` (before/at end) | off | `task_occurrence_open` | Done · Snooze · Skip | P0 |
| Planner | relative `dayOffset`+`atTime` (all-day / date-only) | on the day 09:00 | `task_occurrence_open` | Done · Snooze · Open | P0 |
| Planner | overdue (after end + grace, repeating) | off | `task_occurrence_open` | Done · Reschedule · Skip | P1 |
| Planner | up next / timer end | off | `task_occurrence_open` | Start / Stop · +10 min | P1 |
| Checklists | absolute / schedule on list or item | — | `item_not_completed` | Complete · Snooze · Open | P0 |
| Checklists | relative → `follow_up` | at follow-up | `checklist_item_status_in [waiting, blocked]` | Mark ongoing · Complete · Snooze 1 d | P0 |
| Checklists | relative → `due` (item / checklist) | at due; date-only 09:00 | `item_not_completed` | Complete · Snooze · Open | P1 |
| Checklists | statusAge (waiting ≥ N d, blocked ≥ N h) | off | status still matches | Mark ongoing · Snooze · Open | P1 |
| Checklists | childrenComplete / childOverdue / stale / reset | off | per event | Complete parent · Open | P1 |
| Habits | relative → `slot` / schedule times | at slot (09:00 if untimed) | `habit_period_open` | Done · Log value · Skip | P0 |
| Habits | notDoneBy, streakRisk | streak risk 21:00 (Gentle) | `habit_period_open` | Done · Log value · Skip | P0 |
| Habits | quotaBehind, milestone, inactivity | off | per trigger | Done · Open | P1 |
| Quit | milestone (health, custom, money, units) | on | `quit_no_relapse_since` | Open · Share | P1 |
| Quit | pledge, evening review, craving support, encouragement | off | per trigger | Pledge · Log craving · Clean day | P1 |
| All | digest (agenda, plan tomorrow, overdue, weekly, monthly) | off | `always` | Open | P1 |

## Progress

- [x] T7.5.01 — Planner: start & end reminders with multiple offsets
- [x] T7.5.02 — Planner: all-day & date-only reminders
- [x] T7.5.03 — Planner: overdue reminders
- [x] T7.5.04 — Planner: up-next chain & timer-end alerts
- [x] T7.5.05 — Checklists: reminders at a chosen time (lists & items)
- [x] T7.5.06 — Checklists: waiting/blocked follow-up reminders
- [x] T7.5.07 — Checklists: item & checklist due reminders
- [x] T7.5.08 — Checklists: status-age escalation
- [x] T7.5.09 — Checklists: structural event triggers
- [x] T7.5.10 — Habits: scheduled reminders (slots, times, several per day)
- [x] T7.5.11 — Habits: not-done-by & streak-at-risk
- [x] T7.5.12 — Habits: quota pace, milestones & inactivity
- [ ] T7.5.13 — Quit: milestone notifications
- [ ] T7.5.14 — Quit: pledge, evening review, craving support & encouragement
- [x] T7.5.15 — Notifications settings page & global controls
- [x] T7.5.16 — Mute until (rule, item, list, habit, section)
- [ ] T7.5.17 — Notification statistics
- [ ] T7.5.18 — Digests: agenda, plan tomorrow, overdue, weekly & monthly
- [ ] T7.5.19 — Smart reminder suggestions
- [ ] T7.5.20 — Status-change & custom event triggers

## Tasks

### T7.5.01 — Planner: start & end reminders with multiple offsets
**Priority:** P0 · **Size:** M · **Depends on:** [7.1], [7.2], [3.2] (occurrence resolver & actions)
**Description:** Relative triggers anchored on each occurrence's **effective** start or end (moved
occurrences use their override time), any number of rules per task/series (e.g. 1 day before at 20:00,
30 min before, 10 min before, at start, 5 min before end), before or after the anchor, from 1 minute to
30 days.
**Implementation notes:**
- Guard `task_occurrence_open`; default condition `onlyIfStatusIn [scheduled, in_progress]` (no "starts in
  10 min" for an occurrence already done or skipped).
- Content defaults: "{title} starts in {minutes_until} min · {start_time}–{end_time}" / "{title} — starting
  now" / "{title} ends in {minutes_until} min"; `{category}`, `{notes_excerpt}`, `{parent_path}` available.
- Actions by tracking mode: `check` → Start · Snooze · Skip (before) and Done · Snooze · Skip (at/after);
  `event` → Open · Snooze; `timer` → Start timer · Snooze.
- Floating vs fixed time zone follows the task (planner handles DST and travel).
**Acceptance criteria:** the user's example — a weekly task with "10 min before" and "at start" — fires two
notifications per occurrence at the exact times, including across a DST change; completing it before start
cancels both.
**Tests:** planner fixtures (multiple offsets, moved occurrence, DST); patrol scenario in [7.2] T7.2.22.
**Notes:** Verified end to end with the real planner source (`catalog_e2e_test.dart`). The planner source supplies the actions by tracking mode.

### T7.5.02 — Planner: all-day & date-only reminders
**Priority:** P0 · **Size:** S · **Depends on:** T7.5.01
**Description:** For all-day and multi-day tasks: "on the day at HH:MM" (default `dateOnlyDefaultTime`,
09:00), "N days before at HH:MM", "on the last day at HH:MM" for multi-day spans.
**Acceptance criteria:** an all-day task on Friday with "1 day before at 20:00" notifies Thursday 20:00 local.
**Tests:** planner fixtures incl. multi-day tasks and zone changes.
**Notes:** *On the last day at…* uses the `end` anchor with `dayOffset 0` (end-like anchors count their last included day).

### T7.5.03 — Planner: overdue reminders
**Priority:** P1 · **Size:** S · **Depends on:** T7.5.01, [7.2] (nag chains)
**Description:** `overdue {afterMinutes}` — after end + `missedGraceMinutes`, if a `check` task is still open:
"{title} is overdue", optional repeats (every N min/h, ≤ 10), actions Done · Reschedule (+1 h / tonight /
tomorrow) · Skip.
**Acceptance criteria:** no overdue notification for `event` tasks or for occurrences done within the grace.
**Tests:** planner fixtures.
**Notes:** `overdue` reminders: planner targets now carry `tracking_mode` and `missed_grace_minutes` (`planner.missedGraceMinutes`); `OverdueTrigger` without `afterMinutes` fires end + grace, never for `event` tasks, nothing once done/skipped (guard + closed target). Default actions Done · Reschedule · Skip; *Reschedule* is a foreground action opening `/task/<id>?occ=…&reschedule=1`, which shows the quick-reschedule sheet (+1 h rounded to 5 min / tonight 20:00 while before 19:00 / tomorrow same time; one undoable move). Repeats use the rule repeat chain (capped by `maxNagRepeats`). Tests: `fixtures/planner/section_catalog_p1.json`, `planner_notifications_test.dart`, `quick_reschedule_test.dart`.

### T7.5.04 — Planner: up-next chain & timer-end alerts
**Priority:** P1 · **Size:** S · **Depends on:** T7.5.01, [3.2] (time tracking)
**Description:** *Up next*: at the end of a task (or N min before the next one) → "Up next: {title} at
{start_time}". *Timer end*: when a running timer reaches the planned end → "Time's up for {title}" with
Stop · +10 min; live countdown surfaces are in [8.2] T8.2.10.
**Acceptance criteria:** back-to-back tasks produce one merged "done → up next" notification, not two.
**Tests:** planner fixtures for chains and merge.
**Notes:** New triggers `up_next {beforeMinutes?}` and `timer_end` (model, codec, validation, editor fields, labels, EN/FR/AR texts). The planner source gives each timed occurrence the next open timed task starting within 3 h (`next_task_id/occurrence_key/title/start` variables). *Up next* fires at the end (or N min before the next task): "Up next: {next} at {time}" (Done · Open); back-to-back tasks get one merged "Done with {title}? Up next: …" that replaces the next task's own reminders at that instant (`_mergeUpNext`). *Timer end* fires at the planned end only while the timer runs (status in_progress), actions Stop · +10 min (`extend` extends the occurrence by 10 min; the replan re-arms the alert). Live countdowns stay in [8.2]. Tests: `section_catalog_p1.json` (up next, merge, timer end), `planner_notifications_test.dart` (neighbours, extend), codec.

### T7.5.05 — Checklists: reminders at a chosen time (lists & items)
**Priority:** P0 · **Size:** S · **Depends on:** [7.1], [7.2], [4.3]
**Description:** Absolute ("Friday 18:00") and schedule ("every Monday 09:00", via the [2.1] builder)
reminders on a checklist or any item at any depth; `scope.appliesTo` lets a checklist-level rule cover all
its open items or a parent item's descendants.
**Implementation notes:** content "{checklist_title}: {open_items} open ({done}/{total})" for lists and
"{item_text} — {parent_path}" for items; guard `item_not_completed`; actions Complete · Snooze · Open
(opens the list focused on the item).
**Acceptance criteria:** a reminder on a level-5 sub-item deep-links to that item with breadcrumbs.
**Tests:** planner fixtures; deep-link unit test.

### T7.5.06 — Checklists: waiting/blocked follow-up reminders
**Priority:** P0 · **Size:** S · **Depends on:** T7.5.05, [4.3] (status sheet with follow-up)
**Description:** When an item is marked waiting or blocked with a follow-up (quick picks tomorrow / 3 days /
next week / date), notify at `follow_up_at`: "Follow up: {item_text} — waiting {status_age}: {status_note}".
**Implementation notes:** guard `checklist_item_status_in [waiting, blocked]`; actions Mark ongoing ·
Complete · Snooze 1 day; changing the follow-up date replans immediately.
**Data model:** `{status_age}` template variable (time since `status_changed_at`) — add to the arch
§8.2 variable list.
**Acceptance criteria:** resolving the item before the follow-up cancels the reminder on all devices.
**Tests:** planner fixtures; convergence scenario (resolved on device B).

### T7.5.07 — Checklists: item & checklist due reminders
**Priority:** P1 · **Size:** S · **Depends on:** T7.5.05, [4.3] (item due dates)
**Description:** Relative triggers on `due` for items and checklists: timed due → offsets like tasks;
date-only due → "on the day at HH:MM" / "N days before at HH:MM"; optional overdue repeat.
**Tests:** planner fixtures (timed and date-only).
**Notes:** Items and checklists already carry `due` (timed or date-only, resolved in their zone); `relative` triggers on `due` give offsets, and the day form gives "on the day / N days before at HH:MM" (date-only lists and items). Overdue repeats use `overdue` + the rule repeat chain. Tests: `section_catalog_p1.json` (date-only item 1 day before at 18:00 + on the day at 09:00; timed checklist due 30 min before + hourly overdue repeats).

### T7.5.08 — Checklists: status-age escalation
**Priority:** P1 · **Size:** S · **Depends on:** T7.5.06
**Description:** `statusAge {statuses, afterMinutes}` — "Still waiting on {item_text} (3 days)" for waiting
≥ N days, "{item_text} has been blocked for 12 h" for blocked ≥ N hours; optional repeat interval; anchored
on `status_changed_at` so re-entering the status restarts the clock.
**Tests:** planner fixtures for re-entry and repeats.
**Notes:** `status_age` anchored on `status_changed_at` (re-entering the status restarts the clock, existing fixtures). Wording now follows the spec: "Still waiting on {item_text} (3 days)" / "{item_text} has been blocked for 12 h" (EN/FR/AR; whole days read as days). Repeats via the rule repeat chain. Tests: `section_catalog_p1.json`, codec, texts.

### T7.5.09 — Checklists: structural event triggers
**Priority:** P1 · **Size:** M · **Depends on:** T7.5.05, [4.5] (resettable checklists)
**Description:** Event-driven rules evaluated when the planner observes the change: **all children
complete** ("All sub-items of {item_text} are done — complete it?" with *Complete parent*), **child
overdue** (surfaced on the watched parent), **stale items/lists** (no activity for N days on open items),
**list reset** ("{checklist_title} was reset for today").
**Acceptance criteria:** completing the last child triggers at most one notification per parent per day.
**Tests:** planner fixtures using event inputs.
**Notes:** Children complete (Complete parent · Open, dedupe per parent per day), child overdue and stale were already planned from item/list events; added *list reset*: new `list_reset {atTime?}` trigger ("{checklist} was reset for today") fed by `checklist_runs` (`ChecklistsRepository.recentResets` → `list_reset` events on list targets), with editor field, labels and EN/FR/AR texts. Tests: `section_catalog_p1.json` (children complete actions + same-day dedupe, list reset at 07:00), `checklist_notifications_test.dart` (reset events).

### T7.5.10 — Habits: scheduled reminders (slots, times, several per day)
**Priority:** P0 · **Size:** M · **Depends on:** [7.1], [7.2], [5.1] (periods & slots), [5.2]
**Description:** Reminders at each intraday slot of the habit's schedule, or at one or more chosen times on
scheduled days ("08:00 and 20:00"), or every N hours in a window; quota habits ("3× per week") remind
only on eligible days while the quota is unmet.
**Implementation notes:** guard `habit_period_open` (count habits: `sum < target`); content
"{title}: {logged_today}/{target} {unit}" or "Time for {title}"; actions Done · Log value (text input
for count/duration) · Skip; paused/archived habits produce nothing.
**Acceptance criteria:** "15 push-ups daily at 07:30" fires at 07:30 only on days not yet done; logging 15
via the notification's text input completes the day.
**Tests:** planner fixtures (slots, times, quota eligibility, pauses).

### T7.5.11 — Habits: not-done-by & streak-at-risk
**Priority:** P0 · **Size:** M · **Depends on:** T7.5.10, [6.1] (streak rules)
**Description:** `notDoneBy {atTime | period_end offset}` → "You haven't logged {title} today"; `streakRisk
{atTime, minStreak}` → "Keep your {streak}-day streak alive" only when the current streak ≥ minStreak and
today's period is still open.
**Implementation notes:** both planned ahead as conditional one-shots and cancelled by replan when the
habit is logged (guard also re-checked by the server); Gentle profile by default.
**Acceptance criteria:** no streak-risk notification when the streak is below the threshold or the period
is already done, skipped or excused.
**Tests:** planner fixtures with streak inputs.

### T7.5.12 — Habits: quota pace, milestones & inactivity
**Priority:** P1 · **Size:** M · **Depends on:** T7.5.11, [5.2]
**Description:** **Quota behind pace** ("2 of 3 this week — 1 day left", fired when completions still
needed ≥ days left, "last chance" on the final eligible day); **milestones** (streak 7/30/100/365, totals
such as 1 000 push-ups — immediate on the triggering log, in-app banner if foreground); **inactivity** (no
log for N days on an active habit).
**Tests:** planner fixtures; unit tests for pace computation.
**Notes:** Each build habit also yields a habit-level summary target (no occurrence key) carrying `lastActivityAt` (last log, else creation) for inactivity plus the milestones just reached: streak 7/30/100/365 (keyed by the streak's start date, so a new streak announces again) and running totals crossing 100/500/1 000… Both are dated at the triggering log, so the planner's catch-up delivers them once; the foreground banner is the generic in-app presentation. Quota copy switches to "Last chance today" when one eligible day is left.

### T7.5.13 — Quit: milestone notifications
**Priority:** P1 · **Size:** M · **Depends on:** [5.3] (quit logic, health milestone content)
**Description:** Because clean time grows deterministically until a relapse, milestones are **projected to
exact instants** and scheduled ahead: health milestones from the [5.3] content asset (smoking only, each with
its source and the health disclaimer link), custom milestones, money-saved and units-avoided thresholds
(piecewise economics from `habit_revisions`). Content uses `{days_free}`, `{money_saved}`,
`{units_avoided}`, `{next_milestone}`.
**Implementation notes:** guard `quit_no_relapse_since {since = milestone baseline}`; a relapse replans and
cancels outstanding milestones everywhere; never shame — copy reviewed.
**Acceptance criteria:** "24 hours smoke-free" fires at quit time + 24 h; logging a relapse at +20 h
cancels it and re-projects from the relapse.
**Tests:** planner fixtures with relapse inputs.

### T7.5.14 — Quit: pledge, evening review, craving support & encouragement
**Priority:** P1 · **Size:** M · **Depends on:** T7.5.13, [6.6] (craving time patterns)
**Description:** **Daily pledge** (morning, action *Pledge* writes the pledge log), **evening review** (actions
*Clean day* · *Log relapse* · *Log craving*), **craving support** 10 min before the user's usual craving hours
(from craving-log patterns) with a coping tip, **encouragement** the morning after a relapse, **motivation**
reminders quoting the user's own `{reason}`.
**Acceptance criteria:** all off by default and individually configurable; craving support needs ≥ 10
logged cravings before it can be enabled (explained in the UI).
**Tests:** planner fixtures; unit tests for usual-hours derivation input handling.

### T7.5.15 — Notifications settings page & global controls
**Priority:** P0 · **Size:** M · **Depends on:** [8.3] (settings structure), [7.2]
**Description:** Settings › Notifications: per-section master switches (Plan, Lists, Habits, Quit, Digests)
with default profile; **quiet hours** (multiple windows per weekday, mode *defer / silent / drop*, bypass
per profile or rule); **pause all** (1 h, until tomorrow 08:00, custom, resume) with an app-bar indicator;
in-app banner toggle; snooze presets; default lateness; max nag repeats (default 5, max 10); entry points
to default-rule editors ([7.1] T7.1.14, P1), multi-device policy ([7.4] T7.4.13, P1), badge policy
([7.3] T7.3.06, P1), hide content ([8.3] T8.3.10, P1) and diagnostics ([7.2] T7.2.21, P1) as they ship.
**Acceptance criteria:** turning Habits off cancels all habit notifications on every device; quiet hours
changes replan immediately; settings sync via `user_settings.notifications`.
**Tests:** widget tests; unit tests that settings changes produce the expected replan scope (`*` or section).
**Notes:** Every settings change triggers a full replan; server jobs are re-uploaded only for targets whose plan hash changed. The per-section switch, pause and quiet hours are verified end to end in `catalog_e2e_test.dart`.

### T7.5.16 — Mute until (rule, item, list, habit, section)
**Priority:** P0 · **Size:** S · **Depends on:** T7.5.15, [7.1] (resolver)
**Description:** "Mute until…" (1 h, today, tomorrow, next week, date) on a rule, task/series, checklist,
item subtree, habit or section — from the notification action *Mute*, the inbox, and every editor's
notification section; visible mute badges with *Unmute*.
**Data model:** new synced table `app.notification_mutes (target_type, target_id, section, until
timestamptz, reason text)` with `enable_sync` (or equivalent fields); the resolver ([7.1] T7.1.06) and
planner ([7.2] T7.2.07) filter on it.
**Acceptance criteria:** muting a checklist silences all its items' reminders until the date, then they resume
without user action.
**Tests:** resolver/planner tests; pgTAP for the table.

### T7.5.17 — Notification statistics
**Priority:** P2 · **Size:** M · **Depends on:** [7.3], [6.1]
**Description:** Per rule, profile, section and target: planned, delivered (local / push / inbox-only),
opened, acted (by action), snoozed, dismissed, ignored, late %, quiet-hours deferrals, median
time-to-action; **reminder effectiveness** (habit check-ins or task starts within 60 min of a reminder) is
exposed to [6.5]; noisy-rule detection ("You ignore 90 % of this reminder — mute or change it?").
**Data model:** uses inbox fields `opened_at`, `delivered_via`, `dismissed_at`, `late` ([7.1] T7.1.01);
a local daily rollup (`stats_cache`) keeps aggregates beyond the 90-day inbox retention.
**Tests:** metric unit tests on fixture inbox data.

### T7.5.18 — Digests: agenda, plan tomorrow, overdue, weekly & monthly
**Priority:** P1 · **Size:** M · **Depends on:** T7.5.15, [8.1] (Today data), [6.7] (reports)
**Description:** Digest rules (`digest {kind, schedule}`): **morning agenda** (today's tasks, first
item, habits due), **plan tomorrow** (evening prompt with backlog/unscheduled count), **overdue summary**,
**weekly review** (opens the weekly report), **monthly report**. Default times use **off-peak minutes**
(e.g. 07:07, 20:37 plus a small per-user offset) to avoid FCM's top-of-quarter-hour spikes.
**Implementation notes:** content is rendered at plan time and refreshed on every replan (data changes
replan the next digest); push fallback uses the latest uploaded content; digests are grouped in their own
channel and never repeat.
**Acceptance criteria:** the morning agenda reflects a task added the previous night on another device
(after sync); disabling Digests removes all digest jobs.
**Tests:** planner fixtures; content rendering tests.

### T7.5.19 — Smart reminder suggestions
**Priority:** P2 · **Size:** M · **Depends on:** T7.5.17, [6.5]
**Description:** Suggest reminder times from behaviour (circular mean of usual check-in/start times, best
response times from notification stats): "You usually do push-ups around 07:45 — move the reminder to
07:30?"; optional auto-adjust with a weekly summary of changes.
**Tests:** unit tests for suggestion logic on fixture histories.

### T7.5.20 — Status-change & custom event triggers
**Priority:** P2 · **Size:** S · **Depends on:** T7.5.09
**Description:** `statusChange {from?, to}` rules on items/tasks (e.g. "when an item becomes blocked,
notify me at 18:00 to review blockers"), "task started late" and similar event triggers; foundation for
future collaboration ([9.3]).
**Tests:** planner fixtures using event inputs.
