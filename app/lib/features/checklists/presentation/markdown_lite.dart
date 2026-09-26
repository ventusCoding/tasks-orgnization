import 'package:everslot/design_system/design_system.dart';
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

/// Markdown-lite rendering (T4.1.11): **bold**, *italic*, ~~strike~~, `code`, headings, bullet
/// lists, [links](url) and bare URLs (tappable). Direction follows each paragraph's text, so
/// mixed Arabic/Latin content lays out naturally.
class MarkdownLite extends StatefulWidget {
  const MarkdownLite(this.text, {super.key, this.style, this.maxLines});

  final String text;
  final TextStyle? style;
  final int? maxLines;

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
    r'(\*\*(.+?)\*\*)|(~~(.+?)~~)|(`([^`]+)`)|(\[([^\]]+)\]\(([^)\s]+)\))|(https?://[^\s)]+)|((?<![*\w])\*(?!\s)(.+?)(?<!\s)\*(?!\w))',
  );

  List<InlineSpan> _spans(String line, TextStyle base) {
    final out = <InlineSpan>[];
    var i = 0;
    for (final m in _inline.allMatches(line)) {
      if (m.start > i) out.add(TextSpan(text: line.substring(i, m.start)));
      if (m.group(1) != null) {
        out.add(TextSpan(text: m.group(2), style: const TextStyle(fontWeight: FontWeight.w700)));
      } else if (m.group(3) != null) {
        out.add(TextSpan(text: m.group(4), style: const TextStyle(decoration: TextDecoration.lineThrough)));
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
      } else if (m.group(11) != null) {
        out.add(TextSpan(text: m.group(12), style: const TextStyle(fontStyle: FontStyle.italic)));
      }
      i = m.end;
    }
    if (i < line.length) out.add(TextSpan(text: line.substring(i)));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    final base = widget.style ?? context.text.bodyMedium ?? const TextStyle();
    final spans = <InlineSpan>[];
    final lines = widget.text.split('\n');
    for (var n = 0; n < lines.length; n++) {
      var line = lines[n];
      var style = base;
      final heading = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line);
      if (heading != null) {
        line = heading.group(2)!;
        style = base.copyWith(fontWeight: FontWeight.w700, fontSize: (base.fontSize ?? 14) + (7 - heading.group(1)!.length));
      }
      final bullet = RegExp(r'^(\s*)[-*+]\s+(.*)$').firstMatch(line);
      if (bullet != null) line = '${bullet.group(1)}• ${bullet.group(2)}';
      spans.add(TextSpan(style: style, children: _spans(line, style)));
      if (n < lines.length - 1) spans.add(const TextSpan(text: '\n'));
    }
    return Text.rich(
      TextSpan(style: base, children: spans),
      maxLines: widget.maxLines,
      overflow: widget.maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}
