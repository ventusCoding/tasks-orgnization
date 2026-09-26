import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/shared/activity/domain/activity_event.dart';

/// Reads the activity log (T2.3.05). Writes happen inside other repositories' operations through
/// `ActivityLogger` / `WriteTx.logEvent`.
class ActivityRepository {
  ActivityRepository(this._db, this._userId);

  final AppDatabase _db;
  final String Function() _userId;

  static ActivityEvent map(ActivityEventRow r) {
    Map<String, Object?> payload;
    try {
      final decoded = jsonDecode(r.payload);
      payload = decoded is Map ? Map<String, Object?>.from(decoded) : const {};
    } on FormatException {
      payload = const {};
    }
    return ActivityEvent(
      id: r.id,
      entityType: r.entityType,
      entityId: r.entityId,
      parentId: r.parentId,
      eventType: r.eventType,
      payload: payload,
      occurredAt: r.occurredAt.toUtc(),
    );
  }

  /// Events of one entity, newest first. With [includeChildren], events whose parent is the entity
  /// are included too (occurrences of a task, items of a checklist). [eventTypes] narrows the
  /// result (e.g. status history, reschedule history).
  Stream<List<ActivityEvent>> watchForEntity(
    String entityType,
    String entityId, {
    bool includeChildren = false,
    Set<String>? eventTypes,
    int limit = 200,
  }) {
    final q = _db.select(_db.activityEvents)
      ..where((e) {
        Expression<bool> w = e.deletedAt.isNull() & e.userId.equals(_userId());
        final own =
            e.entityType.equals(entityType) & e.entityId.equals(entityId);
        w = w & (includeChildren ? (own | e.parentId.equals(entityId)) : own);
        if (eventTypes != null) w = w & e.eventType.isIn(eventTypes);
        return w;
      })
      ..orderBy([
        (e) => OrderingTerm.desc(e.occurredAt),
        (e) => OrderingTerm.desc(e.id),
      ])
      ..limit(limit);
    return q.watch().map((rows) => rows.map(map).toList());
  }

  Future<List<ActivityEvent>> forEntity(
    String entityType,
    String entityId, {
    bool includeChildren = false,
    Set<String>? eventTypes,
  }) => watchForEntity(
    entityType,
    entityId,
    includeChildren: includeChildren,
    eventTypes: eventTypes,
  ).first;

  /// Every event written by one operation, oldest first.
  Future<List<ActivityEvent>> operation(String opId) async {
    final rows = await _db
        .customSelect(
          "SELECT * FROM activity_events WHERE deleted_at IS NULL AND user_id = ? "
          "AND json_extract(payload, '\$.opId') = ? ORDER BY occurred_at, id",
          variables: [Variable<String>(_userId()), Variable<String>(opId)],
          readsFrom: {_db.activityEvents},
        )
        .map((r) => _db.activityEvents.map(r.data))
        .get();
    return rows.map(map).toList();
  }

  /// Delete operations since [since] (Trash, "restore everything deleted together"), newest
  /// first; each group holds every event of that operation.
  Stream<List<ActivityOperation>> watchDeleteOperations({
    required DateTime since,
    int limit = 200,
  }) => _db
      .customSelect(
        '''
SELECT e.* FROM activity_events e
WHERE e.deleted_at IS NULL AND e.user_id = ?1 AND json_extract(e.payload, '\$.opId') IN (
  SELECT json_extract(d.payload, '\$.opId') FROM activity_events d
  WHERE d.deleted_at IS NULL AND d.user_id = ?1 AND d.event_type = 'deleted' AND d.occurred_at >= ?2
  ORDER BY d.occurred_at DESC LIMIT ?3
)
ORDER BY e.occurred_at, e.id''',
        variables: [
          Variable<String>(_userId()),
          Variable<String>(since.toUtc().toIso8601String()),
          Variable<int>(limit),
        ],
        readsFrom: {_db.activityEvents},
      )
      .map((r) => map(_db.activityEvents.map(r.data)))
      .watch()
      .map((events) {
        final groups = <String, List<ActivityEvent>>{};
        for (final e in events) {
          groups.putIfAbsent(e.opId, () => []).add(e);
        }
        final ops = [
          for (final g in groups.entries)
            ActivityOperation(opId: g.key, events: g.value),
        ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
        return ops;
      });
}
