import 'dart:async';
import 'dart:io';

import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/session/local_data_wiper.dart';
import 'package:everslot/core/sync/background_sync.dart';
import 'package:everslot/core/sync/sync_api.dart';
import 'package:everslot/features/auth/application/auth_binding.dart';
import 'package:everslot/features/auth/application/auth_providers.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Result of [SignOutService.signOut].
enum SignOutOutcome {
  signedOut,

  /// Unsynced changes would be lost: ask the user (export / cancel / sign out anyway).
  pendingChanges,
}

class SignOutResult {
  const SignOutResult(this.outcome, {this.pending = 0});

  final SignOutOutcome outcome;

  /// Outbox entries not accepted by the server (pending + failed).
  final int pending;
}

/// Best-effort work that needs the still-valid session or OS state (T1.5.07): each entry is
/// time-boxed and failures are logged, never blocking the sign-out.
typedef SignOutCleanup = Future<void> Function();

/// Cleanups run before the session ends: null the push token server-side (the device stops
/// receiving pushes for this account) and cancel scheduled local notifications.
final signOutCleanupsProvider = Provider<List<SignOutCleanup>>(
  (ref) => [
    () async {
      final api = ref.read(syncApiProvider);
      if (api == null || !(ref.read(sessionProvider)?.isCloud ?? false)) return;
      await api.reportDeviceState(ref.read(activeDeviceIdProvider), {
        DeviceStateKeys.pushToken: null,
        DeviceStateKeys.pushEnabled: false,
      });
    },
    () => ref.read(localSchedulerProvider).clearAll(),
    BackgroundSync.cancelPeriodic, // no background sync without a session (T1.4.17)
  ],
);

/// Directories whose user files are deleted on sign-out (null = the app's documents, support and
/// cache directories). Overridden in tests.
final wipeFileRootsProvider = Provider<List<Directory>?>((ref) => null);

final signOutServiceProvider = Provider<SignOutService>(SignOutService.new);

/// Sign-out (T1.5.07), also used after a device revocation (T1.5.14) and account deletion
/// (T1.5.12): final push → pending-changes guard → server/OS cleanups → session end → local
/// wipe (every table, caches, user files) → Supabase/Google sign-out (secure session removed).
class SignOutService {
  SignOutService(this._ref);

  final Ref _ref;
  static final _log = AppLog.get('auth.signout');

  /// Budget for the final push and each cleanup.
  static const finalPushTimeout = Duration(seconds: 20);
  static const cleanupTimeout = Duration(seconds: 5);

  /// Local changes the server hasn't accepted yet (they'd be lost by a sign-out).
  Future<int> pendingChanges() async {
    final db = _ref.read(appDatabaseProvider);
    final row = await db.customSelect('SELECT COUNT(*) AS n FROM sync_outbox').getSingle();
    return row.data['n'] as int? ?? 0;
  }

  /// Signs out. Unless [force], a final push is attempted first and the call returns
  /// [SignOutOutcome.pendingChanges] when changes would still be lost. [rotateDevice] gives the
  /// install a new device id (after the server revoked it).
  Future<SignOutResult> signOut({bool force = false, bool rotateDevice = false}) async {
    if (!force) {
      var pending = await pendingChanges();
      if (pending > 0) {
        await _finalPush();
        pending = await pendingChanges();
      }
      if (pending > 0) return SignOutResult(SignOutOutcome.pendingChanges, pending: pending);
    }
    await endSession(rotateDevice: rotateDevice);
    return const SignOutResult(SignOutOutcome.signedOut);
  }

  /// Ends the session without the pending-changes guard: cleanups, wipe, auth sign-out.
  Future<void> endSession({bool rotateDevice = false}) async {
    final ref = _ref;
    final db = ref.read(appDatabaseProvider);
    final repo = ref.read(authRepositoryProvider);
    final binding = ref.read(authBindingProvider);
    final session = ref.read(sessionProvider.notifier);
    final issues = ref.read(sessionIssuesProvider.notifier);
    final deviceId = ref.read(activeDeviceIdProvider.notifier);
    final roots = ref.read(wipeFileRootsProvider);

    for (final cleanup in ref.read(signOutCleanupsProvider)) {
      try {
        await cleanup().timeout(cleanupTimeout);
      } on Object catch (e) {
        _log.info('sign-out cleanup skipped: $e');
      }
    }
    binding.expectSignOut = true;
    try {
      // Ending the session disposes the sync engine (Broadcast channel closed) and the
      // notification engine's session listener drops its state.
      session.set(null);
      await LocalDataWiper.wipeAll(db, fileRoots: roots);
      if (rotateDevice) await deviceId.rotate();
      await repo?.signOut();
      issues.clear();
    } finally {
      binding.expectSignOut = false;
    }
  }

  Future<void> _finalPush() async {
    final service = _ref.read(syncServiceProvider);
    if (service == null) return;
    try {
      await service.syncNow(manual: true).timeout(finalPushTimeout);
    } on Object catch (e) {
      _log.info('final push failed: $e');
    }
  }
}
