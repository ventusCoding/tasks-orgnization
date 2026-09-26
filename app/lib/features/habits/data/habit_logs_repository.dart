import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/habits/data/habit_mappers.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';

const _logEquality = ListEquality<HabitLogEntry>();

/// `habit_logs` access (T5.1.02 queries, T5.2.01 writes). Reads are reactive Drift streams that
/// only emit when the mapped result actually changed (so unrelated check-ins don't recompute
/// every habit).
class HabitLogsRepository {
  HabitLogsRepository(this._db, this._writer, this._userId);

  final AppDatabase _db;
  final SyncWriter _writer;
  final String Function() _userId;

  SimpleSelectStatement<$HabitLogsTable, HabitLogRow> _base() =>
      _db.select(_db.habitLogs)..where((l) => l.deletedAt.isNull() & l.userId.equals(_userId()));

  /// Every live log of one habit (history), ordered by `logged_at`.
  Stream<List<HabitLogEntry>> watchForHabit(String habitId) => (_base()
        ..where((l) => l.habitId.equals(habitId))
        ..orderBy([(l) => OrderingTerm.asc(l.loggedAt), (l) => OrderingTerm.asc(l.id)]))
      .watch()
      .map((rows) => rows.map(HabitMappers.log).toList())
      .distinct(_logEquality.equals);

  Future<List<HabitLogEntry>> forHabit(String habitId) async => (await (_base()
            ..where((l) => l.habitId.equals(habitId))
            ..orderBy([(l) => OrderingTerm.asc(l.loggedAt)]))
          .get())
      .map(HabitMappers.log)
      .toList();

  /// Logs of every habit whose `local_date` lies in [from]…[to] (Today, matrix, month overview).
  Stream<List<HabitLogEntry>> watchInRange(LocalDate from, LocalDate to, {Set<String>? habitIds}) {
    final q = _base()
      ..where((l) => l.localDate.isBetweenValues(from.toIso(), to.toIso()))
      ..orderBy([(l) => OrderingTerm.asc(l.loggedAt)]);
    if (habitIds != null) q.where((l) => l.habitId.isIn(habitIds));
    return q.watch().map((rows) => rows.map(HabitMappers.log).toList()).distinct(_logEquality.equals);
  }

  /// Logs with a note or a mood (notes journal, T5.2.15), newest first.
  Stream<List<HabitLogEntry>> watchJournal({int limit = 500}) => (_base()
        ..where((l) => l.note.isNotNull() | l.mood.isNotNull())
        ..orderBy([(l) => OrderingTerm.desc(l.loggedAt)])
        ..limit(limit))
      .watch()
      .map((rows) => rows.map(HabitMappers.log).toList())
      .distinct(_logEquality.equals);

  Future<HabitLogEntry?> byId(String id) async {
    final r = await (_db.select(_db.habitLogs)..where((l) => l.id.equals(id))).getSingleOrNull();
    return r == null ? null : HabitMappers.log(r);
  }

  /// Latest log of each habit (Today "last done" hints, stale detection).
  Future<Map<String, HabitLogEntry>> latestLogPerHabit() async {
    final rows = await (_base()..orderBy([(l) => OrderingTerm.asc(l.loggedAt)])).get();
    return {for (final r in rows) r.habitId: HabitMappers.log(r)};
  }

  /// Latest log of [habitId] among [kinds] (quit: last relapse / restart).
  Future<HabitLogEntry?> lastEventOfKind(String habitId, Set<HabitLogKind> kinds) async {
    final r = await (_base()
          ..where((l) => l.habitId.equals(habitId) & l.kind.isIn([for (final k in kinds) k.name]))
          ..orderBy([(l) => OrderingTerm.desc(l.loggedAt)])
          ..limit(1))
        .getSingleOrNull();
    return r == null ? null : HabitMappers.log(r);
  }

  /// Usage count per vocabulary value (trigger / place / coping) — pickers show most-used first.
  Future<Map<String, int>> vocabUsage(String column) async {
    assert(const {'trigger', 'place', 'coping'}.contains(column), 'unknown vocab column');
    final rows = await _db
        .customSelect(
          'SELECT "$column" AS v, COUNT(*) AS n FROM habit_logs '
          'WHERE deleted_at IS NULL AND user_id = ? AND "$column" IS NOT NULL GROUP BY "$column"',
          variables: [Variable<String>(_userId())],
          readsFrom: {_db.habitLogs},
        )
        .get();
    return {for (final r in rows) r.data['v']! as String: r.data['n']! as int};
  }

  /// Runs one operation group (check-ins composed by the application services).
  Future<OpRecord> write(Future<void> Function(WriteTx tx) body, {String cause = 'user', DateTime? scheduledAt}) =>
      _writer.run(body, cause: cause, scheduledAt: scheduledAt);

  // ------------------------------------------------------------------ writes inside a transaction

  /// Deterministic id of the state row of a period (arch §9.2 `v5(habit|key|state)`).
  static String stateId(String habitId, String key) => Ids.habitDayState(habitId, key);

  /// Upserts the single state row of a period (done / fail / skip / excuse / clean / freeze):
  /// switching state updates `kind` on the same row; a soft-deleted row is revived.
  static Future<String> upsertStateInTx(
    WriteTx tx, {
    required String habitId,
    required String key,
    required HabitLogKind kind,
    required DateTime loggedAt,
    required LocalDate localDate,
    required String source,
    String? note,
    int? mood,
    bool keepNote = true,
  }) async {
    final id = stateId(habitId, key);
    final existing = await tx.readRaw('habit_logs', id);
    final values = <String, Object?>{
      'habit_id': habitId,
      'occurrence_key': key,
      'kind': kind.name,
      'logged_at': loggedAt.toUtc(),
      'local_date': localDate,
      'source': source,
      'deleted_at': null,
      if (note != null || !keepNote) 'note': note,
      'mood': ?mood,
    };
    if (existing == null) {
      await tx.insert('habit_logs', id, values);
    } else {
      await tx.update('habit_logs', id, values);
    }
    return id;
  }

  /// Soft-deletes the state row of a period ("clear"). Returns false when there was none.
  static Future<bool> clearStateInTx(WriteTx tx, String habitId, String key) async {
    final id = stateId(habitId, key);
    final existing = await tx.readRaw('habit_logs', id);
    if (existing == null || existing['deleted_at'] != null) return false;
    await tx.softDelete('habit_logs', id);
    return true;
  }

  /// Inserts a new log (progress entries, relapses, cravings… — UUIDv7 ids by default).
  static Future<String> insertInTx(WriteTx tx, HabitLogEntry entry) async {
    await tx.insert('habit_logs', entry.id, HabitMappers.logColumns(entry));
    return entry.id;
  }

  /// Upserts a deterministic-id log (pledge, period note).
  static Future<void> upsertInTx(WriteTx tx, HabitLogEntry entry) async {
    final values = {...HabitMappers.logColumns(entry), 'deleted_at': null};
    if (await tx.exists('habit_logs', entry.id)) {
      await tx.update('habit_logs', entry.id, values);
    } else {
      await tx.insert('habit_logs', entry.id, values);
    }
  }

  static Future<bool> updateInTx(WriteTx tx, String id, Map<String, Object?> changes) =>
      tx.update('habit_logs', id, changes);

  static Future<void> deleteInTx(WriteTx tx, String id) => tx.softDelete('habit_logs', id);
}

/// `habit_pauses` access (T5.1.14): one habit or — with a null habit id — every habit (vacation).
class HabitPausesRepository {
  HabitPausesRepository(this._db, this._writer, this._userId);

  final AppDatabase _db;
  final SyncWriter _writer;
  final String Function() _userId;

  /// Every live pause of the user (small table), ordered by start date.
  Stream<List<PauseSpan>> watchAll() => (_db.select(_db.habitPauses)
        ..where((p) => p.deletedAt.isNull() & p.userId.equals(_userId()))
        ..orderBy([(p) => OrderingTerm.asc(p.startDate)]))
      .watch()
      .map((rows) => rows.map(HabitMappers.pause).toList())
      .distinct(const ListEquality<PauseSpan>().equals);

  Future<OpRecord> create({required LocalDate start, LocalDate? end, String? habitId, String? reason}) =>
      _writer.run((tx) async {
        final id = Ids.v7();
        await tx.insert('habit_pauses', id, {
          'habit_id': habitId,
          'start_date': start,
          'end_date': end,
          'reason': reason == null || reason.trim().isEmpty ? null : reason.trim(),
        });
        if (habitId != null) {
          await tx.logEvent(entityType: 'habit', entityId: habitId, eventType: 'paused', payload: {'pauseId': id});
        }
      });

  /// Ends [pause] on [lastDay] (Resume = the pause ends yesterday); a pause that had not started
  /// yet is deleted.
  Future<OpRecord> end(PauseSpan pause, LocalDate lastDay) => _writer.run((tx) async {
    if (lastDay.isBefore(pause.start)) {
      await tx.softDelete('habit_pauses', pause.id);
    } else {
      await tx.update('habit_pauses', pause.id, {'end_date': lastDay});
    }
    if (pause.habitId != null) {
      await tx.logEvent(entityType: 'habit', entityId: pause.habitId!, eventType: 'resumed', payload: {'pauseId': pause.id});
    }
  });

  Future<OpRecord> delete(String id) => _writer.run((tx) => tx.softDelete('habit_pauses', id));
}
