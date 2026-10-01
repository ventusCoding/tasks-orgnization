import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';

// Table (spreadsheet) view (T3.7.05) — pure: columns, rows (occurrences or one row per task),
// sorting and grouping.

/// Table columns (`options.columns`, in display order).
enum TableColumn {
  title,
  date,
  start,
  end,
  duration,
  status,
  category,
  priority,
  tags,
  tracking,
  recurrence,
  actual,
  deadline;

  static TableColumn? parse(Object? s) => values.where((c) => c.name == s).firstOrNull;

  /// Default width in logical pixels.
  double get defaultWidth => switch (this) {
    title => 200,
    date => 110,
    start || end => 80,
    duration || actual => 90,
    status => 120,
    category || tags => 130,
    priority => 100,
    tracking => 100,
    recurrence => 110,
    deadline => 120,
  };
}

/// What a row is (`options.rows`): every occurrence of the range, or one row per task/series.
enum TableRows { occurrences, tasks }

/// Grouping (`options.groupBy`).
enum TableGroup { none, day, category, status }

/// Columns of a config's `options.columns` (unknown names dropped; title always first).
List<TableColumn> tableColumns(List<Object?> names) {
  final cols = [
    for (final n in names)
      if (TableColumn.parse(n) case final c?) c,
  ];
  return [TableColumn.title, ...cols.where((c) => c != TableColumn.title)];
}

/// One row per task (series id), keeping its earliest occurrence of the range.
List<PlannerItem> tableTaskRows(Iterable<PlannerItem> items) {
  final first = <String, PlannerItem>{};
  for (final i in items) {
    final current = first[i.seriesId];
    if (current == null || i.startLocal.isBefore(current.startLocal)) first[i.seriesId] = i;
  }
  return first.values.toList();
}

/// Comparator of [column] (ties: start, then title). Names come from the lookups.
int Function(PlannerItem a, PlannerItem b) tableComparator(
  TableColumn column, {
  bool ascending = true,
  String Function(String? categoryId)? categoryName,
  String Function(PlannerItem item)? tagNames,
}) {
  int primary(PlannerItem a, PlannerItem b) => switch (column) {
    TableColumn.title => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    TableColumn.date || TableColumn.start => a.startLocal.compareTo(b.startLocal),
    TableColumn.end => a.endLocal.compareTo(b.endLocal),
    TableColumn.duration => a.durationMinutes.compareTo(b.durationMinutes),
    TableColumn.status => a.status.index.compareTo(b.status.index),
    TableColumn.category => (categoryName?.call(a.categoryId) ?? a.categoryId ?? '').compareTo(
      categoryName?.call(b.categoryId) ?? b.categoryId ?? '',
    ),
    TableColumn.priority => a.priority.compareTo(b.priority),
    TableColumn.tags => (tagNames?.call(a) ?? '').compareTo(tagNames?.call(b) ?? ''),
    TableColumn.tracking => a.trackingMode.index.compareTo(b.trackingMode.index),
    TableColumn.recurrence => (a.isRecurring ? 1 : 0).compareTo(b.isRecurring ? 1 : 0),
    TableColumn.actual => (a.trackedSeconds ?? 0).compareTo(b.trackedSeconds ?? 0),
    TableColumn.deadline => _compareNullable(a.deadlineLocal, b.deadlineLocal),
  };
  return (a, b) {
    final c = primary(a, b);
    if (c != 0) return ascending ? c : -c;
    final s = a.startLocal.compareTo(b.startLocal);
    return s != 0 ? s : a.title.compareTo(b.title);
  };
}

int _compareNullable(LocalDateTime? a, LocalDateTime? b) {
  if (a == null || b == null) return a == null ? (b == null ? 0 : 1) : -1;
  return a.compareTo(b);
}

/// Group key of a row: ISO day, category id ('' = none) or status name.
String tableGroupKey(PlannerItem i, TableGroup g) => switch (g) {
  TableGroup.none => '',
  TableGroup.day => i.startLocal.date.toIso(),
  TableGroup.category => i.categoryId ?? '',
  TableGroup.status => i.status.name,
};

/// A displayed line: a group header (with its count) or a data row.
sealed class TableLine {
  const TableLine();
}

final class TableGroupLine extends TableLine {
  const TableGroupLine(this.key, this.count);

  final String key;
  final int count;
}

final class TableItemLine extends TableLine {
  const TableItemLine(this.item);

  final PlannerItem item;
}

/// Sorted rows, optionally grouped (groups in first-appearance order of the sorted rows, except
/// days, which stay chronological).
List<TableLine> tableLines(List<PlannerItem> sorted, TableGroup g) {
  if (g == TableGroup.none) return [for (final i in sorted) TableItemLine(i)];
  final groups = <String, List<PlannerItem>>{};
  for (final i in sorted) {
    groups.putIfAbsent(tableGroupKey(i, g), () => []).add(i);
  }
  final keys = groups.keys.toList();
  if (g == TableGroup.day) keys.sort();
  return [
    for (final k in keys) ...[TableGroupLine(k, groups[k]!.length), for (final i in groups[k]!) TableItemLine(i)],
  ];
}
