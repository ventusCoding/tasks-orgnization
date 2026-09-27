import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Pumps frames for [total] (bounded: never hangs on spinners, tickers or live counters).
Future<void> pumpFor(WidgetTester tester, [Duration total = const Duration(milliseconds: 700)]) async {
  const step = Duration(milliseconds: 50);
  for (var t = Duration.zero; t < total; t += step) {
    await tester.pump(step);
  }
}

/// Lets Drift streams and async writes run between frames (FakeAsync + real I/O), then pumps.
Future<void> settle(WidgetTester tester, {int rounds = 6}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump(const Duration(milliseconds: 50));
  }
  await pumpFor(tester);
}

/// Taps the "open" button of `pumpOpener` and lets the opened screen load its data.
Future<void> openAndSettle(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('open')));
  await settle(tester);
}

/// Scrolls [finder] into view inside the scrollable under [scrollKey] (top first), then taps it.
Future<void> tapIn(WidgetTester tester, Finder finder, {required Key scrollKey}) async {
  final scrollable = find.descendant(of: find.byKey(scrollKey), matching: find.byType(Scrollable)).first;
  if (finder.evaluate().isEmpty) {
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
    await tester.pump();
  }
  await tester.scrollUntilVisible(finder, 150, scrollable: scrollable);
  await pumpFor(tester, const Duration(milliseconds: 300));
  await tester.tap(finder);
  await settle(tester, rounds: 2);
}
