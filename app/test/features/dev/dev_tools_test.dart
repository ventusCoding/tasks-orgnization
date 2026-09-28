import 'package:drift/native.dart';
import 'package:everslot/app/router.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/env/env.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/session/local_account.dart';
import 'package:everslot/core/session/session.dart';
import 'package:everslot/features/auth/application/auth_binding.dart';
import 'package:everslot/features/dev/application/dev_providers.dart';
import 'package:everslot/features/dev/domain/dev_models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/test_app.dart';

Env _env(Flavor flavor) => Env(
  flavor: flavor,
  supabaseUrl: '',
  supabasePublishableKey: '',
  firebaseEnabled: false,
  featureFlags: const {},
);

List<String> _paths(List<RouteBase> routes, [String prefix = '']) => [
  for (final r in routes) ...[
    if (r is GoRoute) r.path.startsWith('/') ? r.path : '$prefix/${r.path}',
    ..._paths(r.routes, r is GoRoute ? (r.path.startsWith('/') ? r.path : '$prefix/${r.path}') : prefix),
  ],
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('time travel (T1.3.16)', () {
    test('moves the one shared clock: every consumer sees the new time, nothing is rebuilt', () {
      final c = ProviderContainer(overrides: [envProvider.overrideWithValue(_env(Flavor.dev))]);
      final clock = c.read(clockProvider);
      final before = clock.nowUtc();
      c.read(devToolsProvider).travelBy(const Duration(days: 1));
      expect(identical(c.read(clockProvider), clock), isTrue);
      expect(clock.nowUtc().difference(before).inHours, inInclusiveRange(23, 24));
      c.read(devToolsProvider).travelBy(const Duration(hours: -1));
      expect(c.read(timeTravelProvider), const Duration(hours: 23));
      c.read(devToolsProvider).travelTo(DateTime.utc(2030, 1, 1, 12));
      expect(clock.nowUtc().difference(DateTime.utc(2030, 1, 1, 12)).inSeconds.abs(), lessThan(5));
      c.read(devToolsProvider).resetTime();
      expect(clock.nowUtc().difference(DateTime.now().toUtc()).inSeconds.abs(), lessThan(5));
      c.dispose();
    });

    test('is ignored outside dev builds', () {
      final c = ProviderContainer(overrides: [envProvider.overrideWithValue(_env(Flavor.prod))]);
      c.read(devToolsProvider).travelBy(const Duration(days: 3));
      expect(c.read(timeTravelProvider), Duration.zero);
      expect(c.read(clockProvider).nowUtc().difference(DateTime.now().toUtc()).inSeconds.abs(), lessThan(5));
      c.dispose();
    });
  });

  test('zone override sticks across resumes until cleared', () async {
    const channel = MethodChannel('flutter_timezone');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => 'Europe/Paris',
    );
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    final h = TestHarness.create();
    final tools = h.read(devToolsProvider);
    tools.overrideZone('Asia/Tokyo');
    await h.read(deviceZoneProvider.notifier).refresh(); // an app resume
    expect(h.read(deviceZoneProvider), 'Asia/Tokyo');
    expect(h.read(deviceZoneProvider.notifier).isOverridden, isTrue);
    await tools.resetZone();
    expect(h.read(deviceZoneProvider), 'Europe/Paris');
    expect(h.read(deviceZoneProvider.notifier).isOverridden, isFalse);
    await h.dispose();
  });

  test('feature flags toggle at run time in dev builds only', () {
    final dev = ProviderContainer(overrides: [envProvider.overrideWithValue(_env(Flavor.dev))]);
    dev.read(devToolsProvider).toggleFlag('planner_views_m3');
    expect(dev.read(featureFlagsProvider), contains('planner_views_m3'));
    dev.read(devToolsProvider).toggleFlag('planner_views_m3');
    expect(dev.read(featureFlagsProvider), isEmpty);
    dev.dispose();
    final prod = ProviderContainer(overrides: [envProvider.overrideWithValue(_env(Flavor.prod))]);
    prod.read(devToolsProvider).toggleFlag('planner_views_m3');
    expect(prod.read(featureFlagsProvider), isEmpty);
    prod.dispose();
  });

  group('debug routes', () {
    Future<List<String>> routesFor(Flavor flavor) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      SessionController.initial = null;
      final c = ProviderContainer(
        overrides: [envProvider.overrideWithValue(_env(flavor)), appDatabaseProvider.overrideWithValue(db)],
      );
      final paths = _paths(c.read(routerProvider).configuration.routes);
      c.dispose();
      await db.close();
      return paths;
    }

    test('the prod flavor exposes no debug route', () async {
      expect(await routesFor(Flavor.prod), isNot(contains('/dev')));
    });

    test('the dev flavor has the debug menu (compiled in unless FLAVOR=prod)', () async {
      expect(Env.devToolsCompiled, isTrue, reason: 'tests run without FLAVOR=prod');
      expect(await routesFor(Flavor.dev), contains('/dev'));
    });
  });

  test('reset local data (local-only): every row goes, a fresh local account starts', () async {
    final started = <String>[];
    final h = TestHarness.create(
      overrides: [accountStartupProvider.overrideWithValue((c) async => started.add(c.read(currentUserIdProvider)))],
    );
    final oldId = await LocalAccount.ensureUserId(h.db);
    h.read(sessionProvider.notifier).set(AppSession(userId: oldId, mode: SessionMode.localOnly));
    await h.read(syncWriterProvider).run((tx) => tx.insert('categories', 'c1', {'name': 'Work', 'color': 1, 'sort_key': 'a0'}));
    await h.read(devToolsProvider).resetLocalData();
    final newId = h.read(currentUserIdProvider);
    expect(newId, isNot(oldId));
    expect(h.read(sessionProvider)!.isLocalOnly, isTrue);
    expect((await h.db.customSelect('SELECT COUNT(*) AS n FROM categories').getSingle()).data['n'], 0);
    expect((await h.db.customSelect('SELECT COUNT(*) AS n FROM sync_outbox').getSingle()).data['n'], 0);
    await Future<void>.delayed(Duration.zero);
    expect(started, [newId]);
    await h.dispose();
  });

  test('outbox entries are grouped by operation in push order', () {
    OutboxEntryView e(String op, int seq, {String state = 'pending'}) => OutboxEntryView(
      changeId: 'ch$seq',
      opId: op,
      seq: seq,
      table: 't',
      rowId: 'r$seq',
      op: 'update',
      fields: const ['name'],
      state: state,
      attempts: 0,
      enqueuedAt: DateTime.utc(2026, 9, 22),
    );
    final groups = groupOutbox([e('b', 3), e('a', 1), e('b', 2, state: 'failed'), e('c', 4)]);
    expect([for (final g in groups) g.opId], ['a', 'b', 'c']);
    expect([for (final x in groups[1].entries) x.seq], [2, 3]);
    expect(groups[1].hasFailures, isTrue);
    expect(groups[0].hasFailures, isFalse);
  });
}
