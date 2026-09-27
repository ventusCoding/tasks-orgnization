import 'dart:math' as math;

import 'package:meta/meta.dart';

/// Text plus a selection (`start`..`end`, collapsed when equal) — a pure mirror of the editing
/// value used by the Markdown-lite formatting toolbar (T4.1.11).
@immutable
class TextEdit {
  const TextEdit(this.text, this.start, this.end);

  /// Caret at the end of [text].
  const TextEdit.atEnd(this.text) : start = text.length, end = text.length;

  final String text;
  final int start;
  final int end;

  @override
  bool operator ==(Object other) => other is TextEdit && other.text == text && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(text, start, end);

  @override
  String toString() => 'TextEdit(${text.replaceAll('\n', r'\n')}, $start, $end)';
}

/// Plain-text Markdown-lite edits (T4.1.11): editing stays plain text, the toolbar only inserts
/// or removes markers around the selection.
abstract final class MarkdownEdits {
  static (int, int) _range(TextEdit s) {
    final a = math.min(s.start, s.end).clamp(0, s.text.length);
    final b = math.max(s.start, s.end).clamp(0, s.text.length);
    return (a, b);
  }

  /// Wraps the selection in [marker] (`**`, `*`, `~~`, `` ` ``); toggles it off when the selection
  /// is already wrapped. An empty selection inserts a marker pair with the caret between.
  static TextEdit wrap(TextEdit s, String marker) {
    final (a, b) = _range(s);
    final text = s.text;
    final m = marker.length;
    final outside =
        a >= m && b + m <= text.length && text.substring(a - m, a) == marker && text.substring(b, b + m) == marker;
    if (outside && a != b) {
      final t = text.replaceRange(b, b + m, '').replaceRange(a - m, a, '');
      return TextEdit(t, a - m, b - m);
    }
    final selected = text.substring(a, b);
    if (selected.length > 2 * m && selected.startsWith(marker) && selected.endsWith(marker)) {
      final inner = selected.substring(m, selected.length - m);
      return TextEdit(text.replaceRange(a, b, inner), a, a + inner.length);
    }
    return TextEdit(text.replaceRange(a, b, '$marker$selected$marker'), a + m, b + m);
  }

  /// Adds [prefix] (`- `, `# `) to every line touched by the selection, or removes it when all of
  /// them already start with it.
  static TextEdit toggleLinePrefix(TextEdit s, String prefix) {
    final (a, b) = _range(s);
    final text = s.text;
    final lineStart = a == 0 ? 0 : text.lastIndexOf('\n', a - 1) + 1;
    final nextBreak = text.indexOf('\n', b);
    final lineEnd = nextBreak == -1 ? text.length : nextBreak;
    final lines = text.substring(lineStart, lineEnd).split('\n');
    final remove = lines.every((l) => l.startsWith(prefix));
    final changed = [
      for (final l in lines)
        if (remove) l.substring(prefix.length) else if (l.startsWith(prefix)) l else '$prefix$l',
    ].join('\n');
    final t = text.replaceRange(lineStart, lineEnd, changed);
    if (a == b) {
      final delta = remove ? -prefix.length : (lines.first.startsWith(prefix) ? 0 : prefix.length);
      final caret = (a + delta).clamp(lineStart, lineStart + changed.length);
      return TextEdit(t, caret, caret);
    }
    return TextEdit(t, lineStart, lineStart + changed.length);
  }

  /// Placeholder address inserted by [link]; selected so the user types over it.
  static const linkPlaceholder = 'https://';

  /// `[selection](https://)` with the address selected; with an empty selection the caret goes
  /// between the brackets.
  static TextEdit link(TextEdit s) {
    final (a, b) = _range(s);
    final label = s.text.substring(a, b);
    final t = s.text.replaceRange(a, b, '[$label]($linkPlaceholder)');
    if (label.isEmpty) return TextEdit(t, a + 1, a + 1);
    final urlStart = a + label.length + 3;
    return TextEdit(t, urlStart, urlStart + linkPlaceholder.length);
  }
}
