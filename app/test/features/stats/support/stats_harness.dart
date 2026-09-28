import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/env/env.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/session/session.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:everslot/features/stats/application/stats_compute_service.dart';
import 'package:everslot/features/stats/application/stats_providers.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override, ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

/// Stats test harness: in-memory DB, local session, fake clock, a zone and inline stats execution.
class StatsHarness {
  StatsHarness._(this.db, this.container, this.clock);

  static bool _tzReady = false;

  static StatsHarness create({
    DateTime? now,
    String zone = 'UTC',
    String userId = 'user-1',
    List<Override> overrides = const [],
    QueryInterceptor? interceptor,
    StatsExecutor executor = const InlineStatsExecutor(),
  }) {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (!_tzReady) {
      tzdata.initializeTimeZones();
      _tzReady = true;
    }
    final memory = NativeDatabase.memory();
    final db = AppDatabase.forTesting(interceptor == null ? memory : memory.interceptWith(interceptor));
    final clock = FakeClock(now ?? DateTime.utc(2026, 9, 22, 9));
    SessionController.initial = AppSession(userId: userId, mode: SessionMode.localOnly);
    DeviceZoneController.initialZone = zone;
    StatsDataVersionsController.debounce = const Duration(milliseconds: 10);
    final container = ProviderContainer(
      overrides: [
        envProvider.overrideWithValue(
          const Env(
            flavor: Flavor.dev,
            supabaseUrl: '',
            supabasePublishableKey: '',
            firebaseEnabled: false,
            featureFlags: {},
          ),
        ),
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock),
        deviceIdProvider.overrideWithValue('device-test'),
        statsExecutorProvider.overrideWithValue(executor),
        ...overrides,
      ],
    );
    return StatsHarness._(db, container, clock);
  }

  final AppDatabase db;
  final ProviderContainer container;
  final FakeClock clock;

  static const userId = 'user-1';

  T read<T>(ProviderListenable<T> provider) => container.read(provider);

  final List<ProviderSubscription<Object?>> _subs = [];

  /// Keeps the settings/profile streams alive (Riverpod 3 pauses unlistened providers) and waits
  /// for their first values so batch environments see them.
  Future<void> settle() async {
    if (_subs.isEmpty) {
      for (final p in [
        settingsProvider(SettingsNs.stats),
        settingsProvider(SettingsNs.planner),
        settingsProvider(SettingsNs.habits),
        settingsProvider(SettingsNs.regional),
        settingsProvider(SettingsNs.appearance),
      ]) {
        _subs.add(container.listen(p, (_, _) {}));
      }
      _subs
        ..add(container.listen(profileRowProvider, (_, _) {}))
        ..add(container.listen(statsSettingsProvider, (_, _) {}))
        ..add(container.listen(userPreferencesProvider, (_, _) {}));
    }
    await container.read(settingsProvider(SettingsNs.stats).future);
    await container.read(settingsProvider(SettingsNs.planner).future);
    await container.read(settingsProvider(SettingsNs.habits).future);
    await container.read(settingsProvider(SettingsNs.regional).future);
    await container.read(settingsProvider(SettingsNs.appearance).future);
    await container.read(profileRowProvider.future);
  }

  /// Computes [metricIds] for a request through the real pipeline (loaders → job → registry).
  Future<Map<String, MetricResult>> compute(
    MetricScope scope, {
    String? scopeId,
    StatsPeriod period = const StatsPeriod.thisWeek(),
    bool compare = true,
    String? extra,
    Set<String>? metricIds,
    StatsFilters filters = StatsFilters.none,
  }) async {
    await settle();
    final batch = await read(statsComputeServiceProvider).computeBatch(
      StatsRequest(
        scope,
        scopeId: scopeId,
        selection: PeriodSelection(period, compare: compare),
        extra: extra,
        metricIds: metricIds,
        filters: filters,
      ),
      dataVersion: 'test-${DateTime.now().microsecondsSinceEpoch}',
    );
    return batch.results;
  }

  Future<void> dispose() async {
    for (final s in _subs) {
      s.close();
    }
    container.dispose();
    await db.close();
  }

  // ------------------------------------------------------------------------------------------
  // Seeding

  /// Inserts fixture rows (server snake_case column names). Common synced columns are filled in.
  Future<void> seedTables(Map<String, Object?> tables) async {
    final now = clock.nowUtc().toIso8601String();
    for (final entry in tables.entries) {
      final rows = (entry.value! as List).cast<Map<String, Object?>>();
      for (final row in rows) {
        final values = <String, Object?>{
          'user_id': userId,
          'created_at': now,
          'updated_at': row['created_at'] ?? now,
          ...row,
        };
        final cols = values.keys.toList();
        await db.customStatement(
          'INSERT INTO ${entry.key} (${cols.join(', ')}) VALUES (${List.filled(cols.length, '?').join(', ')})',
          [for (final c in cols) _sql(values[c])],
        );
      }
    }
    // Wake table-update listeners.
    db.notifyUpdates({for (final t in db.allTables) TableUpdate.onTable(t)});
  }

  static Object? _sql(Object? v) => switch (v) {
    final bool b => b ? 1 : 0,
    final Map<Object?, Object?> m => jsonEncode(m),
    final List<Object?> l => jsonEncode(l),
    _ => v,
  };

  /// Writes settings namespaces and a profile row.
  Future<void> seedSettings(Map<String, Object?> namespaces, {int weekStart = 1, String homeZone = 'UTC'}) async {
    final now = clock.nowUtc().toIso8601String();
    await db.customStatement(
      'INSERT INTO profiles (id, user_id, created_at, updated_at, home_time_zone, week_start, time_format) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [userId, userId, now, now, homeZone, weekStart, 'h24'],
    );
    for (final e in namespaces.entries) {
      await db.customStatement(
        'INSERT INTO user_settings (id, user_id, created_at, updated_at, namespace, value) VALUES (?, ?, ?, ?, ?, ?)',
        [
          Ids.userSetting(userId, e.key),
          userId,
          now,
          now,
          e.key,
          jsonEncode({'v': 1, ...(e.value! as Map<String, Object?>)}),
        ],
      );
    }
  }
}

/// A table fixture (T6.1.15): `now`, `zone`, `weekStart`, `settings`, `tables`, `expect`.
class StatsFixture {
  StatsFixture(this.name, this.json);

  factory StatsFixture.load(String name) => StatsFixture(
    name,
    jsonDecode(File('test/features/stats/fixtures/$name.json').readAsStringSync()) as Map<String, Object?>,
  );

  final String name;
  final Map<String, Object?> json;

  DateTime get now => DateTime.parse(json['now']! as String).toUtc();
  String get zone => json['zone']! as String;
  int get weekStart => (json['weekStart'] as num?)?.toInt() ?? 1;
  List<Map<String, Object?>> get expectations => (json['expect']! as List).cast<Map<String, Object?>>();

  /// A harness seeded with the fixture's settings and tables.
  Future<StatsHarness> seed({List<Override> overrides = const []}) async {
    final h = StatsHarness.create(now: now, zone: zone, overrides: overrides);
    await h.seedSettings((json['settings'] as Map<String, Object?>?) ?? const {}, weekStart: weekStart, homeZone: zone);
    await h.seedTables((json['tables'] as Map<String, Object?>?) ?? const {});
    return h;
  }
}

/// Runs every expectation of [fixture] and returns readable failures (empty = pass).
Future<List<String>> runFixture(StatsFixture fixture, StatsHarness h) async {
  final failures = <String>[];
  final groups = <String, List<Map<String, Object?>>>{};
  for (final e in fixture.expectations) {
    final key = '${e['scope']}|${e['scopeId'] ?? ''}|${e['period'] ?? ''}|${e['extra'] ?? ''}';
    groups.putIfAbsent(key, () => []).add(e);
  }
  for (final group in groups.values) {
    final first = group.first;
    final results = await h.compute(
      MetricScope.values.byName(first['scope']! as String),
      scopeId: first['scopeId'] as String?,
      period: PeriodSelection.parsePeriod(first['period'] as String?) ?? const StatsPeriod.thisWeek(),
      extra: first['extra'] as String?,
      metricIds: {for (final e in group) e['metricId']! as String},
    );
    for (final e in group) {
      final id = e['metricId']! as String;
      final label = '${fixture.name} · $id (${first['scope']} ${first['scopeId'] ?? ''} ${first['period'] ?? ''})';
      final r = results[id];
      if (r == null) {
        failures.add('$label: no result');
        continue;
      }
      if (r.note == 'error') {
        failures.add('$label: compute error ${r.args['error']}');
        continue;
      }
      final tolerance = (e['tolerance'] as num?)?.toDouble() ?? 1e-6;
      if (e.containsKey('value')) {
        final expected = (e['value']! as num).toDouble();
        final actual = r.value.valueOrNull;
        if (actual == null || (actual - expected).abs() > tolerance) {
          failures.add('$label: value expected $expected, got ${r.value}');
        }
      }
      if (e['insufficient'] == true && r.value is! Insufficient<double>) {
        failures.add('$label: expected Insufficient, got ${r.value}');
      }
      if (e['note'] case final String note when r.note != note) {
        failures.add('$label: note expected $note, got ${r.note}');
      }
      final args = (e['args'] as Map<String, Object?>?) ?? const {};
      for (final a in args.entries) {
        final actual = r.args[a.key];
        final ok = switch ((a.value, actual)) {
          (final num x, final num y) => (x - y).abs() <= tolerance,
          _ => '${a.value}' == '$actual',
        };
        if (!ok) failures.add('$label: arg ${a.key} expected ${a.value}, got $actual');
      }
    }
  }
  return failures;
}

/// Pumps [child] inside localizations, theme and the harness' providers.
Future<void> pumpStats(
  WidgetTester tester,
  StatsHarness h,
  Widget child, {
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: h.container,
      child: MaterialApp(
        locale: locale,
        themeMode: themeMode,
        supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
        localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
        home: child,
      ),
    ),
  );
}
