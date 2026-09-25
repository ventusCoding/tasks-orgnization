import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/ordering/fractional_index.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/planner/presentation/view_config/planner_view_config.dart';
import 'package:meta/meta.dart';

/// A persisted planner view (`saved_views`, section `planner`).
@immutable
class SavedView {
  const SavedView({
    required this.id,
    required this.name,
    required this.config,
    required this.isDefault,
    required this.sortKey,
  });

  final String id;
  final String name;
  final PlannerViewConfig config;
  final bool isDefault;
  final String sortKey;

  PlannerViewType get type => config.type;

  @override
  bool operator ==(Object other) =>
      other is SavedView &&
      other.id == id &&
      other.name == name &&
      other.config == config &&
      other.isDefault == isDefault &&
      other.sortKey == sortKey;

  @override
  int get hashCode => Object.hash(id, name, config, isDefault, sortKey);
}

/// Saved views of the planner (T3.3.01 / T3.6.02): read from Drift, written through [SyncWriter] so
/// presets sync across devices.
class SavedViewsRepository {
  SavedViewsRepository(this._db, this._writer, this._userId);

  static const section = 'planner';

  final AppDatabase _db;
  final SyncWriter _writer;
  final String Function() _userId;

  /// Deterministic id of the built-in view of a registry entry (converges across devices).
  static String entryViewId(String userId, String entryId) => Ids.v5('$userId|saved_view|planner|$entryId');

  static SavedView _map(SavedViewRow r) {
    Map<String, Object?> json;
    try {
      final decoded = jsonDecode(r.config);
      json = decoded is Map ? Map<String, Object?>.from(decoded) : <String, Object?>{};
    } on FormatException {
      json = <String, Object?>{};
    }
    return SavedView(
      id: r.id,
      name: r.name,
      config: PlannerViewConfig.fromJson(json, fallbackType: PlannerViewType.tryParse(r.viewType)),
      isDefault: r.isDefault,
      sortKey: r.sortKey,
    );
  }

  SimpleSelectStatement<$SavedViewsTable, SavedViewRow> _query() => _db.select(_db.savedViews)
    ..where((v) => v.deletedAt.isNull() & v.userId.equals(_userId()) & v.section.equals(section))
    ..orderBy([(v) => OrderingTerm.asc(v.sortKey), (v) => OrderingTerm.asc(v.id)]);

  Stream<List<SavedView>> watchAll() => _query().watch().map((rows) => rows.map(_map).toList());

  Future<List<SavedView>> all() async => (await _query().get()).map(_map).toList();

  Future<SavedView?> byId(String id) async {
    final row = await (_db.select(_db.savedViews)..where((v) => v.id.equals(id) & v.deletedAt.isNull())).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  Future<String?> _lastSortKey() async {
    final rows = await all();
    return rows.isEmpty ? null : rows.last.sortKey;
  }

  /// First run: one built-in view per MVP type (week table = default). Idempotent.
  Future<void> ensureDefaults(Map<String, (PlannerViewConfig, String)> entries, {String defaultEntry = 'week_table'}) async {
    final userId = _userId();
    await _writer.run((tx) async {
      var previous = await _lastSortKey();
      for (final e in entries.entries) {
        final id = entryViewId(userId, e.key);
        if (await tx.exists('saved_views', id)) continue;
        previous = FractionalIndex.between(previous, null);
        await tx.insert('saved_views', id, {
          'section': section,
          'name': e.value.$2,
          'view_type': e.value.$1.type.id,
          'config': e.value.$1.toJson(),
          'is_default': e.key == defaultEntry,
          'sort_key': previous,
        });
      }
    }, cause: 'auto');
  }

  /// Creates or updates the built-in view of a registry entry.
  Future<OpRecord> saveEntry(String entryId, String name, PlannerViewConfig config) async {
    final id = entryViewId(_userId(), entryId);
    final last = await _lastSortKey();
    return _writer.run((tx) async {
      if (await tx.exists('saved_views', id)) {
        await tx.update('saved_views', id, {'config': config.toJson(), 'view_type': config.type.id});
      } else {
        await tx.insert('saved_views', id, {
          'section': section,
          'name': name,
          'view_type': config.type.id,
          'config': config.toJson(),
          'is_default': false,
          'sort_key': FractionalIndex.between(last, null),
        });
      }
    });
  }

  Future<OpRecord> saveConfig(String id, PlannerViewConfig config) =>
      _writer.run((tx) => tx.update('saved_views', id, {'config': config.toJson(), 'view_type': config.type.id}));

  /// "Save view as…" — returns the new id.
  Future<String> create(String name, PlannerViewConfig config) async {
    final id = Ids.v7();
    final last = await _lastSortKey();
    await _writer.run((tx) => tx.insert('saved_views', id, {
      'section': section,
      'name': name.trim(),
      'view_type': config.type.id,
      'config': config.toJson(),
      'is_default': false,
      'sort_key': FractionalIndex.between(last, null),
    }));
    return id;
  }

  Future<OpRecord> rename(String id, String name) =>
      _writer.run((tx) => tx.update('saved_views', id, {'name': name.trim()}));

  Future<String?> duplicate(String id, String name) async {
    final source = await byId(id);
    if (source == null) return null;
    return create(name, source.config);
  }

  Future<OpRecord> delete(String id) => _writer.run((tx) => tx.softDelete('saved_views', id));

  /// Marks [id] as the planner default (clears the flag elsewhere in the same operation).
  Future<OpRecord> setDefault(String id) async {
    final views = await all();
    return _writer.run((tx) async {
      for (final v in views) {
        if (v.isDefault && v.id != id) await tx.update('saved_views', v.id, {'is_default': false});
      }
      await tx.update('saved_views', id, {'is_default': true});
    });
  }

  /// Moves [id] between two neighbours (fractional order).
  Future<OpRecord> move(String id, {String? afterKey, String? beforeKey}) => _writer.run(
    (tx) => tx.update('saved_views', id, {'sort_key': FractionalIndex.between(afterKey, beforeKey)}),
  );
}
