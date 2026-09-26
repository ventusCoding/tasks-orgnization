import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/errors/app_exception.dart';
import 'package:everslot/core/ordering/fractional_index.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/habits/data/habit_mappers.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';

/// Extra writes run inside a habit operation's transaction (reminder drafts, cascades of other
/// features) so the whole command stays one operation group (one undo, one atomic push).
typedef TxHook = Future<void> Function(WriteTx tx);

/// How a schedule / goal / economics change applies to history (T5.1.13).
enum RevisionScope {
  /// From a date (default: today) — earlier periods keep their rules.
  fromDate,

  /// Replace the whole history by one revision (past stats change).
  allHistory,
}

/// Habits repository (T5.1.04): reads Drift, writes through [SyncWriter]. Schedule, goal and quit
/// economics changes append (upsert) a `habit_revisions` snapshot so past periods keep the rules
/// they had; cosmetic edits never create revisions.
class HabitsRepository {
  HabitsRepository(this._db, this._writer, this._userId);

  final AppDatabase _db;
  final SyncWriter _writer;
  final String Function() _userId;

  SimpleSelectStatement<$HabitsTable, HabitRow> _query({bool includeArchived = false, HabitKind? kind}) {
    final q = _db.select(_db.habits)
      ..where((h) => h.deletedAt.isNull() & h.userId.equals(_userId()))
      ..orderBy([(h) => OrderingTerm.asc(h.sortKey), (h) => OrderingTerm.asc(h.id)]);
    if (!includeArchived) q.where((h) => h.archivedAt.isNull());
    if (kind != null) q.where((h) => h.kind.equals(kind.name));
    return q;
  }

  /// Live habits (ordered by `sort_key`), optionally including archived ones or one kind only.
  Stream<List<Habit>> watchAll({bool includeArchived = false, HabitKind? kind}) =>
      _query(includeArchived: includeArchived, kind: kind).watch().map((rows) => rows.map(HabitMappers.habit).toList());

  Future<List<Habit>> all({bool includeArchived = true, HabitKind? kind}) async =>
      (await _query(includeArchived: includeArchived, kind: kind).get()).map(HabitMappers.habit).toList();

  Stream<Habit?> watchHabit(String id) =>
      (_db.select(_db.habits)..where((h) => h.id.equals(id) & h.deletedAt.isNull() & h.userId.equals(_userId())))
          .watchSingleOrNull()
          .map((r) => r == null ? null : HabitMappers.habit(r));

  Future<Habit?> byId(String id) async {
    final r = await (_db.select(_db.habits)..where((h) => h.id.equals(id) & h.deletedAt.isNull())).getSingleOrNull();
    return r == null ? null : HabitMappers.habit(r);
  }

  /// Revisions of one habit (chronological).
  Stream<List<HabitRevision>> watchRevisions(String habitId) => (_db.select(_db.habitRevisions)
        ..where((r) => r.habitId.equals(habitId) & r.deletedAt.isNull())
        ..orderBy([(r) => OrderingTerm.asc(r.effectiveFrom)]))
      .watch()
      .map((rows) => rows.map(HabitMappers.revision).toList());

  /// Every live revision of the user (multi-habit evaluation).
  Stream<List<HabitRevision>> watchAllRevisions() => (_db.select(_db.habitRevisions)
        ..where((r) => r.deletedAt.isNull() & r.userId.equals(_userId()))
        ..orderBy([(r) => OrderingTerm.asc(r.habitId), (r) => OrderingTerm.asc(r.effectiveFrom)]))
      .watch()
      .map((rows) => rows.map(HabitMappers.revision).toList());

  Future<List<HabitRevision>> revisionsFor(String habitId) async => (await (_db.select(_db.habitRevisions)
            ..where((r) => r.habitId.equals(habitId) & r.deletedAt.isNull())
            ..orderBy([(r) => OrderingTerm.asc(r.effectiveFrom)]))
          .get())
      .map(HabitMappers.revision)
      .toList();

  Future<String?> lastSortKey() async {
    final row = await (_db.select(_db.habits)
          ..where((h) => h.deletedAt.isNull() & h.userId.equals(_userId()))
          ..orderBy([(h) => OrderingTerm.desc(h.sortKey)])
          ..limit(1))
        .getSingleOrNull();
    return row?.sortKey;
  }

  /// Creates [habit] (validated) and its initial revision (`effective_from = start_date`).
  /// [habit.sortKey] empty → appended at the end.
  Future<OpRecord> create(Habit habit, {TxHook? inTx}) async {
    habit.validate();
    final sortKey = habit.sortKey.isEmpty ? FractionalIndex.between(await lastSortKey(), null) : habit.sortKey;
    return _writer.run((tx) async {
      await tx.insert('habits', habit.id, {...HabitMappers.habitColumns(habit), 'sort_key': sortKey});
      await _upsertRevision(tx, habit, habit.startDate);
      await tx.logEvent(entityType: 'habit', entityId: habit.id, eventType: 'created', payload: {'kind': habit.kind.name});
      if (inTx != null) await inTx(tx);
    });
  }

  /// Whether [before] → [after] changes schedule, goal or quit economics (→ a revision).
  static bool rulesChanged(Habit before, Habit after) => switch ((before, after)) {
    (final BuildHabit a, final BuildHabit b) => a.schedule != b.schedule || a.goal != b.goal,
    (final QuitHabit a, final QuitHabit b) =>
      a.baselinePerDay != b.baselinePerDay || a.unitCost != b.unitCost || a.dailyLimit != b.dailyLimit || a.unit != b.unit,
    _ => true,
  };

  /// Saves an edited habit. When schedule, goal or economics changed, the revision in force from
  /// [applyFrom] (default [today]) is upserted and later revisions are superseded; with
  /// [RevisionScope.allHistory] every revision is replaced by one at the start date.
  Future<OpRecord> update(
    Habit habit, {
    required LocalDate today,
    LocalDate? applyFrom,
    RevisionScope scope = RevisionScope.fromDate,
    TxHook? inTx,
  }) async {
    habit.validate();
    final before = await byId(habit.id);
    if (before == null) throw NotFoundException('habits/${habit.id} not found');
    return _writer.run((tx) async {
      await tx.update('habits', habit.id, HabitMappers.habitColumns(habit));
      final revisions = await revisionsFor(habit.id);
      // Keep the history anchored at the start date (the start date may have moved).
      await _alignInitialRevision(tx, before, habit, revisions);
      if (rulesChanged(before, habit)) {
        if (scope == RevisionScope.allHistory) {
          for (final r in await revisionsFor(habit.id)) {
            if (r.effectiveFrom != habit.startDate) await tx.softDelete('habit_revisions', r.id);
          }
          await _upsertRevision(tx, habit, habit.startDate);
        } else {
          var from = applyFrom ?? today;
          if (from.isBefore(habit.startDate)) from = habit.startDate;
          for (final r in await revisionsFor(habit.id)) {
            if (r.effectiveFrom.isAfter(from)) await tx.softDelete('habit_revisions', r.id);
          }
          await _upsertRevision(tx, habit, from);
        }
        await tx.logEvent(
          entityType: 'habit',
          entityId: habit.id,
          eventType: 'updated',
          payload: {
            'fields': ['rules'],
            'scope': scope.name,
            'from': (scope == RevisionScope.allHistory ? habit.startDate : (applyFrom ?? today)).toIso(),
          },
        );
      }
      if (inTx != null) await inTx(tx);
    });
  }

  Future<void> _alignInitialRevision(WriteTx tx, Habit before, Habit after, List<HabitRevision> revisions) async {
    if (before.startDate == after.startDate || revisions.isEmpty) return;
    final initial = revisions.first;
    if (!initial.effectiveFrom.isAfter(after.startDate) && initial.effectiveFrom == before.startDate) {
      // The start moved later: revisions before it no longer matter but stay harmless.
      return;
    }
    if (initial.effectiveFrom == before.startDate && after.startDate.isBefore(initial.effectiveFrom)) {
      final raw = await tx.readRaw('habit_revisions', initial.id);
      if (raw == null) return;
      await tx.softDelete('habit_revisions', initial.id);
      final id = HabitIds.revision(after.id, after.startDate);
      final values = {
        for (final c in const [
          'schedule',
          'goal_type',
          'target_value',
          'target_op',
          'unit',
          'baseline_per_day',
          'unit_cost',
          'daily_limit',
        ])
          c: raw[c],
        'habit_id': after.id,
        'effective_from': after.startDate,
        'deleted_at': null,
      };
      if (await tx.exists('habit_revisions', id)) {
        await tx.update('habit_revisions', id, values);
      } else {
        await tx.insert('habit_revisions', id, values);
      }
    }
  }

  Future<void> _upsertRevision(WriteTx tx, Habit habit, LocalDate from) async {
    final id = HabitIds.revision(habit.id, from);
    final values = {
      'habit_id': habit.id,
      'effective_from': from,
      ...HabitMappers.revisionColumns(habit),
    };
    if (await tx.exists('habit_revisions', id)) {
      await tx.update('habit_revisions', id, {...values, 'deleted_at': null});
    } else {
      await tx.insert('habit_revisions', id, values);
    }
  }

  /// Soft-deletes the habit with its logs, pauses, revisions and goals in one operation (Trash).
  Future<OpRecord> delete(String id, {TxHook? inTx}) => _writer.run((tx) async {
    for (final table in const ['habit_logs', 'habit_pauses', 'habit_revisions']) {
      final rows = await _db
          .customSelect(
            'SELECT id FROM $table WHERE habit_id = ? AND deleted_at IS NULL',
            variables: [Variable<String>(id)],
          )
          .get();
      for (final r in rows) {
        await tx.softDelete(table, r.data['id']! as String);
      }
    }
    final goals = await _db
        .customSelect(
          "SELECT id FROM goals WHERE scope_type = 'habit' AND scope_id = ? AND deleted_at IS NULL",
          variables: [Variable<String>(id)],
        )
        .get();
    for (final g in goals) {
      await tx.softDelete('goals', g.data['id']! as String);
    }
    await tx.softDelete('habits', id);
    await tx.logEvent(entityType: 'habit', entityId: id, eventType: 'deleted');
    if (inTx != null) await inTx(tx);
  }, cause: 'user');

  /// Restores a deleted habit and the children deleted with it (same `deleted_at`).
  Future<OpRecord> restore(String id) => _writer.run((tx) async {
    final raw = await tx.readRaw('habits', id);
    if (raw == null) throw NotFoundException('habits/$id not found');
    final deletedAt = raw['deleted_at'] as String?;
    await tx.restore('habits', id);
    if (deletedAt != null) {
      for (final table in const ['habit_logs', 'habit_pauses', 'habit_revisions']) {
        final rows = await _db
            .customSelect(
              'SELECT id FROM $table WHERE habit_id = ? AND deleted_at = ?',
              variables: [Variable<String>(id), Variable<String>(deletedAt)],
            )
            .get();
        for (final r in rows) {
          await tx.restore(table, r.data['id']! as String);
        }
      }
      final goals = await _db
          .customSelect(
            "SELECT id FROM goals WHERE scope_type = 'habit' AND scope_id = ? AND deleted_at = ?",
            variables: [Variable<String>(id), Variable<String>(deletedAt)],
          )
          .get();
      for (final g in goals) {
        await tx.restore('goals', g.data['id']! as String);
      }
    }
    await tx.logEvent(entityType: 'habit', entityId: id, eventType: 'restored');
  });

  Future<OpRecord> setArchived(String id, {required bool archived}) => _writer.run((tx) async {
    await tx.update('habits', id, {'archived_at': archived ? tx.now : null});
    await tx.logEvent(entityType: 'habit', entityId: id, eventType: archived ? 'archived' : 'unarchived');
  });

  /// Moves [id] between two neighbours (fractional order); with [changeSection] it also moves
  /// into [sectionId] (null = no section).
  Future<OpRecord> move(
    String id, {
    String? afterKey,
    String? beforeKey,
    bool changeSection = false,
    String? sectionId,
  }) => _writer.run((tx) async {
    await tx.update('habits', id, {
      'sort_key': FractionalIndex.between(afterKey, beforeKey),
      if (changeSection) 'section_id': sectionId,
    });
  });

  /// Partial column update (settings toggles, section, cosmetic fields) — never a revision.
  Future<OpRecord> patch(String id, Map<String, Object?> columns) =>
      _writer.run((tx) async => tx.update('habits', id, columns));

  /// Clears the end date (challenge "Keep going", T5.4.05) — history is kept.
  Future<OpRecord> clearEndDate(String id) => patch(id, {'end_date': null});

  /// Moves every habit of [sectionId] to [toSectionId] (section deletion).
  Future<void> reassignSectionInTx(WriteTx tx, String sectionId, String? toSectionId) async {
    final rows = await _db
        .customSelect(
          'SELECT id FROM habits WHERE section_id = ? AND deleted_at IS NULL',
          variables: [Variable<String>(sectionId)],
        )
        .get();
    for (final r in rows) {
      await tx.update('habits', r.data['id']! as String, {'section_id': toSectionId});
    }
  }

  /// Habit ids ordered like the UI (for reorder neighbours).
  Future<List<({String id, String sortKey})>> order() async => [
    for (final r in await _query(includeArchived: true).get()) (id: r.id, sortKey: r.sortKey),
  ];
}

/// Neighbour keys to insert an item at [index] of [keys] (drag & drop helper).
({String? after, String? before}) neighboursAt(List<String> keys, int index) {
  final i = index.clamp(0, keys.length);
  return (after: i == 0 ? null : keys[i - 1], before: i >= keys.length ? null : keys[i]);
}

/// Keeps the equality semantics used by distinct streams.
const habitListEquality = ListEquality<Habit>();
