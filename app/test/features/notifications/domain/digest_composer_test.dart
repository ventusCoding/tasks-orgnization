import 'package:everslot/features/notifications/domain/default_rules.dart';
import 'package:everslot/features/notifications/domain/digest_composer.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/template_engine.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

void main() {
  setUpAll(tzdata.initializeTimeZones);
  // Monday 2026-09-21, 20:00 in Paris.
  final now = DateTime.utc(2026, 9, 21, 18);

  NotificationRule digest(String kind) => NotificationRule(
    id: kind,
    targetType: RuleTargetType.section,
    section: NotificationSection.system,
    spec: DefaultRules.digestSpec(kind, DefaultRules.digestDefaultTimes[kind]!),
  );

  NotificationTarget task(String id, DateTime start) => NotificationTarget(
    type: NotificationTargetType.task,
    id: id,
    section: NotificationSection.planner,
    title: id,
    occurrenceKey: start.toIso8601String(),
    start: start,
    end: start.add(const Duration(hours: 1)),
  );

  List<NotificationTarget> compose(List<String> kinds, List<NotificationTarget> targets, {Map<String, int>? facts}) =>
      DigestComposer.compose(
        rules: [for (final k in kinds) digest(k)],
        targets: targets,
        now: now,
        horizonDays: 1,
        zone: 'Europe/Paris',
        zones: TzZoneResolver(),
        texts: const PlainNotificationTexts(),
        facts: facts ?? const {},
      );

  test('plan tomorrow counts tomorrow and adds the unscheduled backlog (T7.5.18)', () {
    final out = compose(
      ['plan_tomorrow'],
      [task('Gym', DateTime.utc(2026, 9, 22, 6)), task('Late', DateTime.utc(2026, 9, 23, 6))],
      facts: {'backlog': 4},
    );
    final today = out.firstWhere((t) => t.occurrenceKey == '2026-09-21');
    expect(today.variables['summary'], '1 tasks · 0 habits · 0 items · first: Gym 08:00 · 4 unscheduled');
  });

  test('a morning agenda never shows the backlog; an empty backlog adds nothing', () {
    final agenda = compose(['daily_agenda'], const [], facts: {'backlog': 4}).first;
    expect(agenda.variables['summary'], '0 tasks · 0 habits · 0 items');
    final plan = compose(['plan_tomorrow'], const [], facts: {'backlog': 0}).first;
    expect(plan.variables['summary'], '0 tasks · 0 habits · 0 items');
  });

  test('weekly review and monthly report announce their report', () {
    final out = compose(['weekly_review', 'monthly_report'], [task('Gym', DateTime.utc(2026, 9, 22, 6))]);
    expect(out.firstWhere((t) => t.id == 'weekly_review').variables['summary'], 'Your week in review is ready');
    expect(out.firstWhere((t) => t.id == 'monthly_report').variables['summary'], 'Your monthly report is ready');
  });

  test('default digest times get a stable per-user 0–4 minute offset, never on a quarter hour', () {
    final a = DefaultRules.digestDefaultTimeFor('user-a', 'daily_agenda');
    expect(a, DefaultRules.digestDefaultTimeFor('user-a', 'daily_agenda'));
    final minutes = {
      for (var i = 0; i < 50; i++) DefaultRules.digestDefaultTimeFor('user-$i', 'daily_agenda').minuteOfDay,
    };
    expect(minutes.length, greaterThan(1), reason: 'users are spread over several minutes');
    for (final kind in DefaultRules.digestDefaultTimes.keys) {
      for (var i = 0; i < 20; i++) {
        final t = DefaultRules.digestDefaultTimeFor('user-$i', kind);
        final base = DefaultRules.digestDefaultTimes[kind]!.minuteOfDay;
        expect(t.minuteOfDay - base, inInclusiveRange(0, 4));
        expect(t.minute % 15, isNot(0));
      }
    }
    expect(LocalTime(7, 7).minuteOfDay, 427);
  });
}
