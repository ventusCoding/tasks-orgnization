import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';

/// The last selected bottom tab (T1.3.06), restored at the next launch. Device-local
/// (`local_kv`, never synced).
abstract final class LastTab {
  static const key = 'ui_last_tab';

  /// Root path of each tab branch, in bar order.
  static const paths = ['/today', '/plan', '/lists', '/habits', '/insights'];

  /// Read once by the bootstrap (before the router is built); 0 = Today.
  static int initial = 0;

  static String get initialLocation => paths[initial.clamp(0, paths.length - 1)];

  static Future<int> load(AppDatabase db) async {
    final row = await db
        .customSelect('SELECT value FROM local_kv WHERE key = ?', variables: [const Variable<String>(key)])
        .getSingleOrNull();
    final index = int.tryParse(row?.data['value'] as String? ?? '');
    return index == null || index < 0 || index >= paths.length ? 0 : index;
  }

  static Future<void> save(AppDatabase db, int index) => db.customStatement(
    'INSERT INTO local_kv(key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value',
    [key, '$index'],
  );
}
