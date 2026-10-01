import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/data/habits_repository.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_periods.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show PeriodStatus;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';
import '../support/habit_fixtures.dart';

void main() {
  late TestHarness h;
  late HabitsRepository repo;

  setUp(() {
    h = TestHarness.create(now: DateTime.utc(2026, 9, 23, 10));
    repo = h.read(habitsRepositoryProvider);
  });
  tearDown(() => h.dispose());

  HabitPeriodService service() => periodService();

  Future<int> count(String table, {String where = '1 = 1'}) async =>
      (await h.db.customSelect('SELECT COUNT(*) AS n FROM $table WHERE $where').getSingle()).data['n']! as int;

  test('create writes the habit and its initial revision; mapping round-trips', () async {
    final habit = buildHabit(
      id: Ids.v7(),
      goal: const HabitTarget(type: HabitGoalType.count, target: 15, unit: 'reps'),
      zone: 'Europe/Paris',
    ).copyWith(description: 'Before breakfast', icon: 'fitness', color: 0xFF3B82F6);
    await repo.create(habit);
    final stored = await repo.byId(habit.id);
    expect(stored, isA<BuildHabit>());
    expect((stored! as BuildHabit).copyWith(sortKey: habit.sortKey), habit);
    final revisions = await repo.revisionsFor(habit.id);
    expect(revisions.single.effectiveFrom, habit.startDate);
    expect(revisions.single.targetValue, 15);
    expect(revisions.single.schedule, RecurrenceRule());
    expect(await count('activity_events', where: "entity_type = 'habit'"), 1);
  });

  test('quit trackers keep exact money values and economics revisions', () async {
    final quit = QuitHabit(
      id: Ids.v7(),
      name: 'Stop smoking',
      startDate: d(2026, 9, 22),
      sortKey: '',
      mode: QuitMode.abstain,
      quitStartedAt: DateTime.utc(2026, 9, 22, 19),
      substance: QuitSubstance.cigarettes,
      baselinePerDay: 15,
      unitCost: Decimal.parse('0.5'),
      currency: 'EUR',
      lifeMinutesPerUnit: 20,
      unit: 'cigarettes',
    );
    await repo.create(quit);
    final stored = await repo.byId(quit.id) as QuitHabit?;
    expect(stored!.unitCost, Decimal.parse('0.5'));
    expect(stored.quitStartedAt, quit.quitStartedAt);
    expect(stored.substance, QuitSubstance.cigarettes);
    await repo.update(stored.copyWith(unitCost: Decimal.parse('0.6')), today: d(2026, 9, 23));
    final revisions = await repo.revisionsFor(quit.id);
    expect(revisions.map((r) => (r.effectiveFrom, r.unitCost)), [
      (d(2026, 9, 22), Decimal.parse('0.5')),
      (d(2026, 9, 23), Decimal.parse('0.6')),
    ]);
  });

  test('daily → weekdays today leaves yesterday unchanged; cosmetic edits add no revision', () async {
    final habit = buildHabit(id: Ids.v7(), start: d(2026, 9, 14));
    await repo.create(habit);
    await repo.update(
      habit.copyWith(name: 'Renamed', icon: 'star'),
      today: d(2026, 9, 23),
    );
    expect(await repo.revisionsFor(habit.id), hasLength(1));
    final weekdays = habit.copyWith(
      schedule: RecurrenceRule(
        freq: Frequency.weekly,
        byWeekday: [for (var i = 1; i <= 5; i++) WeekdayRule(Weekday.fromIso(i))],
      ),
    );
    await repo.update(weekdays, today: d(2026, 9, 23));
    final revisions = await repo.revisionsFor(habit.id);
    expect(revisions.map((r) => r.effectiveFrom), [d(2026, 9, 14), d(2026, 9, 23)]);
    final ps = service().periods(weekdays, revisions, d(2026, 9, 19), d(2026, 9, 27));
    expect(
      {for (final p in ps) p.key: p.due}['2026-09-19'],
      isTrue,
      reason: 'last Saturday was due under the old rule',
    );
    expect({for (final p in ps) p.key: p.due}['2026-09-26'], isFalse);
  });

  test('apply from a past date supersedes later revisions; all history leaves one (T5.1.13)', () async {
    final habit = buildHabit(
      id: Ids.v7(),
      start: d(2026, 9, 1),
      goal: const HabitTarget(type: HabitGoalType.count, target: 10, unit: 'reps'),
    );
    await repo.create(habit);
    await repo.update(
      habit.copyWith(
        goal: const HabitTarget(type: HabitGoalType.count, target: 12, unit: 'reps'),
      ),
      today: d(2026, 9, 20),
    );
    await repo.update(
      habit.copyWith(
        goal: const HabitTarget(type: HabitGoalType.count, target: 15, unit: 'reps'),
      ),
      today: d(2026, 9, 23),
      applyFrom: d(2026, 9, 10),
    );
    expect((await repo.revisionsFor(habit.id)).map((r) => (r.effectiveFrom, r.targetValue)), [
      (d(2026, 9, 1), 10),
      (d(2026, 9, 10), 15),
    ]);
    await repo.update(
      habit.copyWith(
        goal: const HabitTarget(type: HabitGoalType.count, target: 20, unit: 'reps'),
      ),
      today: d(2026, 9, 23),
      scope: RevisionScope.allHistory,
    );
    final revisions = await repo.revisionsFor(habit.id);
    expect(revisions.map((r) => (r.effectiveFrom, r.targetValue)), [(d(2026, 9, 1), 20)]);
  });

  test('moving the start date earlier keeps history anchored', () async {
    final habit = buildHabit(id: Ids.v7(), start: d(2026, 9, 10));
    await repo.create(habit);
    await repo.update(habit.copyWith(startDate: d(2026, 9, 5)), today: d(2026, 9, 23));
    expect((await repo.revisionsFor(habit.id)).map((r) => r.effectiveFrom), [d(2026, 9, 5)]);
  });

  test('delete cascades to logs, pauses and revisions in one operation; restore brings them back', () async {
    final habit = buildHabit(id: Ids.v7());
    await repo.create(habit);
    final writer = h.read(syncWriterProvider);
    await writer.run((tx) async {
      for (final day in ['2026-09-21', '2026-09-22']) {
        await tx.insert('habit_logs', Ids.v7(), {
          'habit_id': habit.id,
          'occurrence_key': day,
          'kind': 'done',
          'logged_at': DateTime.utc(2026, 9, 22),
          'local_date': day,
        });
      }
      await tx.insert('habit_pauses', Ids.v7(), {'habit_id': habit.id, 'start_date': '2026-10-01'});
    });
    final record = await repo.delete(habit.id);
    expect(record.changes.map((c) => c.table).toSet(), {
      'habit_logs',
      'habit_pauses',
      'habit_revisions',
      'habits',
      'activity_events',
    });
    expect(await repo.byId(habit.id), isNull);
    expect(await count('habit_logs', where: 'deleted_at IS NULL'), 0);
    final ops = await h.db
        .customSelect("SELECT DISTINCT op_id FROM sync_outbox WHERE table_name IN ('habits','habit_logs')")
        .get();
    expect(ops.length, greaterThanOrEqualTo(1));
    await repo.restore(habit.id);
    expect(await repo.byId(habit.id), isNotNull);
    expect(await count('habit_logs', where: 'deleted_at IS NULL'), 2);
    expect(await count('habit_pauses', where: 'deleted_at IS NULL'), 1);
    expect(await repo.revisionsFor(habit.id), hasLength(1));
  });

  test('undo restores the exact previous row', () async {
    final habit = buildHabit(
      id: Ids.v7(),
      goal: const HabitTarget(type: HabitGoalType.count, target: 10, unit: 'reps'),
    );
    await repo.create(habit);
    final before = await h.db
        .customSelect('SELECT name, target_value FROM habits WHERE id = ?', variables: [Variable(habit.id)])
        .getSingle();
    final record = await repo.update(
      habit.copyWith(
        name: 'Other',
        goal: const HabitTarget(type: HabitGoalType.count, target: 20, unit: 'reps'),
      ),
      today: d(2026, 9, 23),
    );
    await h.read(syncWriterProvider).revert(record);
    final after = await h.db
        .customSelect('SELECT name, target_value FROM habits WHERE id = ?', variables: [Variable(habit.id)])
        .getSingle();
    expect(after.data, before.data);
    expect(await repo.revisionsFor(habit.id), hasLength(1));
  });

  test('archive, reorder and sections', () async {
    final a = buildHabit(id: 'a-${Ids.v7()}', name: 'A').copyWith(sortKey: '');
    final b = buildHabit(id: 'b-${Ids.v7()}', name: 'B').copyWith(sortKey: '');
    await repo.create(a);
    await repo.create(b);
    var all = await repo.all();
    expect(all.map((x) => x.name), ['A', 'B']);
    await repo.move(b.id, afterKey: null, beforeKey: all.first.sortKey);
    all = await repo.all();
    expect(all.map((x) => x.name), ['B', 'A']);
    await repo.setArchived(a.id, archived: true);
    expect((await repo.all(includeArchived: false)).map((x) => x.name), ['B']);
    expect((await repo.all()).firstWhere((x) => x.id == a.id).isArchived, isTrue);
  });

  test('default sections seed idempotently with deterministic ids (T5.1.11)', () async {
    final sections = h.read(habitSectionsRepositoryProvider);
    const names = {'morning': 'Morning', 'afternoon': 'Afternoon', 'evening': 'Evening', 'anytime': 'Anytime'};
    await sections.seedDefaults(names);
    await sections.seedDefaults(names);
    final all = await sections.all();
    expect(all.map((s) => s.name), ['Morning', 'Afternoon', 'Evening', 'Anytime']);
    expect(all.first.id, Ids.habitSection('user-1', 'morning'));
    expect(all.first.defaultKey, 'morning');
    expect(all.first.startTime, LocalTime(4, 0));
    // Deleting a custom section moves its habits to Anytime.
    await sections.create(name: 'Lunch');
    final lunch = (await sections.all()).firstWhere((s) => s.name == 'Lunch');
    final habit = buildHabit(id: Ids.v7()).copyWith(sectionId: lunch.id);
    await repo.create(habit);
    await sections.delete(lunch.id);
    expect((await repo.byId(habit.id))!.sectionId, sections.defaultId('anytime'));
  });

  test('vocabulary seeds once and counts usage', () async {
    final vocab = h.read(habitVocabRepositoryProvider);
    await vocab.seedDefaults({'trigger.stress': 'Stress'});
    await vocab.seedDefaults({'trigger.stress': 'Stress'});
    final all = await vocab.all();
    expect(all.where((v) => v.kind == VocabKind.trigger).map((v) => v.name), contains('Stress'));
    expect(
      all.length,
      DefaultVocab.triggers.length +
          DefaultVocab.places.length +
          DefaultVocab.coping.length +
          DefaultVocab.distractions.length,
    );
  });

  test('pauses: create, resume ends yesterday, future pause deleted on resume', () async {
    final pauses = h.read(habitPausesRepositoryProvider);
    await pauses.create(start: d(2026, 9, 20), reason: 'Vacation');
    var all = await pauses.watchAll().first;
    expect(all.single.isGlobal, isTrue);
    await pauses.end(all.single, d(2026, 9, 22));
    all = await pauses.watchAll().first;
    expect(all.single.end, d(2026, 9, 22));
    await pauses.create(start: d(2026, 10, 1), habitId: 'x');
    final future = (await pauses.watchAll().first).firstWhere((p) => p.habitId == 'x');
    await pauses.end(future, d(2026, 9, 22));
    expect((await pauses.watchAll().first).any((p) => p.habitId == 'x'), isFalse);
  });

  test('snapshot of a fresh habit evaluates today as pending', () async {
    final habit = buildHabit(id: Ids.v7(), start: d(2026, 9, 21));
    await repo.create(habit);
    final snapshot = computeSnapshot(
      service(),
      habit,
      await repo.revisionsFor(habit.id),
      const [],
      const [],
      h.clock.nowUtc(),
    );
    expect(snapshot.todayResult?.status, PeriodStatus.pending);
    expect(snapshot.evaluation!.dayOn(d(2026, 9, 21))?.status, PeriodStatus.missed);
    expect(snapshot.summary!.currentStreak, 0);
  });
}
