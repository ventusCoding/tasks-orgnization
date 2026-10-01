import 'package:everslot/features/notifications/application/notifications_engine.dart' show seedNotificationDefaults;
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/presentation/simple_rule_editor.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';

void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 9)));
  tearDown(() => h.dispose());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  SimpleEditorOutcome? outcome;

  Future<void> open(
    WidgetTester tester,
    NotificationTargetType type,
    NotificationSection section, {
    ItemKind kind = ItemKind.timed,
    Locale locale = const Locale('en'),
  }) async {
    outcome = null;
    await tester.runAsync(() => seedNotificationDefaults(h.read));
    await pumpInApp(
      tester,
      h,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                outcome = await showSimpleRuleEditor(context, targetType: type, section: section, itemKind: kind),
            child: const Text('open'),
          ),
        ),
      ),
      locale: locale,
    );
    await tester.tap(find.text('open'));
    await settle(tester);
  }

  Finder chip(String text) => find.widgetWithText(FilterChip, text);
  Finder chipContaining(String text) => find.ancestor(of: find.textContaining(text), matching: find.byType(FilterChip));

  Future<void> add(WidgetTester tester) async {
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await settle(tester);
  }

  RelativeTrigger relative(int i) => outcome!.rules[i].spec.trigger as RelativeTrigger;

  testWidgets('timed task chips', (tester) async {
    await open(tester, NotificationTargetType.task, NotificationSection.planner);
    for (final label in [
      'At start',
      '5 min before',
      '10 min before',
      '15 min before',
      '30 min before',
      '60 min before',
      'At end',
      'Custom…',
    ]) {
      expect(chip(label), findsOneWidget, reason: label);
    }
    expect(chipContaining('1 day before at'), findsOneWidget);
    expect(chip('At a time…'), findsNothing);
    expect(chip('Repeat…'), findsNothing);

    await tester.tap(chip('30 min before'));
    await tester.tap(chip('At end'));
    await tester.pump();
    expect(find.text('Add 2 reminders'), findsOneWidget);
    await add(tester);
    expect(outcome!.rules, hasLength(2));
    expect((relative(0).anchor, relative(0).effectiveOffset), (TriggerAnchor.start, -30));
    expect((relative(1).anchor, relative(1).effectiveOffset), (TriggerAnchor.end, 0));
  });

  testWidgets('all-day and date-only task chips', (tester) async {
    await open(tester, NotificationTargetType.task, NotificationSection.planner, kind: ItemKind.allDay);
    expect(chipContaining('On the day at'), findsOneWidget);
    expect(chipContaining('1 day before at'), findsOneWidget);
    expect(chipContaining('On the last day at'), findsOneWidget);
    await tester.tap(chipContaining('On the last day at'));
    await tester.pump();
    await add(tester);
    final t = relative(0);
    expect((t.anchor, t.dayOffset, t.atTime), (TriggerAnchor.end, 0, LocalTime(18, 0)));

    await open(tester, NotificationTargetType.task, NotificationSection.planner, kind: ItemKind.dateOnly);
    expect(chipContaining('On the day at'), findsOneWidget);
    expect(chipContaining('On the last day at'), findsNothing);
  });

  testWidgets('checklist item chips: due, follow-up, every day, at a time, repeat', (tester) async {
    await open(tester, NotificationTargetType.checklistItem, NotificationSection.checklists);
    for (final label in ['At due', 'At follow-up', 'At a time…', 'Repeat…', 'Custom…']) {
      expect(chip(label), findsOneWidget, reason: label);
    }
    expect(chipContaining('Every day at'), findsOneWidget);
    expect(chipContaining('1 day before at'), findsOneWidget);

    await tester.tap(chip('At follow-up'));
    await tester.tap(chipContaining('Every day at'));
    await tester.pump();
    await add(tester);
    expect(relative(0).anchor, TriggerAnchor.followUp);
    final schedule = outcome!.rules[1].spec.trigger as ScheduleTrigger;
    expect(schedule.recurrence['freq'], 'daily');
    expect(schedule.recurrence['times'], ['09:00']);
  });

  testWidgets('habit and quit chips', (tester) async {
    await open(tester, NotificationTargetType.habit, NotificationSection.habits);
    for (final label in ['At slot time', 'Streak at risk', 'At a time…', 'Repeat…']) {
      expect(chip(label), findsOneWidget, reason: label);
    }
    expect(chipContaining('If not done by'), findsOneWidget);
    await tester.tap(chipContaining('If not done by'));
    await tester.tap(chip('Streak at risk'));
    await tester.pump();
    await add(tester);
    expect(outcome!.rules.first.spec.trigger, isA<NotDoneByTrigger>());
    expect((outcome!.rules.first.spec.trigger as NotDoneByTrigger).atTime, LocalTime(21, 0));
    expect(outcome!.rules.last.spec.trigger, isA<StreakRiskTrigger>());

    await open(tester, NotificationTargetType.habit, NotificationSection.quit);
    expect(chip('Milestones'), findsOneWidget);
    expect(chip('At slot time'), findsNothing);
  });

  testWidgets('custom offset: 2 hours before the start', (tester) async {
    await open(tester, NotificationTargetType.task, NotificationSection.planner);
    await tester.tap(chip('Custom…'));
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('notif-custom-amount')), '2');
    await tester.tap(find.text('minutes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('hours').last);
    await tester.pumpAndSettle();
    await add(tester);
    expect((relative(0).anchor, relative(0).effectiveOffset), (TriggerAnchor.start, -120));
  });

  testWidgets('custom day form: 3 days before at 20:00, and inline validation beyond 30 days', (tester) async {
    await open(tester, NotificationTargetType.checklistItem, NotificationSection.checklists);
    await tester.tap(chip('Custom…'));
    await tester.pump();
    await tester.tap(find.text('N days before or after at a time'));
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('notif-custom-amount')), '31');
    await tester.pump();
    expect(find.text('The offset must be within 30 days'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);

    await tester.enterText(find.byKey(const ValueKey('notif-custom-amount')), '3');
    await tester.pump();
    expect(find.text('The offset must be within 30 days'), findsNothing);
    await add(tester);
    final t = relative(0);
    expect((t.anchor, t.dayOffset, t.atTime), (TriggerAnchor.due, -3, LocalTime(20, 0)));
  });

  testWidgets('at a time: absolute date and time through the pickers', (tester) async {
    await open(tester, NotificationTargetType.checklistItem, NotificationSection.checklists);
    await tester.tap(chip('At a time…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK')); // date picker (tomorrow)
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK')); // time picker (09:00)
    await tester.pumpAndSettle();
    expect(chipContaining('On '), findsOneWidget);
    await add(tester);
    final t = outcome!.rules.single.spec.trigger as AbsoluteTrigger;
    expect(t.at, LocalDateTime.of(2026, 9, 23, 9));
  });

  testWidgets('delivery toggles and the advanced editor hand-off', (tester) async {
    await open(tester, NotificationTargetType.task, NotificationSection.planner);
    await tester.tap(chip('At start'));
    await tester.ensureVisible(find.widgetWithText(SwitchListTile, 'Show in inbox'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SwitchListTile, 'Sound'));
    await tester.tap(find.widgetWithText(SwitchListTile, 'Show in inbox'));
    await tester.pump();
    await add(tester);
    final delivery = outcome!.rules.single.spec.delivery;
    expect(delivery.sound, 'none');
    expect(delivery.inbox, isFalse);
    expect(delivery.system, isNull); // inherited

    await open(tester, NotificationTargetType.task, NotificationSection.planner);
    await tester.tap(chip('15 min before'));
    await tester.pump();
    await tester.ensureVisible(find.text('Advanced…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Advanced…'));
    await settle(tester);
    expect(outcome!.openAdvanced, isTrue);
    expect(relative(0).effectiveOffset, -15);
  });

  testWidgets('Arabic: chips are localized and nothing overflows', (tester) async {
    await open(
      tester,
      NotificationTargetType.checklistItem,
      NotificationSection.checklists,
      locale: const Locale('ar'),
    );
    expect(chip('تكرار…'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
