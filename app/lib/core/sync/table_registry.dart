import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';

/// How a column is represented on the server vs in SQLite.
enum ColumnKind { text, integer, real, boolean, instant, json, wallClock, date, time }

/// Static sync metadata that can't be derived from Drift column types.
class SyncedTableSpec {
  const SyncedTableSpec(
    this.name, {
    this.jsonColumns = const {},
    this.wallClockColumns = const {},
    this.timeColumns = const {},
  });

  final String name;
  final Set<String> jsonColumns;
  final Set<String> wallClockColumns;
  final Set<String> timeColumns;
}

/// Every synced table (T1.4.06). Adding a synced table = migration + Drift table + entry here.
const syncedTableSpecs = <SyncedTableSpec>[
  SyncedTableSpec('profiles'),
  SyncedTableSpec('user_settings', jsonColumns: {'value'}),
  SyncedTableSpec('categories'),
  SyncedTableSpec('tags'),
  SyncedTableSpec('entity_tags'),
  SyncedTableSpec('saved_views', jsonColumns: {'config'}),
  SyncedTableSpec('activity_events', jsonColumns: {'payload'}),
  SyncedTableSpec('attachments'),
  SyncedTableSpec('goals'),
  SyncedTableSpec('achievements', jsonColumns: {'payload'}),
  SyncedTableSpec('dashboards', jsonColumns: {'layout'}),
  SyncedTableSpec(
    'tasks',
    jsonColumns: {'recurrence'},
    wallClockColumns: {'start_local', 'recurrence_until_local', 'deadline_local'},
  ),
  SyncedTableSpec('task_occurrences', wallClockColumns: {'override_start_local'}),
  SyncedTableSpec('time_entries'),
  SyncedTableSpec(
    'checklists',
    jsonColumns: {'reset_rule', 'settings'},
    wallClockColumns: {'due_local'},
  ),
  SyncedTableSpec('checklist_items', wallClockColumns: {'due_local'}),
  SyncedTableSpec('checklist_runs', jsonColumns: {'snapshot'}),
  SyncedTableSpec('habit_sections', timeColumns: {'start_time', 'end_time'}),
  SyncedTableSpec('habits', jsonColumns: {'schedule', 'settings'}),
  SyncedTableSpec('habit_vocab'),
  SyncedTableSpec('habit_logs'),
  SyncedTableSpec('habit_pauses'),
  SyncedTableSpec('habit_revisions', jsonColumns: {'schedule'}),
  SyncedTableSpec('notification_profiles', jsonColumns: {'spec'}),
  SyncedTableSpec('notification_rules', jsonColumns: {'spec'}),
  SyncedTableSpec('notifications', jsonColumns: {'payload', 'delivered_via'}),
  SyncedTableSpec('notification_mutes'),
];

/// Columns the client never sends (server-owned).
const serverOwnedColumns = {'user_id', 'rev', 'field_clock', 'server_updated_at'};

/// Registry resolving table metadata and converting values between SQLite and server JSON.
class TableRegistry {
  TableRegistry(this.db) {
    final byName = {for (final t in db.allTables) t.actualTableName: t};
    for (final spec in syncedTableSpecs) {
      final info = byName[spec.name];
      if (info == null) {
        throw StateError('Synced table ${spec.name} missing from AppDatabase');
      }
      final kinds = <String, ColumnKind>{};
      for (final column in info.$columns) {
        kinds[column.name] = _kindOf(spec, column);
      }
      _tables[spec.name] = RegisteredTable(spec, info, kinds);
    }
  }

  final AppDatabase db;
  final Map<String, RegisteredTable> _tables = {};

  Iterable<RegisteredTable> get tables => _tables.values;

  bool isSynced(String table) => _tables.containsKey(table);

  RegisteredTable operator [](String table) {
    final t = _tables[table];
    if (t == null) throw ArgumentError('Unknown synced table: $table');
    return t;
  }

  static ColumnKind _kindOf(SyncedTableSpec spec, GeneratedColumn<Object> column) {
    final name = column.name;
    if (name == 'field_clock' || spec.jsonColumns.contains(name)) return ColumnKind.json;
    if (spec.wallClockColumns.contains(name)) return ColumnKind.wallClock;
    if (spec.timeColumns.contains(name)) return ColumnKind.time;
    return switch (column.type) {
      DriftSqlType.bool => ColumnKind.boolean,
      DriftSqlType.int || DriftSqlType.bigInt => ColumnKind.integer,
      DriftSqlType.double => ColumnKind.real,
      DriftSqlType.dateTime => ColumnKind.instant,
      _ => name.endsWith('_date') || name == 'effective_from' ? ColumnKind.date : ColumnKind.text,
    };
  }
}

class RegisteredTable {
  RegisteredTable(this.spec, this.info, this.kinds);

  final SyncedTableSpec spec;
  final TableInfo<Table, Object?> info;
  final Map<String, ColumnKind> kinds;

  String get name => spec.name;
  Iterable<String> get columns => kinds.keys;

  /// Converts a Dart value supplied by repositories into the SQLite storage value.
  Object? toSqlite(String column, Object? value) {
    if (value == null) return null;
    final kind = kinds[column];
    if (kind == null) throw ArgumentError('Unknown column $name.$column');
    return switch (kind) {
      ColumnKind.boolean => value is bool ? (value ? 1 : 0) : value,
      ColumnKind.instant => value is DateTime ? value.toUtc().toIso8601String() : value.toString(),
      ColumnKind.json => value is String ? value : jsonEncode(value),
      ColumnKind.real => value is num ? value.toDouble() : value,
      ColumnKind.integer => value is num ? value.toInt() : value,
      ColumnKind.wallClock || ColumnKind.date || ColumnKind.time || ColumnKind.text =>
        value is String ? value : value.toString(),
    };
  }

  /// SQLite value → server JSON value (for pushes).
  Object? sqliteToServer(String column, Object? value) {
    if (value == null) return null;
    return switch (kinds[column]) {
      ColumnKind.boolean => value == 1 || value == true,
      ColumnKind.json => value is String ? _tryDecode(value) : value,
      _ => value,
    };
  }

  /// Server JSON value → SQLite value (for pulls).
  Object? serverToSqlite(String column, Object? value) {
    if (value == null) return null;
    return switch (kinds[column]) {
      ColumnKind.boolean => value == true || value == 1 ? 1 : 0,
      ColumnKind.instant => DateTime.parse(value as String).toUtc().toIso8601String(),
      ColumnKind.json => value is String ? value : jsonEncode(value),
      ColumnKind.wallClock => _trim(value as String, 16),
      ColumnKind.time => _trim(value as String, 5),
      ColumnKind.date => _trim(value as String, 10),
      ColumnKind.integer => (value as num).toInt(),
      ColumnKind.real => (value as num).toDouble(),
      ColumnKind.text || null => value is String ? value : value.toString(),
    };
  }

  static Object? _tryDecode(String value) {
    try {
      return jsonDecode(value);
    } on FormatException {
      return value;
    }
  }

  static String _trim(String value, int length) {
    final v = value.replaceFirst(' ', 'T');
    return v.length > length ? v.substring(0, length) : v;
  }
}
