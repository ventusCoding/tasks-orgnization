import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/checklists/domain/markdown_edits.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Removes lightweight Markdown markers (card excerpts, T4.1.08).
String stripMarkdown(String input) => input
    .replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '')
    .replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '• ')
    .replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m[1]!)
    .replaceAllMapped(RegExp(r'__(.+?)__'), (m) => m[1]!)
    .replaceAllMapped(RegExp(r'~~(.+?)~~'), (m) => m[1]!)
    .replaceAllMapped(RegExp(r'(?<![*\w])\*(?!\s)(.+?)(?<!\s)\*(?!\w)'), (m) => m[1]!)
    .replaceAllMapped(RegExp(r'(?<![_\w])_(?!\s)(.+?)(?<!\s)_(?!\w)'), (m) => m[1]!)
    .replaceAllMapped(RegExp('`([^`]+)`'), (m) => m[1]!)
    .replaceAllMapped(RegExp(r'\[([^\]]+)\]\(([^)]+)\)'), (m) => m[1]!);

/// Direction of a paragraph from its first strong character; null when it has none.
TextDirection? paragraphDirection(String text) {
  if (BidiText.startsRtl(text)) return TextDirection.rtl;
  return _latinLetter.hasMatch(text) ? TextDirection.ltr : null;
}

final _latinLetter = RegExp('[A-Za-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u024F\u0370-\u058F]');

/// Markdown-lite rendering (T4.1.11): **bold** / __bold__, *italic* / _italic_, ~~strike~~,
/// `code`, headings, bullet lists, [links](url) and bare URLs (tappable).
///
/// With [autoDirection] (bodies and notes) each paragraph takes the direction of its first
/// strong character, so mixed Arabic/Latin content lays out naturally; rows keep the ambient
/// direction so the text stays next to its status control.
class MarkdownLite extends StatefulWidget {
  const MarkdownLite(this.text, {super.key, this.style, this.maxLines, this.autoDirection = false});

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final bool autoDirection;

  @override
  State<MarkdownLite> createState() => _MarkdownLiteState();
}

class _MarkdownLiteState extends State<MarkdownLite> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  static final _inline = RegExp(
    r'(\*\*(.+?)\*\*)|(~~(.+?)~~)|(`([^`]+)`)|(\[([^\]]+)\]\(([^)\s]+)\))|(https?://[^\s)]+)|((?<![*\w])\*(?!\s)(.+?)(?<!\s)\*(?!\w))'
    r'|(__(.+?)__)|((?<![_\w])_(?!\s)(.+?)(?<!\s)_(?!\w))',
  );

  List<InlineSpan> _spans(String line, TextStyle base) {
    final out = <InlineSpan>[];
    var i = 0;
    for (final m in _inline.allMatches(line)) {
      if (m.start > i) out.add(TextSpan(text: line.substring(i, m.start)));
      if (m.group(1) != null || m.group(13) != null) {
        out.add(
          TextSpan(
            text: m.group(2) ?? m.group(14),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      } else if (m.group(3) != null) {
        out.add(
          TextSpan(
            text: m.group(4),
            style: const TextStyle(decoration: TextDecoration.lineThrough),
          ),
        );
      } else if (m.group(5) != null) {
        out.add(
          TextSpan(
            text: m.group(6),
            style: TextStyle(fontFamily: 'monospace', backgroundColor: context.colors.surfaceContainerHighest),
          ),
        );
      } else if (m.group(7) != null || m.group(10) != null) {
        final label = m.group(8) ?? m.group(10)!;
        final url = m.group(9) ?? m.group(10)!;
        final recognizer = TapGestureRecognizer()..onTap = () => launchUrl(Uri.parse(url));
        _recognizers.add(recognizer);
        out.add(
          TextSpan(
            text: label,
            recognizer: recognizer,
            style: TextStyle(color: context.colors.primary, decoration: TextDecoration.underline),
          ),
        );
      } else if (m.group(11) != null || m.group(15) != null) {
        out.add(
          TextSpan(
            text: m.group(12) ?? m.group(16),
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      }
      i = m.end;
    }
    if (i < line.length) out.add(TextSpan(text: line.substring(i)));
    return out;
  }

  TextSpan _paragraph(String raw, TextStyle base) {
    var line = raw;
    var style = base;
    final heading = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line);
    if (heading != null) {
      line = heading.group(2)!;
      style = base.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: (base.fontSize ?? 14) + (7 - heading.group(1)!.length),
      );
    }
    final bullet = RegExp(r'^(\s*)[-*+]\s+(.*)$').firstMatch(line);
    if (bullet != null) line = '${bullet.group(1)}• ${bullet.group(2)}';
    return TextSpan(style: style, children: _spans(line, style));
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    final base = widget.style ?? context.text.bodyMedium ?? const TextStyle();
    final lines = widget.text.split('\n');
    TextDirection? direction;
    if (widget.autoDirection) {
      final ambient = Directionality.of(context);
      if (widget.maxLines == null && lines.length > 1) {
        // One block per paragraph, each in its own direction (T4.1.11).
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final line in lines)
              Text.rich(
                TextSpan(style: base, children: [_paragraph(line, base)]),
                textDirection: paragraphDirection(line) ?? ambient,
                textAlign: TextAlign.start,
              ),
          ],
        );
      }
      direction = paragraphDirection(widget.text) ?? ambient;
    }
    final spans = <InlineSpan>[];
    for (var n = 0; n < lines.length; n++) {
      spans.add(_paragraph(lines[n], base));
      if (n < lines.length - 1) spans.add(const TextSpan(text: '\n'));
    }
    return Text.rich(
      TextSpan(style: base, children: spans),
      textDirection: direction,
      textAlign: widget.autoDirection ? TextAlign.start : null,
      maxLines: widget.maxLines,
      overflow: widget.maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}

/// Small formatting toolbar for plain-text Markdown-lite fields (T4.1.11): bold, italic,
/// strikethrough, code, heading, bullet and link, applied to [controller]'s selection.
class MarkdownFormatBar extends StatelessWidget {
  const MarkdownFormatBar({required this.controller, super.key, this.onChanged});

  final TextEditingController controller;

  /// Called after every edit (e.g. to schedule a save).
  final VoidCallback? onChanged;

  void _apply(TextEdit Function(TextEdit) edit) {
    final v = controller.value;
    final selection = v.selection.isValid ? v.selection : TextSelection.collapsed(offset: v.text.length);
    final r = edit(TextEdit(v.text, selection.start, selection.end));
    controller.value = TextEditingValue(
      text: r.text,
      selection: TextSelection(baseOffset: r.start, extentOffset: r.end),
    );
    onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget button(IconData icon, String tooltip, TextEdit Function(TextEdit) edit) =>
        IconButton(icon: Icon(icon), tooltip: tooltip, onPressed: () => _apply(edit));
    // Taps on the bar count as inside the text field: it keeps focus (and its keyboard).
    return TextFieldTapRegion(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            button(Icons.format_bold, l.checklistMdBold, (s) => MarkdownEdits.wrap(s, '**')),
            button(Icons.format_italic, l.checklistMdItalic, (s) => MarkdownEdits.wrap(s, '*')),
            button(Icons.format_strikethrough, l.checklistMdStrike, (s) => MarkdownEdits.wrap(s, '~~')),
            button(Icons.code, l.checklistMdCode, (s) => MarkdownEdits.wrap(s, '`')),
            button(Icons.title, l.checklistMdHeading, (s) => MarkdownEdits.toggleLinePrefix(s, '# ')),
            button(Icons.format_list_bulleted, l.checklistMdBullet, (s) => MarkdownEdits.toggleLinePrefix(s, '- ')),
            button(Icons.link, l.checklistMdLink, MarkdownEdits.link),
          ],
        ),
      ),
    );
  }
}
