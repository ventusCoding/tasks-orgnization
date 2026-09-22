import 'package:drift/native.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/env/env.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/session/session.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalCupertinoLocalizations, GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

/// Shared test harness (T9.1.02): in-memory DB, local session, fixed clock.
class TestHarness {
  TestHarness._(this.db, this.container, this.clock);

  static bool _tzReady = false;

  static TestHarness create({DateTime? now, String userId = 'user-1', String zone = 'UTC'}) {
    if (!_tzReady) {
      tzdata.initializeTimeZones();
      _tzReady = true;
    }
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final clock = FakeClock(now ?? DateTime.utc(2026, 9, 22, 9));
    SessionController.initial = AppSession(userId: userId, mode: SessionMode.localOnly);
    DeviceZoneController.initialZone = zone;
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
      ],
    );
    return TestHarness._(db, container, clock);
  }

  final AppDatabase db;
  final ProviderContainer container;
  final FakeClock clock;

  T read<T>(ProviderListenable<T> provider) => container.read(provider);

  Future<void> dispose() async {
    container.dispose();
    await db.close();
  }
}

/// Pumps [child] inside localizations, theme and the harness' providers.
Future<void> pumpInApp(WidgetTester tester, TestHarness h, Widget child, {Locale locale = const Locale('en')}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: h.container,
      child: MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      ),
    ),
  );
}
