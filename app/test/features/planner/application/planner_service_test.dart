import 'package:everslot/core/providers.dart';
import 'package:everslot/features/notifications/application/notification_host_api.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart' as n;
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/planner/application/planner_contract.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';
import '../planner_test_support.dart';

void main() {
  late TestHarness h;
  setUp(() => h = plannerHarness());
  tearDown(() => h.dispose());

  const reminder = RuleDraft(
    targetType: n.RuleTargetType.task,
    section: n.NotificationSection.planner,
    spec: NotificationRuleSpec(trigger: RelativeTrigger(anchor: TriggerAnchor.start, offsetMinutes: -10)),
  );

  test('a new task and its pending reminders are one operation (one undo)', () async {
    final draft = NotificationRulesDraft(notifyMode: n.NotifyMode.custom, rules: const [reminder]);
    final result = await h.planner.createTask(
      Task(id: '', seriesId: '', title: 'Dentist', startLocal: ldt('2026-09-23T10:00'), durationMinutes: 30),
      reminders: draft,
    );
    final rules = await h.read(notificationRulesRepositoryProvider).forTarget(n.RuleTargetType.task, result.taskId);
    expect(rules, hasLength(1));
    expect((await h.raw('tasks', result.taskId))!['notify_mode'], 'custom');
    expect(result.record.changes.map((c) => c.table), containsAll(['tasks', 'notification_rules']));
    await h.read(undoStackProvider).undo();
    expect(await h.task(result.taskId), isNull);
    expect(await h.read(notificationRulesRepositoryProvider).forTarget(n.RuleTargetType.task, result.taskId), isEmpty);
  });

  test('an empty reminders draft writes nothing extra', () async {
    final result = await h.planner.createTask(
      Task(id: '', seriesId: '', title: 'Plain', startLocal: ldt('2026-09-23T10:00'), durationMinutes: 30),
      reminders: NotificationRulesDraft(),
    );
    expect(result.record.changes.map((c) => c.table).toSet(), {'tasks', 'activity_events'});
  });

  test('the planner contract does not register undo entries (views do); the service does', () async {
    final stack = h.read(undoStackProvider);
    await h.read(plannerActionsProvider).createAt(ldt('2026-09-23T10:00'), 30, title: 'From view');
    expect(stack.canUndo, isFalse);
    await h.planner.createAt(ldt('2026-09-23T11:00'), 30, title: 'From editor');
    expect(stack.canUndo, isTrue);
  });

  test('deleting a task cascades to its reminders and mutes; restore brings them back', () async {
    final id = await h.createTask(start: '2026-09-23T10:00');
    await h.read(notificationRulesRepositoryProvider).create([reminder.copyWith(targetId: id)]);
    await h.read(notificationMutesRepositoryProvider).mute(targetType: 'task', targetId: id);
    final item = (await h.items(ld('2026-09-23'), 1)).single;
    await h.planner.delete(item);
    final live = await h.db.customSelect(
      "SELECT (SELECT COUNT(*) FROM notification_rules WHERE target_id = '$id' AND deleted_at IS NULL) AS r, "
      "(SELECT COUNT(*) FROM notification_mutes WHERE target_id = '$id' AND deleted_at IS NULL) AS m",
    ).getSingle();
    expect(live.data, {'r': 0, 'm': 0});
    await h.tasks.restoreTask(id);
    final back = await h.db.customSelect(
      "SELECT (SELECT COUNT(*) FROM notification_rules WHERE target_id = '$id' AND deleted_at IS NULL) AS r, "
      "(SELECT COUNT(*) FROM notification_mutes WHERE target_id = '$id' AND deleted_at IS NULL) AS m",
    ).getSingle();
    expect(back.data, {'r': 1, 'm': 1});
  });

  test('duplicating a task copies its own reminders', () async {
    final id = await h.createTask(start: '2026-09-23T10:00');
    await h.read(notificationRulesRepositoryProvider).create([reminder.copyWith(targetId: id)]);
    final copy = await h.planner.duplicate(id);
    final rules = await h.read(notificationRulesRepositoryProvider).forTarget(n.RuleTargetType.task, copy.newTaskId!);
    expect(rules, hasLength(1));
  });

  test('removing an exdate brings the occurrence back', () async {
    final id = await h.createTask(start: '2026-09-21T08:00', rule: RecurrenceRule(exdates: const ['2026-09-23']));
    expect(await h.items(ld('2026-09-23'), 1), isEmpty);
    await h.planner.removeExdate(id, '2026-09-23');
    expect((await h.items(ld('2026-09-23'), 1)).single.taskId, id);
    expect((await h.task(id))!.recurrence!.exdates, isEmpty);
  });

  test('overlap hint lists open check/timer occurrences of the day (T3.1.14)', () async {
    final sync = await h.createTask(title: 'Team sync', start: '2026-09-23T09:30', duration: 30);
    await h.createTask(title: 'Lunch', start: '2026-09-23T09:00', duration: 60, mode: TrackingMode.event);
    final done = await h.createTask(title: 'Done', start: '2026-09-23T09:45', duration: 30);
    await h.occurrences.markDone(done, '2026-09-23T09:45');
    final overlaps = await h.planner.overlapsFor(start: ldt('2026-09-23T09:15'), durationMinutes: 60);
    expect(overlaps.map((i) => i.taskId), [sync]);
    final excluded = await h.planner.overlapsFor(start: ldt('2026-09-23T09:15'), durationMinutes: 60, excludeTaskId: sync);
    expect(excluded, isEmpty);
    expect(OccurrenceStatus.values, isNotEmpty);
  });
}
