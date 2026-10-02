import 'package:everslot/features/settings/domain/export_format.dart';
import 'package:meta/meta.dart';

/// How an export is brought back (T8.3.08).
enum ImportMode {
  /// Same account: rows keep their ids; per row the newer side wins (`updated_at`).
  restore,

  /// Any account: every row gets a new id, references are rewritten and deterministic ids are
  /// re-derived for the new owner, so nothing collides with existing data.
  copy,
}

/// A parsed `everslot-export-v1` document.
@immutable
class ExportDocument {
  const ExportDocument({
    required this.schemaVersion,
    required this.exportedAt,
    required this.appVersion,
    required this.tables,
  });

  final int schemaVersion;
  final DateTime? exportedAt;
  final String appVersion;

  /// Rows per table, server JSON representation.
  final Map<String, List<Map<String, Object?>>> tables;

  /// The account the export was made from (the profile row id is the user id).
  String? get userId {
    final profiles = tables['profiles'];
    return profiles == null || profiles.isEmpty ? null : profiles.first['id'] as String?;
  }

  int get rowCount => tables.values.fold(0, (a, rows) => a + rows.length);

  /// Throws [FormatException] for anything that is not an Everslot JSON export.
  static ExportDocument parse(Object? json) {
    if (json is! Map) throw const FormatException('not_an_export');
    if (json['format'] != ExportFormat.id) {
      throw FormatException(json.containsKey('format') ? 'unsupported_format' : 'not_an_export');
    }
    final rawTables = json['tables'];
    if (rawTables is! Map) throw const FormatException('not_an_export');
    final tables = <String, List<Map<String, Object?>>>{};
    for (final e in rawTables.entries) {
      final rows = e.value;
      if (e.key is! String || rows is! List) throw const FormatException('not_an_export');
      tables[e.key as String] = [
        for (final r in rows)
          if (r is Map && r['id'] is String) Map<String, Object?>.from(r),
      ];
    }
    return ExportDocument(
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 0,
      exportedAt: DateTime.tryParse('${json['exported_at']}')?.toUtc(),
      appVersion: '${json['app_version'] ?? ''}',
      tables: tables,
    );
  }
}

/// Builds the v5 names a deterministic id of [row] may have been derived from. [ref] maps an id
/// the row refers to (identity when checking the old id, the new id when re-deriving) and [user]
/// is the owner's id.
typedef IdNames = List<String> Function(Map<String, Object?> row, String Function(String id) ref, String user);

/// Deterministic-id recipes per table (arch §9.2), the same formulas as `Ids` / feature helpers.
typedef IdRecipes = Map<String, IdNames>;

/// New ids for a copy import (T8.3.08): random ids for ordinary rows, re-derived UUIDv5 ids for
/// deterministic rows (occurrences, day states, settings, tag links, defaults…), and every
/// reference to an exported id — `*_id` columns, ids inside JSON columns and composite keys such
/// as `dedupe_key` or `storage_path` — rewritten.
class IdRemapper {
  IdRemapper({
    required this.document,
    required this.oldUser,
    required this.newUser,
    required this.recipes,
    required this.v5,
    required this.v7,
  }) {
    for (final e in document.tables.entries) {
      for (final (i, r) in e.value.indexed) {
        _where[r['id']! as String] = (table: e.key, index: i);
      }
    }
  }

  final ExportDocument document;
  final String oldUser;
  final String newUser;
  final IdRecipes recipes;
  final String Function(String name) v5;
  final String Function() v7;

  final _where = <String, ({String table, int index})>{};
  final _map = <String, String>{};
  final _inProgress = <String>{};

  /// UUIDs inside text values (references, `dedupe_key`, `storage_path`, …).
  static final uuid = RegExp('[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}');

  /// Whether [id] was derived by a recipe (vs a random id) — after [idOf] ran for it.
  final derived = <String>{};

  /// v5 rows of tables whose formula needs data the export lacks (they are skipped: the target
  /// account generates its own).
  final unmatched = <String>{};

  /// The new id of exported row (or user) [old]; unknown ids are returned unchanged.
  String idOf(String old) {
    if (old == oldUser) return newUser;
    final known = _map[old];
    if (known != null) return known;
    final at = _where[old];
    if (at == null) return old;
    if (!_inProgress.add(old)) return _map[old] = v7(); // reference cycle: fall back to a new id
    final row = document.tables[at.table]![at.index];
    var id = v7();
    final names = recipes[at.table];
    if (names != null) {
      final candidates = names(row, (x) => x, oldUser);
      final i = candidates.indexWhere((n) => v5(n) == old);
      if (i >= 0) {
        id = v5(names(row, idOf, newUser)[i]);
        derived.add(old);
      } else if (_isV5(old) && _skipUnmatched.contains(at.table)) {
        unmatched.add(old);
      }
    }
    _inProgress.remove(old);
    return _map[old] = id;
  }

  /// Built-in rows whose entry key is not stored in the row.
  static const _skipUnmatched = {'saved_views'};

  static bool _isV5(String id) => id.length == 36 && id[14] == '5';

  /// [value] with every exported id replaced (strings, JSON objects / arrays).
  Object? remapValue(Object? value) => switch (value) {
    final String s when s == oldUser || _where.containsKey(s) => idOf(s),
    final String s => s.contains('-') ? s.replaceAllMapped(uuid, (m) => idOf(m[0]!)) : s,
    final Map<Object?, Object?> m => {for (final e in m.entries) e.key: remapValue(e.value)},
    final List<Object?> l => [for (final v in l) remapValue(v)],
    _ => value,
  };

  /// [row] of the copy (new id, remapped references).
  Map<String, Object?> remapRow(Map<String, Object?> row) => {
    for (final e in row.entries) e.key: e.key == 'id' ? idOf(e.value! as String) : remapValue(e.value),
  };
}

/// What an import would do to one table (dry run).
@immutable
class ImportTableCounts {
  const ImportTableCounts({this.added = 0, this.updated = 0, this.unchanged = 0, this.keptLocal = 0, this.skipped = 0});

  /// New rows.
  final int added;

  /// Existing rows the export changes (older locally, or "replace newer" on).
  final int updated;

  /// Rows already identical.
  final int unchanged;

  /// Conflicts: rows changed locally after the export, kept as they are.
  final int keptLocal;

  /// Rows not imported (unknown table, rows the target account recreates itself).
  final int skipped;

  int get total => added + updated + unchanged + keptLocal + skipped;

  ImportTableCounts operator +(ImportTableCounts o) => ImportTableCounts(
    added: added + o.added,
    updated: updated + o.updated,
    unchanged: unchanged + o.unchanged,
    keptLocal: keptLocal + o.keptLocal,
    skipped: skipped + o.skipped,
  );

  @override
  bool operator ==(Object other) =>
      other is ImportTableCounts &&
      other.added == added &&
      other.updated == updated &&
      other.unchanged == unchanged &&
      other.keptLocal == keptLocal &&
      other.skipped == skipped;

  @override
  int get hashCode => Object.hash(added, updated, unchanged, keptLocal, skipped);

  @override
  String toString() => 'ImportTableCounts(+$added ~$updated =$unchanged !$keptLocal -$skipped)';
}

/// What will happen to one exported row.
enum RowAction { insert, update, unchanged, keepLocal, skip }

abstract final class ImportRules {
  /// Columns the writer manages itself (never copied from the export).
  static const managedColumns = {'updated_at', 'origin_device_id'};

  /// Decides the fate of an exported row given the local row (server representation, null when
  /// absent). Restore follows last-writer-wins on `updated_at` unless [replaceNewer].
  static RowAction decide(Map<String, Object?> exported, Map<String, Object?>? local, {required bool replaceNewer}) {
    if (local == null) return RowAction.insert;
    if (sameContent(exported, local)) return RowAction.unchanged;
    if (replaceNewer) return RowAction.update;
    final mine = DateTime.tryParse('${local['updated_at']}');
    final theirs = DateTime.tryParse('${exported['updated_at']}');
    if (mine != null && theirs != null && mine.isAfter(theirs)) return RowAction.keepLocal;
    return RowAction.update;
  }

  /// Same values for every exported column (writer-managed columns ignored).
  static bool sameContent(Map<String, Object?> exported, Map<String, Object?> local) {
    for (final e in exported.entries) {
      if (managedColumns.contains(e.key)) continue;
      if (!_deepEquals(_norm(e.value), _norm(local[e.key]))) return false;
    }
    return true;
  }

  // Instants compare as instants ("…Z" vs "+00:00"), numbers numerically.
  static Object? _norm(Object? v) {
    if (v is String && v.length >= 20 && v[10] == 'T') {
      final t = DateTime.tryParse(v);
      if (t != null && (v.endsWith('Z') || v.contains('+'))) return t.toUtc().microsecondsSinceEpoch;
    }
    if (v is num) return v.toDouble();
    return v;
  }

  static bool _deepEquals(Object? a, Object? b) {
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final k in a.keys) {
        if (!b.containsKey(k) || !_deepEquals(_norm(a[k]), _norm(b[k]))) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_deepEquals(_norm(a[i]), _norm(b[i]))) return false;
      }
      return true;
    }
    return a == b;
  }
}
