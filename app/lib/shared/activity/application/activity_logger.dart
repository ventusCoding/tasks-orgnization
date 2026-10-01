import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/shared/activity/domain/activity_event.dart';

/// Typed front-end to [WriteTx.logEvent] (T2.3.05): use it inside a `SyncWriter.run` body so the
/// event joins the operation (same `opId`, same transaction). Payloads come from
/// [ActivityPayloads]; `opId` and `cause` are added by the write path.
///
/// ```dart
/// await writer.run((tx) async {
///   await tx.update('checklist_items', id, {'status': 'blocked'});
///   await tx.activity.statusChanged('checklist_item', id, from: 'waiting', to: 'blocked', parentId: listId);
/// });
/// ```
class ActivityLogger {
  const ActivityLogger(this._tx);

  final WriteTx _tx;

  Future<void> log(
    String entityType,
    String entityId,
    String eventType, {
    Map<String, Object?> payload = const {},
    String? parentId,
    String? id,
  }) => _tx.logEvent(
    entityType: entityType,
    entityId: entityId,
    eventType: eventType,
    parentId: parentId,
    payload: payload,
    id: id,
  );

  Future<void> created(
    String entityType,
    String entityId, {
    String? parentId,
    Map<String, Object?> payload = const {},
  }) => log(entityType, entityId, ActivityEventTypes.created, parentId: parentId, payload: payload);

  /// Skipped when [fields] is empty (nothing changed).
  Future<void> updated(
    String entityType,
    String entityId, {
    required Iterable<String> fields,
    Map<String, Object?>? before,
    Map<String, Object?>? after,
    String? parentId,
  }) async {
    if (fields.isEmpty) return;
    await log(
      entityType,
      entityId,
      ActivityEventTypes.updated,
      parentId: parentId,
      payload: ActivityPayloads.updated(fields, before: before, after: after),
    );
  }

  /// Written for every status change, including bulk and cascaded ones (the run's cause says
  /// which). Skipped when [from] equals [to].
  Future<void> statusChanged(
    String entityType,
    String entityId, {
    required String from,
    required String to,
    String? note,
    String? source,
    String? parentId,
  }) async {
    if (from == to) return;
    await log(
      entityType,
      entityId,
      ActivityEventTypes.statusChanged,
      parentId: parentId,
      payload: ActivityPayloads.statusChanged(from: from, to: to, note: note, source: source),
    );
  }

  Future<void> rescheduled(
    String entityType,
    String entityId, {
    String? occurrenceKey,
    String? scope,
    String? fromStart,
    String? toStart,
    int? fromDuration,
    int? toDuration,
    String? zone,
    String? source,
    String? parentId,
  }) => log(
    entityType,
    entityId,
    ActivityEventTypes.rescheduled,
    parentId: parentId,
    payload: ActivityPayloads.rescheduled(
      occurrenceKey: occurrenceKey,
      scope: scope,
      fromStart: fromStart,
      toStart: toStart,
      fromDuration: fromDuration,
      toDuration: toDuration,
      zone: zone,
      source: source,
    ),
  );

  Future<void> moved(
    String entityType,
    String entityId, {
    String? fromParentId,
    String? toParentId,
    String? fromChecklistId,
    String? toChecklistId,
    String? parentId,
  }) => log(
    entityType,
    entityId,
    ActivityEventTypes.moved,
    parentId: parentId,
    payload: ActivityPayloads.moved(
      fromParentId: fromParentId,
      toParentId: toParentId,
      fromChecklistId: fromChecklistId,
      toChecklistId: toChecklistId,
    ),
  );

  Future<void> completed(String entityType, String entityId, {String? parentId}) =>
      log(entityType, entityId, ActivityEventTypes.completed, parentId: parentId);

  Future<void> reopened(String entityType, String entityId, {String? parentId}) =>
      log(entityType, entityId, ActivityEventTypes.reopened, parentId: parentId);

  Future<void> skipped(
    String entityType,
    String entityId, {
    String? from,
    String? reason,
    String? source,
    String? parentId,
  }) => log(
    entityType,
    entityId,
    ActivityEventTypes.skipped,
    parentId: parentId,
    payload: ActivityPayloads.skipped(from: from, reason: reason, source: source),
  );

  Future<void> deleted(String entityType, String entityId, {int? count, String? parentId}) => log(
    entityType,
    entityId,
    ActivityEventTypes.deleted,
    parentId: parentId,
    payload: ActivityPayloads.deleted(count: count),
  );

  Future<void> restored(String entityType, String entityId, {String? fromOpId, String? parentId}) => log(
    entityType,
    entityId,
    ActivityEventTypes.restored,
    parentId: parentId,
    payload: ActivityPayloads.restored(fromOpId: fromOpId),
  );

  Future<void> attachmentAdded(
    String entityType,
    String entityId, {
    required String attachmentId,
    String? fileName,
    String? mimeType,
  }) => log(
    entityType,
    entityId,
    ActivityEventTypes.attachmentAdded,
    payload: ActivityPayloads.attachment(attachmentId: attachmentId, fileName: fileName, mimeType: mimeType),
  );

  Future<void> attachmentRemoved(
    String entityType,
    String entityId, {
    required String attachmentId,
    String? fileName,
  }) => log(
    entityType,
    entityId,
    ActivityEventTypes.attachmentRemoved,
    payload: ActivityPayloads.attachment(attachmentId: attachmentId, fileName: fileName),
  );
}

extension ActivityLoggerTx on WriteTx {
  /// `tx.activity.statusChanged(...)` inside a `SyncWriter.run` body.
  ActivityLogger get activity => ActivityLogger(this);
}
