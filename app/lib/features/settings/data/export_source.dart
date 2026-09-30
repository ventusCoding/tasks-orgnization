import 'dart:io';

import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/sync/table_registry.dart';
import 'package:everslot/features/settings/domain/export_format.dart';

/// Reads the local database for an export (T8.3.07): live rows of every synced table, in the
/// server JSON representation, page by page (bounded memory, progress per page).
class ExportSource {
  ExportSource(this._db, this._registry);

  final AppDatabase _db;
  final TableRegistry _registry;

  static const pageSize = 2000;

  /// Synced tables in dependency-friendly order (the registry order).
  List<String> get tables => [for (final t in _registry.tables) t.name];

  /// Exported columns of [table] (sync internals removed).
  List<String> columns(String table) => [
    for (final c in _registry[table].columns)
      if (!ExportFormat.internalColumns.contains(c)) c,
  ];

  /// Live rows per table.
  Future<Map<String, int>> counts() async => {
    for (final t in tables)
      t:
          (await _db
                      .customSelect(
                        'SELECT COUNT(*) AS n FROM $t WHERE deleted_at IS NULL',
                      )
                      .getSingle())
                  .data['n']
              as int,
  };

  Future<List<Map<String, Object?>>> page(String table, int offset) async {
    final t = _registry[table];
    final cols = columns(table);
    final rows = await _db
        .customSelect(
          'SELECT ${cols.join(', ')} FROM $table WHERE deleted_at IS NULL ORDER BY id LIMIT ? OFFSET ?',
          variables: [Variable<int>(pageSize), Variable<int>(offset)],
        )
        .get();
    return [
      for (final r in rows)
        {for (final c in cols) c: t.sqliteToServer(c, r.data[c])},
    ];
  }

  /// Local files of live attachments: (id, file name, absolute path) under [root]
  /// (`<root>/<attachment id>/<file>`; thumbnails skipped).
  Future<List<({String id, String name, String path})>> attachmentFiles(
    Directory root,
  ) async {
    if (!root.existsSync()) return const [];
    final ids = {
      for (final r
          in await _db
              .customSelect(
                'SELECT id FROM attachments WHERE deleted_at IS NULL',
              )
              .get())
        r.data['id']! as String,
    };
    final files = <({String id, String name, String path})>[];
    for (final dir in root.listSync().whereType<Directory>()) {
      final id = dir.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (!ids.contains(id)) continue;
      for (final f in dir.listSync().whereType<File>()) {
        final name = f.uri.pathSegments.last;
        if (name == 'thumb.jpg' || name.endsWith('.tmp')) continue;
        files.add((id: id, name: name, path: f.path));
      }
    }
    return files;
  }
}
