import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/errors/app_exception.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/ordering/fractional_index.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/design_system/tokens.dart';
import 'package:everslot/features/organization/domain/category.dart';

/// Reference repository pattern (read Drift streams, write through [SyncWriter]).
class CategoriesRepository {
  CategoriesRepository(this._db, this._writer, this._userId);

  final AppDatabase _db;
  final SyncWriter _writer;
  final String Function() _userId;

  static Category _map(CategoryRow r) => Category(
    id: r.id,
    name: r.name,
    color: r.color,
    icon: r.icon,
    sortKey: r.sortKey,
    archived: r.archivedAt != null,
    countsAsUnavailable: r.countsAsUnavailable,
  );

  Stream<List<Category>> watchAll({bool includeArchived = false}) {
    final q = _db.select(_db.categories)
      ..where((c) => c.deletedAt.isNull() & c.userId.equals(_userId()))
      ..orderBy([
        (c) => OrderingTerm.asc(c.sortKey),
        (c) => OrderingTerm.asc(c.id),
      ]);
    if (!includeArchived) q.where((c) => c.archivedAt.isNull());
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  Future<List<Category>> all() async =>
      (await (_db.select(_db.categories)
                ..where(
                  (c) => c.deletedAt.isNull() & c.userId.equals(_userId()),
                )
                ..orderBy([
                  (c) => OrderingTerm.asc(c.sortKey),
                  (c) => OrderingTerm.asc(c.id),
                ]))
              .get())
          .map(_map)
          .toList();

  static const _usageSql = '''
SELECT category_id AS id, COUNT(*) AS c FROM (
  SELECT category_id FROM tasks WHERE category_id IS NOT NULL AND deleted_at IS NULL AND user_id = ?1
  UNION ALL
  SELECT category_id FROM habits WHERE category_id IS NOT NULL AND deleted_at IS NULL AND user_id = ?1
  UNION ALL
  SELECT category_id FROM checklists WHERE category_id IS NOT NULL AND deleted_at IS NULL AND user_id = ?1
) GROUP BY category_id''';

  /// Number of live tasks, habits and checklists per category id.
  Stream<Map<String, int>> watchUsageCounts() => _db
      .customSelect(
        _usageSql,
        variables: [Variable<String>(_userId())],
        readsFrom: {_db.tasks, _db.habits, _db.checklists},
      )
      .watch()
      .map(
        (rows) => {
          for (final r in rows) r.read<String>('id'): r.read<int>('c'),
        },
      );

  /// Number of live entities using [id].
  Future<int> usageCount(String id) async =>
      (await watchUsageCounts().first)[id] ?? 0;

  /// Creates a category at the end of the list. Throws [ValidationException] with
  /// [CategoryNames.errorInvalid] / [CategoryNames.errorDuplicate].
  Future<OpRecord> create({
    required String name,
    required int color,
    String? icon,
  }) async => (await add(name: name, color: color, icon: icon)).record;

  /// [create] that also returns the new id (inline create in pickers).
  Future<({String id, OpRecord record})> add({
    required String name,
    required int color,
    String? icon,
  }) async {
    final normalized = _validName(name);
    final existing = await all();
    _ensureUnique(existing, normalized);
    final last = existing.isEmpty ? null : existing.last.sortKey;
    final id = Ids.v7();
    final record = await _writer.run(
      (tx) => tx.insert('categories', id, {
        'name': normalized,
        'color': color,
        'icon': icon,
        'sort_key': FractionalIndex.between(last, null),
      }),
    );
    return (id: id, record: record);
  }

  /// Renames, recolors, changes the icon or the capacity flag in one operation.
  Future<OpRecord> update(
    String id, {
    String? name,
    int? color,
    String? icon,
    bool? countsAsUnavailable,
  }) async {
    String? normalized;
    if (name != null) {
      normalized = _validName(name);
      _ensureUnique(await all(), normalized, exceptId: id);
    }
    return _writer.run(
      (tx) => tx.update('categories', id, {
        'name': ?normalized,
        'color': ?color,
        'icon': ?icon,
        'counts_as_unavailable': ?countsAsUnavailable,
      }),
    );
  }

  Future<OpRecord> setArchived(String id, {required bool archived}) =>
      _writer.run(
        (tx) => tx.update('categories', id, {
          'archived_at': archived ? tx.now : null,
        }),
      );

  /// Moves [id] between two neighbours (fractional order).
  Future<OpRecord> move(String id, {String? afterKey, String? beforeKey}) =>
      _writer.run(
        (tx) => tx.update('categories', id, {
          'sort_key': FractionalIndex.between(afterKey, beforeKey),
        }),
      );

  /// Deletes a category, reassigning ([reassignTo]) or clearing it on the referencing tasks,
  /// habits and checklists — one operation (one undo), with an `updated` activity event per
  /// affected entity, so no `category_id` is ever left dangling.
  Future<OpRecord> delete(String id, {String? reassignTo}) {
    if (reassignTo == id) {
      throw const ValidationException(
        'Cannot reassign to the deleted category',
        field: 'reassignTo',
      );
    }
    return _writer.run((tx) async {
      var affected = 0;
      for (final e in CategorizedTables.entityTypeByTable.entries) {
        final refs = await _db
            .customSelect(
              'SELECT id FROM ${e.key} WHERE category_id = ? AND deleted_at IS NULL',
              variables: [Variable<String>(id)],
            )
            .get();
        for (final r in refs) {
          final entityId = r.data['id'] as String;
          await tx.update(e.key, entityId, {'category_id': reassignTo});
          await tx.logEvent(
            entityType: e.value,
            entityId: entityId,
            eventType: 'updated',
            payload: {
              'fields': const ['category_id'],
              'from': id,
              'to': reassignTo,
            },
          );
          affected++;
        }
      }
      await tx.softDelete('categories', id);
      await tx.logEvent(
        entityType: 'category',
        entityId: id,
        eventType: 'deleted',
        payload: {'items': affected, 'reassignedTo': ?reassignTo},
      );
    });
  }

  /// Seeds localized default categories once per account (T2.3.02). Deterministic ids make two
  /// offline devices converge on the same 6 rows.
  Future<void> seedDefaults(Map<String, String> localizedNames) async {
    const defaults = [
      ('work', 'work', 0),
      ('personal', 'star', 4),
      ('health', 'health', 2),
      ('study', 'study', 9),
      ('home', 'home', 3),
      ('social', 'friends', 6),
    ];
    final userId = _userId();
    await _writer.run((tx) async {
      var previous = await _lastSortKey();
      for (final (key, icon, colorIndex) in defaults) {
        final id = Ids.defaultCategory(userId, key);
        if (await tx.exists('categories', id)) continue;
        previous = FractionalIndex.between(previous, null);
        await tx.insert('categories', id, {
          'name': localizedNames[key] ?? key,
          'color': CategoryPalette.at(colorIndex),
          'icon': icon,
          'sort_key': previous,
        });
      }
    }, cause: 'auto');
  }

  Future<String?> _lastSortKey() async {
    final rows = await all();
    return rows.isEmpty ? null : rows.last.sortKey;
  }

  static String _validName(String name) {
    final normalized = CategoryNames.normalize(name);
    if (!CategoryNames.isValid(normalized)) {
      throw const ValidationException(
        CategoryNames.errorInvalid,
        field: 'name',
      );
    }
    return normalized;
  }

  static void _ensureUnique(
    List<Category> existing,
    String normalized, {
    String? exceptId,
  }) {
    final key = normalized.toLowerCase();
    if (existing.any(
      (c) => c.id != exceptId && CategoryNames.key(c.name) == key,
    )) {
      throw const ValidationException(
        CategoryNames.errorDuplicate,
        field: 'name',
      );
    }
  }
}
