import 'dart:convert';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart' show seedNotificationDefaults;
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/presentation/advanced_rule_editor.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';

/// Advanced rule editor (T7.1.12): every field group, round trip without edits, errors block
/// saving while warnings don't, Arabic layout, goldens.
void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 6)));
  tearDown(() => h.dispose());

  // A complex rule with an unknown future field (must survive a save without edits).
  const complexJson =
      '{"v":1,"trigger":{"type":"relative","anchor":"start","offsetMinutes":-15},'
      '"repeat":{"everyMinutes":10,"maxTimes":3,"until":"completed"},'
      '"conditions":{"onlyIfStatusIn":["scheduled"],"respectQuietHours":false},'
      '"delivery":{"importance":"high","sound":"none","actions":["done","snooze"],'
      '"snoozeOptionsMinutes":[5,15],"latenessMinutes":20},'
      '"content":{"title":"{title}","body":"In {minutes_until} min"},'
      '"future":{"x":1}}';

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  /// Opens the editor from a host button; the result lands in [results].
  Future<List<RuleEdit?>> open(
    WidgetTester tester,
    NotificationRuleSpec spec, {
    Locale locale = const Locale('en'),
    bool dark = false,
    Size? size,
  }) async {
    if (size != null) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }
    await tester.runAsync(() => seedNotificationDefaults(h.read));
    final results = <RuleEdit?>[];
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: h.container,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: locale,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
          localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  key: const ValueKey('open'),
                  onPressed: () async => results.add(
                    await showAdvancedRuleEditor(
                      context,
                      targetType: NotificationTargetType.task,
                      section: NotificationSection.planner,
                      spec: spec,
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open')));
    await settle(tester);
    return results;
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await settle(tester);
  }

  NotificationRuleSpec decode(String json) =>
      NotificationRuleSpec.fromJson(Map<String, Object?>.from(jsonDecode(json) as Map));

  /// The group tile whose own title is [title] (nested fields may repeat the word).
  Finder group(String title) =>
      find.byWidgetPredicate((w) => w is ExpansionTile && w.title is Text && (w.title as Text).data == title);

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.descendant(of: find.byType(AdvancedRuleEditorScreen), matching: find.byType(Scrollable)).first,
    );
    await tester.pump();
  }

  testWidgets('every field group is present', (tester) async {
    await open(tester, decode(complexJson));
    for (final title in ['Trigger', 'Repeat (nag)', 'Conditions', 'Delivery', 'Content']) {
      await reveal(tester, group(title));
      expect(group(title), findsOneWidget, reason: title);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('saving without edits returns the rule unchanged (unknown keys kept)', (tester) async {
    final spec = decode(complexJson);
    final results = await open(tester, spec);
    await save(tester);
    expect(results, hasLength(1));
    expect(results.single!.spec.encode(), spec.encode());
    expect(results.single!.spec.encode(), contains('"future":{"x":1}'));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('editing the content template updates the rule', (tester) async {
    final results = await open(tester, decode(complexJson));
    await reveal(tester, group('Content'));
    await tester.tap(group('Content'));
    await settle(tester);
    await reveal(tester, find.widgetWithText(TextField, 'Body template'));
    await tester.enterText(find.widgetWithText(TextField, 'Body template'), 'Now: {title}');
    await settle(tester);
    await save(tester);
    expect(results.single!.spec.content.body, 'Now: {title}');
    // The other groups are untouched.
    expect(results.single!.spec.repeat!.everyMinutes, 10);
    expect(results.single!.spec.delivery.importance, 'high');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('errors disable Save; warnings are shown but never block', (tester) async {
    await open(
      tester,
      const NotificationRuleSpec(trigger: OverdueTrigger(), repeat: RepeatSpec(everyMinutes: 5, maxTimes: 11)),
    );
    final button = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Save'));
    expect(button.onPressed, isNull);
    expect(find.text('At most 10 repeats'), findsOneWidget);
    expect(find.textContaining('10 minutes apart'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());

    await open(
      tester,
      const NotificationRuleSpec(trigger: OverdueTrigger(), repeat: RepeatSpec(everyMinutes: 5, maxTimes: 5)),
    );
    expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Save')).onPressed, isNotNull);
    expect(find.textContaining('10 minutes apart'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Arabic: right-to-left without overflow', (tester) async {
    await open(tester, decode(complexJson), locale: const Locale('ar'));
    expect(Directionality.of(tester.element(find.byType(AdvancedRuleEditorScreen))), TextDirection.rtl);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final dark in [false, true]) {
    for (final rtl in [false, true]) {
      final name = '${dark ? 'dark' : 'light'}_${rtl ? 'rtl' : 'ltr'}';
      testWidgets('advanced editor golden $name', (tester) async {
        await open(
          tester,
          decode(complexJson),
          locale: rtl ? const Locale('ar') : const Locale('en'),
          dark: dark,
          size: const Size(360, 780),
        );
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/advanced_rule_editor_$name.png'));
        await tester.pumpWidget(const SizedBox.shrink());
      }, tags: ['golden']);
    }
  }
}
