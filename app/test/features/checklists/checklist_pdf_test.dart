import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart' show getCrc32;
import 'package:everslot/features/checklists/application/checklist_pdf.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/pdf_layout.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// One drawn word: page index (content stream order), position and text.
typedef PdfWord = ({int page, double x, double y, String text});

/// Minimal text extraction for uncompressed PDFs written by `package:pdf`: fonts are named
/// `/F<object number>`, TrueType text is `[<hex codes>]TJ` mapped through the font's ToUnicode
/// CMap, positions come from the preceding `x y Td`.
List<PdfWord> extractWords(Uint8List bytes) {
  final s = latin1.decode(bytes);
  final objects = {
    for (final m in RegExp(r'(\d+) 0 obj(.*?)endobj', dotAll: true).allMatches(s)) int.parse(m[1]!): m[2]!,
  };
  final cmaps = <int, Map<int, int>>{};
  for (final e in objects.entries) {
    if (!e.value.contains('beginbfchar')) continue;
    cmaps[e.key] = {
      for (final m in RegExp('<([0-9A-F]{4})> <([0-9A-F]{4,})>').allMatches(e.value))
        int.parse(m[1]!, radix: 16): int.parse(m[2]!, radix: 16),
    };
  }
  Map<int, int>? cmapOfFont(int font) {
    final ref = RegExp(r'/ToUnicode (\d+) 0 R').firstMatch(objects[font] ?? '');
    return ref == null ? null : cmaps[int.parse(ref[1]!)];
  }

  final words = <PdfWord>[];
  var page = -1;
  final keys = objects.keys.toList()..sort();
  for (final k in keys) {
    final body = objects[k]!;
    if (!body.contains('stream') || !body.contains('TJ')) continue;
    page++;
    Map<int, int>? cmap;
    // Translation of the current graphics state (`q … cm … Q`; package:pdf only translates
    // text) plus the text position of the last `Td`.
    var origin = (0.0, 0.0);
    final saved = <(double, double)>[];
    var x = 0.0;
    var y = 0.0;
    const num = r'(-?[\d.]+)';
    final ops = RegExp(
      '(?<![\\w/])q(?=\\s)|(?<=\\s)Q(?=\\s)|$num $num $num $num $num $num cm|/F(\\d+) [\\d.]+ Tf|$num $num Td|\\[<([0-9a-fA-F]*)>\\]TJ',
    );
    for (final m in ops.allMatches(body)) {
      final op = m[0]!;
      if (op == 'q') {
        saved.add(origin);
      } else if (op == 'Q') {
        if (saved.isNotEmpty) origin = saved.removeLast();
      } else if (m[1] != null) {
        origin = (origin.$1 + double.parse(m[5]!), origin.$2 + double.parse(m[6]!));
      } else if (m[7] != null) {
        cmap = cmapOfFont(int.parse(m[7]!));
      } else if (m[8] != null) {
        x = origin.$1 + double.parse(m[8]!);
        y = origin.$2 + double.parse(m[9]!);
      } else if (cmap != null) {
        final hex = m[10]!;
        final runes = [
          for (var i = 0; i + 4 <= hex.length; i += 4) cmap[int.parse(hex.substring(i, i + 4), radix: 16)] ?? 0x3F,
        ];
        words.add((page: page, x: x, y: y, text: String.fromCharCodes(runes)));
      }
    }
  }
  return words;
}

/// A real (decodable) 2×2 RGB PNG.
Uint8List _png() {
  List<int> chunk(String type, List<int> data) {
    final body = [...latin1.encode(type), ...data];
    final crc = getCrc32(body);
    int b(int v, int s) => (v >> s) & 0xFF;
    return [
      b(data.length, 24),
      b(data.length, 16),
      b(data.length, 8),
      b(data.length, 0),
      ...body,
      b(crc, 24),
      b(crc, 16),
      b(crc, 8),
      b(crc, 0),
    ];
  }

  final raw = [
    for (var row = 0; row < 2; row++) ...[0, 200, 30, 30, 30, 200, 30],
  ];
  return Uint8List.fromList([
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    ...chunk('IHDR', [0, 0, 0, 2, 0, 0, 0, 2, 8, 2, 0, 0, 0]),
    ...chunk('IDAT', zlib.encode(raw)),
    ...chunk('IEND', const []),
  ]);
}

ChecklistItem _item(
  String id,
  String text, {
  String? parent,
  String sort = 'a',
  ItemStatus status = ItemStatus.todo,
  String? statusNote,
  String? note,
}) => ChecklistItem(
  id: id,
  checklistId: 'L',
  parentId: parent,
  sortKey: sort,
  text: text,
  status: status,
  statusNote: statusNote,
  note: note,
);

void main() {
  pw.Font font(String path) => pw.Font.ttf(ByteData.sublistView(File(path).readAsBytesSync()));
  final fonts = ChecklistPdfFonts(
    regular: font('assets/fonts/inter/Inter-Regular.ttf'),
    bold: font('assets/fonts/inter/Inter-Bold.ttf'),
    arabic: font('assets/fonts/noto_sans_arabic/NotoSansArabic-Regular.ttf'),
    arabicBold: font('assets/fonts/noto_sans_arabic/NotoSansArabic-Bold.ttf'),
  );
  final labels = ChecklistPdfLabels(
    statusNames: {for (final s in ItemStatus.values) s: s.name[0].toUpperCase() + s.name.substring(1)},
    pageOf: (p, n) => 'Page $p of $n',
  );

  final trip = ChecklistTree.build([
    _item('docs', 'Documents', sort: 'a'),
    _item('pass', 'Passport', parent: 'docs', sort: 'a', status: ItemStatus.completed),
    _item('visa', 'Visa', parent: 'docs', sort: 'b', status: ItemStatus.waiting, statusNote: 'embassy'),
    _item('clothes', 'Clothes', sort: 'b', note: 'Pack light'),
    _item('old', 'Guidebook', sort: 'c', status: ItemStatus.cancelled),
  ]);

  Future<List<PdfWord>> render(
    ChecklistTree tree, {
    String title = 'Trip',
    ChecklistPdfOptions? options,
    String? rootId,
    Map<String, List<Uint8List>> thumbnails = const {},
  }) async => extractWords(
    await buildChecklistPdf(
      tree: tree,
      title: title,
      fonts: fonts,
      labels: labels,
      rootId: rootId,
      thumbnails: thumbnails,
      options: options ?? const ChecklistPdfOptions(compress: false),
    ),
  );

  String textOf(List<PdfWord> words) => words.map((w) => w.text).join(' ');

  test('the PDF holds the title, items, status reasons, notes and page numbers', () async {
    final words = await render(trip);
    final text = textOf(words);
    for (final w in [
      'Trip',
      'Documents',
      'Passport',
      'Visa',
      'Waiting:',
      'embassy',
      'Clothes',
      'Pack',
      'light',
      'Guidebook',
      'Cancelled',
      'Page',
      '1',
      'of',
    ]) {
      expect(text, contains(w));
    }
    // Children are indented 16 pt after their parent.
    final docs = words.firstWhere((w) => w.text == 'Documents');
    final pass = words.firstWhere((w) => w.text == 'Passport');
    expect(pass.x - docs.x, closeTo(16, 0.01));
    // Reading order follows the tree.
    expect(words.indexWhere((w) => w.text == 'Visa'), lessThan(words.indexWhere((w) => w.text == 'Clothes')));
  });

  test('notes can be left out; a branch prints only its subtree', () async {
    final noNotes = textOf(
      await render(trip, options: const ChecklistPdfOptions(compress: false, includeNotes: false)),
    );
    expect(noNotes, isNot(contains('Pack')));
    final branch = textOf(await render(trip, rootId: 'docs', title: 'Documents'));
    expect(branch, contains('Passport'));
    expect(branch, isNot(contains('Clothes')));
  });

  test('image thumbnails are embedded when asked', () async {
    final thumbs = {
      'pass': [_png()],
      'visa': [
        Uint8List.fromList(const [1, 2, 3]),
      ],
    };
    Future<int> images(bool include) async {
      final bytes = await buildChecklistPdf(
        tree: trip,
        title: 'Trip',
        fonts: fonts,
        labels: labels,
        thumbnails: thumbs,
        options: ChecklistPdfOptions(compress: false, includeImages: include),
      );
      return RegExp('/Subtype ?/Image').allMatches(latin1.decode(bytes)).length;
    }

    expect(await images(true), greaterThan(0));
    expect(await images(false), 0);
  });

  test('RTL fixture: Arabic text, indentation toward the left', () async {
    final tree = ChecklistTree.build([
      _item('p', 'سفر', sort: 'a'),
      _item('c', 'سفر', parent: 'p', sort: 'a', status: ItemStatus.blocked, statusNote: 'تأشيرة'),
    ]);
    final words = await render(tree, title: 'رحلة', options: const ChecklistPdfOptions(compress: false, rtl: true));
    final arabic = words.where(
      (w) => w.text.runes.any((r) => (r >= 0x0600 && r <= 0x06FF) || (r >= 0xFE70 && r <= 0xFEFF)),
    );
    expect(arabic.length, greaterThanOrEqualTo(4), reason: 'title, two items and the reason are Arabic');
    // The same word at depth 0 and 1 (identical width): the child starts 16 pt further left
    // (start = right in RTL), both on the right half of the page.
    final counts = <String, int>{};
    for (final w in arabic) {
      counts[w.text] = (counts[w.text] ?? 0) + 1;
    }
    final item = counts.entries.firstWhere((e) => e.value == 2).key;
    final itemRows = arabic.where((w) => w.text == item).toList()..sort((a, b) => b.y.compareTo(a.y));
    expect(itemRows.every((w) => w.x > PdfPageFormat.a4.width / 2), isTrue);
    expect(itemRows[0].x - itemRows[1].x, closeTo(16, 0.01));
  });

  group('page breaks (pdfBlocks)', () {
    final big = ChecklistTree.build([
      _item('a', 'A', sort: 'a'),
      for (var i = 0; i < 3; i++) _item('a$i', 'A$i', parent: 'a', sort: 'a$i'),
      _item('b', 'B', sort: 'b'),
      for (var i = 0; i < 20; i++) _item('b$i', 'B$i', parent: 'b', sort: 'b${i.toString().padLeft(2, '0')}'),
      _item('c', 'C', sort: 'c'),
    ]);

    test('small subtrees are one kept-together block; large ones split per child', () {
      final blocks = pdfBlocks(big, keepTogetherRows: 12);
      expect(blocks.first.keepTogether, isTrue);
      expect(blocks.first.rows.map((r) => r.id), ['a', 'a0', 'a1', 'a2']);
      expect(blocks[1].rows, [const PdfRow('b', 0)]);
      expect(blocks[1].keepTogether, isFalse);
      expect(blocks.where((b) => b.rows.any((r) => r.id.startsWith('b'))).length, 21);
      expect(blocks.last.rows, [const PdfRow('c', 0)]);
      expect(blocks.last.keepTogether, isFalse);
      // Every item printed exactly once, in tree order.
      expect(blocks.expand((b) => b.rows).map((r) => r.id).toList(), big.order);
    });

    test('a kept-together subtree never straddles two pages', () async {
      final items = [
        for (var i = 0; i < 45; i++) _item('f$i', 'Filler$i', sort: 'a${i.toString().padLeft(2, '0')}'),
        _item('g', 'Group', sort: 'b'),
        for (var i = 0; i < 8; i++) _item('g$i', 'Member$i', parent: 'g', sort: 'b$i'),
      ];
      final words = await render(ChecklistTree.build(items));
      final pages = {
        for (final w in words)
          if (w.text == 'Group' || w.text.startsWith('Member')) w.page,
      };
      expect(pages, hasLength(1));
      expect(words.map((w) => w.page).toSet().length, greaterThan(1), reason: 'the fixture spans pages');
    });
  });

  test('file names are safe', () {
    const c = Checklist(id: 'L', title: 'Trip: A/B', sortKey: 'a');
    expect(checklistPdfName(c), 'Trip_ A_B.pdf');
    expect(checklistPdfName(const Checklist(id: 'L', title: ' ', sortKey: 'a')), 'checklist.pdf');
  });
}
