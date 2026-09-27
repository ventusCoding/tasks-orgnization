import 'package:everslot/features/checklists/domain/board.dart';
import 'package:everslot/features/checklists/domain/collation.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:meta/meta.dart';

/// Columns of the flat all-items table (T4.5.15).
enum ItemTableColumn { text, checklist, path, status, age, due, followUp, priority, attachments }

/// Sort + filter of the all-items table. Pure: applied to the rows the DAO streams.
@immutable
class ItemTableQuery {
  const ItemTableQuery({
    this.sortBy = ItemTableColumn.checklist,
    this.descending = false,
    this.statuses = const {},
    this.text = '',
  });

  final ItemTableColumn sortBy;
  final bool descending;

  /// Empty = every status.
  final Set<ItemStatus> statuses;

  /// Matches the item text, its list title or its path (case-insensitive).
  final String text;

  ItemTableQuery copyWith({ItemTableColumn? sortBy, bool? descending, Set<ItemStatus>? statuses, String? text}) =>
      ItemTableQuery(
        sortBy: sortBy ?? this.sortBy,
        descending: descending ?? this.descending,
        statuses: statuses ?? this.statuses,
        text: text ?? this.text,
      );

  /// Tapping a header: same column toggles the direction, a new column sorts ascending.
  ItemTableQuery sortedBy(ItemTableColumn column) =>
      column == sortBy ? copyWith(descending: !descending) : copyWith(sortBy: column, descending: false);

  /// Filters then sorts [rows] (stable: the DAO order breaks ties). Missing values (no due date,
  /// no follow-up, never changed) stay last in both directions.
  List<SmartItem> apply(List<SmartItem> rows, {Map<String, int> attachments = const {}}) {
    final needle = text.trim().toLowerCase();
    final filtered = [
      for (final r in rows)
        if ((statuses.isEmpty || statuses.contains(r.item.status)) &&
            (needle.isEmpty ||
                r.item.text.toLowerCase().contains(needle) ||
                r.checklistTitle.toLowerCase().contains(needle) ||
                r.path.any((p) => p.toLowerCase().contains(needle))))
          r,
    ];
    final indexed = [for (var i = 0; i < filtered.length; i++) (i, filtered[i])];
    int missing(SmartItem r) => switch (sortBy) {
      ItemTableColumn.due => r.item.dueLocal == null ? 1 : 0,
      ItemTableColumn.followUp => r.item.followUpAt == null ? 1 : 0,
      ItemTableColumn.age => r.item.statusSince == null ? 1 : 0,
      _ => 0,
    };
    int compare(SmartItem a, SmartItem b) => switch (sortBy) {
      ItemTableColumn.text => Collation.compare(a.item.text, b.item.text),
      ItemTableColumn.checklist => Collation.compare(a.checklistTitle, b.checklistTitle),
      ItemTableColumn.path => Collation.compare(a.path.join(' › '), b.path.join(' › ')),
      ItemTableColumn.status => a.item.status.urgencyRank.compareTo(b.item.status.urgencyRank),
      // Oldest status first = longest in its state.
      ItemTableColumn.age => a.item.statusSince!.compareTo(b.item.statusSince!),
      ItemTableColumn.due => a.item.dueLocal!.compareTo(b.item.dueLocal!),
      ItemTableColumn.followUp => a.item.followUpAt!.compareTo(b.item.followUpAt!),
      ItemTableColumn.priority => b.item.priority.compareTo(a.item.priority),
      ItemTableColumn.attachments => (attachments[b.item.id] ?? 0).compareTo(attachments[a.item.id] ?? 0),
    };
    indexed.sort((x, y) {
      final m = missing(x.$2).compareTo(missing(y.$2));
      if (m != 0) return m;
      if (missing(x.$2) == 1) return x.$1.compareTo(y.$1);
      final c = compare(x.$2, y.$2);
      final r = descending ? -c : c;
      return r != 0 ? r : x.$1.compareTo(y.$1);
    });
    return [for (final e in indexed) e.$2];
  }

  @override
  bool operator ==(Object other) =>
      other is ItemTableQuery &&
      other.sortBy == sortBy &&
      other.descending == descending &&
      other.text == text &&
      other.statuses.length == statuses.length &&
      other.statuses.containsAll(statuses);

  @override
  int get hashCode => Object.hash(sortBy, descending, text, Object.hashAllUnordered(statuses));
}
