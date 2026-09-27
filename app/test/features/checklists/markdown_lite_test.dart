// Markdown-lite bodies and notes (T4.1.11): inline styles, headings, bullets, links, per-paragraph
// direction for mixed Arabic/Latin text, and the plain-text formatting toolbar.
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/markdown_edits.dart';
import 'package:everslot/features/checklists/presentation/checklist_screen.dart';
import 'package:everslot/features/checklists/presentation/markdown_lite.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

Widget _app(Widget child, {bool rtl = false}) => MaterialApp(
  locale: Locale(rtl ? 'ar' : 'en'),
  supportedLocales: const [Locale('en'), Locale('ar')],
  localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
  home: Scaffold(body: child),
);

/// Leaf text spans of every RichText under [finder], in order.
List<TextSpan> _leaves(WidgetTester tester, Finder finder) {
  final out = <TextSpan>[];
  for (final rich in tester.widgetList<RichText>(finder)) {
    rich.text.visitChildren((span) {
      if (span is TextSpan && span.text != null && span.text!.isNotEmpty) out.add(span);
      return true;
    });
  }
  return out;
}

TextSpan _span(List<TextSpan> spans, String text) => spans.firstWhere((s) => s.text == text);

/// Style of the leaf [text] merged down from the root span (what the paragraph paints with).
TextStyle? _effectiveStyle(InlineSpan root, String text) {
  TextStyle? walk(InlineSpan span, TextStyle? inherited) {
    if (span is! TextSpan) return null;
    final style = inherited == null ? span.style : inherited.merge(span.style);
    if (span.text == text) return style;
    for (final child in span.children ?? const <InlineSpan>[]) {
      final found = walk(child, style);
      if (found != null) return found;
    }
    return null;
  }

  return walk(root, null);
}

void main() {
  group('MarkdownEdits (pure)', () {
    test('wrap adds markers around the selection and removes them again', () {
      const s = TextEdit('say hello world', 4, 9);
      final bold = MarkdownEdits.wrap(s, '**');
      expect(bold, const TextEdit('say **hello** world', 6, 11));
      expect(MarkdownEdits.wrap(bold, '**'), s, reason: 'toggling restores the text');
      // A selection that includes its markers unwraps too.
      expect(MarkdownEdits.wrap(const TextEdit('a ~~b~~', 2, 7), '~~'), const TextEdit('a b', 2, 3));
    });

    test('wrap with an empty selection inserts a pair and puts the caret inside', () {
      expect(MarkdownEdits.wrap(const TextEdit.atEnd('note '), '`'), const TextEdit('note ``', 6, 6));
    });

    test('line prefixes toggle on every selected line', () {
      const s = TextEdit('one\ntwo\nthree', 1, 6);
      final bullets = MarkdownEdits.toggleLinePrefix(s, '- ');
      expect(bullets.text, '- one\n- two\nthree');
      expect(MarkdownEdits.toggleLinePrefix(bullets, '- ').text, 'one\ntwo\nthree');
      final heading = MarkdownEdits.toggleLinePrefix(const TextEdit('a\nTitle', 4, 4), '# ');
      expect(heading, const TextEdit('a\n# Title', 6, 6), reason: 'the caret follows its text');
    });

    test('link wraps the selection and selects the placeholder address', () {
      final r = MarkdownEdits.link(const TextEdit('see docs', 4, 8));
      expect(r.text, 'see [docs](https://)');
      expect(r.text.substring(r.start, r.end), MarkdownEdits.linkPlaceholder);
      expect(MarkdownEdits.link(const TextEdit.atEnd('x ')), const TextEdit('x [](https://)', 3, 3));
    });

    test('out-of-range selections are clamped', () {
      expect(MarkdownEdits.wrap(const TextEdit('ab', -1, -1), '*').text, '**ab');
    });
  });

  test('stripMarkdown keeps the words only (card excerpts)', () {
    expect(
      stripMarkdown('# Title\n- **bold** and _it_ ~~x~~ `c` [site](https://a.b)'),
      'Title\n• bold and it x c site',
    );
  });

  group('rendering', () {
    testWidgets('inline styles, headings, bullets and links', (tester) async {
      await tester.pumpWidget(
        _app(
          const MarkdownLite(
            '# Plan\n- **bold** *it* _also_ __strong__ ~~gone~~ `code` [site](https://e.x) https://a.b\nsnake_case_name',
          ),
        ),
      );
      final spans = _leaves(tester, find.byType(RichText));
      expect(_span(spans, 'bold').style!.fontWeight, FontWeight.w700);
      expect(_span(spans, 'strong').style!.fontWeight, FontWeight.w700);
      expect(_span(spans, 'it').style!.fontStyle, FontStyle.italic);
      expect(_span(spans, 'also').style!.fontStyle, FontStyle.italic);
      expect(_span(spans, 'gone').style!.decoration, TextDecoration.lineThrough);
      expect(_span(spans, 'code').style!.fontFamily, 'monospace');
      expect(_span(spans, 'site').recognizer, isA<TapGestureRecognizer>());
      expect(_span(spans, 'https://a.b').recognizer, isA<TapGestureRecognizer>());
      final plain = tester.widget<RichText>(find.byType(RichText)).text.toPlainText();
      expect(plain, startsWith('Plan\n• '));
      expect(plain, contains('snake_case_name'), reason: 'underscores inside words are not emphasis');
      final title = _effectiveStyle(tester.widget<RichText>(find.byType(RichText)).text, 'Plan')!;
      expect(title.fontWeight, FontWeight.w700);
      expect(
        title.fontSize,
        greaterThan(_effectiveStyle(tester.widget<RichText>(find.byType(RichText)).text, 'bold')!.fontSize!),
      );
    });

    testWidgets('auto direction: each paragraph follows its first strong character (LTR app)', (tester) async {
      await tester.pumpWidget(
        _app(const MarkdownLite('Buy **milk**\nاشترِ **الخبز** من Carrefour\n123', autoDirection: true)),
      );
      final paragraphs = tester.widgetList<RichText>(find.byType(RichText)).toList();
      expect(paragraphs.map((p) => p.textDirection), [TextDirection.ltr, TextDirection.rtl, TextDirection.ltr]);
      expect(paragraphs[1].text.toPlainText(), 'اشترِ الخبز من Carrefour');
    });

    testWidgets('auto direction in an Arabic app: Latin paragraphs stay LTR, neutral ones follow the app', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const MarkdownLite('Meeting notes\nملاحظات\n— 42 —', autoDirection: true), rtl: true),
      );
      final dirs = tester.widgetList<RichText>(find.byType(RichText)).map((p) => p.textDirection).toList();
      expect(dirs, [TextDirection.ltr, TextDirection.rtl, TextDirection.rtl]);
    });

    testWidgets('collapsed bodies use the first paragraph direction; rows keep the ambient one', (tester) async {
      await tester.pumpWidget(
        _app(
          const Column(
            children: [MarkdownLite('مرحبا\nHello', maxLines: 1, autoDirection: true), MarkdownLite('Hello')],
          ),
        ),
      );
      final rich = tester.widgetList<RichText>(find.byType(RichText)).toList();
      expect(rich.first.textDirection, TextDirection.rtl);
      expect(rich.first.maxLines, 1);
      expect(rich.last.textDirection, isNull, reason: 'no override: the ambient direction applies');
      expect(tester.renderObject<RenderParagraph>(find.byType(RichText).last).textDirection, TextDirection.ltr);
    });
  });

  group('formatting toolbar', () {
    testWidgets('buttons edit the selection as plain Markdown', (tester) async {
      final controller = TextEditingController(text: 'hello world');
      addTearDown(controller.dispose);
      var changes = 0;
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              TextField(controller: controller),
              MarkdownFormatBar(controller: controller, onChanged: () => changes++),
            ],
          ),
        ),
      );
      controller.selection = const TextSelection(baseOffset: 6, extentOffset: 11);
      await tester.tap(find.byTooltip('Bold'));
      expect(controller.text, 'hello **world**');
      expect(controller.selection, const TextSelection(baseOffset: 8, extentOffset: 13));
      await tester.tap(find.byTooltip('Bulleted list'));
      expect(controller.text, '- hello **world**');
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
      await tester.tap(find.byTooltip('Link'));
      expect(controller.text, '- hello **world**[](https://)');
      expect(changes, 3);
      // Every button is labelled and has a 48 dp target.
      for (final tip in ['Bold', 'Italic', 'Strikethrough', 'Code', 'Heading', 'Bulleted list', 'Link']) {
        expect(find.byTooltip(tip), findsOneWidget, reason: tip);
      }
      final handle = tester.ensureSemantics();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('the checklist body shows the toolbar while it is edited', (tester) async {
      final h = TestHarness.create();
      addTearDown(h.dispose);
      late String id;
      await tester.runAsync(() async {
        id = (await h.read(checklistsRepositoryProvider).create(title: 'Groceries', body: 'Weekly run')).id;
      });
      await pumpInApp(tester, h, ChecklistScreen(checklistId: id));
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      if (find.byTooltip('Edit').evaluate().isNotEmpty) {
        await tester.tap(find.byTooltip('Edit'));
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.byType(MarkdownFormatBar), findsNothing);
      await tester.tap(find.widgetWithText(TextField, 'Weekly run'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(MarkdownFormatBar), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
