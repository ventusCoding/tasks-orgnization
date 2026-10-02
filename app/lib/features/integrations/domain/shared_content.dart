import 'package:everslot/features/checklists/domain/import_export.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:meta/meta.dart';

enum SharedFileKind { image, video, file }

@immutable
class SharedFile {
  const SharedFile({required this.path, required this.kind, this.mimeType});

  final String path;
  final SharedFileKind kind;
  final String? mimeType;

  String get name => path.split(RegExp(r'[/\\]')).last;

  @override
  bool operator ==(Object other) =>
      other is SharedFile && other.path == path && other.kind == kind && other.mimeType == mimeType;

  @override
  int get hashCode => Object.hash(path, kind, mimeType);
}

/// What the system share sheet handed to Everslot (T8.2.07): text / URLs and files.
@immutable
class SharedContent {
  const SharedContent({this.text = '', this.files = const []});

  /// Text and URLs, joined by new lines.
  final String text;
  final List<SharedFile> files;

  bool get isEmpty => text.trim().isEmpty && files.isEmpty;

  int get imageCount => files.where((f) => f.kind == SharedFileKind.image).length;

  /// The text is a single link.
  bool get isUrl => Uri.tryParse(text.trim())?.hasScheme == true && !text.trim().contains(RegExp(r'\s'));

  List<String> get _lines => [
    for (final l in text.split(RegExp(r'\r?\n')))
      if (l.trim().isNotEmpty) l,
  ];

  /// Title for a new task: the first line (clipped); null when only files were shared.
  String? get taskTitle {
    final lines = _lines;
    if (lines.isEmpty) return null;
    final first = lines.first.trim();
    return first.length <= 120 ? first : '${first.substring(0, 119)}…';
  }

  /// Notes for a new task: everything after the first line.
  String? get taskNotes {
    final lines = _lines;
    return lines.length < 2 ? null : lines.skip(1).join('\n');
  }

  @override
  bool operator ==(Object other) => other is SharedContent && other.text == text && _sameFiles(other.files, files);

  @override
  int get hashCode => Object.hash(text, Object.hashAll(files));

  static bool _sameFiles(List<SharedFile> a, List<SharedFile> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Shared text → checklist items (T8.2.07): every line becomes an item, indentation nests, Markdown
/// task boxes and bullets are understood (the [4.5] import parser). Files alone become one item
/// named [filesTitle] that will carry them.
abstract final class ShareIntake {
  static List<NodeSpec> itemsFor(SharedContent content, {required String filesTitle}) {
    final nodes = content.text.trim().isEmpty ? const <NodeSpec>[] : ChecklistImport.parseText(content.text).nodes;
    if (nodes.isNotEmpty) return nodes;
    return content.files.isEmpty ? const [] : [NodeSpec(text: filesTitle)];
  }

  /// A new list from shared text: a single top line with nested lines becomes the title and its
  /// items; otherwise the first line is the title and the remaining lines the items.
  static ({String title, List<NodeSpec> items}) newList(SharedContent content, {required String fallbackTitle}) {
    final nodes = content.text.trim().isEmpty ? const <NodeSpec>[] : ChecklistImport.parseText(content.text).nodes;
    if (nodes.length == 1 && nodes.single.children.isNotEmpty) {
      return (title: nodes.single.text, items: nodes.single.children);
    }
    if (nodes.isEmpty) return (title: fallbackTitle, items: const []);
    return (title: nodes.first.text, items: [...nodes.first.children, ...nodes.skip(1)]);
  }
}
