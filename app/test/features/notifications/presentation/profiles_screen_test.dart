import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart'
    show seedNotificationDefaults;
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/rule_draft.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/presentation/profiles_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';

/// Custom profiles editor (T7.1.13).
void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 6)));
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

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.runAsync(() => seedNotificationDefaults(h.read));
    await pumpInApp(tester, h, const NotificationProfilesScreen());
    await settle(tester);
  }

  Future<List<NotificationProfile>> profiles(WidgetTester tester) async =>
      await tester.runAsync(
        () => h.read(notificationProfilesRepositoryProvider).all(),
      ) ??
      const [];

  testWidgets(
    'built-ins are listed (Alarm hidden) and can only be duplicated',
    (tester) async {
      await pumpScreen(tester);
      for (final name in ['Gentle', 'Standard', 'Nag until done']) {
        expect(
          find.widgetWithText(ListTile, name),
          findsOneWidget,
          reason: name,
        );
      }
      expect(find.widgetWithText(ListTile, 'Alarm'), findsNothing);

      await tester.tap(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Standard'),
          matching: find.byIcon(Icons.more_vert),
        ),
      );
      await settle(tester);
      expect(find.text('Duplicate'), findsOneWidget);
      expect(find.text('Rename'), findsNothing);
      expect(find.text('Delete profile'), findsNothing);
      await tester.tap(find.text('Duplicate'));
      await settle(tester);
      expect(find.widgetWithText(ListTile, 'Standard 2'), findsOneWidget);
      final copy = (await profiles(tester))
          .firstWhere((p) => p.name == 'Standard 2');
      expect(copy.isBuiltin, isFalse);
      expect(
        copy.spec.delivery.importance,
        BuiltinProfiles.specs[BuiltinProfiles.standard]!.delivery.importance,
      );
    },
  );

  testWidgets('create, rename and delete a custom profile', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('New profile'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Work focus');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.widgetWithText(ListTile, 'Work focus'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Work focus'),
        matching: find.byIcon(Icons.more_vert),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Rename'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Deep work');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.widgetWithText(ListTile, 'Deep work'), findsOneWidget);

    // Unused → a simple confirmation.
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Deep work'),
        matching: find.byIcon(Icons.more_vert),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Delete profile'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm').last);
    await settle(tester);
    expect(find.widgetWithText(ListTile, 'Deep work'), findsNothing);
  });

  testWidgets('deleting a profile in use asks where its rules go', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await seedNotificationDefaults(h.read);
      final profiles = h.read(notificationProfilesRepositoryProvider);
      await profiles.create(name: 'Loud', spec: const ProfileSpec());
      final loud = (await profiles.all()).firstWhere((p) => p.name == 'Loud');
      await h.read(notificationRulesRepositoryProvider).create([
        RuleDraft(
          targetType: RuleTargetType.task,
          targetId: 't1',
          section: NotificationSection.planner,
          profileId: loud.id,
          spec: const NotificationRuleSpec(
            trigger: RelativeTrigger(
              anchor: TriggerAnchor.start,
              offsetMinutes: 0,
            ),
          ),
        ),
      ]);
    });
    await pumpInApp(tester, h, const NotificationProfilesScreen());
    await settle(tester);
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Loud'),
        matching: find.byIcon(Icons.more_vert),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Delete profile'));
    await settle(tester);
    // The sheet lists the other profiles; move the rule to Gentle.
    await tester.tap(find.widgetWithText(ListTile, 'Gentle').last);
    await settle(tester);
    final rules = await tester.runAsync(
      () => h
          .read(notificationRulesRepositoryProvider)
          .forTarget(RuleTargetType.task, 't1'),
    );
    final gentle = (await profiles(tester))
        .firstWhere((p) => p.code == BuiltinProfiles.gentle);
    expect(rules!.single.profileId, gentle.id);
    expect(find.widgetWithText(ListTile, 'Loud'), findsNothing);
  });

  test(
    'reorder moves a profile after another one (hidden ones keep their place)',
    () async {
      await seedNotificationDefaults(h.read);
      final repo = h.read(notificationProfilesRepositoryProvider);
      Future<List<String?>> codes() async => [
        for (final p in await repo.all()) p.code,
      ];
      expect(await codes(), ['gentle', 'standard', 'nag', 'alarm']);
      final byCode = {for (final p in await repo.all()) p.code: p.id};
      await repo.reorder(byCode['nag']!);
      expect(await codes(), ['nag', 'gentle', 'standard', 'alarm']);
      await repo.reorder(byCode['nag']!, afterId: byCode['standard']);
      expect(await codes(), ['gentle', 'standard', 'nag', 'alarm']);
      await repo.reorder(byCode['gentle']!, afterId: byCode['alarm']);
      expect(await codes(), ['standard', 'nag', 'alarm', 'gentle']);
      expect(await repo.reorder(byCode['gentle']!, afterId: 'missing'), isNull);
    },
  );
}
