import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/data/inbox_repository.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/presentation/reminder_history.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';

/// Per-item notification history (T7.3.09).
void main() {
  late TestHarness h;
  final now = DateTime.utc(2026, 9, 22, 12);
  setUp(() => h = TestHarness.create(now: now));
  tearDown(() => h.dispose());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  Future<void> seed(WidgetTester tester) => tester.runAsync(() async {
    final inbox = h.read(inboxRepositoryProvider);
    Future<void> put(String dk, String title, String sourceId, Duration ago) =>
        inbox.upsertDelivered(
          InboxDelivery(
            dedupeKey: dk,
            category: InboxCategory.reminder,
            title: title,
            body: 'Starts in 10 min',
            fireAt: now.subtract(ago),
            section: NotificationSection.planner,
            sourceType: 'task',
            sourceId: sourceId,
            payload: {'v': 1, 'dk': dk},
          ),
        );
    await put('g1', 'Gym (Monday)', 'gym', const Duration(days: 1));
    await put('g2', 'Gym (today)', 'gym', const Duration(minutes: 5));
    await put('r1', 'Read', 'read', const Duration(hours: 1));
    // Acted and dismissed rows still belong to the history.
    await inbox.markActed(Ids.inbox('g1'), 'done');
    await inbox.dismiss(Ids.inbox('g1'));
  });

  Future<void> pumpHistory(WidgetTester tester, String sourceId) async {
    await pumpInApp(
      tester,
      h,
      Scaffold(
        body: ListView(
          children: [ReminderHistory(sourceType: 'task', sourceId: sourceId)],
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets(
    'lists the past reminders of one source, newest first, acted ones included',
    (tester) async {
      await seed(tester);
      await pumpHistory(tester, 'gym');
      expect(find.text('Reminder history'), findsOneWidget);
      expect(find.text('Gym (today)'), findsOneWidget);
      expect(find.text('Gym (Monday)'), findsOneWidget);
      expect(find.text('Read'), findsNothing);
      final today = tester.getTopLeft(find.text('Gym (today)')).dy;
      final monday = tester.getTopLeft(find.text('Gym (Monday)')).dy;
      expect(today, lessThan(monday));
    },
  );

  testWidgets('empty state for an item without reminders', (tester) async {
    await seed(tester);
    await pumpHistory(tester, 'nothing');
    expect(find.text('No reminders yet'), findsOneWidget);
  });
}
