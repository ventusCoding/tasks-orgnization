/// Insights feed (T6.7.08): GL-19 evaluates the 18 triggers on the current data in the stats
/// isolate; this service filters the candidates with the local `insight_state` (dedupe key and
/// per-trigger cooldowns) and the muted trigger types (`user_settings.stats.mutedInsightTypes`),
/// records the new ones and keeps announced record keys (`stats.announcedRecords`) so a record is
/// never announced twice. Generation runs whenever a screen shows the feed and the data changes
/// (data versions are already debounced). TODO(integration): daily background generation and
/// opt-in inbox / push delivery per trigger type are wired by [7.5].
library;

import 'dart:convert';

import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/features/stats/application/stats_compute_service.dart';
import 'package:everslot/features/stats/application/stats_providers.dart';
import 'package:everslot/features/stats/data/insight_state_store.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_settings.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot_metrics/everslot_metrics.dart'
    show Insight, InsightState, InsightTrigger, StatsPeriod, filterInsights;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// One insight of the feed.
@immutable
final class FeedInsight {
  const FeedInsight({
    required this.key,
    required this.trigger,
    required this.entityId,
    required this.valueKey,
    required this.firedAt,
    this.args = const {},
    this.metricId,
    this.ref,
  });

  /// Parses a GL-19 candidate / stored payload (null when malformed or from an unknown trigger).
  static FeedInsight? fromJson(Map<String, Object?> json, {DateTime? firedAt}) {
    final trigger = InsightTrigger.values.where((t) => t.name == json['trigger']).firstOrNull;
    final key = json['key'];
    if (trigger == null || key is! String) return null;
    final refJson = json['ref'];
    DrillRef? ref;
    if (refJson is Map) {
      final kind = DrillKind.values.where((k) => k.name == refJson['kind']).firstOrNull;
      final id = refJson['id'];
      if (kind != null && id is String) {
        ref = DrillRef(kind, id, extra: refJson['extra'] as String?, title: (json['args'] as Map?)?['name'] as String?);
      }
    }
    return FeedInsight(
      key: key,
      trigger: trigger,
      entityId: '${json['entity'] ?? ''}',
      valueKey: '${json['value'] ?? ''}',
      firedAt: firedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      args: json['args'] is Map ? Map<String, Object?>.from(json['args']! as Map) : const {},
      metricId: json['metric'] as String?,
      ref: ref,
    );
  }

  final String key;
  final InsightTrigger trigger;
  final String entityId;
  final String valueKey;
  final DateTime firedAt;
  final Map<String, Object?> args;

  /// Metric that supports the insight (opened by the card).
  final String? metricId;

  /// Entity the insight is about.
  final DrillRef? ref;

  Insight get asInsight => Insight(trigger, entityId: entityId, valueKey: valueKey, args: args);
}

final insightStateStoreProvider = Provider<InsightStateStore>(
  (ref) => InsightStateStore(ref.watch(appDatabaseProvider)),
);

final insightsFeedServiceProvider = Provider<InsightsFeedService>(
  (ref) => InsightsFeedService(
    compute: ref.watch(statsComputeServiceProvider),
    store: ref.watch(insightStateStoreProvider),
    settings: ref.watch(settingsRepositoryProvider),
    now: () => ref.read(clockProvider).nowUtc(),
  ),
);

class InsightsFeedService {
  InsightsFeedService({required this.compute, required this.store, required this.settings, required this.now});

  final StatsComputeService compute;
  final InsightStateStore store;
  final SettingsRepository settings;
  final DateTime Function() now;

  /// How long a fired insight stays in the feed.
  static const feedDays = 30;

  /// Evaluates the triggers and records the insights that may fire now; returns them.
  Future<List<FeedInsight>> generate({required String dataVersion, required StatsSettings statsSettings}) async {
    final batch = await compute.computeBatch(
      const StatsRequest(
        MetricScope.global,
        selection: PeriodSelection(StatsPeriod.thisWeek(), compare: false),
        metricIds: {'GL-19'},
      ),
      dataVersion: dataVersion,
    );
    final raw = (batch['GL-19']?.args['insights'] as List?) ?? const [];
    final candidates = [
      for (final c in raw)
        if (c is Map) ?FeedInsight.fromJson(Map<String, Object?>.from(c)),
    ];
    final rows = await store.all();
    final at = now();
    final state = InsightState(
      firedAt: {
        for (final r in rows)
          if (r.firedAt != null) r.key: r.firedAt!,
      },
      muted: {
        for (final t in InsightTrigger.values)
          if (statsSettings.mutedInsights.contains(t.name)) t,
      },
    );
    final byKey = {for (final c in candidates) c.key: c};
    final fresh = [
      for (final i in filterInsights([for (final c in candidates) c.asInsight], state: state, now: at))
        byKey[i.dedupeKey]!,
    ];
    if (fresh.isEmpty) return const [];
    await store.fire({
      for (final f in fresh) f.key: jsonEncode(raw.firstWhere((c) => c is Map && c['key'] == f.key) as Map),
    }, at);
    // A record is announced once (`stats.announcedRecords` = "type|value").
    final records = [
      for (final f in fresh)
        if (f.trigger == InsightTrigger.newRecord) '${f.entityId}|${f.valueKey}',
    ];
    if (records.isNotEmpty) {
      final stats = await settings.read(SettingsNs.stats);
      final announced = {...?(stats['announcedRecords'] as List?)?.whereType<String>(), ...records};
      await settings.update(SettingsNs.stats, {'announcedRecords': announced.toList()..sort()});
    }
    return fresh;
  }

  Future<void> dismiss(String key) => store.dismiss(key, now());

  /// Mutes (or unmutes) a trigger type.
  Future<void> setMuted(InsightTrigger trigger, {required bool muted}) async {
    final stats = await settings.read(SettingsNs.stats);
    final current = {...?((stats['mutedInsightTypes'] ?? stats['mutedInsights']) as List?)?.whereType<String>()};
    muted ? current.add(trigger.name) : current.remove(trigger.name);
    await settings.update(SettingsNs.stats, {'mutedInsightTypes': current.toList()..sort()});
  }

  /// The feed: fired within [feedDays], not dismissed, not muted, newest first.
  static List<FeedInsight> feedOf(List<InsightStateRow> rows, {required DateTime now, required Set<String> muted}) {
    final list = <FeedInsight>[];
    for (final r in rows) {
      if (r.dismissedAt != null || r.firedAt == null || r.payload == null) continue;
      if (now.difference(r.firedAt!) > const Duration(days: feedDays)) continue;
      try {
        final json = jsonDecode(r.payload!);
        if (json is! Map) continue;
        final f = FeedInsight.fromJson(Map<String, Object?>.from(json), firedAt: r.firedAt);
        if (f != null && !muted.contains(f.trigger.name)) list.add(f);
      } on FormatException {
        // A corrupt payload is skipped.
      }
    }
    return list..sort((a, b) => b.firedAt.compareTo(a.firedAt));
  }
}

/// Runs the generator when the data or settings change while a feed is on screen.
final insightsGenerationProvider = FutureProvider.autoDispose<int>((ref) async {
  final versions = ref.watch(statsDataVersionsProvider);
  final settings = ref.watch(statsSettingsProvider);
  final now = ref.read(clockProvider).nowUtc();
  final fresh = await ref
      .read(insightsFeedServiceProvider)
      .generate(dataVersion: dataVersionKey(versions, MetricScope.global, now), statsSettings: settings);
  return fresh.length;
});

/// The live feed.
final insightsFeedProvider = StreamProvider.autoDispose<List<FeedInsight>>((ref) {
  final muted = ref.watch(statsSettingsProvider.select((s) => s.mutedInsights));
  final clock = ref.read(clockProvider);
  return ref
      .watch(insightStateStoreProvider)
      .watch()
      .map((rows) => InsightsFeedService.feedOf(rows, now: clock.nowUtc(), muted: muted));
});
