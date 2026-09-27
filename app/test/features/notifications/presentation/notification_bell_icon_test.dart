import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/notifications/application/inbox_providers.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/data/inbox_repository.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/presentation/notification_bell_icon.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';

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

  Future<void> deliver(WidgetTester tester, int count) => tester.runAsync(() async {
    for (var i = 0; i < count; i++) {
      await h.read(inboxRepositoryProvider).upsertDelivered(
        InboxDelivery(dedupeKey: 'k$i', category: InboxCategory.reminder, title: 'R$i', fireAt: now),
      );
    }
  });

  Future<void> pumpBell(WidgetTester tester) => pumpInApp(
    tester,
    h,
    Scaffold(appBar: AppBar(actions: [IconButton(tooltip: 'Inbox', onPressed: () {}, icon: const NotificationBellIcon())])),
  );

  const timeout = Timeout(Duration(seconds: 60));

  testWidgets('badge shows the unread count, capped at 99+', timeout: timeout, (tester) async {
    await pumpBell(tester);
    await settle(tester);
    expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);

    await deliver(tester, 3);
    await settle(tester);
    expect(find.text('3'), findsOneWidget);

    await deliver(tester, 120);
    await settle(tester);
    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets('a paused bell while "Pause all" is active, back to normal when it ends', timeout: timeout, (tester) async {
    await tester.runAsync(
      () => h.read(settingsRepositoryProvider).update(SettingsNs.notifications, {
        'pausedUntil': now.add(const Duration(seconds: 2)).toIso8601String(),
      }),
    );
    await pumpBell(tester);
    await settle(tester);
    expect(find.byIcon(Icons.notifications_paused_outlined), findsOneWidget);
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel(RegExp('Notifications paused')), findsOneWidget);
    semantics.dispose();

    h.clock.advance(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    await settle(tester);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
  });

  test('a snoozed row counts as unread again once its snooze ends', timeout: timeout, () async {
    final repo = h.read(inboxRepositoryProvider);
    await repo.upsertDelivered(InboxDelivery(dedupeKey: 'a', category: InboxCategory.reminder, title: 'Gym', fireAt: now));
    await repo.setSnoozedUntil(Ids.inbox('a'), now.add(const Duration(milliseconds: 300)));
    final values = <int>[];
    final sub = h.container.listen(inboxUnreadCountProvider, (_, next) {
      final value = next.value;
      if (value != null) values.add(value);
    }, fireImmediately: true);
    addTearDown(sub.close);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(values.last, 0);

    h.clock.advance(const Duration(seconds: 2));
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    expect(values.last, 1);
    expect(h.read(notificationsPausedProvider), isFalse);
  });
}
