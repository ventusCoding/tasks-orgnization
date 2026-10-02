import 'package:everslot/features/notifications/domain/inbox_item.dart';
import 'package:everslot/features/notifications/domain/notification_stats.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:flutter_test/flutter_test.dart';

/// Notification statistics (T7.5.17) on fixture inbox rows.
void main() {
  final now = DateTime.utc(2026, 9, 22, 12);
  var n = 0;

  InboxItem row({
    required DateTime at,
    String rule = 'r1',
    String type = 'habit',
    String id = 'water',
    NotificationSection section = NotificationSection.habits,
    List<String> via = const ['local'],
    Duration? openedAfter,
    Duration? actedAfter,
    String? action,
    bool dismissed = false,
    bool read = false,
    bool late = false,
    List<String>? adj,
  }) {
    n++;
    return InboxItem(
      id: 'i$n',
      dedupeKey: 'k$n',
      category: InboxCategory.reminder,
      title: 'Water',
      fireAt: at,
      ruleId: rule,
      sourceType: type,
      sourceId: id,
      section: section,
      deliveredVia: via,
      late: late,
      openedAt: openedAfter == null ? null : at.add(openedAfter),
      actedAt: actedAfter == null ? null : at.add(actedAfter),
      action: action,
      dismissedAt: dismissed ? at.add(const Duration(minutes: 1)) : null,
      readAt: read ? at.add(const Duration(minutes: 2)) : null,
      payload: {'adj': ?adj},
    );
  }

  test('per-rule counters: channels, opens, actions, ignores, late, deferrals, median time to act', () {
    final t = now.subtract(const Duration(days: 1));
    final rows = [
      row(at: t, actedAfter: const Duration(minutes: 4), action: 'done'),
      row(at: t.add(const Duration(hours: 1)), actedAfter: const Duration(minutes: 10), action: 'done', via: ['push']),
      row(at: t.add(const Duration(hours: 2)), actedAfter: const Duration(minutes: 20), action: 'snooze'),
      row(at: t.add(const Duration(hours: 3)), openedAfter: const Duration(minutes: 1), via: const []),
      row(at: t.add(const Duration(hours: 4)), dismissed: true, late: true),
      row(at: t.add(const Duration(hours: 5)), adj: ['deferredQuietHours']),
      row(at: now.subtract(const Duration(minutes: 10))), // too recent to count as ignored
      row(at: now.add(const Duration(hours: 1))), // future rows are not delivered yet
      row(at: t, rule: 'r2', section: NotificationSection.planner, type: 'task', id: 'gym'),
    ];
    final byRule = NotificationStats.compute(rows, by: StatsGroup.rule, now: now);
    expect(byRule.map((r) => r.key), ['r1', 'r2']);
    final r1 = byRule.first;
    expect(
      (r1.delivered, r1.local, r1.push, r1.inboxOnly, r1.opened, r1.acted, r1.snoozed, r1.dismissed),
      (7, 5, 1, 1, 1, 3, 1, 1),
    );
    expect(r1.actions, {'done': 2, 'snooze': 1});
    expect(r1.ignored, 1, reason: 'only the deferred one is old, untouched and unread');
    expect((r1.late, r1.deferred), (1, 1));
    expect(r1.medianActionMinutes, 10);
    expect(r1.ignoreRate, closeTo(1 / 7, 1e-9));
    final bySection = NotificationStats.compute(rows, by: StatsGroup.section, now: now);
    expect({for (final r in bySection) r.key: r.delivered}, {'habits': 7, 'planner': 1});
    final byTarget = NotificationStats.compute(rows, by: StatsGroup.target, now: now);
    expect(byTarget.first.label, 'Water');
  });

  test('effectiveness: a check-in or task start within an hour of the reminder', () {
    final t = now.subtract(const Duration(days: 2));
    final rows = [
      row(at: t),
      row(at: t.add(const Duration(days: 1))),
      row(at: t, type: 'task', id: 'gym', rule: 'r2'),
      row(at: t, type: 'checklist', id: 'list', rule: 'r3'),
    ];
    final activity = {
      'habit:water': [t.add(const Duration(minutes: 45)), t.add(const Duration(days: 1, hours: 2))],
      'task:gym': [t.subtract(const Duration(minutes: 5))],
    };
    final stats = {
      for (final r in NotificationStats.compute(rows, by: StatsGroup.rule, now: now, activity: activity)) r.key: r,
    };
    expect((stats['r1']!.effective, stats['r1']!.effectivenessBase), (1, 2));
    expect(stats['r1']!.effectiveness, 0.5);
    expect(stats['r2']!.effectiveness, 0, reason: 'started before the reminder');
    expect(stats['r3']!.effectiveness, isNull, reason: 'lists have no check-ins');
  });

  test('noisy rules: at least 10 deliveries, ignored 90 % of the time', () {
    final rows = [
      for (var i = 0; i < 10; i++)
        row(
          at: now.subtract(Duration(days: i + 1)),
          rule: 'noisy',
        ),
      for (var i = 0; i < 10; i++)
        row(
          at: now.subtract(Duration(days: i + 1)),
          rule: 'useful',
          actedAfter: const Duration(minutes: 3),
          action: 'done',
        ),
      for (var i = 0; i < 5; i++)
        row(
          at: now.subtract(Duration(days: i + 1)),
          rule: 'rare',
        ),
    ];
    final noisy = NotificationStats.noisyRules(NotificationStats.compute(rows, by: StatsGroup.rule, now: now));
    expect(noisy.map((r) => r.ruleId), ['noisy']);
    expect(noisy.single.ignoreRate, 1);
  });

  test('rollup keeps daily counters past the inbox retention and merges with live rows', () {
    final old = [
      row(at: DateTime.utc(2026, 6, 1, 8)),
      row(at: DateTime.utc(2026, 6, 1, 9), actedAfter: const Duration(minutes: 2), action: 'done'),
      row(at: DateTime.utc(2026, 6, 2, 8), rule: 'r2'),
    ];
    final rollup = const StatsRollup().rollUp(old, cutoff: DateTime.utc(2026, 7, 1), now: now);
    expect(rollup.through, DateTime.utc(2026, 7));
    final back = StatsRollup.fromJson(rollup.toJson());
    final rows = {
      for (final r in back.rowsBetween(StatsGroup.rule, DateTime.utc(2026, 5, 1), DateTime.utc(2026, 7))) r.key: r,
    };
    expect((rows['r1']!.delivered, rows['r1']!.acted, rows['r2']!.delivered), (2, 1, 1));
    expect(back.rowsBetween(StatsGroup.rule, DateTime.utc(2026, 6, 2), DateTime.utc(2026, 7)).single.key, 'r2');
    final merged = rows['r1']! + const NotificationStatsRow(key: 'r1', delivered: 3, acted: 1, actions: {'done': 1});
    expect((merged.delivered, merged.acted, merged.actions['done']), (5, 2, 2));
    final again = back.rollUp(
      [row(at: DateTime.utc(2026, 6, 1, 10))],
      cutoff: DateTime.utc(2026, 7, 1),
      now: now,
    );
    expect(
      again.rowsBetween(StatsGroup.rule, DateTime.utc(2026, 5, 1), DateTime.utc(2026, 7)).length,
      2,
      reason: 'days already rolled up are not counted twice',
    );
  });
}
