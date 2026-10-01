import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/ordering/fractional_index.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/shared/views/domain/saved_view_config.dart';

/// A built-in view of a section: its config and localized name.
typedef BuiltInView<C> = ({C config, String name});

/// View presets of one section in `app.saved_views` (T2.3.08): read from Drift, written through
/// [SyncWriter] so they sync; configs go through the section's versioned [ViewConfigCodec].
/// Built-in views have deterministic ids per user, section and entry, so two devices seeding them
/// offline converge.
class SavedViewsStore<C> {
  SavedViewsStore(this._db, this._writer, this._userId, this.codec);

  final AppDatabase _db;
  final SyncWriter _writer;
  final String Function() _userId;
  final ViewConfigCodec<C> codec;

  static const _table = 'saved_views';

  String get section => codec.section;

  /// Deterministic id of the built-in view [entryId] of [section].
  static String builtInId(String userId, String section, String entryId) =>
      Ids.v5('$userId|saved_view|$section|$entryId');

  String _builtInId(String entryId) => builtInId(_userId(), section, entryId);

  StoredView<C> _map(SavedViewRow r) {
    Map<String, Object?> json;
    try {
      final decoded = jsonDecode(r.config);
      json = decoded is Map ? Map<String, Object?>.from(decoded) : <String, Object?>{};
    } on FormatException {
      json = <String, Object?>{};
    }
    return StoredView(
      id: r.id,
      section: r.section,
      name: r.name,
      viewType: r.viewType,
      config: codec.decode(json, viewType: r.viewType),
      isDefault: r.isDefault,
      sortKey: r.sortKey,
    );
  }

  SimpleSelectStatement<$SavedViewsTable, SavedViewRow> _query() => _db.select(_db.savedViews)
    ..where((v) => v.deletedAt.isNull() & v.userId.equals(_userId()) & v.section.equals(section))
    ..orderBy([(v) => OrderingTerm.asc(v.sortKey), (v) => OrderingTerm.asc(v.id)]);

  Stream<List<StoredView<C>>> watchAll() => _query().watch().map((rows) => rows.map(_map).toList());

  Future<List<StoredView<C>>> all() async => (await _query().get()).map(_map).toList();

  Future<StoredView<C>?> byId(String id) async {
    final row = await (_db.select(
      _db.savedViews,
    )..where((v) => v.id.equals(id) & v.deletedAt.isNull() & v.section.equals(section))).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  /// The section's default view (the flagged one, else the first).
  Future<StoredView<C>?> defaultView() async {
    final views = await all();
    if (views.isEmpty) return null;
    return views.firstWhere((v) => v.isDefault, orElse: () => views.first);
  }

  Future<String?> _lastSortKey() async {
    final rows = await _query().get();
    return rows.isEmpty ? null : rows.last.sortKey;
  }

  Map<String, Object?> _values(String name, C config, {required bool isDefault, required String sortKey}) => {
    'section': section,
    'name': name.trim(),
    'view_type': codec.viewTypeOf(config),
    'config': codec.encode(config),
    'is_default': isDefault,
    'sort_key': sortKey,
  };

  /// First run: one row per built-in entry ([defaultEntry] flagged). Idempotent; never touches
  /// existing rows (a user's edits and deletions of built-ins stay).
  Future<OpRecord> ensureDefaults(Map<String, BuiltInView<C>> entries, {String? defaultEntry}) =>
      _writer.run((tx) async {
        var previous = await _lastSortKey();
        for (final e in entries.entries) {
          final id = _builtInId(e.key);
          if (await tx.exists(_table, id)) continue;
          previous = FractionalIndex.between(previous, null);
          await tx.insert(
            _table,
            id,
            _values(e.value.name, e.value.config, isDefault: e.key == defaultEntry, sortKey: previous),
          );
        }
      }, cause: 'auto');

  /// "Reset to defaults": in one operation (undoable), deletes the user's own views and puts every
  /// built-in back to its default config, name, order and default flag (restoring deleted ones).
  Future<OpRecord> resetToDefaults(Map<String, BuiltInView<C>> entries, {String? defaultEntry}) async {
    final builtIns = {for (final key in entries.keys) _builtInId(key): key};
    final current = await all();
    return _writer.run((tx) async {
      for (final v in current) {
        if (!builtIns.containsKey(v.id)) await tx.softDelete(_table, v.id);
      }
      String? previous;
      for (final e in entries.entries) {
        final id = _builtInId(e.key);
        previous = FractionalIndex.between(previous, null);
        final values = _values(e.value.name, e.value.config, isDefault: e.key == defaultEntry, sortKey: previous);
        if (await tx.exists(_table, id)) {
          await tx.update(_table, id, {...values, 'deleted_at': null});
        } else {
          await tx.insert(_table, id, values);
        }
      }
    }, cause: 'reset');
  }

  /// Creates or updates the built-in view [entryId].
  Future<OpRecord> saveBuiltIn(String entryId, String name, C config) async {
    final id = _builtInId(entryId);
    final last = await _lastSortKey();
    return _writer.run((tx) async {
      if (await tx.exists(_table, id)) {
        await tx.update(_table, id, {'config': codec.encode(config), 'view_type': codec.viewTypeOf(config)});
      } else {
        await tx.insert(
          _table,
          id,
          _values(name, config, isDefault: false, sortKey: FractionalIndex.between(last, null)),
        );
      }
    });
  }

  Future<OpRecord> saveConfig(String id, C config) => _writer.run(
    (tx) => tx.update(_table, id, {'config': codec.encode(config), 'view_type': codec.viewTypeOf(config)}),
  );

  /// "Save view as…" — returns the new id.
  Future<String> create(String name, C config) async {
    final id = Ids.v7();
    final last = await _lastSortKey();
    await _writer.run(
      (tx) =>
          tx.insert(_table, id, _values(name, config, isDefault: false, sortKey: FractionalIndex.between(last, null))),
    );
    return id;
  }

  Future<OpRecord> rename(String id, String name) => _writer.run((tx) => tx.update(_table, id, {'name': name.trim()}));

  Future<String?> duplicate(String id, String name) async {
    final source = await byId(id);
    return source == null ? null : create(name, source.config);
  }

  Future<OpRecord> delete(String id) => _writer.run((tx) => tx.softDelete(_table, id));

  /// Marks [id] as the section default (clears the flag elsewhere in the same operation).
  Future<OpRecord> setDefault(String id) async {
    final views = await all();
    return _writer.run((tx) async {
      for (final v in views) {
        if (v.isDefault && v.id != id) await tx.update(_table, v.id, {'is_default': false});
      }
      await tx.update(_table, id, {'is_default': true});
    });
  }

  /// Moves [id] between two neighbours (fractional order).
  Future<OpRecord> move(String id, {String? afterKey, String? beforeKey}) =>
      _writer.run((tx) => tx.update(_table, id, {'sort_key': FractionalIndex.between(afterKey, beforeKey)}));
}
