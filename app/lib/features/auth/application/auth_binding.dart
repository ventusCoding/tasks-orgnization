import 'dart:async';

import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/session/local_account.dart';
import 'package:everslot/core/session/local_data_owner.dart';
import 'package:everslot/core/session/local_data_wiper.dart';
import 'package:everslot/core/session/local_only_choice.dart';
import 'package:everslot/core/session/session.dart';
import 'package:everslot/core/sync/sync_service.dart';
import 'package:everslot/core/sync/sync_status.dart';
import 'package:everslot/features/auth/application/auth_providers.dart';
import 'package:everslot/features/auth/domain/auth_models.dart';
import 'package:everslot/startup/profile_bootstrap.dart';
import 'package:everslot/startup/startup_tasks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Called before another account's local data is wiped (account switch with unsynced changes):
/// receives the previous owner id. The settings feature plugs a backup export here.
typedef BeforeAccountWipe = Future<void> Function(String previousOwner);

/// Keeps [sessionProvider] in step with Supabase Auth (T1.5.02) and protects local data:
///
/// - first cloud sign-in on a device with local-only data → the data is claimed by the account
///   (`LocalAccount.claimForCloudUser`);
/// - a different account signs in on a device holding another account's data → wipe before the
///   first pull (T1.5.08); the sync engine refuses to run until the data is bound;
/// - the session ends unexpectedly (refresh token rejected) → the app stays usable offline and a
///   non-blocking re-auth prompt appears; the outbox is preserved (T1.5.14);
/// - the device is revoked / the build is unsupported → session issues for the guard UI.
final authBindingProvider = Provider<AuthBinding>((ref) {
  final binding = AuthBinding(ref)..start();
  ref.onDispose(binding.dispose);
  return binding;
});

/// Optional backup hook (see [BeforeAccountWipe]).
final beforeAccountWipeProvider = Provider<BeforeAccountWipe?>((ref) => null);

class AuthBinding {
  AuthBinding(this._ref);

  final Ref _ref;
  static final _log = AppLog.get('auth');

  StreamSubscription<AuthUser?>? _sub;
  Future<void> _queue = Future.value();
  final Set<String> _profileEnsuredFor = {};
  void Function()? _detachService;

  /// Set by the sign-out flow so the resulting "signed out" event isn't treated as an
  /// unexpected session loss.
  bool expectSignOut = false;

  void start() {
    final repo = _ref.read(authRepositoryProvider);
    if (repo != null) {
      _sub = repo.userChanges.listen((user) => unawaited(_enqueue(() => _onUser(user))));
      final current = repo.currentUser;
      if (current != null) unawaited(bind(current));
    }
    _ref.listen<SyncService?>(syncServiceProvider, (_, next) => _attach(next), fireImmediately: true);
  }

  void dispose() {
    unawaited(_sub?.cancel());
    _detachService?.call();
  }

  /// Binds [user] as the current session (serialized with auth events).
  Future<void> bind(AuthUser user) => _enqueue(() => _bind(user));

  Future<void> _enqueue(Future<void> Function() task) {
    final next = _queue.then((_) => task()).catchError((Object e, StackTrace st) {
      _log.warning('auth binding task failed', e, st);
    });
    _queue = next;
    return next;
  }

  Future<void> _onUser(AuthUser? user) async {
    if (user != null) return _bind(user);
    if (expectSignOut) return;
    final session = _ref.read(sessionProvider);
    if (session != null && session.isCloud) {
      // Refresh token rejected: keep the session and the data, ask to sign in again.
      _ref.read(sessionIssuesProvider.notifier).raise(SessionIssue.reauthRequired);
    }
  }

  Future<void> _bind(AuthUser user) async {
    final db = _ref.read(appDatabaseProvider);
    final owner = await LocalDataOwner.read(db);
    if (owner != user.id) {
      if (owner == null) {
        await LocalAccount.claimForCloudUser(db, user.id);
      } else {
        _log.info('account switch on this device: wiping the previous account data');
        final hook = _ref.read(beforeAccountWipeProvider);
        if (hook != null) {
          try {
            await hook(owner);
          } on Object catch (e) {
            _log.warning('backup before wipe failed', e);
          }
        }
        await LocalDataWiper.wipeAll(db);
      }
      await LocalDataOwner.write(db, user.id);
    }
    await LocalOnlyChoice.clear(db);
    final session = AppSession(
      userId: user.id,
      mode: SessionMode.cloud,
      email: user.email,
      isAnonymous: user.isAnonymous,
    );
    final previous = _ref.read(sessionProvider);
    _ref.read(sessionIssuesProvider.notifier).resolve(SessionIssue.reauthRequired);
    if (previous != session) _ref.read(sessionProvider.notifier).set(session);
    if (previous?.userId != user.id) {
      // New account on this device: its startup tasks (profile/defaults wait for the first pull).
      unawaited(runStartupTasks(_ref.container));
    }
    unawaited(_ref.read(syncServiceProvider)?.syncNow(manual: true));
  }

  void _attach(SyncService? service) {
    _detachService?.call();
    _detachService = null;
    if (service == null) return;
    final issues = _ref.read(sessionIssuesProvider.notifier);
    void onRevoked() {
      if (service.revoked.value) issues.raise(SessionIssue.deviceRevoked);
    }

    void onStatus() {
      final status = service.status.value;
      if (status.errorCode == SyncErrorCodes.unsupportedClient) {
        issues.raise(SessionIssue.updateRequired);
      } else if (status.phase == SyncPhase.idle) {
        issues.resolve(SessionIssue.updateRequired);
      }
      if (status.errorCode == SyncErrorCodes.notAuthenticated) unawaited(_checkSession());
      if (status.phase == SyncPhase.idle && status.lastSuccessAt != null) unawaited(_afterFirstPull());
    }

    service.revoked.addListener(onRevoked);
    service.status.addListener(onStatus);
    onRevoked();
    _detachService = () {
      try {
        service.revoked.removeListener(onRevoked);
        service.status.removeListener(onStatus);
      } on Object {
        // Already disposed with its provider.
      }
    };
  }

  /// A 401 from the API: try a silent refresh; if the refresh token is dead, ask to re-auth.
  Future<void> _checkSession() async {
    final repo = _ref.read(authRepositoryProvider);
    if (repo == null) return;
    try {
      if (!await repo.refreshSession()) {
        _ref.read(sessionIssuesProvider.notifier).raise(SessionIssue.reauthRequired);
      }
    } on Object {
      // Offline: retry on the next sync error.
    }
  }

  /// Profile and default rows are created only after the first successful pull in cloud mode,
  /// so a second device never overwrites the account's profile with its own defaults (T1.5.05).
  Future<void> _afterFirstPull() async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId.isEmpty || !_profileEnsuredFor.add(userId)) return;
    try {
      await ensureProfileAndDefaults(_ref.container);
    } on Object catch (e) {
      _profileEnsuredFor.remove(userId);
      _log.warning('profile bootstrap after first pull failed', e);
    }
  }
}
