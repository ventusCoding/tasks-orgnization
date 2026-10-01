// Advanced chart interactions (T6.2.22): a vertical drag scrolls the page while a horizontal drag
// scrubs; the crosshair is shared by the charts of one screen; two-finger pinch zooms the time axis;
// long series get a range brush.
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/charts.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

TimeSeriesData series(int n) => TimeSeriesData(
  [for (var i = 0; i < n; i++) LocalDate(2026, 1, 1).plusDays(i)],
  [
    ChartSeries(const TokenLabel(LabelToken.count), [for (var i = 0; i < n; i++) (i % 17).toDouble()]),
    ChartSeries(const TokenLabel(LabelToken.rollingMean), [for (var i = 0; i < n; i++) 8], color: const SeriesColor(1)),
  ],
);

Future<void> pumpScreen(WidgetTester tester, List<Widget> children, {ScrollController? controller}) async {
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
      home: Scaffold(
        body: ChartPrefs(
          haptics: false,
          child: ListView(controller: controller, padding: const EdgeInsets.all(16), children: children),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a vertical drag on a chart scrolls the page; a horizontal drag scrubs', (tester) async {
    final controller = ScrollController();
    final crosshair = ValueNotifier<LocalDate?>(null);
    await pumpScreen(tester, [
      ChartCrosshairScope(
        notifier: crosshair,
        child: Column(
          children: [
            TimeSeriesChart(series(30), height: 240),
            const SizedBox(height: 16),
            TimeSeriesChart(series(30), height: 240, key: const ValueKey('second')),
          ],
        ),
      ),
      const SizedBox(height: 1200),
    ], controller: controller);
    final chart = tester.getCenter(find.byType(TimeSeriesChart).first);

    await tester.dragFrom(chart, const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(100), reason: 'vertical drag scrolls the page');
    expect(crosshair.value, isNull, reason: 'a vertical drag does not scrub');

    controller.jumpTo(0);
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(chart);
    for (var i = 0; i < 8; i++) {
      await gesture.moveBy(const Offset(-12, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(controller.offset, 0, reason: 'a horizontal drag does not scroll');
    expect(crosshair.value, isNotNull, reason: 'the horizontal drag scrubs and shares the date');
    // The other chart of the screen draws the shared crosshair (it rebuilt with the date).
    expect(find.byKey(const ValueKey('second')), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(crosshair.value, isNull, reason: 'the crosshair clears when the scrub ends');
  });

  testWidgets('two-finger pinch zooms in, the reset button zooms out', (tester) async {
    await pumpScreen(tester, [TimeSeriesChart(series(60), height: 240)]);
    final state = tester.state<TimeSeriesChartState>(find.byType(TimeSeriesChart));
    expect(state.window, isNull);
    final c = tester.getCenter(find.byType(TimeSeriesChart));
    final a = await tester.startGesture(c - const Offset(40, 0), pointer: 1);
    final b = await tester.startGesture(c + const Offset(40, 0), pointer: 2);
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await a.moveBy(const Offset(-20, 0));
      await b.moveBy(const Offset(20, 0));
      await tester.pump();
    }
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
    final w = state.window!;
    expect(w.end - w.start, lessThan(59), reason: 'spreading the fingers narrows the window');
    expect(w.end - w.start, greaterThanOrEqualTo(TimeSeriesChart.minWindow));
    expect(w.start, greaterThanOrEqualTo(0));
    expect(w.end, lessThanOrEqualTo(59));
    await tester.tap(find.text('Reset zoom'));
    await tester.pumpAndSettle();
    expect(state.window, isNull);
  });

  testWidgets('long series get a range brush that pans and resizes the window', (tester) async {
    await pumpScreen(tester, [TimeSeriesChart(series(365), height: 220)]);
    expect(find.byKey(const ValueKey('range-brush')), findsOneWidget);
    final state = tester.state<TimeSeriesChartState>(find.byType(TimeSeriesChart));
    state.setWindow((start: 100, end: 160));
    await tester.pumpAndSettle();
    final brush = tester.getRect(find.byKey(const ValueKey('range-brush')));
    double px(double i) => brush.left + i / 364 * brush.width;
    // Drag the middle of the window to the right: it moves, keeping its width.
    await tester.dragFrom(Offset(px(130), brush.center.dy), const Offset(60, 0));
    await tester.pumpAndSettle();
    var w = state.window!;
    expect(w.end - w.start, closeTo(60, 0.5));
    expect(w.start, greaterThan(110));
    // Drag the end edge: the window grows.
    final before = w.end - w.start;
    await tester.dragFrom(Offset(px(w.end), brush.center.dy), const Offset(40, 0));
    await tester.pumpAndSettle();
    w = state.window!;
    expect(w.end - w.start, greaterThan(before + 10));
    // Clamped to the data.
    state.setWindow((start: -50, end: 2));
    expect(state.window, (start: 0.0, end: 52.0));
    state.setWindow((start: 10, end: 12));
    expect(state.window!.end - state.window!.start, TimeSeriesChart.minWindow);
    // Short series have no brush.
    await pumpScreen(tester, [TimeSeriesChart(series(30))]);
    expect(find.byKey(const ValueKey('range-brush')), findsNothing);
  });
}
