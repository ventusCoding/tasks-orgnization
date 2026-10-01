import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/goals/domain/goal.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';

/// Goals (T5.4.01): read from Drift, written through [SyncWriter] (one operation per command).
/// Deleting a habit soft-deletes its goals in the same transaction (habits repository).
class GoalsRepository {
  GoalsRepository(this._db, this._writer, this._userId);

  final AppDatabase _db;
  final SyncWriter _writer;
  final String Function() _userId;

  static Goal map(GoalRow r) => Goal(
    id: r.id,
    scopeType: GoalScopeType.parse(r.scopeType),
    scopeId: r.scopeId,
    metric: GoalMetric.tryParse(r.metric) ?? GoalMetric.completions,
    target: r.target,
    period: GoalPeriod.parse(r.period),
    startDate: r.startDate == null ? null : LocalDate.tryParse(r.startDate!),
    endDate: r.endDate == null ? null : LocalDate.tryParse(r.endDate!),
    title: r.title,
    reward: r.reward,
    achievedAt: r.achievedAt?.toUtc(),
    createdAt: r.createdAt.toUtc(),
  );

  SimpleSelectStatement<$GoalsTable, GoalRow> _base() => _db.select(_db.goals)
    ..where((g) => g.deletedAt.isNull() & g.userId.equals(_userId()))
    ..orderBy([(g) => OrderingTerm.asc(g.createdAt), (g) => OrderingTerm.asc(g.id)]);

  /// Every live goal.
  Stream<List<Goal>> watchAll() =>
      _base().watch().map((rows) => rows.map(map).toList()).distinct(const ListEquality<Goal>().equals);

  /// Live goals of one scope (a habit's goals and rewards).
  Stream<List<Goal>> watchForScope(GoalScopeType type, String? scopeId) {
    final q = _base()..where((g) => g.scopeType.equals(type.name));
    if (scopeId == null) {
      q.where((g) => g.scopeId.isNull());
    } else {
      q.where((g) => g.scopeId.equals(scopeId));
    }
    return q.watch().map((rows) => rows.map(map).toList()).distinct(const ListEquality<Goal>().equals);
  }

  Future<List<Goal>> all() async => (await _base().get()).map(map).toList();

  Future<Goal?> byId(String id) async {
    final row = await (_db.select(_db.goals)..where((g) => g.id.equals(id) & g.deletedAt.isNull())).getSingleOrNull();
    return row == null ? null : map(row);
  }

  static Map<String, Object?> _columns(Goal g) => {
    'scope_type': g.scopeType.name,
    'scope_id': g.scopeId,
    'metric': g.metric.wire,
    'target': g.target,
    'period': g.period.wire,
    'start_date': g.startDate,
    'end_date': g.endDate,
    'title': _clean(g.title),
    'reward': _clean(g.reward),
  };

  static String? _clean(String? s) => s == null || s.trim().isEmpty ? null : s.trim();

  Future<OpRecord> create(Goal goal) => _writer.run((tx) async {
    await tx.insert('goals', goal.id, _columns(goal));
    if (goal.scopeType == GoalScopeType.habit && goal.scopeId != null) {
      await tx.logEvent(
        entityType: 'habit',
        entityId: goal.scopeId!,
        eventType: 'goal_created',
        payload: {'goalId': goal.id},
      );
    }
  });

  /// Saves an edited goal (achievement state is kept).
  Future<OpRecord> update(Goal goal) => _writer.run((tx) => tx.update('goals', goal.id, _columns(goal)));

  Future<OpRecord> delete(String id) => _writer.run((tx) => tx.softDelete('goals', id));

  /// Records the achievement once (`achieved_at` is never moved once set). [at] is the instant the
  /// goal was reached; an automatic detection passes it as `scheduledAt` so user edits win.
  Future<OpRecord?> markAchieved(String id, DateTime at, {bool automatic = true}) async {
    final existing = await byId(id);
    if (existing == null || existing.isAchieved) return null;
    return _writer.run(
      (tx) async {
        final row = await tx.readRaw('goals', id);
        if (row == null || row['achieved_at'] != null) return;
        await tx.update('goals', id, {'achieved_at': at.toUtc()});
        if (existing.scopeType == GoalScopeType.habit && existing.scopeId != null) {
          await tx.logEvent(
            entityType: 'habit',
            entityId: existing.scopeId!,
            eventType: 'goal_achieved',
            payload: {'goalId': id},
          );
        }
      },
      cause: automatic ? 'auto' : 'user',
      scheduledAt: automatic ? at.toUtc() : null,
    );
  }

  /// Undoes an achievement or a claimed reward.
  Future<OpRecord> clearAchieved(String id) => _writer.run((tx) => tx.update('goals', id, {'achieved_at': null}));
}
