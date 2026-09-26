/// Riverpod wiring of the Insights feature (T6.1.13, T6.1.17): settings, data versions, the compute
/// service and the per-request batch provider with a 60 s keep-alive.
library;

import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/features/stats/application/metric_registry.dart';
import 'package:everslot/features/stats/application/stats_cache.dart';
import 'package:everslot/features/stats/application/stats_compute_service.dart';
import 'package:everslot/features/stats/data/stats_data_source.dart';
import 'package:everslot/features/stats/data/stats_invalidation.dart';
import 'package:everslot/features/stats/data/stats_local_store.dart';
import 'package:everslot/features/stats/domain/stats_inputs.dart';
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_settings.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show StatsPeriod;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final metricRegistryProvider = Provider<MetricRegistry>((ref) => MetricRegistry.instance);

final statsDataSourceProvider = Provider<StatsDataSource>(
  (ref) => StatsDataSource(ref.watch(appDatabaseProvider), () => ref.read(currentUserIdProvider)),
);

/// Where batches run (tests override with [InlineStatsExecutor]).
final statsExecutorProvider = Provider<StatsExecutor>((ref) => const IsolateStatsExecutor());

final statsCacheProvider = Provider<StatsResultCache>((ref) => StatsResultCache());

/// `stats` + `planner` settings namespaces (arch §8.5).
final statsSettingsProvider = Provider<StatsSettings>((ref) {
  final stats = ref.watch(settingsProvider(SettingsNs.stats)).value ?? const <String, dynamic>{};
  final planner = ref.watch(settingsProvider(SettingsNs.planner)).value ?? const <String, dynamic>{};
  return StatsSettings.fromMaps(stats: stats, planner: planner);
});

/// Per-domain data versions, bumped (debounced 300 ms) by Drift table updates (T6.1.13).
final statsDataVersionsProvider = NotifierProvider<StatsDataVersionsController, Map<StatsDomain, int>>(
  StatsDataVersionsController.new,
);

class StatsDataVersionsController extends Notifier<Map<StatsDomain, int>> {
  /// Debounce of table updates (tests shorten it).
  static Duration debounce = const Duration(milliseconds: 300);

  @override
  Map<StatsDomain, int> build() {
    final db = ref.watch(appDatabaseProvider);
    ref.watch(currentUserIdProvider);
    final sub = watchStatsDomains(db, debounce: debounce).listen(bumpAll);
    ref.onDispose(sub.cancel);
    return {for (final d in StatsDomain.values) d: 0};
  }

  void bumpAll(Set<StatsDomain> domains) {
    state = {for (final e in state.entries) e.key: domains.contains(e.key) ? e.value + 1 : e.value};
  }
}

/// Version key of [scope]: its domains plus settings, and a 5-minute time bucket so time-dependent
/// metrics (streaks, overdue ages) never stay cached for long.
String dataVersionKey(Map<StatsDomain, int> versions, MetricScope scope, DateTime now) {
  final domains = {...scope.domains, StatsDomain.settings}.toList()..sort((a, b) => a.index.compareTo(b.index));
  return [
    for (final d in domains) '${d.name}${versions[d] ?? 0}',
    't${now.millisecondsSinceEpoch ~/ 300000}',
  ].join('.');
}

final statsComputeServiceProvider = Provider<StatsComputeService>(
  (ref) => StatsComputeService(
    source: ref.watch(statsDataSourceProvider),
    executor: ref.watch(statsExecutorProvider),
    cache: ref.watch(statsCacheProvider),
    registry: ref.watch(metricRegistryProvider),
    environment: () {
      final prefs = ref.read(userPreferencesProvider);
      final settings = ref.read(statsSettingsProvider);
      return StatsEnvironment(
        now: ref.read(clockProvider).nowUtc(),
        zoneId: ref.read(deviceZoneProvider),
        zones: const {},
        weekStart: settings.weekStartOverride ?? prefs.weekStart,
        dayStartMinutes: prefs.dayStartMinutes,
        settings: settings,
        currency: prefs.currency,
      );
    },
  ),
);

/// Results of one request. Kept alive 60 s after the last listener so reopening a screen hits the
/// cache; recomputed when a relevant domain's data version changes (T6.1.13).
final metricsBatchProvider = FutureProvider.autoDispose.family<StatsBatch, StatsRequest>((ref, request) async {
  final link = ref.keepAlive();
  Timer? timer;
  ref
    ..onCancel(() => timer = Timer(const Duration(seconds: 60), link.close))
    ..onResume(() => timer?.cancel())
    ..onDispose(() => timer?.cancel());
  final versions = ref.watch(statsDataVersionsProvider);
  ref.watch(statsSettingsProvider);
  final service = ref.watch(statsComputeServiceProvider);
  final now = ref.read(clockProvider).nowUtc();
  return service.computeBatch(request, dataVersion: dataVersionKey(versions, request.scope, now));
});

// ---------------------------------------------------------------------------------------------
// Local UI state (T6.1.17)
// ---------------------------------------------------------------------------------------------

final statsLocalStoreProvider = Provider<StatsLocalStore>((ref) => StatsLocalStore(ref.watch(appDatabaseProvider)));

/// Remembered Insights state: selected segment and per-scope period selection.
class StatsUiState {
  const StatsUiState({this.segment = 'overview', this.periods = const {}, this.compare = const {}});

  final String segment;

  /// scope key → period key (`thisWeek`, `rolling:30`…).
  final Map<String, String> periods;

  /// scope key → compare toggle.
  final Map<String, bool> compare;

  StatsUiState copyWith({String? segment, Map<String, String>? periods, Map<String, bool>? compare}) => StatsUiState(
    segment: segment ?? this.segment,
    periods: periods ?? this.periods,
    compare: compare ?? this.compare,
  );
}

final statsUiStateProvider = NotifierProvider<StatsUiController, StatsUiState>(StatsUiController.new);

class StatsUiController extends Notifier<StatsUiState> {
  @override
  StatsUiState build() {
    unawaited(_load());
    return const StatsUiState();
  }

  Future<void> _load() async {
    try {
      final all = await ref.read(statsLocalStoreProvider).readAll();
      final periods = <String, String>{};
      final compare = <String, bool>{};
      for (final e in all.entries) {
        if (e.key.startsWith('period.')) periods[e.key.substring(7)] = e.value;
        if (e.key.startsWith('compare.')) compare[e.key.substring(8)] = e.value == 'true';
      }
      state = StatsUiState(
        segment: all['segment'] ?? state.segment,
        periods: {...periods, ...state.periods},
        compare: {...compare, ...state.compare},
      );
    } on Object {
      // Local state is a convenience; defaults apply.
    }
  }

  void setSegment(String segment) {
    state = state.copyWith(segment: segment);
    unawaited(ref.read(statsLocalStoreProvider).write('segment', segment).catchError((Object _) {}));
  }

  void setPeriod(String scopeKey, StatsPeriod period) {
    state = state.copyWith(periods: {...state.periods, scopeKey: period.key});
    unawaited(ref.read(statsLocalStoreProvider).write('period.$scopeKey', period.key).catchError((Object _) {}));
  }

  void setCompare(String scopeKey, bool compare) {
    state = state.copyWith(compare: {...state.compare, scopeKey: compare});
    unawaited(ref.read(statsLocalStoreProvider).write('compare.$scopeKey', '$compare').catchError((Object _) {}));
  }

  /// The selection of [scopeKey]: remembered period, else the `stats.defaultPeriod` setting.
  PeriodSelection selectionFor(String scopeKey, StatsSettings settings, {StatsPeriod? fallback}) {
    final period =
        PeriodSelection.parsePeriod(state.periods[scopeKey]) ??
        fallback ??
        PeriodSelection.parsePeriod(settings.defaultPeriod) ??
        const StatsPeriod.thisWeek();
    return PeriodSelection(period, compare: state.compare[scopeKey] ?? settings.compareWithPrevious);
  }
}
