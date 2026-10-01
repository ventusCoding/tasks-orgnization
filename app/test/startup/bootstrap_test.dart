import 'dart:async';
import 'dart:ui' show ErrorCallback, PlatformDispatcher;

import 'package:drift/native.dart';
import 'package:everslot/bootstrap.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/env/env.dart';
import 'package:everslot/core/errors/global_error_handlers.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/session/session.dart';
import 'package:everslot/startup/bootstrap_error_app.dart';
import 'package:everslot/startup/bootstrap_platform.dart';
import 'package:everslot/startup/bootstrap_runner.dart';
import 'package:everslot/startup/bootstrap_steps.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show CircularProgressIndicator;
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

/// Platform double: records every call in order, no plugin involved.
class FakePlatform extends BootstrapPlatform {
  FakePlatform({this.failOn = const {}});

  /// Method names that throw once (`'openDatabase'`, `'initFirebase'`, …).
  final Set<String> failOn;
  final calls = <String>[];
  final launched = <Widget>[];
  final databases = <AppDatabase>[];
  String? zone = 'Africa/Tunis';

  Future<T> _call<T>(String name, FutureOr<T> Function() body) async {
    calls.add(name);
    if (failOn.contains(name)) {
      // Fail once: a retry succeeds.
      failOn.remove(name);
      throw StateError('$name failed (fake)');
    }
    return body();
  }

  @override
  Env env(Flavor flavor) {
    calls.add('env');
    return Env(
      flavor: flavor,
      supabaseUrl: '',
      supabasePublishableKey: '',
      firebaseEnabled: false,
      featureFlags: const {},
    );
  }

  @override
  Future<String?> deviceTimeZone() => _call('deviceTimeZone', () => zone);

  @override
  Future<int> buildNumber() => _call('buildNumber', () => 42);

  @override
  Future<bool> initFirebase(Env env, GlobalErrorHandlers handlers) => _call('initFirebase', () => false);

  @override
  Future<SupabaseClient?> initSupabase(Env env) => _call<SupabaseClient?>('initSupabase', () => null);

  @override
  CloudUser? cloudUser(SupabaseClient client) => null;

  @override
  Future<AppDatabase> openDatabase() => _call('openDatabase', () {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    databases.add(db);
    return db;
  });

  @override
  Future<String> loadDeviceId(AppDatabase db) => _call('loadDeviceId', () => 'device-fake');

  @override
  Future<void> runStartupTasks(ProviderContainer container) => _call('runStartupTasks', () {});

  @override
  void launch(Widget root) {
    calls.add('launch');
    launched.add(root);
  }
}

/// T1.3.02: the ordered startup sequence and its failure paths.
void main() {
  late FakePlatform platform;
  late BootstrapContext context;
  late List<ProviderContainer> containers;
  late FlutterExceptionHandler? oldFlutterHandler;
  late ErrorCallback? oldPlatformHandler;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    oldFlutterHandler = FlutterError.onError;
    oldPlatformHandler = PlatformDispatcher.instance.onError;
    containers = [];
    platform = FakePlatform();
  });

  tearDown(() async {
    FlutterError.onError = oldFlutterHandler;
    PlatformDispatcher.instance.onError = oldPlatformHandler;
    for (final c in containers) {
      c.dispose();
    }
    for (final db in platform.databases) {
      await db.close();
    }
  });

  BootstrapRunner runnerFor(FakePlatform p, {List<BootstrapStep>? steps}) {
    platform = p;
    context = BootstrapContext(flavor: Flavor.dev, platform: p, handlers: GlobalErrorHandlers(releaseMode: false));
    final runner = BootstrapRunner(steps ?? defaultBootstrapSteps(), context);
    addTearDown(() => context.container?.dispose());
    return runner;
  }

  group('step list', () {
    test('runs in the documented order; only Firebase and Supabase are optional', () {
      final steps = defaultBootstrapSteps();
      expect(steps.map((s) => s.name), [
        BootstrapSteps.logging,
        BootstrapSteps.environment,
        BootstrapSteps.timeZones,
        BootstrapSteps.firebase,
        BootstrapSteps.supabase,
        BootstrapSteps.database,
        BootstrapSteps.session,
        BootstrapSteps.providers,
        BootstrapSteps.startupTasks,
      ]);
      expect(steps.where((s) => s.optional).map((s) => s.name), [BootstrapSteps.firebase, BootstrapSteps.supabase]);
    });
  });

  group('BootstrapRunner with the default steps', () {
    test('local-only start: every step runs once, in order, and the app can launch', () async {
      final runner = runnerFor(FakePlatform());
      final failure = await runner.run();
      expect(failure, isNull);
      expect(platform.calls, [
        'env',
        'deviceTimeZone',
        'initFirebase',
        'initSupabase',
        'openDatabase',
        'loadDeviceId',
        'buildNumber',
        'runStartupTasks',
      ]);
      expect(runner.timings.keys, defaultBootstrapSteps().map((s) => s.name));
      expect(runner.skipped, isEmpty);
      // Results are exposed to the app through provider overrides.
      final container = context.container!;
      expect(container.read(deviceIdProvider), 'device-fake');
      expect(container.read(appBuildProvider), 42);
      expect(container.read(supabaseClientProvider), isNull);
      expect(container.read(envProvider).isDev, isTrue);
      expect(identical(container.read(appDatabaseProvider), context.db), isTrue);
      // Session: a local account (Supabase isn't configured).
      expect(SessionController.initial!.mode, SessionMode.localOnly);
      expect(SessionController.initial!.userId, isNotEmpty);
      expect(DeviceZoneController.initialZone, 'Africa/Tunis');
    });

    test('an unreadable device time zone only logs: startup goes on', () async {
      final runner = runnerFor(FakePlatform(failOn: {'deviceTimeZone'}));
      expect(await runner.run(), isNull);
      expect(runner.skipped, isEmpty, reason: 'handled inside the step, not skipped');
      expect(platform.calls, contains('openDatabase'));
    });

    test('Firebase and Supabase failures are skipped: the app starts in local-only mode', () async {
      final runner = runnerFor(FakePlatform(failOn: {'initFirebase', 'initSupabase'}));
      expect(await runner.run(), isNull);
      expect(runner.skipped, [BootstrapSteps.firebase, BootstrapSteps.supabase]);
      expect(context.firebaseReady, isFalse);
      expect(context.supabase, isNull);
      expect(SessionController.initial!.mode, SessionMode.localOnly);
      expect(platform.calls, containsAllInOrder(['initFirebase', 'initSupabase', 'openDatabase', 'runStartupTasks']));
    });

    test('a database failure stops startup at that step: later steps never run', () async {
      final runner = runnerFor(FakePlatform(failOn: {'openDatabase'}));
      final failure = await runner.run();
      expect(failure, isNotNull);
      expect(failure!.step, BootstrapSteps.database);
      expect(failure.error, isA<StateError>());
      expect(failure.index, 5);
      expect(platform.calls, isNot(contains('loadDeviceId')));
      expect(platform.calls, isNot(contains('runStartupTasks')));
      expect(context.container, isNull);
    });

    test('retry resumes at the failed step without repeating the earlier ones', () async {
      final runner = runnerFor(FakePlatform(failOn: {'openDatabase'}));
      final failure = await runner.run();
      final zoneReads = platform.calls.where((c) => c == 'deviceTimeZone').length;
      expect(await runner.run(from: failure!.index), isNull);
      expect(
        platform.calls.where((c) => c == 'deviceTimeZone'),
        hasLength(zoneReads),
        reason: 'earlier steps are not re-run',
      );
      expect(platform.calls.where((c) => c == 'openDatabase'), hasLength(2));
      expect(platform.calls.last, 'runStartupTasks');
      expect(context.container, isNotNull);
    });

    test('reading a value before its step ran names the missing step', () {
      runnerFor(FakePlatform());
      expect(() => context.db, throwsA(isA<StateError>().having((e) => e.message, 'message', contains('database'))));
      expect(() => context.env, throwsStateError);
    });

    test('a failing startup task list does not stop the app (tasks catch their own errors)', () async {
      final runner = runnerFor(
        FakePlatform(),
        steps: [
          BootstrapStep('one', (c) => c.log.info('one')),
          BootstrapStep('two', (c) => throw const FormatException('bad'), optional: true),
          BootstrapStep('three', (c) => c.log.info('three')),
        ],
      );
      expect(await runner.run(), isNull);
      expect(runner.skipped, ['two']);
      expect(runner.timings.keys, ['one', 'three']);
    });
  });

  group('bootstrap() entry point', () {
    test('runs the steps and launches the app root', () async {
      final p = platform = FakePlatform();
      await bootstrap(
        Flavor.dev,
        platform: p,
        steps: [BootstrapStep('providers', (c) => c.container = ProviderContainer())],
        handlers: GlobalErrorHandlers(releaseMode: false),
      );
      expect(p.launched, hasLength(1));
      expect(p.launched.single, isA<UncontrolledProviderScope>());
      final scope = p.launched.single as UncontrolledProviderScope;
      containers.add(scope.container);
    });

    test('a required step failure launches the recoverable error screen; retry relaunches the app', () async {
      final p = platform = FakePlatform();
      var attempts = 0;
      await bootstrap(
        Flavor.dev,
        platform: p,
        steps: [
          BootstrapStep('boom', (c) {
            attempts++;
            if (attempts == 1) throw StateError('first attempt fails');
          }),
          BootstrapStep('providers', (c) => c.container = ProviderContainer()),
        ],
        handlers: GlobalErrorHandlers(releaseMode: false),
      );
      expect(p.launched.single, isA<BootstrapErrorApp>());
      final errorApp = p.launched.single as BootstrapErrorApp;
      expect(errorApp.failure.step, 'boom');
      await errorApp.onRetry();
      expect(attempts, 2);
      expect(p.launched, hasLength(2));
      expect(p.launched.last, isA<UncontrolledProviderScope>());
      containers.add((p.launched.last as UncontrolledProviderScope).container);
    });

    test('an uncaught async error in the bootstrap zone is handled, not fatal', () async {
      final p = platform = FakePlatform();
      final handlers = GlobalErrorHandlers(releaseMode: false);
      await bootstrap(
        Flavor.dev,
        platform: p,
        steps: [
          BootstrapStep('leaky', (c) {
            unawaited(Future<void>.delayed(Duration.zero, () => throw StateError('nobody awaits me')));
            c.container = ProviderContainer();
          }),
        ],
        handlers: handlers,
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(handlers.handledCount, 1);
      expect(p.launched.single, isA<UncontrolledProviderScope>());
      containers.add((p.launched.single as UncontrolledProviderScope).container);
    });
  });

  group('BootstrapErrorApp', () {
    BootstrapFailure failure() => BootstrapFailure(
      step: BootstrapSteps.database,
      index: 5,
      error: StateError('disk I/O error'),
      stack: StackTrace.fromString('#0 main (file.dart:1:1)'),
    );

    testWidgets('dev: friendly message, retry and the failing step with the error', (tester) async {
      var retries = 0;
      await tester.pumpWidget(BootstrapErrorApp(failure: failure(), onRetry: () async => retries++, showDetails: true));
      await tester.pump();
      expect(find.text("Everslot couldn't start"), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byKey(const ValueKey('bootstrap-details')), findsOneWidget);
      expect(find.textContaining('step: database'), findsOneWidget);
      expect(find.textContaining('disk I/O error'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('bootstrap-retry')));
      await tester.pump();
      expect(retries, 1);
    });

    testWidgets('prod: friendly message and retry only, no technical details', (tester) async {
      await tester.pumpWidget(BootstrapErrorApp(failure: failure(), onRetry: () async {}));
      await tester.pump();
      expect(find.text("Everslot couldn't start"), findsOneWidget);
      expect(find.byKey(const ValueKey('bootstrap-retry')), findsOneWidget);
      expect(find.byKey(const ValueKey('bootstrap-details')), findsNothing);
      expect(find.textContaining('disk I/O error'), findsNothing);
      expect(find.textContaining('StateError'), findsNothing);
    });

    testWidgets('a retry shows progress until it finishes', (tester) async {
      final done = Completer<void>();
      await tester.pumpWidget(BootstrapErrorApp(failure: failure(), onRetry: () => done.future));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('bootstrap-retry')));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(const ValueKey('bootstrap-retry')), findsNothing);
      done.complete();
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('bootstrap-retry')), findsOneWidget);
    });

    testWidgets('French and Arabic (RTL) with text scale 2.0 do not overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final locale in [const Locale('fr'), const Locale('ar')]) {
        tester.platformDispatcher.localesTestValue = [locale];
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        await tester.pumpWidget(BootstrapErrorApp(failure: failure(), onRetry: () async {}, showDetails: true));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: locale.languageCode);
        expect(find.byKey(const ValueKey('bootstrap-retry')), findsOneWidget);
        final direction = Directionality.of(tester.element(find.byKey(const ValueKey('bootstrap-retry'))));
        expect(direction, locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr);
      }
      addTearDown(tester.platformDispatcher.clearAllTestValues);
    });
  });
}
