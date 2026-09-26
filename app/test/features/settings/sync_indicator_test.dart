import 'package:everslot/core/providers.dart';
import 'package:everslot/core/sync/sync_status.dart';
import 'package:everslot/features/settings/presentation/widgets/sync_indicator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import '../auth/support/cloud_sync_harness.dart';
import '../auth/support/widget_helpers.dart';

class _Fixed extends SyncStatusController {
  _Fixed(this.value);

  final SyncStatus value;

  @override
  SyncStatus build() => value;
}

Future<void> _pumpIndicator(WidgetTester tester, SyncStatus status) async {
  final h = TestHarness.create(overrides: [syncStatusProvider.overrideWith(() => _Fixed(status))]);
  await pumpInApp(tester, h, Scaffold(appBar: AppBar(actions: const [SyncIndicator()])));
  await tester.pump();
  addTearDown(h.dispose);
}

class _List extends StatelessWidget {
  const _List();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SyncRefresh(
      child: ListView(children: [for (var i = 0; i < 30; i++) ListTile(title: Text('row $i'))]),
    ),
  );
}

void main() {
  group('indicator states (T8.1.09)', () {
    testWidgets('hidden when synced or local-only', (tester) async {
      await _pumpIndicator(tester, const SyncStatus(phase: SyncPhase.idle));
      expect(find.byKey(const ValueKey('sync-indicator')), findsNothing);
      await _pumpIndicator(tester, SyncStatus.localOnly);
      expect(find.byKey(const ValueKey('sync-indicator')), findsNothing);
    });

    testWidgets('syncing shows a spinner; an initial sync shows its progress', (tester) async {
      await _pumpIndicator(tester, const SyncStatus(phase: SyncPhase.pulling));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byTooltip('Updating…'), findsOneWidget);
      await _pumpIndicator(tester, const SyncStatus(phase: SyncPhase.pulling, initialSyncProgress: 0.5));
      expect(tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator)).value, 0.5);
      expect(find.byTooltip('Downloading your data… 50%'), findsOneWidget);
    });

    testWidgets('offline and error states explain themselves', (tester) async {
      await _pumpIndicator(tester, const SyncStatus(phase: SyncPhase.offline));
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.byTooltip('Offline — changes will sync later'), findsOneWidget);
      await _pumpIndicator(
        tester,
        const SyncStatus(phase: SyncPhase.error, errorCode: SyncErrorCodes.unsupportedClient),
      );
      expect(find.byIcon(Icons.sync_problem), findsOneWidget);
      expect(find.byTooltip('Please update Everslot to keep syncing.'), findsOneWidget);
    });

    testWidgets('rejected changes surface even when idle', (tester) async {
      await _pumpIndicator(tester, const SyncStatus(phase: SyncPhase.idle, failedChanges: 2));
      expect(find.byIcon(Icons.sync_problem), findsOneWidget);
    });
  });

  group('pull-to-refresh', () {
    testWidgets('pushes and pulls, then completes', (tester) async {
      final d = (await tester.runAsync(CloudDevice.create))!;
      await tester.runAsync(() => d.addCategory('c1', 'Work'));
      await pumpInApp(tester, d.h, const _List());
      await settle(tester);
      await tester.fling(find.text('row 0'), const Offset(0, 400), 1000);
      await tester.pump();
      await settle(tester, rounds: 10);
      await tester.pumpAndSettle();
      expect(d.server.row('categories', 'c1'), isNotNull);
      expect(find.byType(RefreshProgressIndicator), findsNothing, reason: 'no spinner lock');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(d.dispose);
    });

    testWidgets('offline: completes with a message', (tester) async {
      final d = (await tester.runAsync(CloudDevice.create))!;
      d.api.offline = true;
      await pumpInApp(tester, d.h, const _List());
      await settle(tester);
      await tester.fling(find.text('row 0'), const Offset(0, 400), 1000);
      await tester.pump();
      await settle(tester, rounds: 10);
      await tester.pumpAndSettle();
      expect(find.text('Offline — changes will sync later'), findsOneWidget);
      expect(find.byType(RefreshProgressIndicator), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(d.dispose);
    });

    testWidgets('local-only: explains that everything is on this device', (tester) async {
      final h = TestHarness.create();
      await pumpInApp(tester, h, const _List());
      await tester.fling(find.text('row 0'), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Everything is saved on this device.'), findsOneWidget);
      await finish(tester, h);
    });
  });
}
