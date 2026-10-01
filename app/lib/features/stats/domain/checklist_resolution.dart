/// Checklist stats adapter (T6.4.01): turns checklist rows and `checklist_item` activity events into
/// the per-item facts of `everslot_metrics` (status timelines, start/done, reopens, episodes).
/// Pure Dart — runs in the stats isolate.
///
/// Event normalization: `created`, `status_changed` (`{from, to, note}`), `moved`
/// (`{fromChecklistId, toChecklistId, fromParentId, toParentId}`), `deleted` and `restored`; other
/// event types (text edits, attachments) only feed the staleness activity.
library;

import 'package:everslot/features/stats/domain/stats_inputs.dart';
import 'package:everslot/features/stats/domain/zone_snapshot.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show ZoneResolver;

/// Everything the checklist catalog needs, derived once per batch.
final class ChecklistFacts {
  ChecklistFacts(this.input, {required ZoneResolver resolver, required String viewerZone, required this.now}) {
    final rowsList = <ChecklistItemRow>[];
    for (final i in input.items) {
      DateTime? due;
      if (i.dueLocal != null) {
        due = resolver.resolve(i.dueLocal!, i.timeZone ?? viewerZone).utc;
      }
      rowsList.add(
        ChecklistItemRow(
          i.id,
          checklistId: i.checklistId,
          status: ItemStatus.values.firstWhere((s) => s.name == i.status, orElse: () => ItemStatus.todo),
          createdAt: i.createdAt,
          parentId: i.parentId,
          completedAt: i.completedAt,
          deletedAt: i.deletedAt,
          dueAt: due,
          followUpAt: i.followUpAt,
          waitingOn: i.waitingOn,
          statusNote: i.statusNote,
          text: i.text,
        ),
      );
    }
    rows = rowsList;
    final ev = <StatusEvent>[];
    final activity = <String, DateTime>{};
    final edits = <String, List<DateTime>>{};
    for (final e in input.events) {
      final type = switch (e.eventType) {
        'created' => StatusEventType.created,
        'status_changed' => StatusEventType.statusChanged,
        'moved' => StatusEventType.moved,
        'deleted' => StatusEventType.deleted,
        'restored' => StatusEventType.restored,
        _ => null,
      };
      if (type == null) {
        final fields = e.payload['fields'];
        if (e.eventType == 'updated' && fields is List && fields.contains('text')) {
          edits.putIfAbsent(e.entityId, () => []).add(e.occurredAt);
        }
        final cur = activity[e.entityId];
        if (cur == null || e.occurredAt.isAfter(cur)) activity[e.entityId] = e.occurredAt;
        continue;
      }
      ev.add(
        StatusEvent(
          e.entityId,
          type,
          occurredAt: e.occurredAt,
          rev: e.rev,
          from: e.payloadString('from'),
          to: e.payloadString('to'),
          note: e.payloadString('note'),
          fromContainerId: e.payloadString('fromChecklistId'),
          toContainerId: e.payloadString('toChecklistId'),
          fromParentId: e.payloadString('fromParentId'),
          toParentId: e.payloadString('toParentId'),
          cause: e.payloadString('cause'),
        ),
      );
    }
    for (final i in input.items) {
      final u = i.updatedAt;
      if (u == null) continue;
      final cur = activity[i.id];
      if (cur == null || u.isAfter(cur)) activity[i.id] = u;
    }
    events = ev;
    textEdits = edits;
    facts = buildChecklistItemFacts(rows, events, extraActivity: activity);
    lists = [
      for (final c in input.checklists)
        ChecklistRow(
          c.id,
          createdAt: c.createdAt,
          archivedAt: c.archivedAt,
          isTemplate: c.isTemplate,
          deletedAt: c.deletedAt,
        ),
    ];
    final itemToList = {for (final i in input.items) i.id: i.checklistId};
    attachments = [
      for (final a in input.attachments)
        AttachmentFact(
          a.ownerId,
          byteSize: a.byteSize,
          mimeType: a.mimeType,
          checklistId: a.ownerType == 'checklist' ? a.ownerId : itemToList[a.ownerId],
        ),
    ];
    runs = <String, List<ChecklistRunFact>>{};
    final bounds = dayBoundariesOf(resolver, viewerZone);
    for (final r in input.runs) {
      runs
          .putIfAbsent(r.checklistId, () => [])
          .add(
            ChecklistRunFact(
              r.key,
              date: bounds.dateOf(r.startedAt),
              startedAt: r.startedAt,
              totalItems: r.totalItems ?? r.snapshot.length,
              completedItems: r.completedItems ?? r.snapshot.where((s) => s.status == 'completed').length,
              endedAt: r.endedAt,
              snapshot: [
                for (final s in r.snapshot)
                  RunItemSnapshot(
                    s.itemId,
                    status: ItemStatus.values.firstWhere((x) => x.name == s.status, orElse: () => ItemStatus.todo),
                    completedAt: s.completedAt,
                  ),
              ],
            ),
          );
    }
    for (final list in runs.values) {
      list.sort((a, b) => a.startedAt.compareTo(b.startedAt));
    }
  }

  final ChecklistInput input;
  final DateTime now;

  late final List<ChecklistItemRow> rows;
  late final List<StatusEvent> events;

  /// Instants of text edits per item (`updated` events touching `text`, CL-I-14).
  late final Map<String, List<DateTime>> textEdits;
  late final List<ChecklistItemFact> facts;
  late final List<ChecklistRow> lists;
  late final List<AttachmentFact> attachments;
  late final Map<String, List<ChecklistRunFact>> runs;

  Set<String> get archivedListIds => {
    for (final c in input.checklists)
      if (c.archivedAt != null) c.id,
  };

  ChecklistRecord? listById(String id) {
    for (final c in input.checklists) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Facts of one checklist (items currently or formerly in it).
  List<ChecklistItemFact> factsOf(String checklistId) => [
    for (final f in facts)
      if (f.checklistId == checklistId || f.timeline.memberships.any((m) => m.containerId == checklistId)) f,
  ];

  /// Live rows of one checklist (tree metrics).
  List<ChecklistItemRow> rowsOf(String checklistId) => [
    for (final r in rows)
      if (r.checklistId == checklistId) r,
  ];
}
