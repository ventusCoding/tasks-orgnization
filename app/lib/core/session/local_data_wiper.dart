import 'dart:io';

import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/logging/log.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Removes every trace of the user's data from this device (T1.5.07 sign-out, T1.5.08 account
/// switch, T1.5.12 account deletion, debug "reset local data").
///
/// Device-level keys ([deviceKeys]: install id, hybrid-logical-clock state) survive so the HLC
/// stays monotonic and the device keeps its identity.
abstract final class LocalDataWiper {
  static const deviceKeys = {'everslot_device_id', 'hlc_state'};

  /// Directories (relative to the app documents / support / cache dirs) holding user files.
  static const userDirectories = ['attachments', 'exports', 'imports', 'thumbnails'];

  static final _log = AppLog.get('wipe');

  /// Extra cleanup hooks registered by features (cancel scheduled notifications, clear widget
  /// data, …). Each hook must be idempotent; failures are logged and ignored.
  static final List<Future<void> Function()> hooks = [];

  /// Deletes every row of every table (synced tables, outbox, sync state, UI state, caches, FTS
  /// index) and every non-device `local_kv` entry, in one transaction.
  static Future<void> wipeDatabase(AppDatabase db) async {
    await db.transaction(() async {
      for (final table in db.allTables) {
        final name = table.actualTableName;
        if (name == 'local_kv') {
          await db.customStatement(
            'DELETE FROM local_kv WHERE key NOT IN (${List.filled(deviceKeys.length, '?').join(', ')})',
            deviceKeys.toList(),
          );
        } else {
          await db.customStatement('DELETE FROM $name');
        }
      }
      try {
        await db.customStatement('DELETE FROM search_index');
      } on Object {
        // FTS table absent (older schema) — nothing to clear.
      }
    });
    db.notifyUpdates({for (final t in db.allTables) TableUpdate.onTable(t)});
  }

  /// Deletes user files (attachments, exports, thumbnails) from the app directories.
  static Future<void> deleteUserFiles({List<Directory>? roots}) async {
    final dirs = roots ?? await _roots();
    for (final root in dirs) {
      for (final name in userDirectories) {
        final dir = Directory(p.join(root.path, name));
        try {
          if (dir.existsSync()) await dir.delete(recursive: true);
        } on Object catch (e) {
          _log.warning('could not delete ${dir.path}', e);
        }
      }
    }
  }

  /// Full wipe: hooks, database, files.
  static Future<void> wipeAll(AppDatabase db, {List<Directory>? fileRoots}) async {
    for (final hook in List.of(hooks)) {
      try {
        await hook();
      } on Object catch (e) {
        _log.warning('wipe hook failed', e);
      }
    }
    await wipeDatabase(db);
    await deleteUserFiles(roots: fileRoots);
  }

  static Future<List<Directory>> _roots() async {
    final result = <Directory>[];
    for (final get in [getApplicationDocumentsDirectory, getApplicationSupportDirectory, getTemporaryDirectory]) {
      try {
        result.add(await get());
      } on Object {
        // Unsupported platform (tests).
      }
    }
    return result;
  }
}
