import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/errors/app_exception.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/ordering/fractional_index.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/habits/data/habit_mappers.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';

/// Time-of-day sections (T5.1.11, T5.1.15). Defaults use `v5(user_id|habit_section|key)` so two
/// devices seeding offline converge on the same four rows.
class HabitSectionsRepository {
  HabitSectionsRepository(this._db, this._writer, this._userId);

  final AppDatabase _db;
  final SyncWriter _writer;
  final String Function() _userId;

  SimpleSelectStatement<$HabitSectionsTable, HabitSectionRow> _query({bool includeArchived = false}) {
    final q = _db.select(_db.habitSections)
      ..where((s) => s.deletedAt.isNull() & s.userId.equals(_userId()))
      ..orderBy([(s) => OrderingTerm.asc(s.sortKey), (s) => OrderingTerm.asc(s.id)]);
    if (!includeArchived) q.where((s) => s.archivedAt.isNull());
    return q;
  }

  Stream<List<HabitSection>> watchAll({bool includeArchived = false}) => _query(includeArchived: includeArchived)
      .watch()
      .map((rows) => [for (final r in rows) HabitMappers.section(r, _userId())])
      .distinct(const ListEquality<HabitSection>().equals);

  Future<List<HabitSection>> all({bool includeArchived = true}) async =>
      [for (final r in await _query(includeArchived: includeArchived).get()) HabitMappers.section(r, _userId())];

  /// Id of the default section [key] for the current user.
  String defaultId(String key) => Ids.habitSection(_userId(), key);

  /// Whether this device completed its first pull for the current user (cloud accounts seed
  /// defaults only afterwards, see `HabitDefaults`).
  Future<bool> firstPullDone() async {
    final userId = _userId();
    if (userId.isEmpty) return false;
    final state = await (_db.select(_db.syncState)..where((s) => s.userId.equals(userId))).getSingleOrNull();
    return state?.lastPullAt != null;
  }

  /// Seeds the four default sections once (idempotent; localized [names] by key).
  Future<void> seedDefaults(Map<String, String> names) async {
    final userId = _userId();
    if (userId.isEmpty) return;
    final existing = {for (final s in await all()) s.id};
    final missing = [
      for (final d in DefaultSections.all)
        if (!existing.contains(Ids.habitSection(userId, d.$1))) d,
    ];
    if (missing.isEmpty) return;
    await _writer.run((tx) async {
      final keys = FractionalIndex.nBetween(null, null, DefaultSections.all.length);
      for (var i = 0; i < DefaultSections.all.length; i++) {
        final (key, icon, start, end) = DefaultSections.all[i];
        final id = Ids.habitSection(userId, key);
        if (await tx.exists('habit_sections', id)) continue;
        await tx.insert('habit_sections', id, {
          'name': names[key] ?? key,
          'icon': icon,
          'sort_key': keys[i],
          'start_time': start?.toIso(),
          'end_time': end?.toIso(),
        });
      }
    }, cause: 'auto');
  }

  static void _validateName(String name) {
    final n = name.trim();
    if (n.isEmpty || n.length > 40) throw const ValidationException('Section name must be 1–40 characters', field: 'name');
  }

  Future<OpRecord> create({required String name, String? icon, LocalTime? start, LocalTime? end}) async {
    _validateName(name);
    final existing = await all();
    final last = existing.isEmpty ? null : existing.last.sortKey;
    return _writer.run(
      (tx) => tx.insert('habit_sections', Ids.v7(), {
        'name': name.trim(),
        'icon': icon,
        'sort_key': FractionalIndex.between(last, null),
        'start_time': start?.toIso(),
        'end_time': end?.toIso(),
      }),
    );
  }

  Future<OpRecord> update(
    String id, {
    String? name,
    String? icon,
    Object? start = _keep,
    Object? end = _keep,
  }) {
    if (name != null) _validateName(name);
    return _writer.run(
      (tx) => tx.update('habit_sections', id, {
        if (name != null) 'name': name.trim(),
        'icon': ?icon,
        if (!identical(start, _keep)) 'start_time': (start as LocalTime?)?.toIso(),
        if (!identical(end, _keep)) 'end_time': (end as LocalTime?)?.toIso(),
      }),
    );
  }

  Future<OpRecord> move(String id, {String? afterKey, String? beforeKey}) =>
      _writer.run((tx) => tx.update('habit_sections', id, {'sort_key': FractionalIndex.between(afterKey, beforeKey)}));

  /// Deletes a custom section; its habits move to Anytime (one operation).
  Future<OpRecord> delete(String id) => _writer.run((tx) async {
    final anytime = defaultId(DefaultSections.anytime);
    final rows = await _db
        .customSelect(
          'SELECT id FROM habits WHERE section_id = ? AND deleted_at IS NULL',
          variables: [Variable<String>(id)],
        )
        .get();
    for (final r in rows) {
      await tx.update('habits', r.data['id']! as String, {'section_id': anytime == id ? null : anytime});
    }
    await tx.softDelete('habit_sections', id);
  });

  static const Object _keep = Object();
}

/// Trigger / place / coping / distraction libraries (T5.3.14). Defaults are seeded with
/// deterministic ids and localized names; logs store the entry id (free text still allowed).
class HabitVocabRepository {
  HabitVocabRepository(this._db, this._writer, this._userId);

  final AppDatabase _db;
  final SyncWriter _writer;
  final String Function() _userId;

  Stream<List<VocabEntry>> watchAll({bool includeArchived = false}) {
    final q = _db.select(_db.habitVocab)
      ..where((v) => v.deletedAt.isNull() & v.userId.equals(_userId()))
      ..orderBy([(v) => OrderingTerm.asc(v.kind), (v) => OrderingTerm.asc(v.sortKey), (v) => OrderingTerm.asc(v.id)]);
    if (!includeArchived) q.where((v) => v.archivedAt.isNull());
    return q
        .watch()
        .map((rows) => rows.map(HabitMappers.vocab).toList())
        .distinct(const ListEquality<VocabEntry>().equals);
  }

  Future<List<VocabEntry>> all() async => (await (_db.select(_db.habitVocab)
            ..where((v) => v.deletedAt.isNull() & v.userId.equals(_userId()))
            ..orderBy([(v) => OrderingTerm.asc(v.sortKey)]))
          .get())
      .map(HabitMappers.vocab)
      .toList();

  /// Seeds the default libraries once (idempotent). [names] maps `kind.key` → localized name.
  Future<void> seedDefaults(Map<String, String> names) async {
    final userId = _userId();
    if (userId.isEmpty) return;
    final existing = {for (final v in await all()) v.id};
    final wanted = [
      for (final kind in VocabKind.values)
        for (final key in DefaultVocab.keysFor(kind)) (kind, key, HabitIds.vocab(userId, kind.name, key)),
    ];
    if (wanted.every((w) => existing.contains(w.$3))) return;
    await _writer.run((tx) async {
      for (final kind in VocabKind.values) {
        final keys = DefaultVocab.keysFor(kind);
        final sortKeys = FractionalIndex.nBetween(null, null, keys.length);
        for (var i = 0; i < keys.length; i++) {
          final id = HabitIds.vocab(userId, kind.name, keys[i]);
          if (await tx.exists('habit_vocab', id)) continue;
          await tx.insert('habit_vocab', id, {
            'kind': kind.name,
            'name': names['${kind.name}.${keys[i]}'] ?? keys[i],
            'sort_key': sortKeys[i],
          });
        }
      }
    }, cause: 'auto');
  }

  Future<OpRecord> create(VocabKind kind, String name, {String? icon, int? color}) async {
    final n = name.trim();
    if (n.isEmpty || n.length > 60) throw const ValidationException('Name must be 1–60 characters', field: 'name');
    final same = [for (final v in await all()) if (v.kind == kind) v];
    final last = same.isEmpty ? null : same.map((v) => v.sortKey).reduce((a, b) => a.compareTo(b) > 0 ? a : b);
    return _writer.run(
      (tx) => tx.insert('habit_vocab', Ids.v7(), {
        'kind': kind.name,
        'name': n,
        'icon': icon,
        'color': color,
        'sort_key': FractionalIndex.between(last, null),
      }),
    );
  }

  Future<OpRecord> rename(String id, String name) {
    final n = name.trim();
    if (n.isEmpty || n.length > 60) throw const ValidationException('Name must be 1–60 characters', field: 'name');
    return _writer.run((tx) => tx.update('habit_vocab', id, {'name': n}));
  }

  Future<OpRecord> setArchived(String id, {required bool archived}) =>
      _writer.run((tx) => tx.update('habit_vocab', id, {'archived_at': archived ? tx.now : null}));

  Future<OpRecord> move(String id, {String? afterKey, String? beforeKey}) =>
      _writer.run((tx) => tx.update('habit_vocab', id, {'sort_key': FractionalIndex.between(afterKey, beforeKey)}));
}

/// Local-only duration timers (T5.2.04): `habit_timer_state` is never synced; a running timer
/// survives app kills because its start instant is persisted.
class HabitTimerStore {
  HabitTimerStore(this._db);

  final AppDatabase _db;

  static HabitTimer _map(HabitTimerStateRow r) => HabitTimer(
    habitId: r.habitId,
    key: r.occurrenceKey,
    startedAt: r.startedAt.toUtc(),
    accumulatedSeconds: r.accumulatedSeconds,
    running: r.running,
  );

  Stream<List<HabitTimer>> watchAll() => _db
      .select(_db.habitTimerState)
      .watch()
      .map((rows) => rows.map(_map).toList())
      .distinct(const ListEquality<HabitTimer>().equals);

  Future<HabitTimer?> read(String habitId, String key) async {
    final row = await (_db.select(_db.habitTimerState)
          ..where((t) => t.habitId.equals(habitId) & t.occurrenceKey.equals(key)))
        .getSingleOrNull();
    return row == null ? null : _map(row);
  }

  /// Starts (or resumes) the timer at [now].
  Future<void> start(String habitId, String key, DateTime now) async {
    final current = await read(habitId, key);
    await _db.into(_db.habitTimerState).insertOnConflictUpdate(
      HabitTimerStateCompanion.insert(
        habitId: habitId,
        occurrenceKey: key,
        startedAt: now.toUtc(),
        accumulatedSeconds: Value(current?.accumulatedSeconds ?? 0),
        running: const Value(true),
      ),
    );
  }

  /// Pauses a running timer (accumulates the elapsed seconds).
  Future<void> pause(String habitId, String key, DateTime now) async {
    final current = await read(habitId, key);
    if (current == null || !current.running) return;
    await (_db.update(_db.habitTimerState)..where((t) => t.habitId.equals(habitId) & t.occurrenceKey.equals(key)))
        .write(
          HabitTimerStateCompanion(
            accumulatedSeconds: Value(current.elapsedSeconds(now)),
            running: const Value(false),
            startedAt: Value(now.toUtc()),
          ),
        );
  }

  /// Stops the timer and returns its total seconds (0 when none).
  Future<int> stop(String habitId, String key, DateTime now) async {
    final current = await read(habitId, key);
    if (current == null) return 0;
    final total = current.elapsedSeconds(now);
    await discard(habitId, key);
    return total;
  }

  Future<void> discard(String habitId, String key) =>
      (_db.delete(_db.habitTimerState)..where((t) => t.habitId.equals(habitId) & t.occurrenceKey.equals(key))).go();
}

/// Local-only UI memory of the Habits tab (last view, filter) in `local_kv` — never synced.
class HabitUiStore {
  HabitUiStore(this._db);

  final AppDatabase _db;

  static const _prefix = 'habits.ui.';

  Future<String?> read(String key) async {
    final row = await (_db.select(_db.localKv)..where((k) => k.key.equals('$_prefix$key'))).getSingleOrNull();
    return row?.value;
  }

  Future<void> write(String key, String value) =>
      _db.into(_db.localKv).insertOnConflictUpdate(LocalKvCompanion.insert(key: '$_prefix$key', value: value));
}
