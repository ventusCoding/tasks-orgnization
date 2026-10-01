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
final identitiesProvider = FutureProvider.autoDispose<List<AuthIdentity>>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  final session = ref.watch(sessionProvider);
  if (repo == null || session == null || !session.isCloud) return const [];
  return repo.identities();
}, retry: (_, _) => null);

/// Authenticator-app factors (T1.5.17); empty for local-only and guest sessions.
final mfaFactorsProvider = FutureProvider.autoDispose<List<MfaFactor>>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  final session = ref.watch(sessionProvider);
  if (repo == null || session == null || !session.isCloud || session.isAnonymous) return const [];
  return repo.mfaFactors();
}, retry: (_, _) => null);

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

/// Account management (T1.5.11 upgrade & linking, T1.5.12 deletion, T1.5.13 profile, T1.5.17
/// two-step verification).
class AccountService {
  AccountService(this._ref);

  /// How long an e-mail re-authentication stays valid for the deletion's authenticator step.
  static const reauthWindow = Duration(minutes: 10);

  final Ref _ref;
  DateTime? _reauthenticatedAt;

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
  ///
  /// With two-step verification on, the server needs an aal2 session: without [mfaCode] this
  /// throws [AuthFailureCode.mfaRequired] after the e-mail step, and the caller asks for the
  /// authenticator code and calls again with only [mfaCode] (within [reauthWindow]).
  Future<void> deleteAccount({String? code, String? mfaCode}) async {
    final session = _ref.read(sessionProvider);
    if (session == null || !session.isCloud) throw const AuthFailure(AuthFailureCode.notConfigured);
    final email = session.email;
    final now = _ref.read(clockProvider).nowUtc();
    if (email != null && email.isNotEmpty) {
      final recent = _reauthenticatedAt;
      if (code != null || recent == null || now.difference(recent) > reauthWindow) {
        final user = await _repo.verifyEmailCode(email, normalizeOtp(code ?? ''));
        if (user.id != session.userId) throw const AuthFailure(AuthFailureCode.unknown, 'reauth returned another user');
        // The fresh sign-in emits an auth event; drain the binding queue now so its (idempotent)
        // bind can never land after the wipe below and resurrect the session.
        await _ref.read(authBindingProvider).bind(user);
        _reauthenticatedAt = now;
      }
    }
    if (_repo.mfaStepUpRequired) {
      if (mfaCode == null) throw const AuthFailure(AuthFailureCode.mfaRequired);
      await verifyMfa(mfaCode);
    }
    await _repo.deleteAccount();
    _reauthenticatedAt = null;
    await _ref.read(signOutServiceProvider).endSession();
  }

  /// The account has two-step verification and this session still needs the authenticator code.
  bool get mfaStepUpRequired => _ref.read(authRepositoryProvider)?.mfaStepUpRequired ?? false;

  /// Steps the session up to aal2 with an authenticator [code] (after sign-in, before deletion).
  Future<void> verifyMfa(String code) async {
    final verified = (await _repo.mfaFactors()).where((f) => f.verified).firstOrNull;
    if (verified == null) return;
    await _repo.verifyTotp(verified.id, normalizeOtp(code));
  }

  /// Two-step verification, step 1: a new key for the authenticator app.
  Future<TotpEnrollment> startMfaEnrollment() => _repo.enrollTotp();

  /// Step 2: the first code from the app confirms the factor (the session becomes aal2).
  Future<void> confirmMfaEnrollment(TotpEnrollment enrollment, String code) async {
    await _repo.verifyTotp(enrollment.factorId, normalizeOtp(code));
    _ref.invalidate(mfaFactorsProvider);
  }

  /// Turns two-step verification off: a current [code] proves possession (and gives the aal2
  /// session Supabase requires), then every factor is removed.
  Future<void> disableMfa(String code) async {
    final factors = await _repo.mfaFactors();
    final verified = factors.where((f) => f.verified).firstOrNull;
    if (verified != null) await _repo.verifyTotp(verified.id, normalizeOtp(code));
    for (final f in factors) {
      await _repo.unenrollMfa(f.id);
    }
    _ref.invalidate(mfaFactorsProvider);
  }
}
