import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/data/inbox_repository.dart';
import 'package:everslot/features/notifications/notification_contributions.dart';
import 'package:everslot/features/notifications/presentation/inbox_screen.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';

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

  /// Lets a debounced replan (1.5 s) run so no timer is left pending.
  Future<void> drainReplan(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
  }

  Future<void> deliver(
    WidgetTester tester,
    String dk, {
    required String title,
    DateTime? at,
    NotificationSection section = NotificationSection.planner,
    InboxCategory category = InboxCategory.reminder,
    Map<String, Object?> payload = const {},
    String sourceType = 'task',
    String sourceId = 'gym',
    bool late = false,
  }) => tester.runAsync(
    () => h
        .read(inboxRepositoryProvider)
        .upsertDelivered(
          InboxDelivery(
            dedupeKey: dk,
            category: category,
            title: title,
            body: 'Starts in 10 min',
            fireAt: at ?? now.subtract(const Duration(minutes: 5)),
            section: section,
            sourceType: sourceType,
            sourceId: sourceId,
            payload: {'v': 1, 'dk': dk, ...payload},
            late: late,
          ),
        ),
  );

  final opened = <String>[];

  Future<void> pumpInbox(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    opened.clear();
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const InboxScreen()),
        GoRoute(
          path: '/task/:id',
          builder: (_, state) {
            opened.add(state.uri.toString());
            return const Scaffold(body: Text('task page'));
          },
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: h.container,
        child: MaterialApp.router(
          routerConfig: router,
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
        ),
      ),
    );
    await settle(tester);
  }

  Future<InboxItemView> row(WidgetTester tester, String dk) async {
    final item = await tester.runAsync(
      () => h.read(inboxRepositoryProvider).byId(Ids.inbox(dk)),
    );
    return InboxItemView(
      item!.readAt,
      item.dismissedAt,
      item.actedAt,
      item.action,
      item.openedAt,
      item.snoozedUntil,
    );
  }

  testWidgets('empty inbox and "all caught up"', (tester) async {
    await pumpInbox(tester);
    expect(find.text('No notifications yet'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'Unread'));
    await settle(tester);
    expect(find.text('All caught up'), findsOneWidget);
  });

  testWidgets(
    'rows are grouped by day, nag chains collapse, late rows are flagged',
    (tester) async {
      await deliver(tester, 'a', title: 'Gym');
      await deliver(
        tester,
        'b',
        title: 'Water',
        at: now.subtract(const Duration(days: 1)),
        late: true,
      );
      await deliver(
        tester,
        'c',
        title: 'Report',
        at: DateTime.utc(2026, 9, 18, 9),
      );
      for (var i = 0; i < 3; i++) {
        await deliver(
          tester,
          'nag$i',
          title: 'Call Sam',
          payload: {'bk': 'nag-base'},
          at: now.subtract(Duration(minutes: 30 - i)),
        );
      }
      await pumpInbox(tester);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Call Sam'), findsOneWidget);
      expect(find.text('×3'), findsOneWidget);
      expect(find.text('Late'), findsOneWidget);
      final semantics = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel(
          RegExp(r'^Unread reminder, Gym, Starts in 10 min, 5 minutes ago'),
        ),
        findsOneWidget,
      );
      semantics.dispose();
      // Older days further down the list.
      final list = find
          .descendant(
            of: find.byType(RefreshIndicator),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Yesterday'),
        200,
        scrollable: list,
      );
      expect(find.text('Yesterday'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Friday, September 18'),
        200,
        scrollable: list,
      );
      expect(find.text('Friday, September 18'), findsOneWidget);
    },
  );

  testWidgets('filters: unread only and per section', (tester) async {
    await deliver(tester, 'a', title: 'Gym');
    await deliver(
      tester,
      'b',
      title: 'Buy milk',
      section: NotificationSection.checklists,
      sourceType: 'checklist_item',
    );
    await tester.runAsync(
      () => h.read(inboxRepositoryProvider).markRead([Ids.inbox('a')]),
    );
    await pumpInbox(tester);
    expect(find.text('Gym'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Unread'));
    await settle(tester);
    expect(find.text('Gym'), findsNothing);
    expect(find.text('Buy milk'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Unread'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilterChip, 'Plan'));
    await settle(tester);
    expect(find.text('Gym'), findsOneWidget);
    expect(find.text('Buy milk'), findsNothing);
  });

  testWidgets(
    'swipe right toggles read, swipe left dismisses with undo, mark all read',
    (tester) async {
      await deliver(tester, 'a', title: 'Gym');
      await deliver(tester, 'b', title: 'Water');
      await pumpInbox(tester);

      await tester.drag(find.text('Gym'), const Offset(500, 0));
      await settle(tester);
      expect((await row(tester, 'a')).readAt, isNotNull);
      expect(find.text('Marked as read'), findsOneWidget);

      await tester.drag(find.text('Water'), const Offset(-500, 0));
      await settle(tester);
      expect((await row(tester, 'b')).dismissedAt, isNotNull);
      expect(find.text('Water'), findsNothing);
      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect((await row(tester, 'b')).dismissedAt, isNull);
      expect(find.text('Water'), findsOneWidget);

      await tester.tap(find.byTooltip('Mark all read'));
      await settle(tester);
      expect((await row(tester, 'b')).readAt, isNotNull);
    },
  );

  testWidgets(
    'inline actions call the same handler as OS notifications, once',
    (tester) async {
      final calls = <String>[];
      h
          .read(notificationRegistryProvider)
          .registerActionHandler(
            CallbackActionHandler(
              actionIds: {NotificationActionIds.done},
              targetTypes: {NotificationTargetType.task},
              onHandle: (c) async {
                calls.add('${c.actionId}:${c.targetId}:${c.origin.name}');
                return NotificationActionResult.ok;
              },
            ),
          );
      await deliver(
        tester,
        'a',
        title: 'Gym',
        payload: {
          'acts': ['done', 'snooze', 'skip'],
        },
      );
      await pumpInbox(tester);
      expect(find.widgetWithText(ActionChip, 'Done'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, 'Snooze'), findsOneWidget);
      expect(
        find.widgetWithText(ActionChip, 'Skip'),
        findsNothing,
        reason: 'two inline actions at most',
      );

      await tester.tap(find.widgetWithText(ActionChip, 'Done'));
      await settle(tester);
      await drainReplan(tester);
      expect(calls, ['done:gym:inbox']);
      final r = await row(tester, 'a');
      expect((r.action, r.actedAt != null), ('done', true));
      expect(find.widgetWithText(ActionChip, 'Done'), findsNothing);
    },
  );

  testWidgets('tapping a row marks it opened and navigates to its deep link', (
    tester,
  ) async {
    await deliver(
      tester,
      'a',
      title: 'Gym',
      payload: {'link': '/task/gym?occ=2026-09-22T12:10'},
    );
    await pumpInbox(tester);
    await tester.tap(find.text('Gym'));
    await settle(tester);
    await drainReplan(tester);
    expect(opened, ['/task/gym?occ=2026-09-22T12:10']);
    expect(find.text('task page'), findsOneWidget);
    expect((await row(tester, 'a')).openedAt, isNotNull);
  });

  testWidgets('snoozed rows are listed on top; wake now clears the snooze', (
    tester,
  ) async {
    await deliver(tester, 'a', title: 'Gym');
    await tester.runAsync(
      () => h
          .read(inboxRepositoryProvider)
          .setSnoozedUntil(
            Ids.inbox('a'),
            now.add(const Duration(minutes: 30)),
          ),
    );
    await pumpInbox(tester);
    expect(find.text('Snoozed'), findsOneWidget);
    expect(find.textContaining('Snoozed until'), findsOneWidget);

    await tester.tap(find.text('Wake now'));
    await settle(tester);
    expect((await row(tester, 'a')).snoozedUntil, isNull);
    expect(find.text('Snoozed'), findsNothing);
  });

  testWidgets('Remind me again… snoozes a past row that was never snoozed', (
    tester,
  ) async {
    await deliver(tester, 'a', title: 'Gym');
    await pumpInbox(tester);
    expect(find.text('Remind me again…'), findsOneWidget);
    await tester.tap(find.text('Remind me again…'));
    await settle(tester);
    await tester.tap(
      find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(ActionChip),
          )
          .first,
    );
    await settle(tester);
    expect((await row(tester, 'a')).snoozedUntil, isNotNull);
    expect(find.text('Snoozed'), findsOneWidget);
    // A snoozed row doesn't offer it again.
    expect(find.text('Remind me again…'), findsNothing);
    await drainReplan(tester);
  });

  testWidgets('Arabic: right-to-left, localized, no overflow', (tester) async {
    await deliver(
      tester,
      'a',
      title: 'رياضة',
      payload: {
        'acts': ['done', 'snooze'],
      },
    );
    await pumpInbox(tester, locale: const Locale('ar'));
    expect(find.text('صندوق الوارد'), findsOneWidget);
    expect(find.text('اليوم'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('رياضة'))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });
}

/// The user-state fields a test checks.
class InboxItemView {
  InboxItemView(
    this.readAt,
    this.dismissedAt,
    this.actedAt,
    this.action,
    this.openedAt,
    this.snoozedUntil,
  );

  final DateTime? readAt;
  final DateTime? dismissedAt;
  final DateTime? actedAt;
  final String? action;
  final DateTime? openedAt;
  final DateTime? snoozedUntil;
}
