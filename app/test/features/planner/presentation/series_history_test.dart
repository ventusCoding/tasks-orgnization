import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/series_history_screen.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';
import '../../recurrence_ui/recurrence_test_support.dart';
import '../planner_test_support.dart';
import 'planner_ui_support.dart';

/// Series history (T3.2.20): statuses, planned vs actual, moves, filters, month calendar,
/// across a series split.
void main() {
  late TestHarness h;
  // Tuesday 2026-09-22 12:00 UTC.
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 12)));
  tearDown(() => h.dispose());

  Finder key(String k) => find.byKey(ValueKey(k));
  const list = ValueKey('series-history-list');

  /// Daily 08:00 from Sept 14: done (late) on the 14th, skipped on the 15th, moved on the 16th,
  /// then split on the 20th to 09:00 (same series).
  Future<String> seed(WidgetTester tester) async => (await tester.runAsync(() async {
    final id = await h.createTask(title: 'Stretch', start: '2026-09-14T08:00', duration: 15, rule: RecurrenceRule());
    await h.occurrences.markDone(
      id,
      '2026-09-14T08:00',
      actualStart: DateTime.utc(2026, 9, 14, 8, 20),
      actualEnd: DateTime.utc(2026, 9, 14, 8, 35),
    );
    await h.occurrences.skip(id, '2026-09-15T08:00', reason: 'sick');
    await h.tasks.editOccurrence(id, '2026-09-16T08:00', start: ldt('2026-09-16T18:00'));
    final task = (await h.task(id))!;
    await h.tasks.update(
      task.copyWith(startLocal: ldt('2026-09-20T09:00')),
      scope: EditScope.thisAndFollowing,
      occurrenceKey: '2026-09-20T08:00',
    );
    return task.seriesId;
  }))!;

  Future<void> open(WidgetTester tester, String seriesId) async {
    await pumpOpener(
      tester,
      h,
      (context) => Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => SeriesHistoryScreen(seriesId: seriesId, title: 'Stretch'),
        ),
      ),
    );
    await openAndSettle(tester);
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    final scrollable = find.descendant(of: find.byKey(list), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(finder.first, 200, scrollable: scrollable);
    await pumpFor(tester, const Duration(milliseconds: 200));
  }

  testWidgets('lists the whole series across the split with statuses, actual times and moves', (tester) async {
    final seriesId = await seed(tester);
    await open(tester, seriesId);
    expect(key('series-month'), findsOneWidget);
    expect(key('series-dot-2026-09-14'), findsOneWidget);
    await scrollTo(tester, find.textContaining('Planned'));
    expect(find.textContaining('08:20'), findsOneWidget, reason: 'actual start shown next to the planned one');
    await scrollTo(tester, find.textContaining('Moved from'));
    expect(find.textContaining('Moved from'), findsOneWidget);
    // After the split the occurrences continue at 09:00 in the same series.
    await scrollTo(tester, find.textContaining('09:00'));
    expect(find.textContaining('09:00'), findsWidgets);
  });

  testWidgets('filters: done, skipped, missed, moved', (tester) async {
    final seriesId = await seed(tester);
    await open(tester, seriesId);
    // A tall window builds every row of the (lazy) list.
    tester.view.physicalSize = const Size(1080, 12000);
    await pumpFor(tester);
    Future<void> filter(String name) async {
      await scrollTo(tester, key('series-filter-$name'));
      await tester.tap(key('series-filter-$name'));
      await pumpFor(tester);
    }

    int rows() => find
        .byWidgetPredicate(
          (w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('series-') && w is ListTile,
        )
        .evaluate()
        .length;

    await filter('done');
    expect(rows(), 1);
    await filter('skipped');
    expect(rows(), 1);
    await filter('moved');
    expect(rows(), 1);
    await filter('missed');
    // Sept 16 (moved, never done), 17–19 at 08:00 and 20–22 at 09:00 ended without an outcome.
    expect(rows(), 7);
  });

  testWidgets('month navigation shows the next month', (tester) async {
    final seriesId = await seed(tester);
    await open(tester, seriesId);
    await tester.tap(find.byTooltip('Next month'));
    await settle(tester);
    expect(find.textContaining('October'), findsWidgets);
    expect(key('series-dot-2026-10-01'), findsOneWidget);
  });
}
