import 'package:everslot/features/notifications/domain/notification_settings.dart';
import 'package:everslot/features/notifications/domain/planner/notification_planner.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/domain/template_engine.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../support/fixture_parsing.dart';

/// Motivational content packs (T7.1.17): one variant per occurrence, picked from the dedupe key.
void main() {
  setUpAll(tzdata.initializeTimeZones);
  final now = DateTime.utc(2026, 9, 21, 5);

  List<String> bodies(String pack, Map<String, Object?> target, {int days = 7}) {
    final rule = ruleFromJson({
      'id': 'r',
      'targetType': 'section',
      'section': target['section'],
      'spec': {
        'v': 1,
        'trigger': {'type': 'relative', 'anchor': 'period_start', 'dayOffset': 0, 'atTime': '09:00'},
        'content': {'pack': pack},
      },
    });
    final targets = [
      for (var i = 0; i < days; i++)
        targetFromJson({
          ...target,
          'occurrenceKey': '2026-09-${21 + i}',
          'periodStart': DateTime.utc(2026, 9, 20 + i, 22).toIso8601String(),
          'periodEnd': DateTime.utc(2026, 9, 21 + i, 22).toIso8601String(),
        }),
    ];
    final ctx = PlanningContext(
      now: now,
      deviceZone: 'Europe/Paris',
      zones: TzZoneResolver(),
      settings: NotificationSettings.defaults,
      rules: [rule],
      targets: targets,
      profiles: builtinProfilesById(),
    );
    return [for (final p in NotificationPlanner.plan(ctx).planned) p.inboxBody ?? ''];
  }

  const texts = PlainNotificationTexts();
  final habit = {'type': 'habit', 'id': 'run', 'section': 'habits', 'title': 'Run'};

  test('same occurrence → same variant on every plan; occurrences rotate through the pack', () {
    final first = bodies(ContentPacks.habitMotivation, habit);
    expect(first, hasLength(7));
    expect(bodies(ContentPacks.habitMotivation, habit), first, reason: 'deterministic (dedupe-key seeded)');
    final pack = {
      for (final v in texts.packVariants(ContentPacks.habitMotivation)) v.body!.replaceAll('{title}', 'Run'),
    };
    expect(first.every(pack.contains), isTrue, reason: first.join('\n'));
    expect(first.toSet().length, greaterThan(1), reason: 'no monotony over a week');
  });

  test('variants needing a variable the target lacks are skipped ({reason}, {money_saved})', () {
    final quit = {'type': 'habit', 'id': 'smoke', 'section': 'quit', 'title': 'Smoke-free'};
    final noReason = bodies(ContentPacks.quitMotivation, {
      ...quit,
      'variables': <String, Object?>{'days_free': '12'},
    }, days: 14);
    expect(noReason.any((b) => b.startsWith('Remember why')), isFalse);
    expect(noReason.any((b) => b.contains('{')), isFalse, reason: noReason.join('\n'));
    final withReason = bodies(ContentPacks.quitMotivation, {
      ...quit,
      'variables': <String, Object?>{'days_free': '12', 'reason': 'For my kids', 'money_saved': '€60.00'},
    }, days: 14);
    expect(withReason.toSet().length, greaterThan(2));
    expect(withReason.every((b) => !b.contains('{')), isTrue);
  });

  test('content.pack round-trips and counts as content', () {
    final spec = NotificationRuleSpec.fromJson(const {
      'v': 1,
      'trigger': {'type': 'overdue'},
      'content': {'pack': 'quit_motivation'},
    });
    expect(spec.content.pack, ContentPacks.quitMotivation);
    expect(spec.content.isEmpty, isFalse);
    expect(spec.toJson()['content'], {'pack': 'quit_motivation'});
    expect(texts.packVariants('unknown'), isEmpty);
  });
}
