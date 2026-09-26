import 'dart:async';

import 'package:everslot/app/app.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/env/env.dart';
import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/session/device_identity.dart';
import 'package:everslot/core/session/local_account.dart';
import 'package:everslot/core/session/local_only_choice.dart';
import 'package:everslot/core/session/secure_session_storage.dart';
import 'package:everslot/core/session/session.dart';
import 'package:everslot/features/auth/application/auth_binding.dart';
import 'package:everslot/firebase_options.dart';
import 'package:everslot/startup/startup_tasks.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

/// App startup (T1.3.02). Order matters: logging → env → time zones → Firebase (optional) →
/// Supabase (optional) → database → device id → session → providers → runApp.
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLog.init();
  final log = AppLog.get('bootstrap');
  final env = Env.fromEnvironment(flavor: flavor);
  for (final w in env.warnings) {
    log.info(w);
  }

  tzdata.initializeTimeZones();
  try {
    DeviceZoneController.initialZone = (await FlutterTimezone.getLocalTimezone()).identifier;
  } on Object catch (e) {
    log.warning('Could not read device time zone', e);
  }

  var firebaseReady = false;
  if (env.firebaseEnabled && DefaultFirebaseOptions.isConfigured) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      firebaseReady = true;
      if (!kDebugMode) {
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          unawaited(FirebaseCrashlytics.instance.recordError(error, stack, fatal: true));
          return true;
        };
      }
    } on Object catch (e) {
      log.warning('Firebase init failed — continuing without push/Crashlytics', e);
    }
  }
  if (!firebaseReady) {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      log.severe('Flutter error', details.exception, details.stack);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      log.severe('Uncaught error', error, stack);
      return true;
    };
  }

  SupabaseClient? supabase;
  if (env.isSupabaseConfigured) {
    try {
      await Supabase.initialize(
        url: env.supabaseUrl,
        publishableKey: env.supabasePublishableKey,
        // Session + PKCE verifier in the Keychain/Keystore, never plain preferences (T1.5.02).
        authOptions: FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          localStorage: SecureSessionStorage(),
          pkceAsyncStorage: SecurePkceStorage(),
        ),
      );
      supabase = Supabase.instance.client;
    } on Object catch (e) {
      log.severe('Supabase init failed — falling back to local-only mode', e);
    }
  }

  final db = AppDatabase();
  final deviceId = await DeviceIdentity.load(db);
  final hlcState = await (db.select(db.localKv)..where((k) => k.key.equals('hlc_state')))
      .getSingleOrNull();
  HlcBootstrap.initialState = hlcState?.value;

  // Session: cloud user when signed in, local account in local-only mode.
  if (supabase == null) {
    SessionController.initial = AppSession(
      userId: await LocalAccount.ensureUserId(db),
      mode: SessionMode.localOnly,
    );
  } else {
    final user = supabase.auth.currentUser;
    if (user != null) {
      SessionController.initial = AppSession(
        userId: user.id,
        mode: SessionMode.cloud,
        email: user.email,
        isAnonymous: user.isAnonymous,
      );
    } else if (await LocalOnlyChoice.isChosen(db)) {
      // "Use on this device only" was chosen on the sign-in screen (ADR-017).
      SessionController.initial = AppSession(
        userId: await LocalAccount.ensureUserId(db),
        mode: SessionMode.localOnly,
      );
    } else {
      SessionController.initial = null;
    }
  }

  var build = 1;
  try {
    build = int.tryParse((await PackageInfo.fromPlatform()).buildNumber) ?? 1;
  } on Object {
    // tests / unsupported platforms
  }

  final container = ProviderContainer(
    overrides: [
      envProvider.overrideWithValue(env),
      appDatabaseProvider.overrideWithValue(db),
      deviceIdProvider.overrideWithValue(deviceId),
      appBuildProvider.overrideWithValue(build),
      supabaseClientProvider.overrideWithValue(supabase),
    ],
  );

  // Auth state → session (claim / wipe / re-auth), T1.5.02. Listens even while signed out so
  // magic links and OAuth redirects bind the new session.
  if (supabase != null) container.read(authBindingProvider);

  await runStartupTasks(container);

  runApp(UncontrolledProviderScope(container: container, child: const EverslotApp()));
}
