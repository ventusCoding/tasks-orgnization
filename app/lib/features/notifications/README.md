# Notifications (`features/notifications`)

Reminders for every task, checklist, item, habit and quit tracker — "X minutes before a task
starts **and** when it starts", nags, digests, milestones — delivered as **local notifications**
(offline, exact to the minute where the OS allows), an **in-app inbox + banners**, and **FCM push**
when Firebase and Supabase are configured (arch §6.13, ADR-005, tasks 7.1–7.5).

```text
feature sources ──targets──▶ NotificationPlanner (pure, domain/planner) ──▶ LocalNotificationScheduler ──▶ OS
      ▲                        rules × profiles × settings × mutes             (budgets, merge, diff)
      │                                     │
 guardOpen / changes                        └──▶ inbox rows (Ids.inbox(dedupeKey)) ──▶ InboxScreen, banners
                                            └──▶ server jobs (app.replace_notification_jobs) ──▶ FCM push
OS / banner / inbox / push action ──▶ NotificationActionDispatcher ──▶ your NotificationActionHandler
```

Feature teams touch this module in **four** places, all described below:

1. embed `NotificationSettingsSection` in their editors (and save drafts / cascade deletes);
2. implement a `NotificationTargetSource` per section and register it;
3. implement a `NotificationActionHandler` for their actions (`done`, `skip`, `log_value`…);
4. optionally show `ReminderHistory` / `MuteMenuButton` in detail screens.

Everything a feature needs is exported by two files:

| Import | Gives you |
|---|---|
| `features/notifications/notification_contributions.dart` | `NotificationTarget`, `NotificationTargetSource`, `NotificationGuard`, enums (`NotificationSection`, `NotificationTargetType`, `NotifyMode`, `ItemKind`…), `NotificationActionHandler`, `NotificationActionContext`, `NotificationActionResult`, `NotificationActionIds`, `NotificationPayload`, `CallbackActionHandler`, `notificationRegistryProvider`, and the `notificationContributions` list |
| `features/notifications/presentation/notification_settings_section.dart` | `NotificationSettingsSection`, `NotificationRulesDraft`, `NotificationHostApi` / `notificationHostApiProvider` |

---

## 1. The editor section (T7.1.09)

```dart
import 'package:everslot/features/notifications/presentation/notification_settings_section.dart';

// Saved item: reads/writes its rules and its `notify_mode` column directly.
NotificationSettingsSection(
  targetType: NotificationTargetType.task,    // task | checklist | checklistItem | habit
  targetId: task.id,
  section: NotificationSection.planner,       // planner | checklists | habits | quit
  itemKind: task.isAllDay ? ItemKind.allDay : ItemKind.timed, // dated items: timed/allDay/dateOnly
  categoryId: task.categoryId,                // category defaults ("Work: 15 min before")
  // checklistId: item.checklistId,           // items: rules of the list with appliesTo=items
  // ancestorItemIds: [parentId, grandParentId], // items: rules scoped to descendants
)
```

It shows the mode chips (*Use defaults / Custom / Defaults + mine / Off* = `notify_mode`), the
inherited defaults greyed with their provenance and *Customize* (copies them as own rules and
switches to *Custom*), *Add reminder* (quick chips → multiple rules at once, *Advanced…* for every
field of the spec), per-rule switches, swipe-to-delete with undo, a mute menu + badge and the
next-firings preview with *Send test notification*. The widget is a `Column`: put it in your
editor's `ListView` (or a `SliverToBoxAdapter`).

**Unsaved items (create editors)** — pass a draft and save it in the same transaction as the item:

```dart
final _reminders = NotificationRulesDraft();          // keep it in your editor State
...
NotificationSettingsSection(
  targetType: NotificationTargetType.habit,
  targetId: _newId,                                   // the id the item will be saved with
  section: NotificationSection.habits,
  draft: _reminders,
)
...
// application layer, on save — AFTER inserting the item row, in the same run():
await ref.read(syncWriterProvider).run((tx) async {
  await tx.insert('habits', _newId, {...});
  await ref.read(notificationHostApiProvider).saveDraftInTx(
    tx, _reminders, type: NotificationTargetType.habit, targetId: _newId,
  ); // inserts the rules and writes the item's notify_mode
});
```

**Deleting / duplicating items** — inside your delete (or duplicate) transaction:

```dart
final notifications = ref.read(notificationHostApiProvider);
await notifications.deleteForTargetInTx(tx, NotificationTargetType.task, taskId);   // rules + mutes
await notifications.copyRulesInTx(tx, NotificationTargetType.task, fromId: a, toId: b); // duplicate
```

**Copy reminders from… / bulk Set reminders (T7.1.15)** — pass your own item picker to show
*Copy reminders from…* in the section, and use `setReminders` from multi-select actions (one
undoable command; the items switch to *Custom* so their own rules count):

```dart
NotificationSettingsSection(
  targetType: NotificationTargetType.task,
  targetId: task.id,
  section: NotificationSection.planner,
  pickCopySource: (context) => pickTask(context),   // returns another task id or null
)

// Multi-select "Set reminders" (planner / checklists / habits):
final host = ref.read(notificationHostApiProvider);
final rules = await host.rulesOf(NotificationTargetType.task, templateTaskId);
final record = await host.setReminders(NotificationTargetType.task, selectedIds, rules);
showUndoSnackBar(context, ref, message: …, record: record);
```

Only the `notify_mode` column of your table is written by this module (through `SyncWriter`); the
four host tables already have it (default `inherit`).

---

## 2. Target sources — making your items notifiable

A `NotificationTarget` is one notifiable thing **for one occurrence** (`occurrenceKey`), or the
item itself when it doesn't recur (`occurrenceKey: null`). The planner applies the effective rules
to its **anchors** (UTC instants of that occurrence):

| Anchor | Used by | Typical source |
|---|---|---|
| `start`, `end` | tasks (relative "10 min before start", "at end", overdue) | effective occurrence times (moved occurrences use their override) |
| `due` | checklists, items | due instant (date-only: local start of day + `itemKind: dateOnly`) |
| `followUp` | waiting/blocked items | `follow_up_at` |
| `slot` | habits (one target per intraday slot) | slot instant; untimed habits: omit it (defaults use 09:00) |
| `periodStart`, `periodEnd` | habits, quotas, not-done-by, streak risk | habit period bounds |

Other fields: `status` (+ `statusChangedAt`) for `conditions.onlyIfStatusIn` and status-age
rules; `isOpen: false` when the occurrence is done/skipped (return it anyway so replans cancel its
reminders); `notifyMode`, `categoryId`, `checklistId`, `ancestorItemIds` for inheritance; `itemKind`
for timed vs all-day defaults; `timeZone` (IANA, or `null` = floating in the device zone);
`guard` (re-checked before delivery and by the server — ids/statuses only, see
`NotificationGuard.taskOccurrenceOpen`, `habitPeriodOpen`, `checklistItemStatusIn`,
`itemNotCompleted`, `quitNoRelapseSince`); `variables` for templates (`category`,
`notes_excerpt`, `checklist_title`, `item_text`, `parent_path`, `open_items`, `done`, `total`,
`progress`, `target`, `unit`, `logged_today`, `best_streak`, `money_saved`…; the planner computes
`title`, `date`, `weekday`, `start_time`, `end_time`, `duration`, `minutes_until`, `due_relative`,
`status`, `status_age`, `streak` itself); `streak`, `quota`, `milestoneBaseline` / `milestones`,
`events` for habit/quit/event triggers; `defaultActions` when neither rule nor profile sets actions;
`deepLink` (defaults: `AppLinks.task(id, occurrenceKey:)`, `AppLinks.checklist(checklistId,
itemId:)`, `AppLinks.habit(id)` / `AppLinks.quit(id)`).

```dart
// features/planner/application/planner_notification_source.dart
import 'package:everslot/features/notifications/notification_contributions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlannerNotificationSource implements NotificationTargetSource {
  PlannerNotificationSource(this._ref);

  final Ref _ref; // long-lived: use _ref.read lazily, never watch

  @override
  String get section => NotificationSection.planner.wire; // one source per section

  /// Emit whenever something that changes targets changed (the replan is debounced 1.5 s).
  /// Writes to tasks/occurrences/items/habits tables already trigger a replan; this stream is
  /// for anything else your targets depend on.
  @override
  Stream<void> get changes => _ref.read(yourPlannerChangesProvider);

  /// Every occurrence whose anchors fall in [fromUtc, toUtc] (the pipeline widens the range by
  /// the largest rule offset) + open non-recurring items. Keep it fast: it runs on every replan.
  @override
  Future<List<NotificationTarget>> targetsBetween(DateTime fromUtc, DateTime toUtc) async {
    final occurrences = await _ref.read(yourOccurrenceServiceProvider).between(fromUtc, toUtc);
    return [
      for (final o in occurrences)
        NotificationTarget(
          type: NotificationTargetType.task,
          id: o.taskId,
          section: NotificationSection.planner,
          title: o.title,
          occurrenceKey: o.occurrenceKey,               // 'YYYY-MM-DDTHH:mm'
          notifyMode: NotifyMode.parse(o.notifyMode),   // the task's notify_mode column
          categoryId: o.categoryId,
          itemKind: o.isAllDay ? ItemKind.allDay : ItemKind.timed,
          timeZone: o.timeZone,                         // null = floating
          start: o.startUtc,
          end: o.endUtc,
          status: o.status,                             // scheduled | in_progress | done | skipped…
          isOpen: o.status == 'scheduled' || o.status == 'in_progress',
          guard: NotificationGuard.taskOccurrenceOpen(o.taskId, o.occurrenceKey),
          variables: {'category': o.categoryName, 'notes_excerpt': o.notesExcerpt},
          defaultActions: const [NotificationActionIds.done, NotificationActionIds.snooze, NotificationActionIds.skip],
        ),
    ];
  }

  /// Re-check right before a banner / action / tap: false = obsolete ("Already done").
  @override
  Future<bool> guardOpen(NotificationTarget t) =>
      _ref.read(yourOccurrenceServiceProvider).isOpen(t.id, t.occurrenceKey);
}
```

### Registering (static — required for background actions)

Append **one** entry to `notificationContributions` in
`app/lib/features/notifications/notification_contributions.dart`:

```dart
import 'package:everslot/features/planner/application/planner_notification_source.dart';
import 'package:everslot/features/planner/application/planner_notification_actions.dart';

final List<NotificationContribution> notificationContributions = [
  NotificationContribution(
    sources: [PlannerNotificationSource.new],          // NotificationTargetSource Function(Ref)
    actionHandlers: [(_) => PlannerNotificationActions()], // NotificationActionHandler Function(Ref)
  ),
  // NotificationContribution(sources: [ChecklistsNotificationSource.new], actionHandlers: [...]),
  // NotificationContribution(sources: [HabitsNotificationSource.new, QuitNotificationSource.new], ...),
];
```

This list is read by the main isolate **and** by the background isolate that runs actions while
the app is killed, so factories must not depend on widgets or on providers that only exist in the
UI. Runtime registration (`ref.read(notificationRegistryProvider).registerSource(...)`) exists for
tests, the debug menu and optional sources; it is invisible to the background isolate. For the same
action and target type a runtime-registered handler takes precedence over a static one (main
isolate only).

---

## 3. Action handlers

Buttons on OS notifications, pushes, in-app banners and inbox rows all go through
`NotificationActionDispatcher`, which handles the generic actions itself — `snooze`, `open`/tap,
`mute_rule`, `mark_read`, `dismiss` — and forwards the others (`done`, `start`, `stop`, `skip`,
`reschedule`, `log_value`, `log_craving`, `complete_item`, `mark_ongoing`, `mark_waiting`,
`mark_blocked`; see `NotificationActionIds`) to the most specific registered handler
(`targetTypes` match first, `null` = any type). Without a handler the target is opened instead.

```dart
// features/planner/application/planner_notification_actions.dart
class PlannerNotificationActions implements NotificationActionHandler {
  @override
  Set<NotificationTargetType> get targetTypes => {NotificationTargetType.task};

  @override
  Set<String> get actionIds => {
    NotificationActionIds.done, NotificationActionIds.skip, NotificationActionIds.start, NotificationActionIds.stop,
  };

  @override
  Future<NotificationActionResult> handle(NotificationActionContext c) async {
    // c.targetId / c.occurrenceKey / c.payload identify the occurrence; c.input is the text typed
    // in the notification (log_value, log_craving); c.now is the clock; c.read reads providers in
    // BOTH isolates (c.fromBackground tells which).
    final occurrences = c.read(yourOccurrenceServiceProvider);   // the SAME service as the UI
    switch (c.actionId) {
      case NotificationActionIds.done:
        await occurrences.complete(c.targetId!, c.occurrenceKey!, cause: 'notification');
      case NotificationActionIds.skip:
        await occurrences.skip(c.targetId!, c.occurrenceKey!, cause: 'notification');
      default:
        return NotificationActionResult(openLink: c.payload.deepLink); // open the app
    }
    return NotificationActionResult.ok; // marks the inbox row acted + stops the nag chain
  }
}
```

Rules for handlers:

- **Idempotent** per `(dedupeKey, action)` — the dispatcher already drops exact repeats, but the
  same action can arrive from two devices; write "done" states, not toggles.
- Write through `SyncWriter` using `cause: 'notification'` (and `source: 'notification'` on log
  rows such as `habit_logs`), exactly like the UI would.
- Invalid input (e.g. `log_value` with "12a"): `return NotificationActionResult.failed(message)` —
  from the background the message is posted as a follow-up notification. Localize with
  `c.read(notificationTextsProvider).l10n` (`application/notification_providers.dart`; the user's
  language, works in the background).
- Return `NotificationActionResult(markActed: false)` when the action must not stop a nag chain.
- After every action the dispatcher replans the target, reconciles the inbox and marks the target
  dirty for the server job upload — handlers do nothing about notifications themselves.
- Tests: `CallbackActionHandler(actionIds: {...}, targetTypes: {...}, onHandle: (c) async => ...)`.

---

## 4. Other building blocks

| Widget / API | Use |
|---|---|
| `NotificationsSettingsPage()` (`presentation/notifications_settings_page.dart`) | Settings › Notifications: per-section switches + default profile, pause all, quiet hours, banners, snooze presets, lateness, max nags, date-only default time, digests, multi-device policy, badge policy, hide content, mutes, entry points to *Default reminders*, *Profiles*, *Diagnostics*. `embedded: true` renders only the list (host provides the `Scaffold`). |
| `InboxScreen()` | `/inbox` (bell in `AppBarActions`); unread count: `inboxUnreadCountProvider`. |
| `ReminderHistory(sourceType: 'task', sourceId: id)` | "Reminder history" in detail screens (T7.3.09). |
| `MuteMenuButton(targetType: 'habit', targetId: id)` / `MuteBadge(...)` | "Mute until…" anywhere (T7.5.16); `targetType`: `rule`, `task`, `checklist`, `checklist_item`, `habit`, `section` (+ `section:`). |
| `showNotificationPrimer(context, ref)` (`presentation/permission_primers.dart`) | Onboarding / in-context permission primer (never twice per session). `NotificationPermissionBanner()` shows recovery states. |
| `notificationSettingsProvider` | Typed `user_settings.notifications` (+ `privacy.hideContentInNotifications`). |

Startup: `startNotifications` (in `startup/startup_tasks.dart`) seeds the built-in profiles and
section defaults, starts every replan trigger, reconciles fired notifications into the inbox,
handles cold starts from a notification, starts push when configured and installs the banner
overlay. It restarts on account switches.

Push (FCM) activates only when `FIREBASE_ENABLED` is true, `AppFirebaseOptions.isConfigured` (generated `lib/firebase/firebase_options_<flavor>.dart`),
Supabase is configured and a cloud session exists (`pushAvailableProvider`); otherwise local
notifications and the inbox work fully offline. Data messages the device understands:
`{"type":"sync","head":…}` (pull + replan), `{"type":"cancel","dk":<dedupe key>}` (drop that
reminder from the tray right away — completed on another device) and visible reminders
(`reminder | nag | digest | milestone`, shown by the OS; foreground → banner + inbox row).

## 5. Testing your integration

```dart
final h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 6));
await seedNotificationDefaults(h.read);                   // built-in profiles + section defaults
final source = InMemoryNotificationTargetSource(section: 'planner', targets: [gymAt8]);
h.read(notificationRegistryProvider).registerSource(source);
await h.read(notificationPipelineProvider).run('test');   // plans + schedules
final port = h.read(localNotificationsPortProvider) as InMemoryLocalNotificationsPort;
expect(port.scheduled.values.map((r) => r.fireAt), containsAll([at(7, 50), at(8, 0)]));
```

(`seedNotificationDefaults` and `notificationPipelineProvider` live in
`application/notifications_engine.dart`; see `test/features/notifications/application/` for
complete examples.)

`InMemoryLocalNotificationsPort` records every platform call (scheduled, shown, cancelled,
channels, categories) and `respond(OsResponse(...))` simulates a tap or an action button.
