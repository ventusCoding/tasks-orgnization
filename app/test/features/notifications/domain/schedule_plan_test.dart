import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/planner/planned_notification.dart';
import 'package:everslot/features/notifications/domain/scheduler/schedule_plan.dart';
import 'package:flutter_test/flutter_test.dart';

PlannedNotification planned(
  String id,
  DateTime at, {
  bool system = true,
  bool inbox = true,
  bool local = true,
  int repeat = 0,
  NotificationImportance importance = NotificationImportance.normal,
}) {
  final key = dedupeKeyFor(
    ruleId: 'r',
    targetId: id,
    occurrenceKey: '',
    repeatIdx: repeat,
  );
  return PlannedNotification(
    dedupeKey: key,
    baseKey: repeat == 0
        ? key
        : dedupeKeyFor(ruleId: 'r', targetId: id, occurrenceKey: ''),
    targetKey: 'task:$id',
    targetType: NotificationTargetType.task,
    targetId: id,
    ruleId: 'r',
    occurrenceKey: '',
    triggerType: 'relative',
    fireAt: at,
    expiresAt: at.add(const Duration(minutes: 30)),
    category: repeat > 0 ? InboxCategory.nag : InboxCategory.reminder,
    section: NotificationSection.planner,
    channelId: 'dl.planner.standard.v1',
    importance: importance,
    interruptionLevel: InterruptionLevel.active,
    relevance: 0.5,
    sound: 'default',
    vibration: 'default',
    sticky: false,
    alarmStyle: false,
    actions: const ['done', 'snooze'],
    snoozeOptions: const [10],
    title: id,
    body: null,
    inboxTitle: id,
    inboxBody: null,
    threadId: 'sec:planner',
    deepLink: '/task/$id',
    guard: NotificationGuard.always,
    deliverSystem: system,
    deliverInbox: inbox,
    deliverBanner: true,
    scheduleLocally: local,
    repeatIdx: repeat,
    userId: 'u',
  );
}

List<DesiredItem> desired(
  List<PlannedNotification> p, {
  ScheduleBudget budget = ScheduleBudget.android,
  bool merge = true,
}) => ScheduleComputation.desired(
  p,
  budget: budget,
  sentinelTitle: 'Open',
  mergedTitle: (n) => '$n',
  merge: merge,
);

ScheduleEntry entryFor(DesiredItem d, {int? id, DateTime? scheduledAt}) =>
    ScheduleEntry(
      dedupeKey: d.key,
      platformId: id ?? PlatformIds.hash(d.key),
      fireAt: d.fireAt,
      targetKey: d.targetKey,
      kind: d.kind,
      os: d.os,
      hash: d.hash,
      scheduledAt: scheduledAt ?? DateTime.utc(2026),
    );

void main() {
  final t0 = DateTime.utc(2026, 9, 22, 8);

  test(
    'iOS budget: 2 000 instances → 55 soonest + sentinel; Android keeps 250',
    () {
      final many = [
        for (var i = 0; i < 2000; i++)
          planned('t$i', t0.add(Duration(minutes: 2 * i + 1))),
      ];
      final ios = desired(many, budget: ScheduleBudget.ios);
      final osIos = ios.where((d) => d.os).toList();
      expect(osIos, hasLength(56));
      expect(osIos.where((d) => d.kind == ScheduleKind.sentinel), hasLength(1));
      final regular = osIos
          .where((d) => d.kind != ScheduleKind.sentinel)
          .map((d) => d.fireAt)
          .toList();
      expect(regular.last, many[54].fireAt);
      expect(
        osIos.firstWhere((d) => d.kind == ScheduleKind.sentinel).fireAt,
        many[55].fireAt,
      );
      final android = desired(many);
      expect(android.where((d) => d.os), hasLength(250));
      expect(android.where((d) => d.os).last.fireAt, many[249].fireAt);
      // Everything beyond the budget is still tracked for the inbox.
      expect(android.where((d) => !d.os), hasLength(1750));
    },
  );

  test('nags use the reserved iOS slots first', () {
    final items = [
      for (var i = 0; i < 60; i++)
        planned('t$i', t0.add(Duration(minutes: 2 * i + 1))),
      planned('n', t0.add(const Duration(hours: 20)), repeat: 1),
    ];
    final ios = desired(items, budget: ScheduleBudget.ios);
    expect(ios.where((d) => d.os && d.kind == ScheduleKind.nag), hasLength(1));
  });

  test('same-minute reminders merge into one OS notification; members stay tracked', () {
    final items = [
      planned('a', t0),
      planned('b', t0.add(const Duration(seconds: 20))),
      planned('c', t0.add(const Duration(seconds: 40))),
      planned('d', t0.add(const Duration(minutes: 1))),
    ];
    final d = desired(items);
    final merged = d.where((x) => x.kind == ScheduleKind.merged).single;
    expect(merged.members.map((m) => m.targetId), ['a', 'b', 'c']);
    expect(d.where((x) => x.os), hasLength(2));
    expect(
      d.where((x) => !x.os && x.kind == ScheduleKind.tracked),
      hasLength(3),
    );
    expect(desired(items, merge: false).where((x) => x.os), hasLength(4));
  });

  test('inbox-only and non-local instances', () {
    final d = desired([
      planned('a', t0, system: false),
      planned('b', t0, local: false),
    ]);
    expect(d.single.os, isFalse);
    expect(d.single.kind, ScheduleKind.tracked);
  });

  test('replanning with no changes makes zero platform calls', () {
    final items = [
      for (var i = 0; i < 10; i++)
        planned('t$i', t0.add(Duration(minutes: 10 * i))),
    ];
    final d = desired(items);
    final current = [for (final x in d) entryFor(x)];
    final diff = ScheduleComputation.diff(
      current,
      desired(items),
      t0.subtract(const Duration(hours: 1)),
    );
    expect(diff.isEmpty, isTrue);
    expect(diff.platformCalls, 0);
    expect(diff.unchanged, 10);
  });

  test('diff cancels removed and changed rows, schedules new ones, keeps fired rows', () {
    final now = t0.add(const Duration(minutes: 5));
    final before = desired([
      planned('fired', t0),
      planned('keep', t0.add(const Duration(hours: 1))),
      planned('gone', t0.add(const Duration(hours: 2))),
      planned('moved', t0.add(const Duration(hours: 3))),
    ]);
    final current = [for (final x in before) entryFor(x)];
    final after = desired([
      planned('keep', t0.add(const Duration(hours: 1))),
      planned('moved', t0.add(const Duration(hours: 4))),
      planned('new', t0.add(const Duration(hours: 5))),
    ]);
    final diff = ScheduleComputation.diff(current, after, now);
    expect(diff.cancel.map((e) => e.targetKey).toSet(), {
      'task:gone',
      'task:moved',
    });
    expect(diff.upsert.map((d) => d.targetKey).toSet(), {
      'task:moved',
      'task:new',
    });
    expect(diff.unchanged, 1);
  });

  test('snooze rows are never touched by replans', () {
    final snooze = ScheduleEntry(
      dedupeKey: 's',
      platformId: 1,
      fireAt: t0.add(const Duration(hours: 1)),
      targetKey: 'task:x',
      kind: ScheduleKind.snooze,
      os: true,
      hash: 'h',
      scheduledAt: t0,
    );
    expect(ScheduleComputation.diff([snooze], const [], t0).isEmpty, isTrue);
  });

  test(
    '31-bit platform ids: no collisions across 100 000 keys with probing',
    () {
      final used = <int>{};
      for (var i = 0; i < 100000; i++) {
        final id = PlatformIds.assign(
          dedupeKeyFor(ruleId: 'r$i', targetId: 't', occurrenceKey: '$i'),
          used,
        );
        expect(id, inInclusiveRange(1, 0x7fffffff));
        expect(used.add(id), isTrue);
      }
      expect(PlatformIds.hash('abc'), PlatformIds.hash('abc'));
    },
  );

  test('coverage until: horizon end when everything fits, 56th instance time when saturated', () {
    final horizonEnd = t0.add(const Duration(days: 14));
    final few = desired([planned('a', t0)], budget: ScheduleBudget.ios);
    expect(
      ScheduleComputation.coverageUntil(few, horizonEnd: horizonEnd),
      horizonEnd,
    );
    final many = [
      for (var i = 0; i < 300; i++)
        planned('t$i', t0.add(Duration(minutes: 2 * i + 1))),
    ];
    final saturated = desired(many, budget: ScheduleBudget.ios);
    expect(
      ScheduleComputation.coverageUntil(saturated, horizonEnd: horizonEnd),
      many[55].fireAt,
    );
  });

  test('schedule entry payload round-trips', () {
    final d = desired([planned('a', t0)]).single;
    final e = entryFor(d).copyWith(reconciledAt: t0);
    final decoded = ScheduleEntry.fromRow(
      dedupeKey: e.dedupeKey,
      platformId: e.platformId,
      fireAt: e.fireAt,
      targetKey: e.targetKey,
      payload: e.encodePayload(),
      repeating: false,
      scheduledAt: e.scheduledAt,
    );
    expect(decoded, e);
  });
}
