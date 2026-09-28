/// Trash (T8.3.06, arch §9.3): what can be restored or deleted forever.
enum TrashKind {
  task('task', 'tasks'),
  checklist('checklist', 'checklists'),
  checklistItem('checklist_item', 'checklist_items'),
  habit('habit', 'habits'),
  attachment('attachment', 'attachments');

  const TrashKind(this.entityType, this.table);

  /// `app.purge_now` entity type.
  final String entityType;
  final String table;
}

/// One restorable deletion: a row deleted while its container (checklist, parent item, owner)
/// stays live. Rows deleted by the same operation share the transaction instant as `deleted_at`
/// ("deleted together") and come back with it.
class TrashEntry {
  const TrashEntry({
    required this.kind,
    required this.id,
    required this.title,
    required this.deletedAt,
    this.path = const [],
    this.withCount = 0,
  });

  final TrashKind kind;
  final String id;

  /// Title / name / text / file name (may be empty).
  final String title;
  final DateTime deletedAt;

  /// Where it lived: checklist title, then ancestor items (checklist items only).
  final List<String> path;

  /// Rows deleted together with it (items, logs, occurrences, attachments…) restored with it.
  final int withCount;

  @override
  bool operator ==(Object other) =>
      other is TrashEntry &&
      other.kind == kind &&
      other.id == id &&
      other.title == title &&
      other.deletedAt == deletedAt &&
      other.withCount == withCount &&
      other.path.length == path.length &&
      Iterable<int>.generate(path.length).every((i) => other.path[i] == path[i]);

  @override
  int get hashCode => Object.hash(kind, id, title, deletedAt, withCount, Object.hashAll(path));
}

/// Trash retention shown to the user (the server purges tombstones after 90 days).
const trashRetention = Duration(days: 30);

/// Newest deletion first, then by title.
List<TrashEntry> sortTrash(Iterable<TrashEntry> entries) => [...entries]
  ..sort((a, b) {
    final byTime = b.deletedAt.compareTo(a.deletedAt);
    return byTime != 0 ? byTime : a.title.toLowerCase().compareTo(b.title.toLowerCase());
  });
