import 'dart:io';
import 'dart:typed_data';

import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/pdf_layout.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Fonts embedded in the PDF: Inter, with Noto Sans Arabic as fallback for Arabic text.
class ChecklistPdfFonts {
  const ChecklistPdfFonts({required this.regular, required this.bold, required this.arabic, required this.arabicBold});

  final pw.Font regular;
  final pw.Font bold;
  final pw.Font arabic;
  final pw.Font arabicBold;

  static const _inter = 'assets/fonts/inter/Inter';
  static const _noto = 'assets/fonts/noto_sans_arabic/NotoSansArabic';

  /// Loads the bundled app fonts (`pubspec.yaml` › fonts).
  static Future<ChecklistPdfFonts> load(AssetBundle bundle) async {
    Future<pw.Font> font(String path) async => pw.Font.ttf(await bundle.load(path));
    return ChecklistPdfFonts(
      regular: await font('$_inter-Regular.ttf'),
      bold: await font('$_inter-Bold.ttf'),
      arabic: await font('$_noto-Regular.ttf'),
      arabicBold: await font('$_noto-Bold.ttf'),
    );
  }
}

/// Localized texts of the PDF (resolved by the caller).
class ChecklistPdfLabels {
  const ChecklistPdfLabels({required this.statusNames, required this.pageOf});

  final Map<ItemStatus, String> statusNames;
  final String Function(int page, int total) pageOf;
}

class ChecklistPdfOptions {
  const ChecklistPdfOptions({
    this.includeNotes = true,
    this.includeImages = false,
    this.rtl = false,
    this.keepTogetherRows = 12,
    this.compress = true,
    this.pageFormat = PdfPageFormat.a4,
  });

  final bool includeNotes;
  final bool includeImages;
  final bool rtl;
  final int keepTogetherRows;

  /// False keeps content streams readable (text-extraction tests).
  final bool compress;
  final PdfPageFormat pageFormat;
}

/// Printable PDF of a checklist or a branch (T4.5.10): status glyphs (vector, colored like the
/// app's status palette), status reasons, notes, optional image thumbnails, RTL layout; small
/// subtrees are kept on one page ([pdfBlocks]). Pure Dart (`pdf`), so it runs in tests and could
/// run in an isolate.
Future<Uint8List> buildChecklistPdf({
  required ChecklistTree tree,
  required String title,
  required ChecklistPdfFonts fonts,
  required ChecklistPdfLabels labels,
  String? rootId,
  ChecklistPdfOptions options = const ChecklistPdfOptions(),
  Map<String, List<Uint8List>> thumbnails = const {},
}) async {
  final dir = options.rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;
  final doc = pw.Document(compress: options.compress, title: title, creator: 'Everslot');
  final theme = pw.ThemeData.withFont(
    base: fonts.regular,
    bold: fonts.bold,
    fontFallback: [fonts.arabic, fonts.arabicBold],
  );
  final blocks = pdfBlocks(tree, rootId: rootId, keepTogetherRows: options.keepTogetherRows);

  // Arabic must be shaped by one font: text containing Arabic uses Noto Sans Arabic first (Latin
  // falls back to Inter); a per-glyph fallback would print isolated, unjoined letters.
  pw.Text text(String value, pw.TextStyle style) => pw.Text(
    value,
    style: _arabic.hasMatch(value)
        ? style.copyWith(font: fonts.arabic, fontBold: fonts.arabicBold, fontFallback: [fonts.regular, fonts.bold])
        : style,
  );

  pw.Widget row(PdfRow r) {
    final item = tree[r.id]!;
    final done = item.status == ItemStatus.completed || item.status == ItemStatus.cancelled;
    final reason = item.statusNote;
    final images = [
      if (options.includeImages)
        for (final bytes in (thumbnails[r.id] ?? const <Uint8List>[]).take(6)) ?_image(bytes),
    ];
    return pw.Padding(
      padding: pw.EdgeInsetsDirectional.only(start: 16.0 * r.depth, top: 3, bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1.5),
            child: pw.SvgImage(svg: _statusSvg(item.status), width: 10, height: 10),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                text(
                  item.text,
                  pw.TextStyle(
                    fontSize: 11,
                    color: done ? _muted : null,
                    decoration: item.status == ItemStatus.cancelled ? pw.TextDecoration.lineThrough : null,
                  ),
                ),
                if (item.status != ItemStatus.todo && item.status != ItemStatus.completed || reason != null)
                  text(
                    [labels.statusNames[item.status] ?? item.status.name, ?reason].join(': '),
                    pw.TextStyle(fontSize: 9, color: _statusColor(item.status)),
                  ),
                if (options.includeNotes && item.hasNote)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: text(item.note!.trim(), const pw.TextStyle(fontSize: 9, color: _muted)),
                  ),
                if (images.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 3),
                    child: pw.Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final image in images)
                          pw.SizedBox(width: 56, height: 56, child: pw.Image(image, fit: pw.BoxFit.cover)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: options.pageFormat,
        margin: const pw.EdgeInsets.all(40),
        textDirection: dir,
        theme: theme,
      ),
      header: (ctx) => ctx.pageNumber == 1
          ? pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: text(title, const pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            )
          : pw.SizedBox(),
      footer: (ctx) => pw.Align(
        alignment: pw.AlignmentDirectional.centerEnd,
        child: text(labels.pageOf(ctx.pageNumber, ctx.pagesCount), const pw.TextStyle(fontSize: 8, color: _muted)),
      ),
      build: (ctx) => [
        for (final b in blocks)
          if (b.keepTogether)
            pw.Inseparable(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [for (final r in b.rows) row(r)],
              ),
            )
          else
            for (final r in b.rows) row(r),
      ],
    ),
  );
  return doc.save();
}

/// Decoded thumbnail, or null for unreadable bytes (skipped rather than failing the export).
pw.ImageProvider? _image(Uint8List bytes) {
  try {
    return pw.MemoryImage(bytes);
  } on Object {
    return null;
  }
}

final _arabic = RegExp('[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');

/// Print palette (the PDF is not themed: always dark ink on white paper).
const _muted = PdfColor.fromInt(0xFF5F6368);

PdfColor _statusColor(ItemStatus s) => switch (s) {
  ItemStatus.todo => _muted,
  ItemStatus.ongoing => const PdfColor.fromInt(0xFF1A73E8),
  ItemStatus.waiting => const PdfColor.fromInt(0xFFE37400),
  ItemStatus.blocked => const PdfColor.fromInt(0xFFD93025),
  ItemStatus.completed => const PdfColor.fromInt(0xFF188038),
  ItemStatus.cancelled => const PdfColor.fromInt(0xFF80868B),
};

String _hex(PdfColor c) => c.toHex().substring(0, 7);

/// Vector status glyphs (16×16): box, filled box + check, box + play, clock, no-entry, box + cross.
String _statusSvg(ItemStatus s) {
  final c = _hex(_statusColor(s));
  final body = switch (s) {
    ItemStatus.todo =>
      '<rect x="1.5" y="1.5" width="13" height="13" rx="2" fill="none" stroke="$c" stroke-width="1.5"/>',
    ItemStatus.completed =>
      '<rect x="1" y="1" width="14" height="14" rx="2" fill="$c"/>'
          '<path d="M4 8.2 L6.8 11 L12 5.2" fill="none" stroke="#FFFFFF" stroke-width="1.8"/>',
    ItemStatus.ongoing =>
      '<rect x="1.5" y="1.5" width="13" height="13" rx="2" fill="none" stroke="$c" stroke-width="1.5"/>'
          '<path d="M6 4.5 L11.5 8 L6 11.5 Z" fill="$c"/>',
    ItemStatus.waiting =>
      '<circle cx="8" cy="8" r="6.5" fill="none" stroke="$c" stroke-width="1.5"/>'
          '<path d="M8 4 L8 8 L11 9.5" fill="none" stroke="$c" stroke-width="1.5"/>',
    ItemStatus.blocked =>
      '<circle cx="8" cy="8" r="6.5" fill="none" stroke="$c" stroke-width="1.5"/>'
          '<path d="M4.5 11.5 L11.5 4.5" stroke="$c" stroke-width="1.5"/>',
    ItemStatus.cancelled =>
      '<rect x="1.5" y="1.5" width="13" height="13" rx="2" fill="none" stroke="$c" stroke-width="1.5"/>'
          '<path d="M5 5 L11 11 M11 5 L5 11" stroke="$c" stroke-width="1.5"/>',
  };
  return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16">$body</svg>';
}

/// Suggested file name of the PDF.
String checklistPdfName(Checklist checklist, {String? branchTitle}) {
  final base = (branchTitle ?? checklist.title).trim();
  final safe = base.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  return '${safe.isEmpty ? 'checklist' : safe}.pdf';
}

/// PDF export of a list (T4.5.10): fonts from the app bundle, item image thumbnails from the
/// attachment cache (downloaded when needed and possible; missing ones are skipped).
class ChecklistPdfService {
  ChecklistPdfService({required this.attachments, required this.thumbPath, AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final Future<List<Attachment>> Function(String checklistId) attachments;

  /// Local thumbnail file of an image attachment (downloads it when possible).
  final Future<String?> Function(Attachment a) thumbPath;
  final AssetBundle _bundle;
  ChecklistPdfFonts? _fonts;

  Future<Map<String, List<Uint8List>>> thumbnails(String checklistId) async {
    final out = <String, List<Uint8List>>{};
    for (final a in await attachments(checklistId)) {
      if (!a.isImage || a.ownerType != AttachmentOwnerType.checklistItem) continue;
      try {
        final path = await thumbPath(a);
        if (path == null) continue;
        (out[a.ownerId] ??= []).add(await File(path).readAsBytes());
      } on Object {
        continue;
      }
    }
    return out;
  }

  Future<Uint8List> build({
    required Checklist checklist,
    required ChecklistTree tree,
    required ChecklistPdfLabels labels,
    String? rootId,
    ChecklistPdfOptions options = const ChecklistPdfOptions(),
  }) async {
    final fonts = _fonts ??= await ChecklistPdfFonts.load(_bundle);
    return buildChecklistPdf(
      tree: tree,
      title: rootId == null ? checklist.title : tree[rootId]?.text ?? checklist.title,
      fonts: fonts,
      labels: labels,
      rootId: rootId,
      options: options,
      thumbnails: options.includeImages ? await thumbnails(checklist.id) : const {},
    );
  }
}

final checklistPdfServiceProvider = Provider<ChecklistPdfService>(
  (ref) => ChecklistPdfService(
    attachments: (id) => ref.read(checklistItemsRepositoryProvider).watchChecklistAttachments(id).first,
    thumbPath: ref.watch(attachmentDownloaderProvider).ensureThumb,
  ),
);

/// Where a finished PDF goes: the system print dialog or the share sheet (fake in tests).
abstract class PdfOutput {
  Future<void> print(Uint8List bytes, {required String name});
  Future<void> share(Uint8List bytes, {required String name});
}

/// `printing`: AirPrint / Android print service, and the platform share sheet.
class PrintingPdfOutput implements PdfOutput {
  const PrintingPdfOutput();

  @override
  Future<void> print(Uint8List bytes, {required String name}) =>
      Printing.layoutPdf(onLayout: (_) async => bytes, name: name);

  @override
  Future<void> share(Uint8List bytes, {required String name}) => Printing.sharePdf(bytes: bytes, filename: name);
}

final pdfOutputProvider = Provider<PdfOutput>((ref) => const PrintingPdfOutput());
