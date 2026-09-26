import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/sync/table_registry.dart';
import 'package:flutter_test/flutter_test.dart';

/// Table registry completeness & schema-drift checks (T1.4.06).
///
/// The server schema is read from `supabase/migrations/*.sql` (the source of truth the CI
/// snapshot would be generated from), so a column added on one side only fails here.
void main() {
  late AppDatabase db;
  late TableRegistry registry;
  late Map<String, Map<String, String>> server;

  setUpAll(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    registry = TableRegistry(db);
    server = parseServerTables(Directory('../supabase/migrations'));
  });

  tearDownAll(() => db.close());

  test('every Drift table with synced columns is registered, and only those', () {
    final synced = {
      for (final t in db.allTables)
        if (t.$columns.any((c) => c.name == 'field_clock')) t.actualTableName,
    };
    expect({for (final s in syncedTableSpecs) s.name}, synced);
  });

  test('registered tables exist on the server with exactly the same columns', () {
    expect(server, isNotEmpty, reason: 'migrations not found (run tests from app/)');
    for (final t in registry.tables) {
      final serverColumns = server[t.name];
      expect(serverColumns, isNotNull, reason: 'app.${t.name} missing from migrations');
      expect(t.columns.toSet(), serverColumns!.keys.toSet(), reason: 'column drift in ${t.name}');
    }
  });

  test('column kinds match the server types (json, wall-clock, dates, times, instants, booleans)', () {
    final problems = <String>[];
    for (final t in registry.tables) {
      for (final e in server[t.name]!.entries) {
        final expected = switch (e.value) {
          'jsonb' || 'json' => ColumnKind.json,
          'timestamp' => ColumnKind.wallClock,
          'timestamptz' => ColumnKind.instant,
          'date' => ColumnKind.date,
          'time' => ColumnKind.time,
          'boolean' => ColumnKind.boolean,
          _ => null,
        };
        if (expected != null && t.kinds[e.key] != expected) {
          problems.add('${t.name}.${e.key}: server ${e.value}, client ${t.kinds[e.key]}');
        }
      }
    }
    expect(problems, isEmpty);
  });

  group('serializers round-trip', () {
    test('instants are UTC ISO text locally and parsed back from server strings', () {
      final t = registry['tasks'];
      final local = t.toSqlite('created_at', DateTime.utc(2026, 9, 22, 8, 30));
      expect(local, '2026-09-22T08:30:00.000Z');
      expect(t.serverToSqlite('created_at', '2026-09-22T10:30:00+02:00'), '2026-09-22T08:30:00.000Z');
    });

    test('wall-clock, date and time values are trimmed to their ISO shapes', () {
      expect(registry['tasks'].serverToSqlite('start_local', '2026-09-22 08:30:00'), '2026-09-22T08:30');
      expect(registry['habit_logs'].serverToSqlite('local_date', '2026-09-22'), '2026-09-22');
      expect(registry['habit_sections'].serverToSqlite('start_time', '07:15:00'), '07:15');
    });

    test('booleans and JSON columns convert both ways', () {
      final t = registry['tasks'];
      expect(t.toSqlite('is_all_day', true), 1);
      expect(t.sqliteToServer('is_all_day', 1), true);
      expect(t.serverToSqlite('is_all_day', false), 0);
      final rule = {'v': 1, 'freq': 'daily'};
      final stored = t.toSqlite('recurrence', rule);
      expect(stored, jsonEncode(rule));
      expect(t.sqliteToServer('recurrence', stored), rule);
      expect(t.serverToSqlite('recurrence', rule), jsonEncode(rule));
    });

    test('unknown columns are rejected on write', () {
      expect(() => registry['tasks'].toSqlite('nope', 1), throwsArgumentError);
      expect(() => registry['nope'], throwsArgumentError);
    });
  });
}

/// `{table: {column: base type}}` for every `create table if not exists app.<name> (…)` plus
/// `alter table app.<name> add column …` statements, in migration order.
Map<String, Map<String, String>> parseServerTables(Directory dir) {
  final result = <String, Map<String, String>>{};
  if (!dir.existsSync()) return result;
  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.sql')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  final create = RegExp(r'^create table if not exists app\.([a-z_]+) \($');
  final alter = RegExp(r'^alter table (?:only )?app\.([a-z_]+)\s+add column (?:if not exists )?([a-z_]+)\s+([a-z]+)');
  const notColumns = {'constraint', 'primary', 'unique', 'check', 'foreign', 'exclude', 'like'};
  for (final file in files) {
    String? table;
    var depth = 0;
    for (final raw in file.readAsLinesSync()) {
      final line = raw.trim();
      if (table == null) {
        final m = create.firstMatch(line);
        if (m != null) {
          table = m.group(1);
          result[table!] = {};
          depth = 1;
          continue;
        }
        final a = alter.firstMatch(line);
        if (a != null) result.putIfAbsent(a.group(1)!, () => {})[a.group(2)!] = a.group(3)!;
        continue;
      }
      if (depth == 1 && line.isNotEmpty && !line.startsWith('--') && !line.startsWith(')')) {
        final parts = line.split(RegExp(r'\s+'));
        final name = parts.first.replaceAll('"', '');
        if (parts.length >= 2 && !notColumns.contains(name)) {
          result[table]![name] = parts[1].replaceAll(',', '');
        }
      }
      depth += '('.allMatches(line).length - ')'.allMatches(line).length;
      if (depth <= 0) table = null;
    }
  }
  return result;
}
