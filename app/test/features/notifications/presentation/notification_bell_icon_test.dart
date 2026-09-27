import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/features/notifications/application/inbox_providers.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/data/inbox_repository.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/presentation/notification_bell_icon.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';

// The providers under test own timers (snooze end, pause end) and Drift stream queries: no
// pumpAndSettle, bounded pumps only, and the widget tree + container are torn down inside each
// test body so no fake timer outlives it. Writes run one per `runAsync`: several sequential
// writes inside one `runAsync` while fake-zone stream queries are live deadlock on Drift's lock.
void main() {
  late TestHarness h;
  final now = DateTime.utc(2026, 9, 22, 12);
  setUp(() => h = TestHarness.create(now: now));
  tearDown(() => h.dispose());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  InboxDelivery delivery(int i) =>
      InboxDelivery(dedupeKey: 'k$i', category: InboxCategory.reminder, title: 'R$i', fireAt: now);

  /// One delivered row while the bell is on screen.
  Future<void> deliverOne(WidgetTester tester, int i) async {
    await tester.runAsync(() => h.read(inboxRepositoryProvider).upsertDelivered(delivery(i)));
    await settle(tester);
  }

  Future<void> pumpBell(WidgetTester tester) async {
    await pumpInApp(
      tester,
      h,
      Scaffold(
        appBar: AppBar(
          actions: [IconButton(tooltip: 'Inbox', onPressed: () {}, icon: const NotificationBellIcon())],
        ),
      ),
    );
    await settle(tester);
  }

  /// Unmounts the tree and disposes the container (cancels provider timers) inside the body.
  Future<void> tearDownTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    h.container.dispose();
    await tester.pump();
  }

  testWidgets('badge shows the live unread count', (tester) async {
    await pumpBell(tester);
    expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);

    await deliverOne(tester, 1);
    expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isTrue);
    expect(find.text('1'), findsOneWidget);

    await deliverOne(tester, 2);
    expect(find.text('2'), findsOneWidget);

    await tester.runAsync(() => h.read(inboxRepositoryProvider).markRead([Ids.inbox('k1')]));
    await settle(tester);
    expect(find.text('1'), findsOneWidget);

    await tearDownTree(tester);
  });

  testWidgets('badge is capped at 99+', (tester) async {
    // Seeded before anything watches the table (no live stream query to contend with).
    await tester.runAsync(() async {
      final repository = h.read(inboxRepositoryProvider);
      for (var i = 0; i < 120; i++) {
        await repository.upsertDelivered(delivery(i));
      }
    });
    await pumpBell(tester);
    expect(find.text('99+'), findsOneWidget);
    await tearDownTree(tester);
  });

  testWidgets('a paused bell while "Pause all" is active, back to normal when it ends', (tester) async {
    await tester.runAsync(
      () => h.read(settingsRepositoryProvider).update(SettingsNs.notifications, {
        'pausedUntil': now.add(const Duration(seconds: 2)).toIso8601String(),
      }),
    );
    await pumpBell(tester);
    expect(find.byIcon(Icons.notifications_paused_outlined), findsOneWidget);
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel(RegExp('Notifications paused')), findsOneWidget);
    semantics.dispose();

    h.clock.advance(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    await settle(tester);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    expect(find.byIcon(Icons.notifications_paused_outlined), findsNothing);

    await tearDownTree(tester);
  });

  test('a snoozed row counts as unread again once its snooze ends', () async {
    final repo = h.read(inboxRepositoryProvider);
    await repo.upsertDelivered(delivery(1));
    await repo.setSnoozedUntil(Ids.inbox('k1'), now.add(const Duration(milliseconds: 300)));
    final values = <int>[];
    final sub = h.container.listen(inboxUnreadCountProvider, (_, next) {
      final value = next.value;
      if (value != null) values.add(value);
    }, fireImmediately: true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(values.last, 0);

      // The provider re-evaluates 1 s after the snooze end (real timer here).
      h.clock.advance(const Duration(seconds: 2));
      await Future<void>.delayed(const Duration(milliseconds: 1600));
      expect(values.last, 1);
      expect(h.read(notificationsPausedProvider), isFalse);
    } finally {
      sub.close();
      h.container.dispose();
    }
  });
}
