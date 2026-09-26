import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart'
    show seedNotificationDefaults;
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/rule_draft.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/presentation/notification_settings_section.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';

void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 9)));
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

  Future<void> insertTask(
    WidgetTester tester,
    String id, {
    String notifyMode = 'inherit',
  }) => tester.runAsync(
    () => h
        .read(syncWriterProvider)
        .run(
          (tx) => tx.insert('tasks', id, {
            'series_id': id,
            'title': 'Gym',
            'notify_mode': notifyMode,
          }),
        ),
  );

  Future<void> seedDefaults(WidgetTester tester) =>
      tester.runAsync(() => seedNotificationDefaults(h.read));

  Future<String?> notifyModeOf(WidgetTester tester, String id) async {
    final row = await tester.runAsync(
      () =>
          (h.db.select(h.db.tasks)..where((t) => t.id.equals(id))).getSingle(),
    );
    return row?.notifyMode;
  }

  Future<List<NotificationRule>> ownRules(
    WidgetTester tester,
    String id,
  ) async =>
      await tester.runAsync(
        () => h
            .read(notificationRulesRepositoryProvider)
            .forTarget(RuleTargetType.task, id),
      ) ??
      const [];

  Widget host({NotificationRulesDraft? draft, String id = 't1'}) => Scaffold(
    body: ListView(
      children: [
        NotificationSettingsSection(
          targetType: NotificationTargetType.task,
          targetId: id,
          section: NotificationSection.planner,
          draft: draft,
        ),
      ],
    ),
  );

  testWidgets(
    'inherited planner defaults are listed greyed with their provenance',
    (tester) async {
      await seedDefaults(tester);
      await insertTask(tester, 't1');
      await pumpInApp(tester, h, host());
      await settle(tester);

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('10 min before start · Standard'), findsOneWidget);
      expect(find.text('At start · Standard'), findsOneWidget);
      expect(find.text('From section defaults'), findsNWidgets(2));
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Use defaults'),
      );
      expect(chip.selected, isTrue);
      expect(find.text('Customize'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '"10 min before" and "at start" are added in 4 taps (switches to Defaults + mine)',
    (tester) async {
      await insertTask(tester, 't1');
      await pumpInApp(tester, h, host());
      await settle(tester);
      expect(find.text('No reminders'), findsOneWidget);

      await tester.tap(find.text('Add reminder')); // 1
      await settle(tester);
      await tester.tap(find.widgetWithText(FilterChip, '10 min before')); // 2
      await tester.pump();
      await tester.tap(find.widgetWithText(FilterChip, 'At start')); // 3
      await tester.pump();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Add 2 reminders'),
      ); // 4
      await settle(tester);

      final rules = await ownRules(tester, 't1');
      expect(rules, hasLength(2));
      final offsets = {
        for (final r in rules)
          (r.spec.trigger as RelativeTrigger).effectiveOffset,
      };
      expect(offsets, {-10, 0});
      expect(await notifyModeOf(tester, 't1'), 'inherit_plus');
      expect(find.text('10 min before start'), findsOneWidget);
      expect(find.text('At start'), findsWidgets);
    },
  );

  testWidgets('mode chips write notify_mode; Off hides every reminder', (
    tester,
  ) async {
    await seedDefaults(tester);
    await insertTask(tester, 't1');
    await pumpInApp(tester, h, host());
    await settle(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Custom'));
    await settle(tester);
    expect(await notifyModeOf(tester, 't1'), 'custom');
    expect(find.text('From section defaults'), findsNothing);
    expect(find.text('No reminders'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Off'));
    await settle(tester);
    expect(await notifyModeOf(tester, 't1'), 'off');
    expect(find.text('No notifications for this item'), findsOneWidget);
    expect(find.text('Add reminder'), findsNothing);
  });

  testWidgets(
    'Customize copies the inherited rules as own and switches to Custom',
    (tester) async {
      await seedDefaults(tester);
      await insertTask(tester, 't1');
      await pumpInApp(tester, h, host());
      await settle(tester);

      await tester.tap(find.text('Customize'));
      await settle(tester);
      expect(await ownRules(tester, 't1'), hasLength(2));
      expect(await notifyModeOf(tester, 't1'), 'custom');
      expect(find.text('From section defaults'), findsNothing);
      expect(find.text('10 min before start · Standard'), findsOneWidget);
      expect(find.byType(Switch), findsNWidgets(2));
    },
  );

  testWidgets('toggle, then swipe to delete an own reminder and undo', (
    tester,
  ) async {
    await insertTask(tester, 't1', notifyMode: 'custom');
    await tester.runAsync(
      () => h.read(notificationRulesRepositoryProvider).create([
        const RuleDraft(
          targetType: RuleTargetType.task,
          targetId: 't1',
          section: NotificationSection.planner,
          spec: NotificationRuleSpec(
            trigger: RelativeTrigger(
              anchor: TriggerAnchor.start,
              offsetMinutes: -15,
            ),
          ),
        ),
      ]),
    );
    await pumpInApp(tester, h, host());
    await settle(tester);
    expect(find.text('15 min before start'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await settle(tester);
    expect((await ownRules(tester, 't1')).single.enabled, isFalse);

    await tester.drag(find.text('15 min before start'), const Offset(-600, 0));
    await settle(tester);
    expect(find.text('15 min before start'), findsNothing);
    expect(await ownRules(tester, 't1'), isEmpty);
    expect(find.text('Reminder deleted'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(await ownRules(tester, 't1'), hasLength(1));
    expect(find.text('15 min before start'), findsOneWidget);
  });

  testWidgets(
    'drafts keep reminders in memory until the host saves them with the item',
    (tester) async {
      final draft = NotificationRulesDraft();
      await pumpInApp(tester, h, host(draft: draft, id: 'new-task'));
      await settle(tester);

      await tester.tap(find.text('Add reminder'));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilterChip, '5 min before'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Add 1 reminder'));
      await settle(tester);

      expect(draft.rules, hasLength(1));
      expect(draft.notifyMode, NotifyMode.inheritPlus);
      expect(find.text('5 min before start'), findsOneWidget);
      expect(await ownRules(tester, 'new-task'), isEmpty);

      await tester.runAsync(
        () => h.read(syncWriterProvider).run((tx) async {
          await tx.insert('tasks', 'new-task', {
            'series_id': 'new-task',
            'title': 'New',
          });
          await h
              .read(notificationHostApiProvider)
              .saveDraftInTx(
                tx,
                draft,
                type: NotificationTargetType.task,
                targetId: 'new-task',
              );
        }),
      );
      final saved = await ownRules(tester, 'new-task');
      expect(saved, hasLength(1));
      expect(
        (saved.single.spec.trigger as RelativeTrigger).effectiveOffset,
        -5,
      );
      expect(await notifyModeOf(tester, 'new-task'), 'inherit_plus');
    },
  );

  testWidgets('mute from the section shows a badge with Unmute', (
    tester,
  ) async {
    await insertTask(tester, 't1');
    await pumpInApp(tester, h, host());
    await settle(tester);

    await tester.tap(find.byTooltip('Mute…'));
    await settle(tester);
    await tester.tap(find.text('1 hour'));
    await settle(tester);
    final mutes = await tester.runAsync(
      () => h.read(notificationMutesRepositoryProvider).all(),
    );
    expect(mutes, hasLength(1));
    expect(mutes!.single.targetType, 'task');
    expect(mutes.single.until, DateTime.utc(2026, 9, 22, 10));
    expect(find.text('Unmute'), findsOneWidget);

    await tester.tap(find.text('Unmute'));
    await settle(tester);
    expect(find.text('Unmute'), findsNothing);
  });

  testWidgets('a disabled section shows a hint', (tester) async {
    await insertTask(tester, 't1');
    await tester.runAsync(
      () =>
          h.read(settingsRepositoryProvider).update(SettingsNs.notifications, {
            'perSection': {
              'planner': {'enabled': false},
            },
          }),
    );
    await pumpInApp(tester, h, host());
    await settle(tester);
    expect(
      find.text('Plan notifications are turned off in Settings'),
      findsOneWidget,
    );
  });

  testWidgets(
    'next reminders preview the effective rules and send a test notification',
    (tester) async {
      await seedDefaults(tester);
      await insertTask(tester, 't1');
      await pumpInApp(tester, h, host());
      await settle(tester);

      await tester.tap(find.text('Next reminders'));
      await settle(tester);
      // Sample occurrence tomorrow 09:00 (UTC device zone, 12 h clock in tests): 08:50 and 09:00.
      expect(
        find.textContaining(
          RegExp(r'^Wed 23 · 8:50.AM — 10 min before start$'),
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(RegExp(r'^Wed 23 · 9:00.AM — At start$')),
        findsOneWidget,
      );

      await tester.tap(find.text('Send test notification'));
      await settle(tester);
      final port = h.read(
        localNotificationsPortProvider,
      ) as InMemoryLocalNotificationsPort;
      expect(port.scheduled, hasLength(1));
      expect(find.text('Test notification in 5 seconds'), findsOneWidget);
    },
  );

  testWidgets('Arabic: localized, right-to-left, no overflow', (tester) async {
    await seedDefaults(tester);
    await insertTask(tester, 't1');
    await pumpInApp(tester, h, host(), locale: const Locale('ar'));
    await settle(tester);

    expect(find.text('الإشعارات'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'الافتراضي'), findsOneWidget);
    expect(find.text('عند البدء · قياسي'), findsOneWidget);
    expect(find.text('من افتراضيات القسم'), findsNWidgets(2));
    expect(find.text('إضافة تذكير'), findsOneWidget);
    final context = tester.element(find.text('إضافة تذكير'));
    expect(Directionality.of(context), TextDirection.rtl);

    await tester.tap(find.text('إضافة تذكير'));
    await settle(tester);
    expect(find.widgetWithText(FilterChip, 'عند البدء'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
