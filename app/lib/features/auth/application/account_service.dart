import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/features/auth/application/auth_binding.dart';
import 'package:everslot/features/auth/application/auth_providers.dart';
import 'package:everslot/features/auth/application/sign_out_service.dart';
import 'package:everslot/features/auth/data/auth_prefs.dart';
import 'package:everslot/features/auth/domain/auth_models.dart';
import 'package:everslot/features/auth/domain/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sign-in methods of the signed-in account (empty in local-only mode). Errors (offline) surface
/// at once; refresh with `ref.invalidate(identitiesProvider)`.
final identitiesProvider = FutureProvider.autoDispose<List<AuthIdentity>>(
  (ref) async {
    final repo = ref.watch(authRepositoryProvider);
    final session = ref.watch(sessionProvider);
    if (repo == null || session == null || !session.isCloud) return const [];
    return repo.identities();
  },
  retry: (_, _) => null,
);

final authPrefsProvider = Provider<AuthPrefs>((ref) => AuthPrefs(ref.watch(appDatabaseProvider)));

/// The guest-account banner (T1.5.11): shown to anonymous accounts until dismissed; it comes back
/// a week after a dismissal (the risk doesn't go away until the account is upgraded).
final guestBannerProvider = NotifierProvider<GuestBannerController, bool>(GuestBannerController.new);

class GuestBannerController extends Notifier<bool> {
  static const snooze = Duration(days: 7);

  @override
  bool build() {
    final session = ref.watch(sessionProvider);
    if (session == null || !session.isAnonymous) return false;
    unawaited(_load());
    return false;
  }

  Future<void> _load() async {
    final at = await ref.read(authPrefsProvider).guestBannerDismissedAt();
    if (!ref.mounted) return;
    final now = ref.read(clockProvider).nowUtc();
    state = at == null || now.difference(at) >= snooze;
  }

  Future<void> dismiss() async {
    state = false;
    await ref.read(authPrefsProvider).dismissGuestBanner(ref.read(clockProvider).nowUtc());
  }
}

final accountServiceProvider = Provider<AccountService>(AccountService.new);

/// Account management (T1.5.11 upgrade & linking, T1.5.12 deletion, T1.5.13 profile).
class AccountService {
  AccountService(this._ref);

  final Ref _ref;

  AuthRepository get _repo =>
      _ref.read(authRepositoryProvider) ?? (throw const AuthFailure(AuthFailureCode.notConfigured));

  Future<void> _bind(AuthUser user) async {
    await _ref.read(authBindingProvider).bind(user);
    _ref.invalidate(identitiesProvider);
  }

  /// Guest → e-mail (same user id): sends a confirmation code to [email].
  Future<void> startEmailUpgrade(String email) => _repo.startEmailUpgrade(email.trim().toLowerCase());

  Future<void> confirmEmailUpgrade(String email, String code) async {
    final user = await _repo.confirmEmailUpgrade(email.trim().toLowerCase(), normalizeOtp(code));
    await _bind(user);
  }

  /// Links Google to the account (guest upgrade or an extra sign-in method).
  Future<void> linkGoogle() async => _bind(await _repo.linkGoogle());

  /// Links Apple; false when a browser flow was started (completion via the deep link).
  Future<bool> linkApple() async {
    final user = await _repo.linkApple();
    if (user == null) return false;
    await _bind(user);
    return true;
  }

  Future<void> unlink(AuthIdentity identity) async {
    await _repo.unlink(identity);
    _ref.invalidate(identitiesProvider);
  }

  /// Account deletion, step 1: re-authentication code to the account e-mail. Returns the e-mail,
  /// or null when the account has none (guest) — then no code is needed.
  Future<String?> startDeletion() async {
    final email = _ref.read(sessionProvider)?.email;
    if (email == null || email.isEmpty) return null;
    await _repo.sendEmailCode(email);
    return email;
  }

  /// Account deletion, step 2 (T1.5.12): a fresh sign-in with [code] proves it's the owner, then
  /// the request is recorded and the `account-delete` Edge Function deletes the account
  /// (storage objects, devices, jobs, auth user → cascades), and this device is wiped.
  Future<void> deleteAccount({String? code}) async {
    final session = _ref.read(sessionProvider);
    if (session == null || !session.isCloud) throw const AuthFailure(AuthFailureCode.notConfigured);
    final email = session.email;
    if (email != null && email.isNotEmpty) {
      final user = await _repo.verifyEmailCode(email, normalizeOtp(code ?? ''));
      if (user.id != session.userId) throw const AuthFailure(AuthFailureCode.unknown, 'reauth returned another user');
    }
    await _repo.deleteAccount();
    await _ref.read(signOutServiceProvider).endSession();
  }
}
