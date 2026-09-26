import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_app.dart';

/// RTL baseline (T1.3.14) and runtime locale switching (T1.3.13).
void main() {
  Widget app(Locale locale, Widget home) => MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    home: Scaffold(body: home),
  );

  testWidgets(
    'switching locale at runtime updates strings, formats and direction',
    (tester) async {
      final locale = ValueNotifier(const Locale('en'));
      addTearDown(locale.dispose);
      await tester.pumpWidget(
        ValueListenableBuilder<Locale>(
          valueListenable: locale,
          builder: (_, value, _) => app(
            value,
            Builder(
              builder: (context) => Column(
                children: [
                  Text(context.l10n.actionSearch, key: const Key('string')),
                  Text(
                    AppFormat(
                      context.localeName,
                      l10n: context.l10n,
                    ).duration(2880),
                    key: const Key('format'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      String text(String key) =>
          tester.widget<Text>(find.byKey(Key(key))).data!;
      TextDirection direction() =>
          Directionality.of(tester.element(find.byKey(const Key('string'))));

      for (final (code, days) in [
        ('en', '2 days'),
        ('ar', 'يومان'),
        ('fr', '2 jours'),
      ]) {
        locale.value = Locale(code);
        await tester.pumpAndSettle();
        expect(
          text('string'),
          lookupAppLocalizations(Locale(code)).actionSearch,
        );
        expect(text('format'), days);
        expect(
          direction(),
          code == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
      }
    },
  );

  group('directional icons', () {
    const mirrored = [
      Icons.arrow_back,
      Icons.arrow_forward,
      Icons.chevron_left,
      Icons.chevron_right,
      Icons.format_indent_increase,
      Icons.format_indent_decrease,
      Icons.undo,
      Icons.redo,
      Icons.send,
    ];
    const fixed = [
      Icons.schedule,
      Icons.check,
      Icons.search,
      Icons.add,
      Icons.flag,
    ];

    test('directional icons mirror, clocks and checks do not', () {
      for (final icon in mirrored) {
        expect(icon.matchTextDirection, isTrue, reason: '$icon');
      }
      for (final icon in fixed) {
        expect(icon.matchTextDirection, isFalse, reason: '$icon');
      }
    });

    testWidgets('a back arrow is flipped in Arabic, a clock is not', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          const Locale('ar'),
          const Row(
            children: [
              Icon(Icons.arrow_back, key: Key('back')),
              Icon(Icons.schedule, key: Key('clock')),
            ],
          ),
        ),
      );
      Finder transformIn(String key) => find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(Transform),
      );
      expect(transformIn('back'), findsOneWidget);
      expect(transformIn('clock'), findsNothing);
    });
  });

  group('design-system components in Arabic', () {
    late TestHarness h;
    setUp(() => h = TestHarness.create());
    tearDown(() => h.dispose());

    testWidgets('section header, pill and empty state lay out right-to-left', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        h,
        const Scaffold(
          body: Column(
            children: [
              SectionHeader(
                'عنوان',
                trailing: Icon(Icons.more_vert, key: Key('trailing')),
              ),
              StatusPill(
                label: 'قيد التنفيذ',
                color: Colors.blue,
                icon: Icons.play_arrow,
              ),
              Expanded(
                child: EmptyState(
                  title: 'لا شيء هنا',
                  icon: Icons.inbox_outlined,
                ),
              ),
            ],
          ),
        ),
        locale: const Locale('ar'),
      );
      await tester.pumpAndSettle();
      final title = tester.getRect(find.text('عنوان'));
      final trailing = tester.getRect(find.byKey(const Key('trailing')));
      expect(
        trailing.right,
        lessThanOrEqualTo(title.left + 0.5),
        reason: 'trailing sits at the end (left) side',
      );
      // The header's leading inset is on the right.
      final screen = tester.getSize(find.byType(Scaffold));
      expect(title.right, closeTo(screen.width - Space.lg, 0.5));
      final pillIcon = tester.getRect(find.byIcon(Icons.play_arrow));
      final pillLabel = tester.getRect(find.text('قيد التنفيذ'));
      expect(
        pillIcon.left,
        greaterThan(pillLabel.right - 0.5),
        reason: 'icon leads on the right',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('priority selector reads right-to-left with localized labels', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        h,
        Scaffold(body: PrioritySelector(value: 2, onChanged: (_) {})),
        locale: const Locale('ar'),
      );
      await tester.pumpAndSettle();
      final ar = lookupAppLocalizations(const Locale('ar'));
      final none = tester.getRect(find.text(ar.priorityNone));
      final low = tester.getRect(find.text(ar.priorityLow));
      expect(
        none.left,
        greaterThan(low.left),
        reason: 'first chip is on the right',
      );
    });
  });

  group('BidiText', () {
    test('wraps runs in isolates and strips controls', () {
      expect(BidiText.ltr('v1.2'), '⁦v1.2⁩');
      expect(BidiText.rtl('مرحبا'), '⁧مرحبا⁩');
      expect(BidiText.isolate('Report'), '⁨Report⁩');
      expect(BidiText.strip('‏${BidiText.isolate('Report')}‎'), 'Report');
    });

    test('detects the first strong direction', () {
      expect(BidiText.startsRtl('مرحبا Hello'), isTrue);
      expect(BidiText.startsRtl('Hello مرحبا'), isFalse);
      expect(BidiText.startsRtl('123 - مرحبا'), isTrue);
      expect(BidiText.startsRtl('12:30'), isFalse);
      expect(BidiText.startsRtl('Élan'), isFalse);
    });

    testWidgets('an isolated Latin title inside Arabic text renders', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          const Locale('ar'),
          Text('تم إكمال ${BidiText.isolate('Weekly report (v2)')} للتو'),
        ),
      );
      expect(find.textContaining('Weekly report (v2)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
