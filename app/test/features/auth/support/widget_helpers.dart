import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';
import 'cloud_sync_harness.dart';

/// Lets Drift queries/streams and async work complete between frames.
Future<void> settle(WidgetTester tester, {int rounds = 5}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Unmounts the tree (cancels widget timers) and disposes the harness inside the test body —
/// pending timers are checked before tearDown callbacks run.
///
/// The extra `pump(duration)` after unmounting matters: a raw Drift stream listened to by a
/// `StreamBuilder` schedules its clean-up on the fake-async clock when the subscription is
/// cancelled, and `AppDatabase.close()` would wait forever for it if no fake time elapsed.
Future<void> finish(WidgetTester tester, TestHarness h) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 100));
  await tester.runAsync(h.dispose);
}

/// [finish] for a signed-in [CloudDevice].
Future<void> finishCloud(WidgetTester tester, CloudDevice d) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 100));
  await tester.runAsync(d.dispose);
}
