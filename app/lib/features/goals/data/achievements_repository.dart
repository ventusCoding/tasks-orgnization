import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/goals/domain/achievements.dart';

/// Unlocked achievements (T5.4.08). Ids are deterministic —
/// `v5(code|scope_type|scope_id)` — so re-evaluation and several devices never duplicate a badge.
class AchievementsRepository {
  AchievementsRepository(this._db, this._writer, this._userId);

  final AppDatabase _db;
  final SyncWriter _writer;
  final String Function() _userId;

  static String idOf(EarnedBadge b) => Ids.achievement(
    b.code.wire,
    b.code.scope == AchievementScope.habit ? 'habit' : null,
    b.habitId,
  );

  static UnlockedBadge? _map(AchievementRow r) {
    final code = AchievementCode.tryParse(r.code);
    if (code == null) return null;
    num? value;
    final payload = r.payload;
    if (payload != null) {
      try {
        value = (jsonDecode(payload) as Map)['value'] as num?;
      } on Object {
        value = null;
      }
    }
    return UnlockedBadge(id: r.id, code: code, habitId: r.scopeId, unlockedAt: r.unlockedAt.toUtc(), value: value);
  }

  SimpleSelectStatement<$AchievementsTable, AchievementRow> _base() => _db.select(_db.achievements)
    ..where((a) => a.deletedAt.isNull() & a.userId.equals(_userId()))
    ..orderBy([(a) => OrderingTerm.desc(a.unlockedAt)]);

  Stream<List<UnlockedBadge>> watchAll() => _base()
      .watch()
      .map((rows) => [for (final r in rows) ?_map(r)])
      .distinct(const ListEquality<UnlockedBadge>().equals);

  Future<List<UnlockedBadge>> all() async => [for (final r in await _base().get()) ?_map(r)];

  /// Writes the badges of [earned] that are not unlocked yet (one automatic operation); returns
  /// the newly unlocked ones.
  Future<List<EarnedBadge>> unlockMissing(List<EarnedBadge> earned, DateTime at) async {
    if (earned.isEmpty) return const [];
    final existing = {for (final b in await all()) b.id};
    final missing = [
      for (final b in earned)
        if (!existing.contains(idOf(b))) b,
    ];
    if (missing.isEmpty) return const [];
    await _writer.run((tx) async {
      for (final b in missing) {
        final id = idOf(b);
        if (await tx.exists('achievements', id)) continue;
        await tx.insert('achievements', id, {
          'code': b.code.wire,
          'scope_type': b.code.scope == AchievementScope.habit ? 'habit' : null,
          'scope_id': b.habitId,
          'unlocked_at': at.toUtc(),
          'payload': {'value': ?b.value},
        });
      }
    }, cause: 'auto');
    return missing;
  }
}
