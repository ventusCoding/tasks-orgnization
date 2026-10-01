import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/presentation/markdown_lite_view.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'planner_ui_support.dart';

/// Markdown-lite renderer and toolbar (T3.1.15).
void main() {
  const note =
      '# Plan\n'
      'Bring **passport** and *tickets*, run `npm test`.\n'
      '- first\n'
      '  - nested\n'
      '1. one\n'
      '- [x] packed\n'
      '- [ ] booked\n'
      '\n'
      'See www.example.com\n'
      '\n'
      'مرحبا **بالعالم**\n'
      '\n'
      '- عنصر';

  Widget app(Widget child, {bool rtl = false, bool dark = false}) => MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: rtl ? const Locale('ar') : const Locale('en'),
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
    localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );

  /// All text spans rendered by rich texts (flattened).
  List<TextSpan> spans(WidgetTester tester) => [
    for (final rich in tester.widgetList<RichText>(find.byType(RichText))) ..._flatten(rich.text),
  ];

  testWidgets('renders headings, emphasis, code, lists, checkboxes and links', (tester) async {
    await tester.pumpWidget(app(const MarkdownLiteView(note)));
    await pumpFor(tester);
    final all = spans(tester);
    TextSpan span(String text) => all.firstWhere((s) => s.text == text);
    expect(span('passport').style!.fontWeight, FontWeight.w700);
    expect(span('tickets').style!.fontStyle, FontStyle.italic);
    expect(span('npm test').style!.fontFamily, 'monospace');
    expect(span('www.example.com').recognizer, isNotNull);
    expect(find.text('•'), findsNWidgets(3));
    expect(find.text('1.'), findsOneWidget);
    expect(find.byIcon(Icons.check_box), findsOneWidget);
    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
    final heading = tester.getSemantics(find.text('Plan'));
    expect(heading.flagsCollection.isHeader, isTrue);
  });

  testWidgets('paragraphs and list items follow their first strong character', (tester) async {
    await tester.pumpWidget(app(const MarkdownLiteView(note)));
    await pumpFor(tester);
    TextDirection directionOf(String text) => Directionality.of(
      tester.element(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains(text))),
    );
    expect(directionOf('مرحبا'), TextDirection.rtl);
    expect(directionOf('Bring'), TextDirection.ltr);
    // The Arabic bullet sits on the right of its text in an LTR note.
    final bullet = tester.getCenter(find.text('•').last);
    final item = tester.getCenter(find.textContaining('عنصر'));
    expect(bullet.dx, greaterThan(item.dx));
  });

  testWidgets('links ask before opening; cancel keeps the app in place', (tester) async {
    await tester.pumpWidget(app(const MarkdownLiteView('See www.example.com')));
    await pumpFor(tester);
    final link = spans(tester).firstWhere((s) => s.text == 'www.example.com');
    (link.recognizer! as TapGestureRecognizer).onTap!();
    await pumpFor(tester);
    expect(find.text('Open link?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await pumpFor(tester);
    expect(find.text('Open link?'), findsNothing);
  });

  testWidgets('toolbar wraps the selection and prefixes the current line', (tester) async {
    final controller = TextEditingController(text: 'buy milk');
    addTearDown(controller.dispose);
    await tester.pumpWidget(app(MarkdownLiteField(controller: controller)));
    await pumpFor(tester);
    controller.selection = const TextSelection(baseOffset: 4, extentOffset: 8);
    await tester.tap(find.byTooltip('Bold'));
    await pumpFor(tester);
    expect(controller.text, 'buy **milk**');
    await tester.tap(find.byTooltip('Bulleted list'));
    await pumpFor(tester);
    expect(controller.text, '- buy **milk**');
  });

  for (final rtl in [false, true]) {
    final name = rtl ? 'rtl' : 'ltr';
    testWidgets('markdown-lite golden $name', (tester) async {
      tester.view.physicalSize = const Size(360, 420);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(const MarkdownLiteView(note), rtl: rtl));
      await pumpFor(tester);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/markdown_lite_$name.png'));
    });
  }
}

List<TextSpan> _flatten(InlineSpan span) => [
  if (span is TextSpan) span,
  if (span is TextSpan)
    for (final child in span.children ?? const <InlineSpan>[]) ..._flatten(child),
];
