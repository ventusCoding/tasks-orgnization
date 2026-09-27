import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/presentation/quota_indicator.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';
import '../planner_test_support.dart';
import 'planner_ui_support.dart';

/// Quota tasks (T3.2.16): per-period summaries and the header indicator.
void main() {
  late TestHarness h;
  // Wednesday 2026-09-23 12:00 UTC; weeks start on Monday 2026-09-21.
  setUp(() => h = plannerHarness(now: DateTime.utc(2026, 9, 23, 12)));
  tearDown(() => h.dispose());

  final rule = RecurrenceRule.fromJson(const {
    'v': 1,
    'type': 'quota',
    'quota': {'times': 3, 'per': 'week'},
  });

  Widget app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
    locale: locale,
    theme: AppTheme.light(),
    supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
    localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('Run 3x per week: 1/3, then done for this week after three completions', (tester) async {
    final (first, last) = (await tester.runAsync(() async {
      final id = await h.createTask(title: 'Run', start: '2026-09-21T09:00', duration: 45, rule: rule);
      await h.occurrences.markDone(id, 'week:2026-09-21#1');
      final first = quotaSummaries(await h.items(ld('2026-09-21'), 7));
      await h.occurrences.markDone(id, 'week:2026-09-21#2');
      await h.occurrences.markDone(id, 'week:2026-09-21#3');
      final last = quotaSummaries(await h.items(ld('2026-09-21'), 7));
      return (first, last);
    }))!;
    expect(first.single.done, 1);
    expect(first.single.target, 3);
    expect(first.single.periodKey, 'week:2026-09-21');
    expect(first.single.unit, PeriodUnit.week);
    expect(first.single.complete, isFalse);
    expect(last.single.complete, isTrue);

    await tester.pumpWidget(app(QuotaIndicator(first.single)));
    await pumpFor(tester);
    expect(find.text('Run · 1/3 this week'), findsOneWidget);
    await tester.pumpWidget(app(QuotaIndicator(last.single)));
    await pumpFor(tester);
    expect(find.text('Run · done for this week'), findsOneWidget);
    await tester.pumpWidget(app(QuotaIndicator(last.single), locale: const Locale('ar')));
    await pumpFor(tester);
    expect(find.textContaining('اكتمل لهذا الأسبوع'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('summaries ignore regular occurrences and group by task and period', () async {
    await h.createTask(title: 'Daily', start: '2026-09-21T08:00', rule: RecurrenceRule());
    await h.createTask(title: 'Run', start: '2026-09-21T09:00', duration: 45, rule: rule);
    final summaries = quotaSummaries(await h.items(ld('2026-09-21'), 14));
    expect(summaries.map((s) => (s.title, s.periodKey, s.done, s.target)), [
      ('Run', 'week:2026-09-21', 0, 3),
      ('Run', 'week:2026-09-28', 0, 3),
    ]);
  });
}
