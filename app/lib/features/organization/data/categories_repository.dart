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
      ..orderBy([(c) => OrderingTerm.asc(c.sortKey), (c) => OrderingTerm.asc(c.id)]);
    if (!includeArchived) q.where((c) => c.archivedAt.isNull());
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  Future<List<Category>> all() async => (await (_db.select(_db.categories)
            ..where((c) => c.deletedAt.isNull() & c.userId.equals(_userId()))
            ..orderBy([(c) => OrderingTerm.asc(c.sortKey)]))
          .get())
      .map(_map)
      .toList();

  Future<OpRecord> create({required String name, required int color, String? icon}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 60) {
      throw const ValidationException('Category name must be 1–60 characters', field: 'name');
    }
    final existing = await all();
    if (existing.any((c) => c.name.toLowerCase() == trimmed.toLowerCase())) {
      throw const ValidationException('A category with this name exists', field: 'name');
    }
    final last = existing.isEmpty ? null : existing.last.sortKey;
    return _writer.run((tx) => tx.insert('categories', Ids.v7(), {
      'name': trimmed,
      'color': color,
      'icon': icon,
      'sort_key': FractionalIndex.between(last, null),
    }));
  }

  Future<OpRecord> update(
    String id, {
    String? name,
    int? color,
    String? icon,
    bool? countsAsUnavailable,
  }) => _writer.run((tx) => tx.update('categories', id, {
    if (name != null) 'name': name.trim(),
    if (color != null) 'color': color,
    if (icon != null) 'icon': icon,
    if (countsAsUnavailable != null) 'counts_as_unavailable': countsAsUnavailable,
  }));

  Future<OpRecord> setArchived(String id, {required bool archived}) => _writer.run(
    (tx) => tx.update('categories', id, {'archived_at': archived ? tx.now : null}),
  );

  /// Moves [id] between two neighbours (fractional order).
  Future<OpRecord> move(String id, {String? afterKey, String? beforeKey}) => _writer.run(
    (tx) => tx.update('categories', id, {'sort_key': FractionalIndex.between(afterKey, beforeKey)}),
  );

  /// Deletes a category, reassigning ([reassignTo]) or clearing it on referencing items.
  Future<OpRecord> delete(String id, {String? reassignTo}) => _writer.run((tx) async {
    for (final table in const ['tasks', 'habits', 'checklists']) {
      final refs = await _db
          .customSelect(
            'SELECT id FROM $table WHERE category_id = ? AND deleted_at IS NULL',
            variables: [Variable<String>(id)],
          )
          .get();
      for (final r in refs) {
        await tx.update(table, r.data['id'] as String, {'category_id': reassignTo});
      }
    }
    await tx.softDelete('categories', id);
    await tx.logEvent(entityType: 'category', entityId: id, eventType: 'deleted');
  });

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
}
