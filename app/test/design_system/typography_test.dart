@Tags(['golden'])
library;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fonts.dart';

/// T1.3.09: the bundled fonts render (tests load them from `assets/fonts`, flutter_test does not),
/// Arabic falls back to Noto Sans Arabic, tabular figures align times; goldens EN/AR × 1.0/2.0.
void main() {
  setUpAll(loadAppFonts);

  double width(String text, TextStyle style, {TextDirection direction = TextDirection.ltr}) {
    final p = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
    )..layout();
    final w = p.width;
    p.dispose();
    return w;
  }

  const base = TextStyle(fontFamily: AppTypography.latin, fontFamilyFallback: AppTypography.fallback, fontSize: 20);

  test('the bundled Latin font is proportional; tabular figures make digits equal width', () {
    expect(width('1111', base), lessThan(width('0000', base)), reason: 'Inter is loaded (not the test font)');
    final tab = AppTypography.tabular(base)!;
    expect(width('1111', tab), closeTo(width('0000', tab), 0.01));
    expect(width('07:03', tab), closeTo(width('18:58', tab), 0.01), reason: 'times align in columns');
  });

  test('Arabic glyphs come from Noto Sans Arabic through the fallback', () {
    const arabic = 'اجتماع الفريق';
    final viaFallback = width(arabic, base, direction: TextDirection.rtl);
    final direct = width(
      arabic,
      const TextStyle(fontFamily: AppTypography.arabic, fontSize: 20),
      direction: TextDirection.rtl,
    );
    expect(viaFallback, closeTo(direct, 0.5));
  });

  test('the themes use the bundled families', () {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      final style = theme.textTheme.bodyMedium!;
      expect(style.fontFamily, AppTypography.latin);
      expect(style.fontFamilyFallback, AppTypography.fallback);
    }
  });

  for (final (locale, scale) in const [('en', 1.0), ('ar', 1.0), ('en', 2.0), ('ar', 2.0)]) {
    testWidgets('golden type scale $locale ${scale}x', (tester) async {
      tester.view
        ..physicalSize = const Size(420, 1100)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          locale: Locale(locale),
          supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
          localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
          home: MediaQuery(
            data: MediaQueryData(size: const Size(420, 1100), textScaler: TextScaler.linear(scale)),
            child: const Scaffold(body: _Specimen()),
          ),
        ),
      );
      await expectLater(
        find.byType(_Specimen),
        matchesGoldenFile('goldens/typography_${locale}_${scale.toInt()}x.png'),
      );
    });
  }
}

class _Specimen extends StatelessWidget {
  const _Specimen();

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final ar = Directionality.of(context) == TextDirection.rtl;
    final sample = ar ? 'اجتماع الفريق ‎07:03' : 'Team meeting 07:03';
    final mixed = ar ? 'تمرين Gym في 18:30' : 'Gym — تمرين at 18:30';
    final styles = <(String, TextStyle?)>[
      ('display', t.displaySmall),
      ('headline', t.headlineSmall),
      ('title', t.titleLarge),
      ('body', t.bodyLarge),
      ('label', t.labelMedium),
    ];
    return ListView(
      padding: const EdgeInsets.all(Space.lg),
      children: [
        for (final (name, style) in styles) Text('$name · $sample', style: style),
        const Divider(),
        Text(mixed, style: t.bodyLarge),
        const Divider(),
        for (final time in const ['07:03', '11:11', '18:58', '20:00'])
          Text('$time  –  ${ar ? 'مهمة' : 'Task'}', style: AppTypography.tabular(t.bodyLarge)),
      ],
    );
  }
}
