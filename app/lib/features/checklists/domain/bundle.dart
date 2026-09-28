/// Zip bundle layout (T4.4.08): `<title>.md` at the root (the Markdown export, with each item's
/// `📎` lines holding bundle paths) and every attachment under `files/`.
abstract final class ChecklistBundle {
  static const filesDir = 'files';

  static final _unsafe = RegExp(r'[\\/:*?"<>|\x00-\x1F]');
  static final _prefix = RegExp(r'^\d+-');

  /// A safe, unique entry path per attachment: `files/<n>-<name>`.
  static String entryPath(int index, String fileName) {
    final safe = fileName.replaceAll(_unsafe, '_').trim();
    return '$filesDir/${index + 1}-${safe.isEmpty ? 'file' : safe}';
  }

  /// The Markdown file inside the bundle.
  static String textName(String title) {
    final safe = title.replaceAll(_unsafe, '_').trim();
    return '${safe.isEmpty ? 'checklist' : safe}.md';
  }

  /// Whether [ref] points into the bundle's files folder.
  static bool isEntryPath(String ref) => ref.startsWith('$filesDir/') && ref.length > filesDir.length + 1;

  /// Original file name of an entry (`files/3-photo.jpg` → `photo.jpg`).
  static String originalName(String entryPath) {
    final base = entryPath.substring(entryPath.lastIndexOf('/') + 1);
    final name = base.replaceFirst(_prefix, '');
    return name.isEmpty ? base : name;
  }
}
