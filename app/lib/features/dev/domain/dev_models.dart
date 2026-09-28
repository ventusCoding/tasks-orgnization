// View models of the dev debug menu (T1.3.16) and sync diagnostics (T1.4.18). Pure Dart.

/// Row count of one local table (DB inspector).
class TableCount {
  const TableCount(this.table, this.rows);

  final String table;
  final int rows;

  @override
  bool operator ==(Object other) => other is TableCount && other.table == table && other.rows == rows;

  @override
  int get hashCode => Object.hash(table, rows);
}

/// One outbox entry (a field patch waiting for the server).
class OutboxEntryView {
  const OutboxEntryView({
    required this.changeId,
    required this.opId,
    required this.seq,
    required this.table,
    required this.rowId,
    required this.op,
    required this.fields,
    required this.state,
    required this.attempts,
    required this.enqueuedAt,
    this.lastError,
  });

  final String changeId;
  final String opId;
  final int seq;
  final String table;
  final String rowId;

  /// insert | update | delete (as stored in the outbox).
  final String op;

  /// Patched field names.
  final List<String> fields;

  /// pending | inflight | failed.
  final String state;
  final int attempts;
  final DateTime enqueuedAt;
  final String? lastError;

  bool get failed => state == 'failed';
}

/// Entries of one operation group (same `op_id`, always pushed together).
class OutboxGroupView {
  const OutboxGroupView(this.opId, this.entries);

  final String opId;
  final List<OutboxEntryView> entries;

  bool get hasFailures => entries.any((e) => e.failed);

  DateTime get enqueuedAt => entries.first.enqueuedAt;
}

/// Groups [entries] by operation, in outbox order (first entry of each group decides).
List<OutboxGroupView> groupOutbox(List<OutboxEntryView> entries) {
  final sorted = [...entries]..sort((a, b) => a.seq.compareTo(b.seq));
  final groups = <String, List<OutboxEntryView>>{};
  for (final e in sorted) {
    groups.putIfAbsent(e.opId, () => []).add(e);
  }
  return [for (final g in groups.entries) OutboxGroupView(g.key, g.value)];
}

/// Persisted pull cursor & timestamps of the current user.
class SyncStateView {
  const SyncStateView({
    required this.cursor,
    required this.purgeWatermarkSeen,
    this.lastPushAt,
    this.lastPullAt,
    this.lastSuccessAt,
    this.lastError,
  });

  final int cursor;
  final int purgeWatermarkSeen;
  final DateTime? lastPushAt;
  final DateTime? lastPullAt;
  final DateTime? lastSuccessAt;
  final String? lastError;
}

/// Feature flags the debug menu offers even when no build enables them.
abstract final class DevFlags {
  static const known = ['planner_views_m3'];
}

/// Time-travel shortcuts of the debug menu.
abstract final class TimeTravelSteps {
  static const steps = [
    Duration(hours: -1),
    Duration(hours: 1),
    Duration(days: -1),
    Duration(days: 1),
    Duration(days: 7),
  ];

  /// Offset that makes the app clock read [target] when real time is [realNow].
  static Duration offsetFor(DateTime target, DateTime realNow) => target.toUtc().difference(realNow.toUtc());
}
