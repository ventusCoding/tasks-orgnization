import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// One row of the append-only activity log (`activity_events`, arch §7.3, T2.3.05).
///
/// History timelines, status/reschedule history, stats and Trash grouping read only from this log.
/// Every event of one user command carries the same [opId] (grouped undo, "restore everything
/// deleted together").
@immutable
class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.eventType,
    required this.occurredAt,
    this.parentId,
    this.payload = const {},
  });

  final String id;

  /// See [ActivityEntityTypes].
  final String entityType;
  final String entityId;

  /// E.g. the checklist of an item, the task of an occurrence.
  final String? parentId;

  /// See [ActivityEventTypes].
  final String eventType;

  /// Small JSON payload; always has `opId` and `cause`.
  final Map<String, Object?> payload;

  /// UTC instant.
  final DateTime occurredAt;

  String get opId => payload['opId'] as String? ?? '';

  /// See [ActivityCauses] (`user` when missing).
  String get cause => payload['cause'] as String? ?? ActivityCauses.user;

  bool get isUserAction => cause == ActivityCauses.user || cause == ActivityCauses.undo;

  String? string(String key) {
    final v = payload[key];
    return v is String && v.isNotEmpty ? v : null;
  }

  int? integer(String key) {
    final v = payload[key];
    return v is num ? v.toInt() : null;
  }

  List<String> strings(String key) {
    final v = payload[key];
    return v is List
        ? [
            for (final e in v)
              if (e is String) e,
          ]
        : const [];
  }

  static const _deep = DeepCollectionEquality();

  @override
  bool operator ==(Object other) =>
      other is ActivityEvent &&
      other.id == id &&
      other.entityType == entityType &&
      other.entityId == entityId &&
      other.parentId == parentId &&
      other.eventType == eventType &&
      other.occurredAt == occurredAt &&
      _deep.equals(other.payload, payload);

  @override
  int get hashCode => Object.hash(id, entityType, entityId, parentId, eventType, occurredAt, _deep.hash(payload));

  @override
  String toString() => 'ActivityEvent($entityType/$entityId $eventType $payload)';
}

/// The events of one operation (one user command), e.g. a Trash entry.
@immutable
class ActivityOperation {
  const ActivityOperation({required this.opId, required this.events});

  final String opId;

  /// Oldest first.
  final List<ActivityEvent> events;

  DateTime get occurredAt => events.first.occurredAt;
}

/// Entity types found in the log (arch §7.3).
abstract final class ActivityEntityTypes {
  static const task = 'task';
  static const taskOccurrence = 'task_occurrence';
  static const checklist = 'checklist';
  static const checklistItem = 'checklist_item';
  static const habit = 'habit';
  static const habitLog = 'habit_log';
  static const category = 'category';
  static const tag = 'tag';
  static const review = 'review';
}

/// Event catalog (T2.3.05). Payload contracts — see [ActivityPayloads]:
///
/// | event | payload |
/// |---|---|
/// | `created` | optional `duplicatedFrom`, `fromTemplateId`, `count` |
/// | `updated` | `fields` (changed field names), optional `before`/`after` time fields |
/// | `status_changed` | `from`, `to`, optional `note`, `source` |
/// | `status_note_changed` | optional `note` |
/// | `rescheduled` | `occurrenceKey` or `scope`, `fromStart`, `toStart`, `fromDuration`, `toDuration`, `zone`, `source` |
/// | `moved` | `fromParentId`, `toParentId`, optional `fromChecklistId`, `toChecklistId` |
/// | `skipped` | optional `from`, `reason`, `source` |
/// | `deleted` | optional `count` (cascaded children) |
/// | `restored` | optional `fromOpId` |
/// | `attachment_added` / `attachment_removed` | `attachmentId`, `fileName`, optional `mimeType` |
///
/// Every payload also gets `opId` and `cause` from the write path.
abstract final class ActivityEventTypes {
  static const created = 'created';
  static const updated = 'updated';
  static const statusChanged = 'status_changed';
  static const statusNoteChanged = 'status_note_changed';
  static const rescheduled = 'rescheduled';
  static const seriesSplit = 'series_split';
  static const scheduled = 'scheduled';
  static const unscheduled = 'unscheduled';
  static const started = 'started';
  static const stopped = 'stopped';
  static const timeEntryAdded = 'time_entry_added';
  static const paused = 'paused';
  static const resumed = 'resumed';
  static const rollover = 'rollover';
  static const moved = 'moved';
  static const completed = 'completed';
  static const reopened = 'reopened';
  static const skipped = 'skipped';
  static const deleted = 'deleted';
  static const restored = 'restored';
  static const archived = 'archived';
  static const unarchived = 'unarchived';
  static const attachmentAdded = 'attachment_added';
  static const attachmentRemoved = 'attachment_removed';
  static const itemsAdded = 'items_added';
  static const sorted = 'sorted';
  static const reset = 'reset';
  static const relapse = 'relapse';
  static const merged = 'merged';

  static const all = {
    created,
    updated,
    statusChanged,
    statusNoteChanged,
    rescheduled,
    seriesSplit,
    scheduled,
    unscheduled,
    started,
    stopped,
    timeEntryAdded,
    paused,
    resumed,
    rollover,
    moved,
    completed,
    reopened,
    skipped,
    deleted,
    restored,
    archived,
    unarchived,
    attachmentAdded,
    attachmentRemoved,
    itemsAdded,
    sorted,
    reset,
    relapse,
    merged,
  };
}

/// `payload.cause` values (arch §7.3).
abstract final class ActivityCauses {
  static const user = 'user';
  static const auto = 'auto';
  static const autoRollup = 'auto_rollup';
  static const cascade = 'cascade';
  static const reset = 'reset';
  static const bulk = 'bulk';
  static const import = 'import';
  static const undo = 'undo';
}

/// Payload builders (T2.3.05): small payloads — field names and key values, never full rows;
/// free texts are clipped to [maxTextLength]; null values are omitted.
abstract final class ActivityPayloads {
  static const maxTextLength = 280;

  /// Time fields whose before/after values stats need to rebuild the plan (arch §7.3).
  static const timeFields = {'start_local', 'duration_minutes', 'is_all_day', 'time_zone', 'due_local', 'recurrence'};

  static String? clip(String? text) {
    if (text == null) return null;
    final t = text.trim();
    if (t.isEmpty) return null;
    if (t.length <= maxTextLength) return t;
    return '${t.substring(0, maxTextLength - 1)}…';
  }

  /// `updated`: sorted, de-duplicated field names; `before`/`after` keep time fields only.
  static Map<String, Object?> updated(
    Iterable<String> fields, {
    Map<String, Object?>? before,
    Map<String, Object?>? after,
  }) {
    Map<String, Object?>? times(Map<String, Object?>? values) {
      if (values == null) return null;
      final kept = {
        for (final e in values.entries)
          if (timeFields.contains(e.key)) e.key: e.value,
      };
      return kept.isEmpty ? null : kept;
    }

    final b = times(before);
    final a = times(after);
    return {
      'fields': ({...fields}.toList()..sort()),
      'before': ?b,
      'after': ?a,
    };
  }

  static Map<String, Object?> statusChanged({required String from, required String to, String? note, String? source}) =>
      {'from': from, 'to': to, 'note': ?clip(note), 'source': ?source};

  static Map<String, Object?> statusNoteChanged({String? note}) => {'note': ?clip(note)};

  /// `rescheduled`: one occurrence ([occurrenceKey]) or a [scope] (`series`, `this`,
  /// `this_and_following`); starts are ISO wall-clock strings.
  static Map<String, Object?> rescheduled({
    String? occurrenceKey,
    String? scope,
    String? fromStart,
    String? toStart,
    int? fromDuration,
    int? toDuration,
    String? zone,
    String? source,
  }) {
    if ((occurrenceKey == null) == (scope == null)) {
      throw ArgumentError('rescheduled needs exactly one of occurrenceKey or scope');
    }
    return {
      'occurrenceKey': ?occurrenceKey,
      'scope': ?scope,
      'fromStart': ?fromStart,
      'toStart': ?toStart,
      'fromDuration': ?fromDuration,
      'toDuration': ?toDuration,
      'zone': ?zone,
      'source': ?source,
    };
  }

  static Map<String, Object?> moved({
    String? fromParentId,
    String? toParentId,
    String? fromChecklistId,
    String? toChecklistId,
  }) => {
    'fromParentId': fromParentId,
    'toParentId': toParentId,
    'fromChecklistId': ?fromChecklistId,
    'toChecklistId': ?toChecklistId,
  };

  static Map<String, Object?> skipped({String? from, String? reason, String? source}) => {
    'from': ?from,
    'reason': ?clip(reason),
    'source': ?source,
  };

  static Map<String, Object?> deleted({int? count}) => {'count': ?count};

  static Map<String, Object?> restored({String? fromOpId}) => {'fromOpId': ?fromOpId};

  static Map<String, Object?> attachment({required String attachmentId, String? fileName, String? mimeType}) => {
    'attachmentId': attachmentId,
    'fileName': ?clip(fileName),
    'mimeType': ?mimeType,
  };
}
