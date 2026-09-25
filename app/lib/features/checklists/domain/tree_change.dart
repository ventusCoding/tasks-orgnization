import 'package:everslot/core/ordering/fractional_index.dart';
import 'package:meta/meta.dart';

/// One row write produced by a pure operation (snake_case server columns, arch §7.3).
@immutable
class RowWrite {
  const RowWrite.insert(this.table, this.id, this.values) : isInsert = true;
  const RowWrite.update(this.table, this.id, this.values) : isInsert = false;

  final String table;
  final String id;
  final Map<String, Object?> values;
  final bool isInsert;

  @override
  String toString() => '${isInsert ? 'INSERT' : 'UPDATE'} $table/$id $values';
}

/// Activity event to append in the same operation (payload conventions arch §7.3).
@immutable
class EventSpec {
  const EventSpec({
    required this.entityType,
    required this.entityId,
    required this.eventType,
    this.parentId,
    this.payload = const {},
    this.cause,
  });

  final String entityType;
  final String entityId;
  final String? parentId;
  final String eventType;
  final Map<String, Object?> payload;

  /// Overrides the operation cause for this event (e.g. `auto_rollup` inside a `user` op).
  final String? cause;
}

/// Where the editor should put the caret after an operation.
@immutable
class FocusHint {
  const FocusHint(this.itemId, {this.cursor, this.selectAll = false});

  final String itemId;

  /// Caret offset in the plain text; null = end.
  final int? cursor;
  final bool selectAll;
}

/// Result of a pure tree operation (T4.2.02): everything one user command writes, applied by
/// `ChecklistItemsRepository.apply` as ONE `SyncWriter.run` (one op group, one undo step).
@immutable
class TreeChange {
  const TreeChange({
    this.writes = const [],
    this.events = const [],
    this.deletedItemIds = const {},
    this.copiedItemIds = const {},
    this.reownedAttachments = const [],
    this.promotedAttachments = const {},
    this.focus,
    this.cause = 'user',
    this.scheduledAt,
  });

  static const none = TreeChange();

  final List<RowWrite> writes;
  final List<EventSpec> events;

  /// Items tombstoned by this change: their attachments and entity tags are tombstoned too.
  final Set<String> deletedItemIds;

  /// Source item id → copy id: attachment rows (same storage objects) and tags are copied.
  final Map<String, String> copiedItemIds;

  /// Attachments moved from one item to another (merge rows).
  final List<({String fromItemId, String toItemId})> reownedAttachments;

  /// Item id → checklist id: the item's attachments become checklist-level (promote).
  final Map<String, String> promotedAttachments;
  final FocusHint? focus;
  final String cause;

  /// Automatic writes (resets) use the scheduled instant as their clock (arch §6.6).
  final DateTime? scheduledAt;

  bool get isEmpty =>
      writes.isEmpty &&
      events.isEmpty &&
      deletedItemIds.isEmpty &&
      copiedItemIds.isEmpty &&
      reownedAttachments.isEmpty &&
      promotedAttachments.isEmpty;

  /// Writes to one table.
  Iterable<RowWrite> writesTo(String table) => writes.where((w) => w.table == table);

  /// Final values written for `(table, id)` (inserts and updates merged).
  Map<String, Object?>? valuesFor(String id, {String table = 'checklist_items'}) {
    Map<String, Object?>? out;
    for (final w in writes) {
      if (w.table == table && w.id == id) out = {...?out, ...w.values};
    }
    return out;
  }

  TreeChange copyWith({FocusHint? focus, String? cause, DateTime? scheduledAt}) => TreeChange(
    writes: writes,
    events: events,
    deletedItemIds: deletedItemIds,
    copiedItemIds: copiedItemIds,
    reownedAttachments: reownedAttachments,
    promotedAttachments: promotedAttachments,
    focus: focus ?? this.focus,
    cause: cause ?? this.cause,
    scheduledAt: scheduledAt ?? this.scheduledAt,
  );

  /// Concatenates two changes (writes to the same row are merged by the builder when applied).
  TreeChange merge(TreeChange other) => TreeChange(
    writes: [...writes, ...other.writes],
    events: [...events, ...other.events],
    deletedItemIds: {...deletedItemIds, ...other.deletedItemIds},
    copiedItemIds: {...copiedItemIds, ...other.copiedItemIds},
    reownedAttachments: [...reownedAttachments, ...other.reownedAttachments],
    promotedAttachments: {...promotedAttachments, ...other.promotedAttachments},
    focus: other.focus ?? focus,
    cause: cause,
    scheduledAt: scheduledAt ?? other.scheduledAt,
  );
}

/// Accumulates writes, merging several updates of one row into a single write.
class TreeChangeBuilder {
  TreeChangeBuilder({this.cause = 'user'});

  final String cause;
  final Map<String, RowWrite> _writes = {};
  final List<EventSpec> events = [];
  final Set<String> deletedItemIds = {};
  final Map<String, String> copiedItemIds = {};
  final List<({String fromItemId, String toItemId})> reownedAttachments = [];
  final Map<String, String> promotedAttachments = {};
  FocusHint? focus;

  void insert(String id, Map<String, Object?> values, {String table = 'checklist_items'}) =>
      _writes['$table|$id'] = RowWrite.insert(table, id, values);

  void update(String id, Map<String, Object?> values, {String table = 'checklist_items'}) {
    if (values.isEmpty) return;
    final key = '$table|$id';
    final existing = _writes[key];
    if (existing == null) {
      _writes[key] = RowWrite.update(table, id, values);
    } else if (existing.isInsert) {
      _writes[key] = RowWrite.insert(table, id, {...existing.values, ...values});
    } else {
      _writes[key] = RowWrite.update(table, id, {...existing.values, ...values});
    }
  }

  /// Current pending values for a row (for follow-up computations).
  Map<String, Object?>? pending(String id, {String table = 'checklist_items'}) => _writes['$table|$id']?.values;

  void event(EventSpec e) => events.add(e);

  bool get isEmpty => _writes.isEmpty && events.isEmpty && deletedItemIds.isEmpty;

  TreeChange build({DateTime? scheduledAt}) => TreeChange(
    writes: _writes.values.toList(),
    events: List.unmodifiable(events),
    deletedItemIds: Set.unmodifiable(deletedItemIds),
    copiedItemIds: Map.unmodifiable(copiedItemIds),
    reownedAttachments: List.unmodifiable(reownedAttachments),
    promotedAttachments: Map.unmodifiable(promotedAttachments),
    focus: focus,
    cause: cause,
    scheduledAt: scheduledAt,
  );
}

/// Fractional keys tolerant of equal/invalid neighbours (concurrent devices may produce equal
/// keys; imported data may contain anything). Other siblings are never renumbered.
abstract final class SortKeys {
  static String? _valid(String? k) => k != null && FractionalIndex.isValid(k) ? k : null;

  static String between(String? a, String? b) {
    final va = _valid(a);
    final vb = _valid(b);
    try {
      if (va != null && vb != null && va.compareTo(vb) >= 0) return FractionalIndex.between(va, null);
      return FractionalIndex.between(va, vb);
    } on Object {
      return FractionalIndex.between(va, null);
    }
  }

  static List<String> nBetween(String? a, String? b, int n) {
    if (n <= 0) return const [];
    final va = _valid(a);
    final vb = _valid(b);
    try {
      if (va != null && vb != null && va.compareTo(vb) >= 0) return FractionalIndex.nBetween(va, null, n);
      return FractionalIndex.nBetween(va, vb, n);
    } on Object {
      return FractionalIndex.nBetween(va, null, n);
    }
  }

  /// Evenly spaced fresh keys for a whole sibling group (sort children, imports).
  static List<String> spread(int n) => n <= 0 ? const [] : FractionalIndex.nBetween(null, null, n);
}
