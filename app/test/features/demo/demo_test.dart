import 'package:everslot/features/demo/application/demo_service.dart';
import 'package:everslot/features/demo/domain/demo_generator.dart';
import 'package:everslot/features/planner/domain/planner_item.dart' show OccurrenceStatus;
import 'package:everslot/features/stats/presentation/insights_screen.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../stats/support/stats_harness.dart';

final en = lookupAppLocalizations(const Locale('en'));

DemoTexts _texts() => const DemoTexts(
  tasks: {},
  lists: [
    (
      title: 'Trip',
      nodes: [
        DemoNode('Flights', children: [DemoNode('Compare')]),
        DemoNode('Passport'),
      ],
    ),
  ],
  habits: {},
  quitName: 'Stop smoking',
  cravingTriggers: ['stress', 'coffee'],
);

void main() {
  group('generator (T8.3.16)', () {
    final today = LocalDate(2026, 9, 22);

    test('the same seed gives the same data; another seed differs', () {
      String fingerprint(DemoDataset d) => [
        for (final t in d.tasks) '${t.key}:${t.history.map((h) => '${h.key}${h.status.name[0]}').join()}',
        for (final h in d.habits) '${h.key}:${h.days.map((x) => '${x.date.toIso()}${x.value}').join()}',
        for (final c in d.quit.cravings) '${c.at.toIso()}${c.intensity}${c.resisted}${c.trigger}',
        for (final l in d.lists) '${l.title}:${l.nodes.map((n) => n.status.name).join()}',
      ].join('|');
      final a = DemoGenerator.generate(seed: 7, today: today, texts: _texts());
      final b = DemoGenerator.generate(seed: 7, today: today, texts: _texts());
      final c = DemoGenerator.generate(seed: 8, today: today, texts: _texts());
      expect(fingerprint(a), fingerprint(b));
      expect(fingerprint(a), isNot(fingerprint(c)));
    });

    test('six months of plausible history, nothing in the future', () {
      final d = DemoGenerator.generate(seed: 42, today: today, texts: _texts());
      final first = today.plusDays(-DemoGenerator.days);
      for (final t in d.tasks) {
        for (final h in t.history) {
          expect(h.start.date.isBefore(today), isTrue);
          expect(h.start.date.isBefore(first), isFalse);
          if (t.weekdays != null) expect(t.weekdays, contains(h.start.date.weekday));
        }
      }
      final standup = d.tasks.firstWhere((t) => t.key == 'standup');
      final done = standup.history.where((h) => h.status == OccurrenceStatus.done).length;
      expect(done / 130, inInclusiveRange(0.7, 1.0), reason: 'about 26 weeks of weekdays');
      for (final h in d.habits) {
        expect(h.days, isNotEmpty);
        expect(h.days.last.date.isBefore(today), isTrue);
      }
      expect(d.quit.relapses, hasLength(2));
      final early = d.quit.cravings.where((c) => c.at.date.isBefore(d.quit.quitAt.date.plusDays(30))).length;
      final late = d.quit.cravings.where((c) => !c.at.date.isBefore(today.plusDays(-30))).length;
      expect(early, greaterThan(late), reason: 'cravings fade');
      expect(d.lists.single.nodes.first.status, isNot(isNull));
    });
  });

  testWidgets('generate → stats screens render → remove', (tester) async {
    final h = StatsHarness.create();
    addTearDown(h.dispose);
    await tester.runAsync(() async {
      await h.settle();
      final data = await h.read(demoServiceProvider).generate(seed: 3);
      expect(data.occurrenceCount, greaterThan(300));
      expect((await h.db.select(h.db.tasks).get()).length, data.tasks.length);
      expect((await h.db.select(h.db.checklists).get()).length, 3);
      expect((await h.db.select(h.db.habits).get()).length, 6);
      expect((await h.db.select(h.db.habitLogs).get()).length, greaterThan(data.checkInCount));
    });
    tester.view.physicalSize = const Size(420, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpStats(tester, h, const InsightsScreen());
    for (var i = 0; i < 6; i++) {
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    }
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(find.text(en.chartsLabelCravings), findsWidgets);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 61));

    await tester.runAsync(() async {
      await h.read(demoServiceProvider).remove();
      final tasks = await h.db.select(h.db.tasks).get();
      expect(tasks.every((t) => t.deletedAt != null), isTrue);
      final habits = await h.db.select(h.db.habits).get();
      expect(habits.every((x) => x.deletedAt != null), isTrue);
      expect(await h.read(demoPresentProvider.future), isFalse);
    });
    // Undo entries and stats invalidation debounce of the writes above.
    await tester.pump(const Duration(seconds: 61));
  });
}
