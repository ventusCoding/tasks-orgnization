import 'package:meta/meta.dart';

/// Markdown-lite (T3.1.15): bold, italic, one heading level, bullet and numbered lists,
/// display-only checkboxes, auto-detected links and code spans. No raw HTML: `<tags>` are
/// plain text. Pure parser — rendering lives in the presentation layer.

/// Paragraph direction from the first strong character (mixed Arabic/Latin notes).
enum MdDirection { ltr, rtl, neutral }

@immutable
sealed class MdBlock {
  const MdBlock(this.inlines);

  final List<MdInline> inlines;

  String get plainText => inlines.map((i) => i.text).join();

  MdDirection get direction => firstStrongDirection(plainText);
}

final class MdParagraph extends MdBlock {
  const MdParagraph(super.inlines);

  @override
  bool operator ==(Object other) => other is MdParagraph && _listEq(other.inlines, inlines);

  @override
  int get hashCode => Object.hashAll(inlines);

  @override
  String toString() => 'MdParagraph($inlines)';
}

final class MdHeading extends MdBlock {
  const MdHeading(super.inlines);

  @override
  bool operator ==(Object other) => other is MdHeading && _listEq(other.inlines, inlines);

  @override
  int get hashCode => Object.hash('h', Object.hashAll(inlines));

  @override
  String toString() => 'MdHeading($inlines)';
}

final class MdBullet extends MdBlock {
  const MdBullet(super.inlines, {this.indent = 0});

  final int indent;

  @override
  bool operator ==(Object other) => other is MdBullet && other.indent == indent && _listEq(other.inlines, inlines);

  @override
  int get hashCode => Object.hash('b', indent, Object.hashAll(inlines));

  @override
  String toString() => 'MdBullet($inlines)';
}

final class MdNumbered extends MdBlock {
  const MdNumbered(this.number, super.inlines, {this.indent = 0});

  final int number;
  final int indent;

  @override
  bool operator ==(Object other) =>
      other is MdNumbered && other.number == number && other.indent == indent && _listEq(other.inlines, inlines);

  @override
  int get hashCode => Object.hash('n', number, indent, Object.hashAll(inlines));

  @override
  String toString() => 'MdNumbered($number, $inlines)';
}

/// Display-only checkbox (`- [ ]` / `- [x]`).
final class MdCheckbox extends MdBlock {
  const MdCheckbox(super.inlines, {required this.checked, this.indent = 0});

  final bool checked;
  final int indent;

  @override
  bool operator ==(Object other) =>
      other is MdCheckbox && other.checked == checked && other.indent == indent && _listEq(other.inlines, inlines);

  @override
  int get hashCode => Object.hash('c', checked, indent, Object.hashAll(inlines));

  @override
  String toString() => 'MdCheckbox($checked, $inlines)';
}

/// Empty line between paragraphs.
final class MdSpacer extends MdBlock {
  const MdSpacer() : super(const []);

  @override
  bool operator ==(Object other) => other is MdSpacer;

  @override
  int get hashCode => 7;
}

/// A run of inline text with styles.
@immutable
class MdInline {
  const MdInline(this.text, {this.bold = false, this.italic = false, this.code = false, this.link});

  final String text;
  final bool bold;
  final bool italic;
  final bool code;

  /// Auto-detected URL (http/https/www.).
  final String? link;

  @override
  bool operator ==(Object other) =>
      other is MdInline &&
      other.text == text &&
      other.bold == bold &&
      other.italic == italic &&
      other.code == code &&
      other.link == link;

  @override
  int get hashCode => Object.hash(text, bold, italic, code, link);

  @override
  String toString() =>
      'MdInline("$text"${bold ? ' b' : ''}${italic ? ' i' : ''}${code ? ' code' : ''}${link == null ? '' : ' link'})';
}

bool _listEq(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

final _heading = RegExp(r'^#{1,6}\s+(.*)$');
final _checkbox = RegExp(r'^(\s*)[-*+]\s+\[([ xX])\]\s+(.*)$');
final _bullet = RegExp(r'^(\s*)[-*+]\s+(.*)$');
final _numbered = RegExp(r'^(\s*)(\d{1,4})[.)]\s+(.*)$');
final _link = RegExp(r'''(https?://[^\s<>()]+[^\s<>().,;:!?'"]|www\.[^\s<>()]+[^\s<>().,;:!?'"])''');

/// Parses markdown-lite [source] into blocks.
List<MdBlock> parseMarkdownLite(String source) {
  final blocks = <MdBlock>[];
  final paragraph = <String>[];
  void flush() {
    if (paragraph.isEmpty) return;
    blocks.add(MdParagraph(parseInlines(paragraph.join('\n'))));
    paragraph.clear();
  }

  for (final raw in source.replaceAll('\r\n', '\n').split('\n')) {
    final line = raw.trimRight();
    if (line.trim().isEmpty) {
      flush();
      if (blocks.isNotEmpty && blocks.last is! MdSpacer) blocks.add(const MdSpacer());
      continue;
    }
    int indentOf(String s) => (s.replaceAll('\t', '  ').length ~/ 2).clamp(0, 4);
    final h = _heading.firstMatch(line);
    if (h != null) {
      flush();
      blocks.add(MdHeading(parseInlines(h.group(1)!)));
      continue;
    }
    final c = _checkbox.firstMatch(line);
    if (c != null) {
      flush();
      blocks.add(MdCheckbox(parseInlines(c.group(3)!), checked: c.group(2) != ' ', indent: indentOf(c.group(1)!)));
      continue;
    }
    final b = _bullet.firstMatch(line);
    if (b != null) {
      flush();
      blocks.add(MdBullet(parseInlines(b.group(2)!), indent: indentOf(b.group(1)!)));
      continue;
    }
    final n = _numbered.firstMatch(line);
    if (n != null) {
      flush();
      blocks.add(MdNumbered(int.parse(n.group(2)!), parseInlines(n.group(3)!), indent: indentOf(n.group(1)!)));
      continue;
    }
    paragraph.add(line);
  }
  flush();
  while (blocks.isNotEmpty && blocks.last is MdSpacer) {
    blocks.removeLast();
  }
  return blocks;
}

/// Parses inline styles: `**bold**`, `*italic*`/`_italic_`, `` `code` `` and bare links.
List<MdInline> parseInlines(String text) {
  final out = <MdInline>[];
  var bold = false;
  var italic = false;
  final buffer = StringBuffer();

  void emit() {
    if (buffer.isEmpty) return;
    out.addAll(_splitLinks(buffer.toString(), bold: bold, italic: italic));
    buffer.clear();
  }

  var i = 0;
  while (i < text.length) {
    final ch = text[i];
    if (ch == r'\' && i + 1 < text.length && r'*_`\'.contains(text[i + 1])) {
      buffer.write(text[i + 1]);
      i += 2;
      continue;
    }
    if (ch == '`') {
      final end = text.indexOf('`', i + 1);
      if (end > i + 1) {
        emit();
        out.add(MdInline(text.substring(i + 1, end), bold: bold, italic: italic, code: true));
        i = end + 1;
        continue;
      }
    }
    if (text.startsWith('**', i)) {
      if (bold || text.indexOf('**', i + 2) > i + 2) {
        emit();
        bold = !bold;
        i += 2;
        continue;
      }
    }
    if ((ch == '*' || ch == '_') && !text.startsWith('**', i)) {
      final wordChar = RegExp(r'[\p{L}\p{N}]', unicode: true);
      final prevIsWord = i > 0 && wordChar.hasMatch(text[i - 1]);
      final closes = italic;
      final opens = !italic && text.indexOf(ch, i + 1) > i + 1 && !(ch == '_' && prevIsWord);
      if (closes || opens) {
        emit();
        italic = !italic;
        i += 1;
        continue;
      }
    }
    buffer.write(ch);
    i++;
  }
  emit();
  return _merge(out);
}

List<MdInline> _splitLinks(String text, {required bool bold, required bool italic}) {
  final out = <MdInline>[];
  var last = 0;
  for (final m in _link.allMatches(text)) {
    if (m.start > last) out.add(MdInline(text.substring(last, m.start), bold: bold, italic: italic));
    final url = m.group(0)!;
    out.add(MdInline(url, bold: bold, italic: italic, link: url.startsWith('www.') ? 'https://$url' : url));
    last = m.end;
  }
  if (last < text.length) out.add(MdInline(text.substring(last), bold: bold, italic: italic));
  return out;
}

List<MdInline> _merge(List<MdInline> runs) {
  final out = <MdInline>[];
  for (final r in runs) {
    if (r.text.isEmpty) continue;
    final prev = out.isEmpty ? null : out.last;
    if (prev != null &&
        prev.bold == r.bold &&
        prev.italic == r.italic &&
        !prev.code &&
        !r.code &&
        prev.link == null &&
        r.link == null) {
      out[out.length - 1] = MdInline(prev.text + r.text, bold: r.bold, italic: r.italic);
    } else {
      out.add(r);
    }
  }
  return out;
}

/// Direction of the first strong character (Arabic/Hebrew → RTL, Latin letters → LTR).
MdDirection firstStrongDirection(String text) {
  for (final rune in text.runes) {
    if ((rune >= 0x0590 && rune <= 0x08FF) || (rune >= 0xFB1D && rune <= 0xFDFF) || (rune >= 0xFE70 && rune <= 0xFEFF)) {
      return MdDirection.rtl;
    }
    if ((rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A) || (rune >= 0xC0 && rune <= 0x024F)) {
      return MdDirection.ltr;
    }
  }
  return MdDirection.neutral;
}

/// Plain-text rendering (search snippets, share as text).
String markdownLiteToPlain(String source) {
  final lines = <String>[];
  for (final b in parseMarkdownLite(source)) {
    final text = b.plainText;
    lines.add(switch (b) {
      MdBullet() => '• $text',
      MdNumbered(:final number) => '$number. $text',
      MdCheckbox(:final checked) => '${checked ? '☑' : '☐'} $text',
      MdSpacer() => '',
      _ => text,
    });
  }
  return lines.join('\n');
}
