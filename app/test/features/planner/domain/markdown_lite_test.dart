import 'package:everslot/features/planner/domain/markdown_lite.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('markdown-lite parser (T3.1.15)', () {
    test('blocks: heading, bullets, numbered, checkboxes, paragraphs', () {
      final blocks = parseMarkdownLite(
        '# Plan\n- one\n* two\n1. first\n2) second\n- [ ] todo\n- [x] done\n\nSome text\nmore',
      );
      expect(blocks, [
        const MdHeading([MdInline('Plan')]),
        const MdBullet([MdInline('one')]),
        const MdBullet([MdInline('two')]),
        const MdNumbered(1, [MdInline('first')]),
        const MdNumbered(2, [MdInline('second')]),
        const MdCheckbox([MdInline('todo')], checked: false),
        const MdCheckbox([MdInline('done')], checked: true),
        const MdSpacer(),
        const MdParagraph([MdInline('Some text\nmore')]),
      ]);
    });

    test('nested list indentation', () {
      final blocks = parseMarkdownLite('- a\n  - b\n    - c');
      expect(blocks.map((b) => (b as MdBullet).indent), [0, 1, 2]);
    });

    test('inline bold, italic, code', () {
      expect(parseInlines('a **b** *c* _d_ `e`'), const [
        MdInline('a '),
        MdInline('b', bold: true),
        MdInline(' '),
        MdInline('c', italic: true),
        MdInline(' '),
        MdInline('d', italic: true),
        MdInline(' '),
        MdInline('e', code: true),
      ]);
    });

    test('unterminated markers stay literal; snake_case is not italic', () {
      expect(parseInlines('**abc'), const [MdInline('**abc')]);
      expect(parseInlines('a * b'), const [MdInline('a * b')]);
      expect(parseInlines('snake_case_name'), const [MdInline('snake_case_name')]);
      expect(parseInlines(r'\*literal\*'), const [MdInline('*literal*')]);
    });

    test('auto-detected links', () {
      expect(parseInlines('see https://everslot.app/x, or www.example.com.'), const [
        MdInline('see '),
        MdInline('https://everslot.app/x', link: 'https://everslot.app/x'),
        MdInline(', or '),
        MdInline('www.example.com', link: 'https://www.example.com'),
        MdInline('.'),
      ]);
    });

    test('raw HTML is plain text', () {
      expect(parseMarkdownLite('<b>hi</b>').single.plainText, '<b>hi</b>');
    });

    test('paragraph direction follows the first strong character', () {
      expect(firstStrongDirection('123 مرحبا hello'), MdDirection.rtl);
      expect(firstStrongDirection('- hello مرحبا'), MdDirection.ltr);
      expect(firstStrongDirection('123 !'), MdDirection.neutral);
      expect(parseMarkdownLite('مرحبا **world**').single.direction, MdDirection.rtl);
    });

    test('plain text rendering', () {
      expect(markdownLiteToPlain('# T\n- a\n- [x] b\n1. c'), 'T\n• a\n☑ b\n1. c');
    });
  });
}
