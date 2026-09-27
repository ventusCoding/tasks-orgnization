import 'dart:async';

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

// Widget tests drive the icon through overridden providers: Drift stream queries listened in the
// fake-async zone hold Drift's lock until the zone is pumped, so a `runAsync` write can wait on it
// forever. The real providers (DB streams + snooze/pause timers) are covered by real-async unit
// tests below, which dispose their container inside the test body.
void main() {
  final now = DateTime.utc(2026, 9, 22, 12);

  group('NotificationBellIcon', () {
    late TestHarness h;
    late StreamController<int> unread;

    Future<void> pumpBell(WidgetTester tester, {bool paused = false}) async {
      unread = StreamController<int>();
      h = TestHarness.create(
        now: now,
        overrides: [
          inboxUnreadCountProvider.overrideWith((ref) => unread.stream),
          notificationsPausedProvider.overrideWithValue(paused),
        ],
      );
      // Container first (cancels the stream subscription); never await the close: its done event
      // would be delivered in the fake-async zone, which is no longer pumped after the test.
      addTearDown(() async {
        await h.dispose();
        unawaited(unread.close());
      });
      await pumpInApp(
        tester,
        h,
        Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                tooltip: 'Inbox',
                onPressed: () {},
                icon: const NotificationBellIcon(),
              ),
            ],
          ),
        ),
      );
      await tester.pump();
    }

    Future<void> emit(WidgetTester tester, int count) async {
      unread.add(count);
      await tester.pump();
      await tester.pump();
    }

    Badge badge(WidgetTester tester) =>
        tester.widget<Badge>(find.byType(Badge));

    testWidgets('no badge while loading or at zero unread', (tester) async {
      await pumpBell(tester);
      expect(badge(tester).isLabelVisible, isFalse);
      expect(find.byIcon(Icons.notifications_none), findsOneWidget);

      await emit(tester, 0);
      expect(badge(tester).isLabelVisible, isFalse);
    });

    testWidgets('badge follows the live unread count', (tester) async {
      await pumpBell(tester);
      await emit(tester, 1);
      expect(badge(tester).isLabelVisible, isTrue);
      expect(find.text('1'), findsOneWidget);

      await emit(tester, 2);
      expect(find.text('2'), findsOneWidget);

      await emit(tester, 0);
      expect(badge(tester).isLabelVisible, isFalse);
    });

    testWidgets('badge is capped at 99+', (tester) async {
      await pumpBell(tester);
      await emit(tester, 99);
      expect(find.text('99'), findsOneWidget);
      await emit(tester, 120);
      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('a paused bell with a label while "Pause all" is active', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpBell(tester, paused: true);
      expect(find.byIcon(Icons.notifications_paused_outlined), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none), findsNothing);
      expect(
        find.bySemanticsLabel(RegExp('Notifications paused')),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('Arabic label for the paused bell', (tester) async {
      unread = StreamController<int>();
      h = TestHarness.create(
        now: now,
        overrides: [
          inboxUnreadCountProvider.overrideWith((ref) => unread.stream),
          notificationsPausedProvider.overrideWithValue(true),
        ],
      );
      // Container first (cancels the stream subscription); never await the close: its done event
      // would be delivered in the fake-async zone, which is no longer pumped after the test.
      addTearDown(() async {
        await h.dispose();
        unawaited(unread.close());
      });
      final semantics = tester.ensureSemantics();
      await pumpInApp(
        tester,
        h,
        const Scaffold(body: Center(child: NotificationBellIcon())),
        locale: const Locale('ar'),
      );
      await tester.pump();
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.semanticLabel, 'الإشعارات موقوفة مؤقتًا');
      semantics.dispose();
    });
  });

  group('bell providers (real async)', () {
    late TestHarness h;
    setUp(() => h = TestHarness.create(now: now));
    tearDown(() => h.dispose());

    InboxDelivery delivery(int i) => InboxDelivery(
      dedupeKey: 'k$i',
      category: InboxCategory.reminder,
      title: 'R$i',
      fireAt: now,
    );

    /// Polls [condition] with short real delays (bounded: 3 s).
    Future<void> until(bool Function() condition) async {
      for (var i = 0; i < 60 && !condition(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }

    test('unread count follows deliveries, reads and dismissals', () async {
      final repo = h.read(inboxRepositoryProvider);
      final values = <int>[];
      final sub = h.container.listen(inboxUnreadCountProvider, (_, next) {
        final value = next.value;
        if (value != null) values.add(value);
      }, fireImmediately: true);
      try {
        await until(() => values.isNotEmpty);
        expect(values.last, 0);

        await repo.upsertDelivered(delivery(1));
        await repo.upsertDelivered(delivery(2));
        await until(() => values.last == 2);
        expect(values.last, 2);

        await repo.markRead([Ids.inbox('k1')]);
        await until(() => values.last == 1);
        expect(values.last, 1);
      } finally {
        sub.close();
        h.container.dispose();
      }
    });

    test('a snoozed row counts as unread again once its snooze ends', () async {
      final repo = h.read(inboxRepositoryProvider);
      await repo.upsertDelivered(delivery(1));
      await repo.setSnoozedUntil(
        Ids.inbox('k1'),
        now.add(const Duration(milliseconds: 300)),
      );
      final values = <int>[];
      final sub = h.container.listen(inboxUnreadCountProvider, (_, next) {
        final value = next.value;
        if (value != null) values.add(value);
      }, fireImmediately: true);
      try {
        await until(() => values.isNotEmpty);
        expect(values.last, 0);

        // The provider re-evaluates 1 s after the snooze end (real timer here).
        h.clock.advance(const Duration(seconds: 2));
        await until(() => values.last == 1);
        expect(values.last, 1);
      } finally {
        sub.close();
        h.container.dispose();
      }
    });

    test('paused while "Pause all" runs, back to false when it ends', () async {
      await h.read(settingsRepositoryProvider).update(
        SettingsNs.notifications,
        {
          'pausedUntil': now
              .add(const Duration(milliseconds: 300))
              .toIso8601String(),
        },
      );
      final values = <bool>[];
      final sub = h.container.listen(
        notificationsPausedProvider,
        (_, next) => values.add(next),
        fireImmediately: true,
      );
      try {
        await until(() => values.contains(true));
        expect(values.last, isTrue);

        h.clock.advance(const Duration(seconds: 1));
        await until(() => values.last == false);
        expect(values.last, isFalse);
      } finally {
        sub.close();
        h.container.dispose();
      }
    });

    test('an expired pause is not active', () async {
      await h.read(settingsRepositoryProvider).update(
        SettingsNs.notifications,
        {
          'pausedUntil': now
              .subtract(const Duration(minutes: 1))
              .toIso8601String(),
        },
      );
      final values = <bool>[];
      final sub = h.container.listen(
        notificationsPausedProvider,
        (_, next) => values.add(next),
        fireImmediately: true,
      );
      try {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        expect(values, everyElement(isFalse));
      } finally {
        sub.close();
        h.container.dispose();
      }
    });
  });
}
