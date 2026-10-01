import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:meta/meta.dart';

/// Live summary of an entity another one links to (T2.3.12): title, status and the parent needed
/// to open it. [missing] once the row is deleted (or not synced to this device yet).
@immutable
class LinkedEntity {
  const LinkedEntity({
    required this.entityType,
    required this.entityId,
    this.title = '',
    this.status,
    this.parentId,
    this.missing = false,
  });

  const LinkedEntity.missing(this.entityType, this.entityId)
    : title = '',
      status = null,
      parentId = null,
      missing = true;

  final String entityType;
  final String entityId;
  final String title;

  /// Status value (see `EntityStatusStyle`): item status, task lifecycle, `archived`/`active`.
  final String? status;
  final String? parentId;
  final bool missing;

  @override
  bool operator ==(Object other) =>
      other is LinkedEntity &&
      other.entityType == entityType &&
      other.entityId == entityId &&
      other.title == title &&
      other.status == status &&
      other.parentId == parentId &&
      other.missing == missing;

  @override
  int get hashCode => Object.hash(entityType, entityId, title, status, parentId, missing);

  @override
  String toString() => 'LinkedEntity($entityType $entityId "$title" $status${missing ? ' missing' : ''})';
}

/// Reads linked-entity summaries straight from Drift (tasks, checklists, items, habits, habit-log
/// notes) so any feature can show a link without importing another feature.
class LinkedEntityStore {
  LinkedEntityStore(this._db);

  final AppDatabase _db;

  static const supportedTypes = {'task', 'checklist', 'checklist_item', 'habit', 'habit_log'};

  Stream<LinkedEntity> watch(String entityType, String entityId) {
    LinkedEntity missing() => LinkedEntity.missing(entityType, entityId);
    switch (entityType) {
      case 'task':
        return (_db.select(
          _db.tasks,
        )..where((t) => t.id.equals(entityId) & t.deletedAt.isNull())).watchSingleOrNull().map(
          (r) => r == null
              ? missing()
              : LinkedEntity(entityType: entityType, entityId: entityId, title: r.title, status: r.status),
        );
      case 'checklist':
        return (_db.select(
          _db.checklists,
        )..where((c) => c.id.equals(entityId) & c.deletedAt.isNull())).watchSingleOrNull().map(
          (r) => r == null
              ? missing()
              : LinkedEntity(
                  entityType: entityType,
                  entityId: entityId,
                  title: r.title,
                  status: r.archivedAt == null ? 'active' : 'archived',
                ),
        );
      case 'checklist_item':
        return (_db.select(
          _db.checklistItems,
        )..where((i) => i.id.equals(entityId) & i.deletedAt.isNull())).watchSingleOrNull().map(
          (r) => r == null
              ? missing()
              : LinkedEntity(
                  entityType: entityType,
                  entityId: entityId,
                  title: r.itemText,
                  status: r.status,
                  parentId: r.checklistId,
                ),
        );
      case 'habit':
        return (_db.select(
          _db.habits,
        )..where((h) => h.id.equals(entityId) & h.deletedAt.isNull())).watchSingleOrNull().map(
          (r) => r == null
              ? missing()
              : LinkedEntity(
                  entityType: entityType,
                  entityId: entityId,
                  title: r.name,
                  status: r.archivedAt == null ? 'active' : 'archived',
                ),
        );
      case 'habit_log':
        return (_db.select(
          _db.habitLogs,
        )..where((h) => h.id.equals(entityId) & h.deletedAt.isNull())).watchSingleOrNull().map(
          (r) => r == null
              ? missing()
              : LinkedEntity(entityType: entityType, entityId: entityId, title: r.note ?? '', parentId: r.habitId),
        );
      default:
        return Stream.value(missing());
    }
  }
}
