import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/settings/domain/trash.dart';

/// Local side of the Trash (T8.3.06).
///
/// "Deleted together": a feature deletes a row and its dependents in ONE `SyncWriter` operation,
/// so they share the transaction instant as `deleted_at` (ISO text with microseconds). Restoring a
/// root brings back its related rows with that exact instant — never rows deleted earlier.
class TrashRepository {
  TrashRepository(this._db, this._writer);

  final AppDatabase _db;
  final SyncWriter _writer;

  /// `attachments.owner_type` → owner table.
  static const ownerTables = {
    'checklist': 'checklists',
    'checklist_item': 'checklist_items',
    'task': 'tasks',
    'task_occurrence': 'task_occurrences',
    'habit': 'habits',
    'habit_log': 'habit_logs',
    'goal': 'goals',
  };

  Future<List<Map<String, Object?>>> _select(String sql, [List<Object?> args = const []]) async {
    final rows = await _db.customSelect(sql, variables: [for (final a in args) _variable(a)]).get();
    return [for (final r in rows) r.data];
  }

  static Variable<Object> _variable(Object? v) => switch (v) {
    final String s => Variable<String>(s),
    final int i => Variable<int>(i),
    _ => throw ArgumentError.value(v, 'arg'),
  };

  static String _in(int n) => List.filled(n, '?').join(', ');

  /// [list], re-run whenever one of the trashable tables changes.
  Stream<List<TrashEntry>> watch({required DateTime Function() since}) async* {
    yield await list(since: since());
    final tables = TableUpdateQuery.onAllTables([
      _db.tasks,
      _db.checklists,
      _db.checklistItems,
      _db.habits,
      _db.attachments,
    ]);
    await for (final _ in _db.tableUpdates(tables)) {
      yield await list(since: since());
    }
  }

  /// Restorable deletions since [since], newest first.
  Future<List<TrashEntry>> list({required DateTime since}) async {
    final s = since.toUtc().toIso8601String();
    const recent = 'deleted_at IS NOT NULL AND julianday(deleted_at) >= julianday(?)';
    final roots = <(TrashKind, Map<String, Object?>)>[
      for (final r in await _select('SELECT id, title AS t, deleted_at FROM tasks WHERE $recent', [s]))
        (TrashKind.task, r),
      for (final r in await _select('SELECT id, title AS t, deleted_at FROM checklists WHERE $recent', [s]))
        (TrashKind.checklist, r),
      for (final r in await _select('SELECT id, name AS t, deleted_at FROM habits WHERE $recent', [s]))
        (TrashKind.habit, r),
      // Items whose checklist and parent are live (otherwise they come back with them).
      for (final r in await _select(
        'SELECT i.id, i.text AS t, i.deleted_at, i.checklist_id, i.parent_id, c.title AS list_title '
        'FROM checklist_items i JOIN checklists c ON c.id = i.checklist_id AND c.deleted_at IS NULL '
        'LEFT JOIN checklist_items p ON p.id = i.parent_id '
        'WHERE i.deleted_at IS NOT NULL AND julianday(i.deleted_at) >= julianday(?) '
        'AND (i.parent_id IS NULL OR p.deleted_at IS NULL)',
        [s],
      ))
        (TrashKind.checklistItem, r),
      for (final r in await _select(
        'SELECT id, file_name AS t, deleted_at, owner_type, owner_id FROM attachments WHERE $recent',
        [s],
      ))
        if (await _ownerLive(r['owner_type'] as String?, r['owner_id'] as String?)) (TrashKind.attachment, r),
    ];
    final entries = <TrashEntry>[];
    for (final (kind, r) in roots) {
      final id = r['id']! as String;
      final raw = r['deleted_at']! as String;
      final group = await _group(kind, id, raw);
      entries.add(
        TrashEntry(
          kind: kind,
          id: id,
          title: (r['t'] as String?) ?? '',
          deletedAt: DateTime.parse(raw).toUtc(),
          path: kind == TrashKind.checklistItem
              ? [(r['list_title'] as String?) ?? '', ...await _ancestorTexts(r['parent_id'] as String?)]
              : const [],
          withCount: group.values.fold<int>(0, (n, ids) => n + ids.length) - 1,
        ),
      );
    }
    return sortTrash(entries);
  }

  Future<bool> _ownerLive(String? ownerType, String? ownerId) async {
    final table = ownerTables[ownerType];
    if (table == null || ownerId == null) return true;
    final rows = await _select('SELECT deleted_at FROM $table WHERE id = ?', [ownerId]);
    return rows.isNotEmpty && rows.single['deleted_at'] == null;
  }

  Future<List<String>> _ancestorTexts(String? parentId) async {
    final texts = <String>[];
    var next = parentId;
    for (var guard = 0; next != null && guard < 64; guard++) {
      final rows = await _select('SELECT text, parent_id FROM checklist_items WHERE id = ?', [next]);
      if (rows.isEmpty) break;
      texts.add((rows.single['text'] as String?) ?? '');
      next = rows.single['parent_id'] as String?;
    }
    return texts.reversed.toList();
  }

  Future<Set<String>> _ids(String sql, List<Object?> args) async => {
    for (final r in await _select(sql, args)) r['id']! as String,
  };

  /// The root and every row deleted by the same operation that belongs to it (table → ids).
  Future<Map<String, Set<String>>> _group(TrashKind kind, String id, String deletedAtRaw) async {
    final t = deletedAtRaw;
    final group = <String, Set<String>>{
      kind.table: {id},
    };
    void add(String table, Iterable<String> ids) {
      if (ids.isNotEmpty) group.putIfAbsent(table, () => {}).addAll(ids);
    }

    switch (kind) {
      case TrashKind.checklist:
        add(
          'checklist_items',
          await _ids('SELECT id FROM checklist_items WHERE checklist_id = ? AND deleted_at = ?', [id, t]),
        );
        add(
          'checklist_runs',
          await _ids('SELECT id FROM checklist_runs WHERE checklist_id = ? AND deleted_at = ?', [id, t]),
        );
      case TrashKind.checklistItem:
        var frontier = {id};
        while (frontier.isNotEmpty) {
          final children = await _ids(
            'SELECT id FROM checklist_items WHERE parent_id IN (${_in(frontier.length)}) AND deleted_at = ?',
            [...frontier, t],
          );
          children.removeAll(group['checklist_items']!);
          add('checklist_items', children);
          frontier = children;
        }
      case TrashKind.task:
        for (final table in const ['task_occurrences', 'time_entries']) {
          add(table, await _ids('SELECT id FROM $table WHERE task_id = ? AND deleted_at = ?', [id, t]));
        }
      case TrashKind.habit:
        for (final table in const ['habit_logs', 'habit_pauses', 'habit_revisions']) {
          add(table, await _ids('SELECT id FROM $table WHERE habit_id = ? AND deleted_at = ?', [id, t]));
        }
        add(
          'goals',
          await _ids("SELECT id FROM goals WHERE scope_type = 'habit' AND scope_id = ? AND deleted_at = ?", [id, t]),
        );
      case TrashKind.attachment:
        break;
    }
    final owners = {for (final ids in group.values) ...ids}.toList();
    if (kind != TrashKind.attachment) {
      add(
        'attachments',
        await _ids('SELECT id FROM attachments WHERE owner_id IN (${_in(owners.length)}) AND deleted_at = ?', [
          ...owners,
          t,
        ]),
      );
    }
    add(
      'entity_tags',
      await _ids('SELECT id FROM entity_tags WHERE entity_id IN (${_in(owners.length)}) AND deleted_at = ?', [
        ...owners,
        t,
      ]),
    );
    for (final table in const ['notification_rules', 'notification_mutes']) {
      add(
        table,
        await _ids('SELECT id FROM $table WHERE target_id IN (${_in(owners.length)}) AND deleted_at = ?', [
          ...owners,
          t,
        ]),
      );
    }
    return group;
  }

  Future<String?> _deletedAtRaw(TrashKind kind, String id) async {
    final rows = await _select('SELECT deleted_at FROM ${kind.table} WHERE id = ?', [id]);
    return rows.isEmpty ? null : rows.single['deleted_at'] as String?;
  }

  /// Restores [entry] and everything deleted with it, as one synced operation. Returns the
  /// number of rows restored (0 when it is no longer in the trash).
  Future<int> restore(TrashEntry entry) async {
    final raw = await _deletedAtRaw(entry.kind, entry.id);
    if (raw == null) return 0;
    final group = await _group(entry.kind, entry.id, raw);
    var n = 0;
    await _writer.run((tx) async {
      for (final e in group.entries) {
        for (final id in e.value) {
          await tx.restore(e.key, id);
          n++;
        }
      }
      await tx.logEvent(
        entityType: entry.kind.entityType,
        entityId: entry.id,
        eventType: 'restored',
        payload: {'count': n},
      );
    }, cause: 'restore');
    return n;
  }

  /// Local unsynced changes of [entry]'s row (a deletion not yet pushed can't be purged remotely).
  Future<bool> hasPendingChanges(TrashEntry entry) async => (await _select(
    'SELECT 1 FROM sync_outbox WHERE table_name = ? AND row_id = ? LIMIT 1',
    [entry.kind.table, entry.id],
  )).isNotEmpty;

  /// Rows `app.purge_now` removes for [entry] (tombstoned descendants, like the server).
  Future<Map<String, Set<String>>> purgePlan(TrashEntry entry) async {
    final id = entry.id;
    final plan = <String, Set<String>>{
      entry.kind.table: {id},
    };
    void add(String table, Iterable<String> ids) {
      if (ids.isNotEmpty) plan.putIfAbsent(table, () => {}).addAll(ids);
    }

    const dead = 'deleted_at IS NOT NULL';
    switch (entry.kind) {
      case TrashKind.task:
        add(
          'attachments',
          await _ids("SELECT id FROM attachments WHERE owner_type = 'task' AND owner_id = ? AND $dead", [id]),
        );
        add('time_entries', await _ids('SELECT id FROM time_entries WHERE task_id = ? AND $dead', [id]));
        add('task_occurrences', await _ids('SELECT id FROM task_occurrences WHERE task_id = ? AND $dead', [id]));
      case TrashKind.checklist || TrashKind.checklistItem:
        final Set<String> items;
        if (entry.kind == TrashKind.checklist) {
          items = await _ids('SELECT id FROM checklist_items WHERE checklist_id = ? AND $dead', [id]);
          add('checklist_runs', await _ids('SELECT id FROM checklist_runs WHERE checklist_id = ? AND $dead', [id]));
        } else {
          items = {};
          var frontier = {id};
          while (frontier.isNotEmpty) {
            final children =
                await _ids('SELECT id FROM checklist_items WHERE parent_id IN (${_in(frontier.length)}) AND $dead', [
                    ...frontier,
                  ])
                  ..removeAll(items);
            items.addAll(children);
            frontier = children;
          }
        }
        add('checklist_items', items);
        final itemOwners = entry.kind == TrashKind.checklistItem ? {...items, id} : items;
        if (itemOwners.isNotEmpty) {
          add(
            'attachments',
            await _ids(
              "SELECT id FROM attachments WHERE owner_type = 'checklist_item' AND owner_id IN (${_in(itemOwners.length)}) AND $dead",
              [...itemOwners],
            ),
          );
        }
        if (entry.kind == TrashKind.checklist) {
          add(
            'attachments',
            await _ids("SELECT id FROM attachments WHERE owner_type = 'checklist' AND owner_id = ? AND $dead", [id]),
          );
        }
      case TrashKind.habit:
        add(
          'attachments',
          await _ids("SELECT id FROM attachments WHERE owner_type = 'habit' AND owner_id = ? AND $dead", [id]),
        );
        for (final table in const ['habit_logs', 'habit_pauses', 'habit_revisions']) {
          add(table, await _ids('SELECT id FROM $table WHERE habit_id = ? AND $dead', [id]));
        }
      case TrashKind.attachment:
        break;
    }
    return plan;
  }

  /// Hard-deletes [plan] locally (children first) with their outbox entries. Returns the purged
  /// attachment ids (their local files are removed by the caller).
  Future<List<String>> purgeLocal(Map<String, Set<String>> plan) async {
    final byName = {for (final t in _db.allTables) t.actualTableName: t};
    // One transaction; the local schema has no foreign keys, so the order doesn't matter.
    await _db.transaction(() async {
      for (final table in plan.keys) {
        final ids = plan[table]!.toList();
        if (ids.isEmpty) continue;
        final info = byName[table];
        await _db.customUpdate(
          'DELETE FROM $table WHERE id IN (${_in(ids.length)}) AND deleted_at IS NOT NULL',
          variables: [for (final id in ids) Variable<String>(id)],
          updates: {?info},
          updateKind: UpdateKind.delete,
        );
        await _db.customUpdate(
          'DELETE FROM sync_outbox WHERE table_name = ? AND row_id IN (${_in(ids.length)})',
          variables: [Variable<String>(table), for (final id in ids) Variable<String>(id)],
          updates: {_db.syncOutbox},
          updateKind: UpdateKind.delete,
        );
      }
    });
    return [...?plan['attachments']];
  }
}
