import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/database/database_encryption.dart';
import 'package:everslot/core/env/env.dart';
import 'package:everslot/core/errors/global_error_handlers.dart';
import 'package:everslot/core/session/device_identity.dart';
import 'package:everslot/core/session/secure_session_storage.dart';
import 'package:everslot/firebase_options.dart';
import 'package:everslot/startup/crash_reporter.dart';
import 'package:everslot/startup/startup_tasks.dart' as tasks;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The signed-in Supabase user at startup, as far as the session needs it.
class CloudUser {
  const CloudUser({required this.id, this.email, this.isAnonymous = false});

  final String id;
  final String? email;
  final bool isAnonymous;
}

/// Everything startup needs from the outside world (plugins, platform channels, the database
/// file, `runApp`). Tests replace it with fakes to exercise the step order and the failure paths
/// without any plugin.
abstract class BootstrapPlatform {
  const BootstrapPlatform();

  /// Build configuration (`--dart-define-from-file`).
  Env env(Flavor flavor);

  /// IANA zone of the device, or null when it can't be read.
  Future<String?> deviceTimeZone();

  /// Store build number (sync min-version gate).
  Future<int> buildNumber();

  /// Initialises Firebase when configured; true when it is ready. May register a crash reporter
  /// on [handlers].
  Future<bool> initFirebase(Env env, GlobalErrorHandlers handlers);

  /// Initialises Supabase (secure session storage) when configured; null in local-only mode.
  Future<SupabaseClient?> initSupabase(Env env);

  /// The user signed in on [client] (restored from secure storage), if any.
  CloudUser? cloudUser(SupabaseClient client);

  Future<AppDatabase> openDatabase();

  /// Per-install device id (secure storage, database fallback).
  Future<String> loadDeviceId(AppDatabase db);

  /// Feature startup hooks (`startup_tasks.dart`).
  Future<void> runStartupTasks(ProviderContainer container);

  /// Replaces the widget tree (`runApp`).
  void launch(Widget root);
}

/// The production implementation.
class RealBootstrapPlatform extends BootstrapPlatform {
  const RealBootstrapPlatform();

  @override
  Env env(Flavor flavor) => Env.fromEnvironment(flavor: flavor);

  @override
  Future<String?> deviceTimeZone() async => (await FlutterTimezone.getLocalTimezone()).identifier;

  @override
  Future<int> buildNumber() async => int.tryParse((await PackageInfo.fromPlatform()).buildNumber) ?? 1;

  @override
  Future<bool> initFirebase(Env env, GlobalErrorHandlers handlers) async {
    if (!env.firebaseEnabled || !AppFirebaseOptions.isConfigured) {
      return false;
    }
    await Firebase.initializeApp(options: AppFirebaseOptions.currentPlatform);
    // Release builds report uncaught errors (opt-out in Settings › Privacy, arch §6.15).
    if (!kDebugMode) handlers.reporter = CrashlyticsErrorReporter.instance;
    return true;
  }

  @override
  Future<SupabaseClient?> initSupabase(Env env) async {
    if (!env.isSupabaseConfigured) return null;
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
    return Supabase.instance.client;
  }

  @override
  CloudUser? cloudUser(SupabaseClient client) {
    final user = client.auth.currentUser;
    return user == null ? null : CloudUser(id: user.id, email: user.email, isAnonymous: user.isAnonymous);
  }

  @override
  Future<AppDatabase> openDatabase() async {
    // Encrypt / decrypt the file first when the user changed the setting (T8.3.15).
    await DatabaseEncryption().migrateIfNeeded();
    return AppDatabase();
  }

  @override
  Future<String> loadDeviceId(AppDatabase db) => DeviceIdentity.load(db);

  @override
  Future<void> runStartupTasks(ProviderContainer container) => tasks.runStartupTasks(container);

  @override
  // ignore: riverpod_lint/missing_provider_scope, bootstrap passes an UncontrolledProviderScope as the root.
  void launch(Widget root) => runApp(root);
}
