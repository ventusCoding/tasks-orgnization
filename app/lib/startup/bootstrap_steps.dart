import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/session/local_account.dart';
import 'package:everslot/core/session/local_only_choice.dart';
import 'package:everslot/core/session/session.dart';
import 'package:everslot/design_system/typography.dart';
import 'package:everslot/features/auth/application/auth_binding.dart';
import 'package:everslot/features/settings/application/settings_providers.dart';
import 'package:everslot/startup/bootstrap_runner.dart';
import 'package:everslot/startup/crash_reporter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

/// Names of the default startup steps, in order (T1.3.02).
abstract final class BootstrapSteps {
  static const logging = 'logging';
  static const environment = 'environment';
  static const timeZones = 'time zones';
  static const firebase = 'firebase';
  static const supabase = 'supabase';
  static const database = 'database';
  static const session = 'session';
  static const providers = 'providers';
  static const startupTasks = 'startup tasks';
}

/// The ordered startup sequence (T1.3.02): logging → env validation → time-zone database + device
/// zone → Firebase (optional) → Supabase (optional, secure session storage) → database → session →
/// providers → feature startup tasks. The caller then launches the app (or the recoverable error
/// screen when a required step failed).
List<BootstrapStep> defaultBootstrapSteps() => [
  BootstrapStep(BootstrapSteps.logging, (c) {
    AppLog.init();
    AppTypography.registerLicenses();
  }),
  BootstrapStep(BootstrapSteps.environment, (c) {
    c.env = c.platform.env(c.flavor);
    for (final warning in c.env.warnings) {
      c.log.info(warning);
    }
  }),
  BootstrapStep(BootstrapSteps.timeZones, (c) async {
    tzdata.initializeTimeZones();
    try {
      final zone = await c.platform.deviceTimeZone();
      if (zone != null && zone.isNotEmpty) {
        DeviceZoneController.initialZone = zone;
      }
    } on Object catch (e) {
      c.log.warning('Could not read the device time zone (${e.runtimeType}) — using UTC until it is known');
    }
  }),
  BootstrapStep(BootstrapSteps.firebase, (c) async {
    c.firebaseReady = await c.platform.initFirebase(c.env, c.handlers);
  }, optional: true),
  BootstrapStep(BootstrapSteps.supabase, (c) async {
    c.supabase = await c.platform.initSupabase(c.env);
  }, optional: true),
  BootstrapStep(BootstrapSteps.database, (c) async {
    final db = await c.platform.openDatabase();
    c.db = db;
    c.deviceId = await c.platform.loadDeviceId(db);
    final hlcState = await (db.select(db.localKv)..where((k) => k.key.equals('hlc_state'))).getSingleOrNull();
    HlcBootstrap.initialState = hlcState?.value;
    try {
      c.build = await c.platform.buildNumber();
    } on Object {
      // tests / unsupported platforms: keep the default build number
    }
  }),
  BootstrapStep(BootstrapSteps.session, (c) async {
    // Cloud user when signed in, local account in local-only mode (ADR-017).
    final supabase = c.supabase;
    if (supabase == null) {
      SessionController.initial = AppSession(
        userId: await LocalAccount.ensureUserId(c.db),
        mode: SessionMode.localOnly,
      );
      return;
    }
    final user = c.platform.cloudUser(supabase);
    if (user != null) {
      SessionController.initial = AppSession(
        userId: user.id,
        mode: SessionMode.cloud,
        email: user.email,
        isAnonymous: user.isAnonymous,
      );
    } else if (await LocalOnlyChoice.isChosen(c.db)) {
      // "Use on this device only" was chosen on the sign-in screen (ADR-017).
      SessionController.initial = AppSession(
        userId: await LocalAccount.ensureUserId(c.db),
        mode: SessionMode.localOnly,
      );
    } else {
      SessionController.initial = null;
    }
  }),
  BootstrapStep(BootstrapSteps.providers, (c) {
    c.container?.dispose(); // a retry rebuilds the container
    final container = ProviderContainer(
      overrides: [
        envProvider.overrideWithValue(c.env),
        appDatabaseProvider.overrideWithValue(c.db),
        deviceIdProvider.overrideWithValue(c.deviceId),
        appBuildProvider.overrideWithValue(c.build),
        supabaseClientProvider.overrideWithValue(c.supabase),
      ],
    );
    c.container = container;
    // Auth state → session (claim / wipe / re-auth), T1.5.02. Listens even while signed out so
    // magic links and OAuth redirects bind the new session.
    if (c.supabase != null) container.read(authBindingProvider);
    // Crash reports follow the Settings › Privacy opt-out (arch §6.15).
    if (c.handlers.reporter is CrashlyticsErrorReporter) {
      container.listen(
        privacySettingsProvider,
        (_, settings) => CrashlyticsErrorReporter.instance.enabled = settings.crashReporting,
        fireImmediately: true,
      );
    }
  }),
  BootstrapStep(BootstrapSteps.startupTasks, (c) => c.platform.runStartupTasks(c.container!)),
];
