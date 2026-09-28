import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:meta/meta.dart';

/// Why part of an import was skipped (localized by the UI).
enum ImportWarning { tooManyLines, emptyInput, malformedOpml, attachmentsSkipped }

/// Parsed external list (T4.5.07).
@immutable
class ImportResult {
  const ImportResult({required this.nodes, this.title, this.warnings = const [], this.attachmentRefs = const []});

  final List<NodeSpec> nodes;
  final String? title;
  final List<ImportWarning> warnings;

  /// With `keepAttachments`: the `📎` references of every node in preorder (bundles, T4.4.08).
  final List<List<String>> attachmentRefs;

  int get count => nodes.fold(0, (a, n) => a + n.size);
  bool get isEmpty => nodes.isEmpty;
}

class _Builder {
  _Builder(this.text, {this.status = ItemStatus.todo, this.statusNote});

  String text;
  ItemStatus status;
  String? statusNote;
  final List<String> noteLines = [];
  final List<String> attachments = [];
  final List<_Builder> children = [];

  void collectAttachments(List<List<String>> out) {
    for (final c in children) {
      out.add(c.attachments);
      c.collectAttachments(out);
    }
  }

  NodeSpec build() => NodeSpec(
    text: text,
    status: status,
    statusNote: statusNote,
    note: noteLines.isEmpty ? null : noteLines.join('\n'),
    children: [for (final c in children) c.build()],
  );
}

/// Status glyphs used by our Markdown/plain exports (T4.5.09).
abstract final class StatusGlyphs {
  static const ongoing = '▶';
  static const waiting = '⏳';
  static const blocked = '⛔';
  static const cancelled = '✖';

  static String? of(ItemStatus s) => switch (s) {
    ItemStatus.ongoing => ongoing,
    ItemStatus.waiting => waiting,
    ItemStatus.blocked => blocked,
    ItemStatus.cancelled => cancelled,
    _ => null,
  };

  static ItemStatus? parse(String glyph) => switch (glyph) {
    ongoing => ItemStatus.ongoing,
    waiting => ItemStatus.waiting,
    blocked => ItemStatus.blocked,
    cancelled => ItemStatus.cancelled,
    _ => null,
  };
}

/// Pure parser for indented text, Markdown task lists and OPML (T4.5.07).
abstract final class ChecklistImport {
  static const maxLines = 10000;

  static final _bullet = RegExp(r'^(?:[-*•+]|\d{1,4}[.)])\s+');
  static final _task = RegExp(r'^(?:\[( |x|X)\]|([☐☑☒✔✓]))\s*');
  static final _heading = RegExp(r'^(#{1,6})\s+(.*)$');
  static final _statusSuffix = RegExp(r'^(.*?)\s+—\s+(ongoing|waiting|blocked|cancelled|completed):\s*(.*)$');

  /// Auto-detects OPML vs text/Markdown.
  static ImportResult parse(String input) {
    final t = input.trimLeft();
    if (t.startsWith('<?xml') || t.startsWith('<opml')) return parseOpml(input);
    return parseText(input);
  }

  static int _indentWidth(String line) {
    var w = 0;
    for (final c in line.codeUnits) {
      if (c == 0x20) {
        w += 1;
      } else if (c == 0x09) {
        w += 4;
      } else {
        break;
      }
    }
    return w;
  }

  static ImportResult parseText(String input, {bool keepAttachments = false}) {
    final warnings = <ImportWarning>[];
    var lines = input.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    if (lines.length > maxLines) {
      lines = lines.sublist(0, maxLines);
      warnings.add(ImportWarning.tooManyLines);
    }
    final nonBlank = lines.where((l) => l.trim().isNotEmpty).toList();
    if (nonBlank.isEmpty) return const ImportResult(nodes: [], warnings: [ImportWarning.emptyInput]);
    final bulletLines = nonBlank.where((l) => _bullet.hasMatch(l.trimLeft()) || _task.hasMatch(l.trimLeft())).length;
    final usesBullets = bulletLines * 2 >= nonBlank.length;

    // A single leading H1 becomes the title.
    String? title;
    final h1 = nonBlank.where((l) => l.startsWith('# ')).length;
    var skipFirst = false;
    if (h1 == 1 && nonBlank.first.startsWith('# ')) {
      title = nonBlank.first.substring(2).trim();
      skipFirst = true;
    }

    final root = _Builder('');
    final stack = <(int, _Builder)>[];
    var skipped = false;
    for (final raw in lines) {
      if (raw.trim().isEmpty) continue;
      if (skipFirst && !skipped && raw.startsWith('# ')) {
        skipped = true;
        continue;
      }
      var width = _indentWidth(raw);
      var content = raw.trim();
      if (content.startsWith('📎')) {
        final ref = content.substring('📎'.length).trim();
        if (keepAttachments && stack.isNotEmpty && ref.isNotEmpty) {
          stack.last.$2.attachments.add(ref);
        } else if (!warnings.contains(ImportWarning.attachmentsSkipped)) {
          warnings.add(ImportWarning.attachmentsSkipped);
        }
        continue;
      }
      final heading = _heading.firstMatch(content);
      final isBullet = _bullet.hasMatch(content) || _task.hasMatch(content);
      if (heading != null) {
        width = -(7 - heading.group(1)!.length) * 1000;
        content = heading.group(2)!.trim();
      } else if (usesBullets && !isBullet) {
        // Note line: attach to the closest shallower item.
        while (stack.isNotEmpty && stack.last.$1 >= width) {
          stack.removeLast();
        }
        if (stack.isNotEmpty) {
          stack.last.$2.noteLines.add(content);
          continue;
        }
      }
      content = content.replaceFirst(_bullet, '');
      var status = ItemStatus.todo;
      final task = _task.firstMatch(content);
      if (task != null) {
        final open = task.group(1) == ' ' || task.group(2) == '☐';
        status = open ? ItemStatus.todo : ItemStatus.completed;
        content = content.substring(task.end);
      }
      if (content.isNotEmpty) {
        final glyph = StatusGlyphs.parse(String.fromCharCodes(content.runes.take(1)));
        if (glyph != null) {
          status = glyph;
          content = String.fromCharCodes(content.runes.skip(1)).trimLeft();
        }
      }
      String? statusNote;
      final suffix = _statusSuffix.firstMatch(content);
      if (suffix != null) {
        content = suffix.group(1)!;
        final note = suffix.group(3)!.trim();
        statusNote = note.isEmpty ? null : note;
      }
      content = content.replaceAll('<br>', '\n');
      final node = _Builder(content, status: status, statusNote: statusNote);
      while (stack.isNotEmpty && stack.last.$1 >= width) {
        stack.removeLast();
      }
      (stack.isEmpty ? root : stack.last.$2).children.add(node);
      stack.add((width, node));
    }
    final refs = <List<String>>[];
    if (keepAttachments) root.collectAttachments(refs);
    return ImportResult(
      nodes: [for (final c in root.children) c.build()],
      title: title,
      warnings: warnings,
      attachmentRefs: refs,
    );
  }

  static String _decode(String s) => s
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&#10;', '\n')
      .replaceAll('&#xA;', '\n')
      .replaceAll('&#xa;', '\n')
      .replaceAll('&#13;', '')
      .replaceAll('&amp;', '&');

  static Map<String, String> _attributes(String raw) => {
    for (final m in RegExp(r'''([\w:.-]+)\s*=\s*("([^"]*)"|'([^']*)')''').allMatches(raw))
      m.group(1)!: _decode(m.group(3) ?? m.group(4) ?? ''),
  };

  /// OPML 1.0/2.0 with Workflowy/Dynalist conventions (`_note`, `_complete`) and our `_status`.
  static ImportResult parseOpml(String input) {
    final warnings = <ImportWarning>[];
    final root = _Builder('');
    final stack = <_Builder>[root];
    String? title;
    final titleMatch = RegExp(r'<title>([\s\S]*?)</title>').firstMatch(input);
    if (titleMatch != null) title = _decode(titleMatch.group(1)!.trim());
    var count = 0;
    for (final m in RegExp(r'<(/?)outline\b([^>]*?)(/?)>').allMatches(input)) {
      final closing = m.group(1) == '/';
      final selfClosing = m.group(3) == '/';
      if (closing) {
        if (stack.length > 1) stack.removeLast();
        continue;
      }
      if (++count > maxLines) {
        warnings.add(ImportWarning.tooManyLines);
        break;
      }
      final a = _attributes(m.group(2)!);
      var status = ItemStatus.parse(a['_status']);
      if (a['_status'] == null && (a['_complete'] == 'true' || a['complete'] == 'true')) status = ItemStatus.completed;
      final node = _Builder(a['text'] ?? a['title'] ?? '', status: status, statusNote: a['_statusNote']);
      final note = a['_note'];
      if (note != null && note.trim().isNotEmpty) node.noteLines.add(note);
      stack.last.children.add(node);
      if (!selfClosing) stack.add(node);
    }
    if (count == 0 && !input.contains('<opml')) warnings.add(ImportWarning.malformedOpml);
    return ImportResult(nodes: [for (final c in root.children) c.build()], title: title, warnings: warnings);
  }
}

/// Exports a checklist or a branch (T4.5.09). Every format round-trips through [ChecklistImport].
abstract final class ChecklistExport {
  static List<String> _roots(ChecklistTree tree, String? rootId) =>
      rootId == null ? tree.childIds(null) : tree.childIds(rootId);

  static void _walk(ChecklistTree tree, String? rootId, void Function(String id, int depth) visit) {
    final stack = <(String, int)>[];
    final roots = _roots(tree, rootId);
    for (var i = roots.length - 1; i >= 0; i--) {
      stack.add((roots[i], 0));
    }
    while (stack.isNotEmpty) {
      final (id, depth) = stack.removeLast();
      visit(id, depth);
      final kids = tree.childIds(id);
      for (var i = kids.length - 1; i >= 0; i--) {
        stack.add((kids[i], depth + 1));
      }
    }
  }

  static String _inline(String text) => text.replaceAll('\n', '<br>');

  static String _statusLine(ItemStatus s, String text, String? note, {required bool checkbox}) {
    final box = checkbox ? (s == ItemStatus.completed ? '[x] ' : '[ ] ') : (s == ItemStatus.completed ? '[x] ' : '');
    final glyph = StatusGlyphs.of(s);
    final suffix = (s.isOpen && s != ItemStatus.todo) || s == ItemStatus.cancelled
        ? (note != null ? ' — ${s.name}: $note' : '')
        : (s == ItemStatus.completed && note != null ? ' — completed: $note' : '');
    return '$box${glyph == null ? '' : '$glyph '}${_inline(text)}$suffix';
  }

  /// Nested `- [ ]` / `- [x]` with status glyphs, notes as indented paragraphs, attachment names.
  static String markdown(
    ChecklistTree tree, {
    String? title,
    String? rootId,
    Map<String, List<String>> attachmentNames = const {},
  }) {
    final out = StringBuffer();
    if (title != null && title.trim().isNotEmpty) out.writeln('# ${title.trim()}\n');
    _walk(tree, rootId, (id, depth) {
      final i = tree[id]!;
      final pad = '  ' * depth;
      out.writeln('$pad- ${_statusLine(i.status, i.text, i.statusNote, checkbox: true)}');
      if (i.hasNote) {
        for (final line in i.note!.split('\n')) {
          if (line.trim().isNotEmpty) out.writeln('$pad  ${line.trim()}');
        }
      }
      for (final name in attachmentNames[id] ?? const <String>[]) {
        out.writeln('$pad  📎 $name');
      }
    });
    return out.toString();
  }

  /// Plain indented text (2 spaces per level).
  static String plainText(ChecklistTree tree, {String? title, String? rootId}) {
    final out = StringBuffer();
    if (title != null && title.trim().isNotEmpty) out.writeln('# ${title.trim()}\n');
    _walk(tree, rootId, (id, depth) {
      final i = tree[id]!;
      out.writeln('${'  ' * depth}${_statusLine(i.status, i.text, i.statusNote, checkbox: false)}');
    });
    return out.toString();
  }

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll('\n', '&#10;');

  /// OPML 2.0 with `_note`, `_complete`, `_status` (+ `_statusNote`).
  static String opml(
    ChecklistTree tree, {
    String? title,
    String? rootId,
    Map<String, List<String>> attachmentNames = const {},
  }) {
    final out = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<opml version="2.0">')
      ..writeln('  <head><title>${_esc(title ?? '')}</title></head>')
      ..writeln('  <body>');
    void node(String id, int depth) {
      final i = tree[id]!;
      final pad = '  ' * (depth + 2);
      final attrs = StringBuffer('text="${_esc(i.text)}"');
      if (i.hasNote) attrs.write(' _note="${_esc(i.note!)}"');
      if (i.status == ItemStatus.completed) attrs.write(' _complete="true"');
      if (i.status != ItemStatus.todo) attrs.write(' _status="${i.status.name}"');
      if (i.statusNote != null) attrs.write(' _statusNote="${_esc(i.statusNote!)}"');
      // File names ride along as an attribute so a re-import does not turn them into items.
      final files = attachmentNames[id] ?? const <String>[];
      if (files.isNotEmpty) attrs.write(' _attachments="${_esc(files.join(' | '))}"');
      final kids = tree.childIds(id);
      if (kids.isEmpty) {
        out.writeln('$pad<outline $attrs/>');
      } else {
        out.writeln('$pad<outline $attrs>');
        for (final k in kids) {
          node(k, depth + 1);
        }
        out.writeln('$pad</outline>');
      }
    }

    for (final r in _roots(tree, rootId)) {
      node(r, 0);
    }
    out
      ..writeln('  </body>')
      ..writeln('</opml>');
    return out.toString();
  }

  /// Plain text of a selection for "copy as text" (T4.2.16/T4.2.17).
  static String subtreesAsText(ChecklistTree tree, List<String> ids) {
    final out = StringBuffer();
    for (final top in tree.topMost(ids)) {
      final base = tree.depthOf(top);
      for (final id in [top, ...tree.descendants(top)]) {
        final i = tree[id]!;
        out.writeln(
          '${'  ' * (tree.depthOf(id) - base)}- ${_statusLine(i.status, i.text, i.statusNote, checkbox: true)}',
        );
      }
    }
    return out.toString();
  }
}
