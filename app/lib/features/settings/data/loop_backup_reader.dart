import 'package:sqlite3/sqlite3.dart';

/// Reads a Loop Habit Tracker `.db` backup (read-only) as plain rows (T8.3.14).
abstract final class LoopBackupReader {
  static ({List<Map<String, Object?>> habits, List<Map<String, Object?>> repetitions}) read(String path) {
    final db = sqlite3.open(path, mode: OpenMode.readOnly);
    try {
      List<Map<String, Object?>> rows(String sql) => [
        for (final r in db.select(sql)) {for (final c in r.keys) c: r[c]},
      ];
      final tables = {for (final r in db.select("SELECT name FROM sqlite_master WHERE type = 'table'")) r['name']};
      if (!tables.contains('Habits') || !tables.contains('Repetitions')) {
        throw const FormatException('loop_not_a_backup');
      }
      return (habits: rows('SELECT * FROM Habits'), repetitions: rows('SELECT * FROM Repetitions'));
    } on SqliteException {
      throw const FormatException('loop_not_a_backup');
    } finally {
      db.close();
    }
  }
}
