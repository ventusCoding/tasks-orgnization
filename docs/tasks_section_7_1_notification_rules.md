# Section 7.1 — Notification Rules, Profiles & Editors

> Milestones: M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 1.2, 1.3, 1.4, 2.1, 2.3, 3.1, 4.1, 5.1
> Architecture: §6.13 (concepts, profiles), §7.3 (notification tables), §8.2 (rule spec), §8.5 (settings), §13 ADR-005

## Goal

Give the user **100 % free configuration** of every reminder in the app: any number of rules per task,
checklist, checklist item, habit or quit tracker (e.g. "10 minutes before the task starts" **and** "when it
starts"), reusable delivery **profiles**, defaults at global / section / category level that items inherit,
and editors that are one tap simple for common cases yet expose every dimension (triggers, offsets,
repeats, conditions, channels, sound, priority, actions, snooze, lateness, content) for power use. This
section defines the *data and the editors*; delivery lives in [7.2] (local), [7.3] (inbox) and [7.4] (push),
and the per-section trigger catalog in [7.5].

## Scope

**In:** migrations for `notification_profiles`, `notification_rules`, `notifications`; Drift mirror and
repositories; the rule-spec domain model (sealed trigger union, repeat, conditions, delivery, content) with
JSON v1 codec and validation; noise guard; built-in and custom profiles with per-field
inherit / set / disable semantics; the inheritance resolver (global → section → category → parent
checklist / item → item → occurrence); default-rule seeding; template engine; the notification section
embedded in every editor, the simple and advanced rule editors, default-rule editors; snapshot
("Customize") vs live inheritance; occurrence overrides (P2); content variants (P2).
**Out:** Planning and OS scheduling ([7.2]); inbox UI ([7.3]); FCM, jobs and dispatcher ([7.4]); concrete
trigger semantics per section and global controls such as quiet hours ([7.5]).

## Rule-spec conventions (normative for this section)

- A rule = `spec` (arch §8.2) + optional `profile_id`. **Absent field = inherit** (from the profile, then
  from the section default profile, then from built-in fallbacks); **present field = set**; the
  **disable sentinel** of each field (`"none"` for sound/vibration, `[]` for actions, `false` for
  `repeat`/`banner`/`system`/`inbox`) = explicitly off.
- Additive spec fields introduced here (still `"v": 1`, optional, ignored by older decoders):
  `scope.appliesTo` (`self | items | descendants | self_and_descendants`) for checklist/item rules;
  `conditions.itemKind` (`timed | all_day | date_only | any`) for timed vs all-day defaults;
  `conditions.occurrenceKeys` (P2 occurrence overrides); `delivery.latenessMinutes`;
  `delivery.interruptionLevel` override; `delivery.relevance` (0–1); `content.variants` (P2).
- Rules never contain free text other than `name` and `content` templates; guards and conditions reference
  ids and statuses only (keeps the door open for E2EE, [9.3]).

## Progress

- [x] T7.1.01 — Server migrations: profiles, rules, inbox
- [x] T7.1.02 — Drift tables, DAOs & repositories
- [x] T7.1.03 — Rule-spec domain model & JSON v1 codec
- [x] T7.1.04 — Rule validation & noise guard
- [x] T7.1.05 — Built-in profiles & per-field inheritance semantics
- [x] T7.1.06 — Inheritance resolver (effective rules per target)
- [x] T7.1.07 — Default rules & profiles seeding
- [x] T7.1.08 — Content template engine
- [x] T7.1.09 — Notification section component (in every editor)
- [x] T7.1.10 — Simple rule editor (quick chips & offsets)
- [x] T7.1.11 — Next-firings preview & test notification
- [x] T7.1.12 — Advanced rule editor
- [x] T7.1.13 — Custom profiles editor
- [x] T7.1.14 — Section & category default-rule editors
- [x] T7.1.15 — "Customize" snapshot, bulk apply & copy rules
- [x] T7.1.16 — Occurrence-level overrides
- [x] T7.1.17 — Motivational content variants
- [x] T7.1.18 — Rule sets (reusable bundles) & export/import

## Tasks

### T7.1.01 — Server migrations: profiles, rules, inbox
**Priority:** P0 · **Size:** M · **Depends on:** [1.2] (`app.enable_sync`, pgTAP harness)
**Description:** Create `app.notification_profiles`, `app.notification_rules` and `app.notifications`
exactly as arch §7.3 (plus the gaps below), each wired with `app.enable_sync(...)` (common columns,
triggers, `(user_id, rev)` index, RLS).
**Implementation notes:**
- Checks: `target_type`/`section` enums; `target_id is null` iff `target_type in ('section','global')`;
  `notifications.category` enum; `unique (user_id, dedupe_key)` on the inbox.
- Indexes: rules `(user_id, target_type, target_id) where deleted_at is null`; inbox
  `(user_id, fire_at desc)`, `(user_id) where read_at is null and deleted_at is null` (unread badge).
- Built-in profile rows use deterministic ids `uuidv5(user_id | 'profile' | code)` (T7.1.07).
**Data model:** `notification_profiles.code text` (nullable, unique per user — `gentle`,
`standard`, `nag`, `alarm`) to identify built-ins; add to `notifications`: `section text`
(planner/checklists/habits/quit/system — inbox filters without joins), `dismissed_at timestamptz`,
`opened_at timestamptz` (tapped from the OS), `late boolean not null default false`,
`delivered_via text[]` (`local`, `push`, `inbox_only`) for notification stats ([7.5]).
**Acceptance criteria:** `supabase db reset` applies cleanly; RLS isolation holds for all three tables;
rows round-trip through `sync_push`/`sync_pull`.
**Tests:** pgTAP: constraints, RLS cross-user denial, sync trigger presence (covered by the completeness
check in [9.1] T9.1.06), unique dedupe key per user.
**Notes:** Built with the app foundation (`supabase/migrations/20260922000100_create_notifications.sql`, also `notification_mutes` and the private jobs/deliveries tables); pgTAP coverage in `020_rls_completeness` and `070_domain_constraints`.

### T7.1.02 — Drift tables, DAOs & repositories
**Priority:** P0 · **Size:** M · **Depends on:** T7.1.01, [1.4]
**Description:** Mirror the three tables in Drift (with the synced-table mixin), plus DAOs and
repositories: `NotificationProfilesRepository`, `NotificationRulesRepository` (watch by target, by section
defaults, by category), `InboxRepository` (used by [7.3]).
**Implementation notes:** writes go through the sync writer (row + outbox + `activity_events` for rule
create/update/delete); JSON columns use the codecs of T7.1.03 via Drift type converters; every rule change
emits a `NotificationTargetsChanged(targetKeys)` event consumed by the replan orchestrator ([7.2]).
**Acceptance criteria:** creating a rule on device A appears on device B after sync and triggers a replan
there; deleting an item soft-deletes its rules in the same transaction.
**Tests:** in-memory Drift DAO tests; repository tests with fake clock; cascade test (item delete → rules).
**Notes:** Replans are triggered by `SyncWriter.committed` (local writes) and Drift `tableUpdates` on the notification-relevant tables (pulled rows) instead of a dedicated `NotificationTargetsChanged` event; item cascades go through `NotificationHostApi.deleteForTargetInTx` (planner, checklists, habits call it).

### T7.1.03 — Rule-spec domain model & JSON v1 codec
**Priority:** P0 · **Size:** L · **Depends on:** T7.1.02, [2.1] (recurrence rule model)
**Description:** Pure-Dart freezed model of arch §8.2 in `features/notifications/domain`:
`NotificationRuleSpec {trigger, repeat?, conditions, delivery, content, scope?}` with a **sealed trigger
union**: `relative` (anchor `start | end | due | follow_up | slot | period_start | period_end`,
`offsetMinutes` **or** `dayOffset + atTime`), `absolute`, `schedule` (recurrence §8.1), `notDoneBy`,
`statusAge`, `overdue`, `streakRisk`, `quotaBehind`, `milestone`, `inactivity`, `digest`, `statusChange`,
`childrenComplete`, `childOverdue`, `stale`.
**Implementation notes:**
- Multiple offsets are multiple rules (one trigger per rule) — the UI groups them (T7.1.09); this keeps
  `dedupe_key` derivation simple (`trigger_idx` = 0 today; reserved for future multi-trigger rules).
- `repeat {everyMinutes ∈ {1,5,10,15,30,60} or custom ≥ 1, maxTimes ≤ 10, until: acknowledged | completed | max}`.
- `delivery {system, inbox, banner, importance min|low|default|high|urgent, interruptionLevel?, relevance?,
  sound, vibration, sticky, alarmStyle, actions[], snoozeOptionsMinutes[], latenessMinutes}`.
- Codec: `"v": 1`, unknown keys preserved on round-trip, additive fields from the conventions above.
**Acceptance criteria:** every example in arch §8.2 and every trigger variant round-trips byte-identically;
unknown future fields survive decode → encode.
**Tests:** codec fixtures (`fixtures/notifications/specs/*.json`), sealed-union exhaustiveness tests.
**Notes:** Hand-written immutable model (ADR-016, no freezed); the codec fixtures (arch §8.2 example + every trigger variant, byte-identical) are inline in `rule_spec_codec_test.dart`.

### T7.1.04 — Rule validation & noise guard
**Priority:** P0 · **Size:** M · **Depends on:** T7.1.03, [7.2] (planner, for the noise estimate)
**Description:** Typed validation issues (localized by the UI) and a **noise estimate** so free
configuration can't silently flood the user or exhaust OS budgets.
**Implementation notes:**
- Issues: anchor not available for the target type (e.g. `due` on a task without due), offset beyond
  ±30 days, `repeat.maxTimes > 10`, more than **3 actions** (Android limit) — extra actions are allowed on
  iOS only if the user explicitly accepts "Android shows the first 3", unknown template variable, empty
  content, `schedule` rule invalid (delegates to [2.1] validator), lateness < 1 min.
- Noise estimate: run the planner ([7.2] T7.2.06) for the rule over the next 7 days → fires/day. Warn above
  48/day, require explicit confirmation above 96/day, hard cap 1 440/day per rule and a per-user cap on
  planned notifications per day (configurable, default 500) with a clear message.
- Warn when a rule's fire times cluster at the same minute as many others (Android plays one sound per second).
**Acceptance criteria:** Save is disabled with inline errors for invalid specs; warnings never block saving
below the hard cap; estimate computed < 100 ms for a daily rule.
**Tests:** table-driven validator tests; noise estimate tests with minutely/hourly rules.

### T7.1.05 — Built-in profiles & per-field inheritance semantics
**Priority:** P0 · **Size:** M · **Depends on:** T7.1.03
**Description:** Profiles bundle delivery/repeat/content defaults. Built-ins: **Gentle** (low importance /
iOS passive, no sound, inbox + system), **Standard** (default importance / active, default sound, actions
Done · Snooze · Skip), **Nag-until-done** (high / time-sensitive when allowed, repeat every 5 min up to 5×
until completed), **Alarm** (P2 — defined but hidden until [7.2] T7.2.21). A rule's effective delivery =
built-in fallback ← section default profile ← rule profile ← rule fields (arch §6.13 *Profiles*).
**Implementation notes:** `EffectiveDelivery resolveDelivery(rule, profile?, sectionDefault?)` pure
function implementing absent/set/disable; importance → Android channel importance and iOS interruption
level mapping table (min/low → passive, default → active, high/urgent → timeSensitive when the capability
is granted else active) lives here and is reused by [7.2]/[7.4].
**Acceptance criteria:** a rule with `sound: "none"` over the Standard profile is silent; removing the field
restores the profile sound; changing a profile updates every rule that inherits (live inheritance).
**Tests:** exhaustive resolution table tests (field × absent/set/disable × profile chain).
**Notes:** The Alarm profile is defined but hidden in pickers until T7.2.24.

### T7.1.06 — Inheritance resolver (effective rules per target)
**Priority:** P0 · **Size:** M · **Depends on:** T7.1.05, [2.3] (categories)
**Description:** `EffectiveRulesResolver.forTarget(target) → List<EffectiveRule>` implementing the
precedence **global → section → category → parent checklist / ancestor item → item → occurrence** and the
item's `notify_mode`: `inherit` (defaults only), `custom` (own rules only), `inherit_plus` (defaults + own),
`off` (nothing).
**Implementation notes:**
- Defaults are rules with `is_default = true` and `target_type ∈ {global, section, category}`; for
  checklist items, rules on the checklist with `scope.appliesTo = items` and on ancestor items with
  `descendants` / `self_and_descendants` apply (nearest ancestor wins for identical trigger kinds).
- Filters: `conditions.itemKind` (timed vs all-day vs date-only defaults), section enabled toggle
  (`user_settings.notifications.perSection`), active mutes ([7.5] T7.5.16), rule `enabled`.
- Output rules carry provenance (`own | category | section | global | ancestor`) for the UI.
- Pure and memoized per target revision; recomputed when rules/settings/category change.
**Acceptance criteria:** switching an item from `inherit` to `custom` removes default rules from its plan;
a category default ("Work: 15 min before") applies to Work tasks only; `off` yields zero notifications.
**Tests:** resolver unit tests over a fixture matrix (item type × notify_mode × defaults × mutes).

### T7.1.07 — Default rules & profiles seeding
**Priority:** P0 · **Size:** S · **Depends on:** T7.1.05, T7.1.06
**Description:** On first run (and idempotently after), create built-in profiles and section default rules
with deterministic ids (`uuidv5(user_id | 'default-rule' | section | code)`) so two devices seeding
offline converge instead of duplicating.
**Implementation notes (defaults, all editable):** Planner timed: *10 min before start* + *at start*
(Standard) — the user's own example; Planner all-day/date-only: *on the day at 09:00*; Checklists:
*follow-up at `follow_up_at`* (Standard) and *at due* (P1 once item due dates exist); Habits: *at each
scheduled slot time* (or 09:00 on scheduled days when the habit has no time) + *streak at risk at 21:00*
(Gentle); Quit: milestone notifications (enabled when [7.5] T7.5.13 ships); digests off by default
(offered during onboarding [8.3]). Default time-of-day values respect `profiles.time_format` in the UI only.
**Data model:** `notifications.dateOnlyDefaultTime` (default `09:00`, arch §8.5).
**Acceptance criteria:** fresh account → a new timed task gets exactly two reminders; two offline devices
seeding simultaneously end with one set of defaults after sync.
**Tests:** seeding idempotency test; two-client convergence scenario added to [9.1] T9.1.03 fixtures.
**Notes:** Checklist *at due* (item due dates exist) and quit *milestones* defaults are seeded too.

### T7.1.08 — Content template engine
**Priority:** P0 · **Size:** M · **Depends on:** T7.1.03, [1.3] (l10n)
**Description:** Render `content.title/body` templates into final strings at planning time with locale
formatting, plurals and redaction.
**Implementation notes:**
- Variables (arch §8.2 + research): `{title} {parent_path} {start_time} {end_time} {date} {weekday}
  {minutes_until} {due_relative} {duration} {category} {notes_excerpt} {status} {status_note} {reason}
  {checklist_title} {item_text} {open_items} {done}/{total} {progress} {target} {unit} {logged_today}
  {remaining_in_period} {streak} {best_streak} {clean_time} {days_free} {money_saved} {units_avoided}
  {next_milestone}`; each variable declares which target types provide it (editor validation).
- Locale-aware (`intl`), 12/24 h per profile, ICU plurals (Arabic 6 forms), bidi isolation of user text
  inside RTL sentences, length budgets (title ≤ 64 chars, body ≤ 178 chars before truncation; push payload
  budget enforced in [7.4]).
- Built-in localized default templates per trigger kind (EN/FR/AR ARB keys) when a rule has no content.
- **Redaction:** when `privacy.hideContentInNotifications` ([8.3] T8.3.10) is on, system content becomes
  generic ("Reminder from Everslot"); inbox keeps full text.
- `{minutes_until}` is computed relative to the fire time (never "now") so pre-scheduled text stays correct.
**Acceptance criteria:** golden renders for every default template in EN/FR/AR; unknown variables render
literally and are flagged by T7.1.04.
**Tests:** template unit tests incl. plurals, RTL mixed text, truncation, redaction.
**Notes:** Every default template is verified as text in EN/FR/AR (`notification_texts_test.dart`) rather than image goldens.

### T7.1.09 — Notification section component (in every editor)
**Priority:** P0 · **Size:** M · **Depends on:** T7.1.06, T7.1.10, [3.1], [4.2], [5.1]
**Description:** A reusable "Notifications" section embedded in the task editor, checklist editor, item
details sheet, habit editor and quit editor: mode selector (*Use defaults / Custom / Defaults + mine / Off*
= `notify_mode`), the list of effective rules (inherited ones shown greyed with their provenance and a
*Customize* action), *Add reminder* (opens T7.1.10), per-rule enable toggle, swipe to delete with undo.
**Implementation notes:** summaries read naturally ("10 min before start · Standard", "Every day at 21:00 if
not done · Gentle"); max 3 visible + "Show all"; works for unsaved drafts (rules saved with the item in one
transaction).
**Acceptance criteria:** a user can add "10 min before" and "at start" to a task in ≤ 4 taps; the section is
identical in all editors apart from the anchors offered.
**Tests:** widget tests per host editor; golden light/dark/RTL.
**Notes:** Hosted by the task editor, checklist settings, item details, habit and quit editors.

### T7.1.10 — Simple rule editor (quick chips & offsets)
**Priority:** P0 · **Size:** M · **Depends on:** T7.1.04, T7.1.05, [1.3] (pickers)
**Description:** Bottom sheet with quick chips tailored to the target: tasks → *At start*, *5 / 10 / 15 /
30 / 60 min before*, *At end*, *Custom offset…*; all-day/date-only → *On the day at…*, *1 day before at…*;
checklist items → *At due*, *At follow-up*, *At a time…*, *Every … (schedule)*; habits → *At slot time*,
*At…*, *If not done by…*; quit → *Daily at…*, *Milestones*. Plus profile picker (Gentle / Standard / Nag /
custom) and the 3 most important delivery toggles (sound, system notification, inbox).
**Implementation notes:** custom offset = number + unit (minutes, hours, days, weeks) + before/after +
anchor; "N days before at HH:MM" form; absolute date-time picker; schedule via the [2.1] builder;
multiple selections create multiple rules at once.
**Acceptance criteria:** any relative offset from 1 minute to 30 days, before or after any available anchor,
can be created without the advanced editor; validation messages inline.
**Tests:** widget tests for each chip set; integration test creating two reminders on a task.

### T7.1.11 — Next-firings preview & test notification
**Priority:** P0 · **Size:** S · **Depends on:** T7.1.10, [7.2] (planner)
**Description:** Every rule and the whole notification section show the **next 5 firing times** with reasons
("Mon 22 Sep · 08:50 — 10 min before start"), skipped ones with the reason (quiet hours, guard already
satisfied, paused) and a *Send test now* button (fires a real local notification in 5 s using the rule's
effective delivery and rendered content).
**Acceptance criteria:** preview matches what the planner schedules (same code path); test notification
shows the configured actions and sound on the device.
**Tests:** unit test comparing preview output with planner output; manual QA script entry.
**Notes:** Preview and planner share `NotificationPlanner.plan` (`application/rule_preview.dart`); *Send test* schedules a real local notification 5 s ahead.

### T7.1.12 — Advanced rule editor
**Priority:** P1 · **Size:** L · **Depends on:** T7.1.10, T7.1.08
**Description:** Full editor for every dimension of the spec: trigger type and parameters (all variants of
T7.1.03), repeat/nag (interval, max ≤ 10, until acknowledged/completed), conditions (status filter,
weekdays, time window with drop/shift, respect quiet hours, item kind, devices), delivery (system / inbox /
banner, importance, interruption level, relevance, sound from the curated list, vibration, sticky,
actions ≤ 3 with order, snooze presets, lateness/TTL minutes), content (title/body templates with a
variable picker filtered by target type, live preview in the user's locale, redaction preview).
**Implementation notes:** sections collapse by default; each field shows *Inherited from <profile>* with
*Override* / *Disable* / *Reset*; Android-specific and iOS-specific fields are labelled.
**Acceptance criteria:** every field of arch §8.2 plus the conventions above is editable; round-trip edit
of a complex rule changes nothing when saved without edits.
**Tests:** widget tests for field groups; golden per section of the editor; round-trip test.
**Notes:** Each field uses an inherit dropdown: empty means *Inherited from <profile>*, a value overrides it, and the field's sentinel (`none`, `[]`, `false`) disables it. Android and iOS fields are badged.

### T7.1.13 — Custom profiles editor
**Priority:** P1 · **Size:** M · **Depends on:** T7.1.05, T7.1.12
**Description:** Create, rename, duplicate, reorder and delete custom profiles (built-ins can be duplicated,
not deleted); each profile edits delivery/repeat/content defaults with the same field widgets as T7.1.12.
**Implementation notes:** changing a profile's importance or sound creates a **new Android channel id**
(channels are immutable, [7.2] T7.2.02) — warn the user that the old channel will appear as deleted in
system settings; rules keep the profile reference.
**Acceptance criteria:** deleting a profile in use asks where to move its rules; built-ins can't be deleted.
**Tests:** widget tests; unit test for channel-id versioning on profile change.
**Notes:** Reordering writes one sort key after the new visible neighbour, so hidden profiles keep their place.

### T7.1.14 — Section & category default-rule editors
**Priority:** P1 · **Size:** M · **Depends on:** T7.1.06, T7.1.12
**Description:** Settings › Notifications › *Plan / Lists / Habits / Quit / Categories*: edit the default
rules and default profile per section, separate lists for timed vs all-day vs date-only items, category
defaults (e.g. "Work: 15 min before + at start"), with an impact preview ("affects 42 tasks that use
defaults").
**Acceptance criteria:** editing a default replans all inheriting targets; items in `custom` mode are unaffected.
**Tests:** widget tests; integration test that a default change reschedules inheriting tasks only.

### T7.1.15 — "Customize" snapshot, bulk apply & copy rules
**Priority:** P1 · **Size:** S · **Depends on:** T7.1.09
**Description:** *Customize* copies the inherited rules into the item as its own (snapshot) and switches it to
`custom`; *Copy reminders from…* another item; bulk *Set reminders* on multi-selected tasks/items/habits
(from [3.1]/[4.2] multi-select).
**Acceptance criteria:** snapshot rules no longer change when defaults change; bulk apply is one undoable command.
**Tests:** unit tests for snapshot/copy; undo test.
**Notes:** Hosts expose the features: `NotificationSettingsSection(pickCopySource:)` for *Copy reminders from…* and `NotificationHostApi.setReminders` for multi-select *Set reminders* (TODO(integration): planner, checklists and habits wire their item picker and multi-select action).

### T7.1.16 — Occurrence-level overrides
**Priority:** P2 · **Size:** M · **Depends on:** T7.1.12, [3.2]
**Description:** From an occurrence sheet: "For this occurrence only" add/disable reminders (e.g. remind me
1 h before *this Tuesday's* meeting) using `conditions.occurrenceKeys` rules and a per-occurrence disable list.
**Data model:** either allow `target_type = 'task_occurrence'` in `notification_rules` or keep
`target_type = 'task'` + `conditions.occurrenceKeys`; plus a disable list (`spec.conditions.excludeOccurrenceKeys`).
**Acceptance criteria:** overrides apply to that occurrence only and survive series edits that keep the key.
**Tests:** resolver + planner tests with occurrence keys.
**Notes:** Kept `target_type = 'task'` + `conditions.occurrenceKeys`. Occurrence rules apply in every notify mode but *off*; a disabled occurrence rule switches off the identical trigger (inherited or own) for that occurrence, and the item's own rules use `excludeOccurrenceKeys` (`OccurrenceOverrides`). UI: *Reminders for this occurrence* on a recurring occurrence's detail screen. Series splits copy the task's rules, so overrides follow the keys.

### T7.1.17 — Motivational content variants
**Priority:** P2 · **Size:** S · **Depends on:** T7.1.08
**Description:** `content.variants[]` — the planner picks one deterministically per occurrence (seeded by
dedupe key) to avoid monotony; curated localized packs for habits and quit (e.g. uses `{reason}` from the
quit tracker's motivation).
**Tests:** determinism test (same occurrence → same variant on every device).
**Notes:** Explicit `content.variants[]` or a curated `content.pack` (`habit_motivation`, `quit_motivation`, EN/FR/AR body variants); the planner keeps only the variants whose `{variables}` the target has (no `{reason}` without a motivation) and picks one from the first 32 bits of the dedupe key. Picker: *Rotating messages* in the advanced editor's content section.

### T7.1.18 — Rule sets (reusable bundles) & export/import
**Priority:** P2 · **Size:** S · **Depends on:** T7.1.15
**Description:** Save the rules of an item as a named *rule set* (e.g. "Meeting style: 1 day before at 20:00,
15 min before, at start") and apply it anywhere; export/import rule sets as JSON files.
**Tests:** round-trip export/import; apply test.
**Notes:** Stored in the synced `user_settings.notification_rule_sets` namespace (whole-value LWW — fine for rarely edited sets); profiles travel by code (custom profiles fall back to the rule default). *Rule sets* button in every item's reminders section (save / apply — applying replaces the item's own reminders and switches it to Custom, drafts included) and Settings › Notifications › Rule sets (rename, export via the share sheet, delete, import a `.json`).
