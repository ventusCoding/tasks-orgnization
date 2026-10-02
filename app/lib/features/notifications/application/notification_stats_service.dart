import 'dart:convert';

import 'package:drift/drift.dart' show Variable;
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/domain/notification_stats.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// One statistics view: the rows of a period and the rules worth taming.
@immutable
class NotificationStatsReport {
  const NotificationStatsReport({required this.rows, required this.noisy, required this.from});

  final List<NotificationStatsRow> rows;
  final List<NoisyRule> noisy;
  final DateTime from;
}

/// Notification statistics (T7.5.17): inbox rows (90-day retention) + the daily rollup kept in
/// `local_kv` for older periods, plus reminder effectiveness from the sections' activity.
class NotificationStatsService {
  NotificationStatsService(this._ref);

  final Ref _ref;

  static const rollupKey = 'notifications.statsRollup';

  /// Days newer than this stay in the inbox (the server purges at 90).
  static const rollupAfter = Duration(days: 80);

  AppDatabase get _db => _ref.read(appDatabaseProvider);
  DateTime get _now => _ref.read(clockProvider).nowUtc();

  Future<StatsRollup> readRollup() async {
    final row = await _db
        .customSelect('SELECT value FROM local_kv WHERE key = ?', variables: [const Variable<String>(rollupKey)])
        .getSingleOrNull();
    if (row == null) return const StatsRollup();
    try {
      return StatsRollup.fromJson(Map<String, Object?>.from(jsonDecode(row.read<String>('value')) as Map));
    } on Object {
      return const StatsRollup();
    }
  }

  /// Rolls the days older than [rollupAfter] into the rollup (idempotent; cheap when up to date).
  Future<StatsRollup> rollUp() async {
    final now = _now;
    final current = await readRollup();
    final cutoff = now.subtract(rollupAfter);
    final day = DateTime.utc(cutoff.year, cutoff.month, cutoff.day);
    if (current.through != null && !current.through!.isBefore(day)) return current;
    final from = current.through ?? now.subtract(const Duration(days: 90));
    final rows = await _ref.read(inboxRepositoryProvider).statsRows(from: from, to: day);
    final next = current.rollUp(rows, cutoff: day, now: now);
    await _db.customStatement('INSERT OR REPLACE INTO local_kv (key, value) VALUES (?, ?)', [
      rollupKey,
      jsonEncode(next.toJson()),
    ]);
    return next;
  }

  /// Completion instants per target key from every section that reports them.
  Future<Map<String, List<DateTime>>> activity(DateTime from, DateTime to) async {
    final out = <String, List<DateTime>>{};
    for (final s in _ref.read(notificationTargetSourcesProvider).whereType<TargetActivitySource>()) {
      try {
        out.addAll(await s.activityBetween(from, to));
      } on Object {
        // a section that can't answer just has no effectiveness figures
      }
    }
    return out;
  }

  /// Statistics of the last [days] days grouped [by]; noisy rules over the same period.
  Future<NotificationStatsReport> load({required int days, required StatsGroup by}) async {
    final now = _now;
    final from = now.subtract(Duration(days: days));
    final rollup = await rollUp();
    final through = rollup.through;
    final inboxFrom = through != null && through.isAfter(from) ? through : from;
    final rows = await _ref.read(inboxRepositoryProvider).statsRows(from: inboxFrom);
    final live = NotificationStats.compute(
      rows,
      by: by,
      now: now,
      activity: await activity(inboxFrom, now.add(NotificationStats.effectivenessWindow)),
    );
    var merged = live;
    if (through != null && through.isAfter(from) && by != StatsGroup.target) {
      final old = {for (final r in rollup.rowsBetween(by, from, through)) r.key: r};
      merged = [for (final r in live) old.containsKey(r.key) ? r + old.remove(r.key)! : r, ...old.values]
        ..sort((a, b) => b.delivered - a.delivered);
    }
    final byRule = by == StatsGroup.rule ? merged : NotificationStats.compute(rows, by: StatsGroup.rule, now: now);
    return NotificationStatsReport(rows: merged, noisy: NotificationStats.noisyRules(byRule), from: from);
  }

  /// Share of a target's reminders followed by a check-in / start within an hour, over [days]
  /// (insights, [6.5]); null without reminders.
  Future<double?> effectivenessFor(String targetKey, {int days = 30}) async {
    final now = _now;
    final from = now.subtract(Duration(days: days));
    final rows = [
      for (final r in await _ref.read(inboxRepositoryProvider).statsRows(from: from))
        if ('${r.sourceType}:${r.sourceId}' == targetKey) r,
    ];
    if (rows.isEmpty) return null;
    final stats = NotificationStats.compute(
      rows,
      by: StatsGroup.target,
      now: now,
      activity: await activity(from, now.add(NotificationStats.effectivenessWindow)),
    );
    return stats.isEmpty ? null : stats.first.effectiveness;
  }
}

final notificationStatsServiceProvider = Provider<NotificationStatsService>(NotificationStatsService.new);
