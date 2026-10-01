import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/features/dev/presentation/debug_menu_screen.dart';
import 'package:everslot/features/dev/presentation/sync_diagnostics_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import '../auth/support/cloud_sync_harness.dart';
import '../auth/support/widget_helpers.dart';

/// Bounded frames (never `pumpAndSettle`: progress indicators may animate forever).
Future<void> _frames(WidgetTester tester, {int n = 8}) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Runs [write] in the fake-async zone and pumps until it completes.
Future<void> _write(WidgetTester tester, Future<void> Function() write) async {
  var done = false;
  unawaited(write().then<void>((_) => done = true));
  for (var i = 0; i < 20 && !done; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(done, isTrue);
}

void main() {
  testWidgets('debug menu: environment warnings, flags, time travel, tools (dev flavor)', (tester) async {
    final h = TestHarness.create();
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    await pumpInApp(tester, h, const DebugMenuScreen());
    await settle(tester);
    expect(find.text('Developer menu'), findsOneWidget);
    expect(find.byKey(const ValueKey('dev-env-warning')), findsNWidgets(2), reason: 'no Supabase, no Firebase');

    await tester.tap(find.byKey(const ValueKey('dev-flag-planner_views_m3')));
    await tester.pump();
    expect(h.read(featureFlagsProvider), contains('planner_views_m3'));

    expect(find.text('Real time'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('dev-travel-1440')));
    await tester.pump();
    expect(h.read(timeTravelProvider), const Duration(days: 1));
    expect(find.text('Shifted: tomorrow'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('dev-travel-reset')));
    await tester.pump();
    expect(h.read(timeTravelProvider), Duration.zero);

    for (final key in ['dev-logs', 'dev-database', 'dev-sync', 'dev-gallery', 'dev-reset']) {
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
    }
    await tester.tap(find.byKey(const ValueKey('dev-database')));
    await _frames(tester);
    await settle(tester);
    expect(find.byKey(const ValueKey('dev-table-categories')), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
    await finish(tester, h);
  });

  testWidgets('sync diagnostics (local-only): sync off, empty outbox', (tester) async {
    final h = TestHarness.create();
    await pumpInApp(tester, h, const DebugMenuScreen(page: 'sync'));
    await settle(tester);
    expect(find.byType(SyncDiagnosticsPage), findsOneWidget);
    expect(find.byKey(const ValueKey('diag-off')), findsOneWidget);
    expect(find.byKey(const ValueKey('diag-outbox-empty')), findsOneWidget);
    await finish(tester, h);
  });

  testWidgets('sync diagnostics (cloud): outbox groups, simulate offline, conflict log', (tester) async {
    final d = (await tester.runAsync(CloudDevice.create))!;
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    await pumpInApp(tester, d.h, const SyncDiagnosticsPage());
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('diag-offline')));
    await tester.pump();
    expect(d.h.read(syncServiceProvider)!.simulateOffline, isTrue);

    await _write(tester, () => d.addCategory('c1', 'Work'));
    await settle(tester);
    expect(find.textContaining('categories'), findsWidgets);
    expect(find.byKey(const ValueKey('diag-conflicts-empty')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('diag-offline')));
    await settle(tester, rounds: 10);
    expect(d.h.read(syncServiceProvider)!.simulateOffline, isFalse);
    expect(d.server.row('categories', 'c1'), isNotNull, reason: 'going back online syncs');
    expect(find.byKey(const ValueKey('diag-outbox-empty')), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(d.dispose);
  });
}
