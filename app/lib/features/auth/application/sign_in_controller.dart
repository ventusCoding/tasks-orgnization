import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/session/local_account.dart';
import 'package:everslot/core/session/local_only_choice.dart';
import 'package:everslot/core/session/session.dart';
import 'package:everslot/features/auth/application/auth_binding.dart';
import 'package:everslot/features/auth/application/auth_providers.dart';
import 'package:everslot/features/auth/domain/auth_models.dart';
import 'package:everslot/features/auth/domain/auth_repository.dart';
import 'package:everslot/startup/startup_tasks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SignInStep { start, code }

/// UI state of the sign-in screen (T1.5.03).
class SignInState {
  const SignInState({
    this.step = SignInStep.start,
    this.email = '',
    this.busy,
    this.error,
    this.resendAvailableAt,
    this.browserFlowStarted = false,
  });

  final SignInStep step;
  final String email;

  /// The method currently running (drives per-button progress), null when idle.
  final AuthMethod? busy;
  final AuthFailureCode? error;

  /// When "Resend code" becomes available again (60 s cooldown).
  final DateTime? resendAvailableAt;

  /// An external browser flow (Apple on Android) is waiting for the deep link.
  final bool browserFlowStarted;

  bool get isBusy => busy != null;

  SignInState copyWith({
    SignInStep? step,
    String? email,
    AuthMethod? busy,
    bool clearBusy = false,
    AuthFailureCode? error,
    bool clearError = false,
    DateTime? resendAvailableAt,
    bool? browserFlowStarted,
  }) => SignInState(
    step: step ?? this.step,
    email: email ?? this.email,
    busy: clearBusy ? null : (busy ?? this.busy),
    error: clearError ? null : (error ?? this.error),
    resendAvailableAt: resendAvailableAt ?? this.resendAvailableAt,
    browserFlowStarted: browserFlowStarted ?? this.browserFlowStarted,
  );
}

final signInControllerProvider = NotifierProvider.autoDispose<SignInController, SignInState>(
  SignInController.new,
);

class SignInController extends Notifier<SignInState> {
  static const resendCooldown = Duration(seconds: 60);

  @override
  SignInState build() => const SignInState();

  DateTime _now() => ref.read(clockProvider).nowUtc();

  /// State updates after an async gap: the screen (and this auto-disposed controller) may be gone
  /// once the session is bound and the router redirects.
  void _set(SignInState Function(SignInState s) update) {
    if (ref.mounted) state = update(state);
  }

  /// Prefills the e-mail (re-authentication).
  void prefill(String email) {
    if (state.email.isEmpty) state = state.copyWith(email: email);
  }

  Future<void> submitEmail(String email) async {
    final repo = ref.read(authRepositoryProvider);
    if (repo == null) {
      state = state.copyWith(error: AuthFailureCode.notConfigured);
      return;
    }
    final normalized = email.trim().toLowerCase();
    if (!isValidEmail(normalized)) {
      state = state.copyWith(error: AuthFailureCode.invalidEmail, email: normalized);
      return;
    }
    state = state.copyWith(busy: AuthMethod.email, clearError: true, email: normalized);
    try {
      await repo.sendEmailCode(normalized, metadata: ref.read(signUpMetadataProvider));
      _set(
        (s) => s.copyWith(step: SignInStep.code, clearBusy: true, resendAvailableAt: _now().add(resendCooldown)),
      );
    } on AuthFailure catch (e) {
      _set((s) => s.copyWith(clearBusy: true, error: e.code));
    }
  }

  /// Returns true when the code was accepted and the session is bound.
  Future<bool> verifyCode(String code) async {
    final repo = ref.read(authRepositoryProvider);
    final digits = normalizeOtp(code);
    if (repo == null || digits.length != 6 || state.isBusy) return false;
    final binding = ref.read(authBindingProvider);
    state = state.copyWith(busy: AuthMethod.email, clearError: true);
    try {
      final user = await repo.verifyEmailCode(state.email, digits);
      await binding.bind(user);
      _set((s) => s.copyWith(clearBusy: true));
      return true;
    } on AuthFailure catch (e) {
      _set((s) => s.copyWith(clearBusy: true, error: e.code));
      return false;
    }
  }

  Future<void> resend() async {
    final at = state.resendAvailableAt;
    if (at != null && _now().isBefore(at)) return;
    await submitEmail(state.email);
  }

  void changeEmail() => state = SignInState(email: state.email);

  Future<bool> signInWithGoogle() => _provider(AuthMethod.google, (repo) => repo.signInWithGoogle());

  Future<bool> signInWithApple() => _provider(AuthMethod.apple, (repo) async {
    final user = await repo.signInWithApple();
    if (user == null) _set((s) => s.copyWith(browserFlowStarted: true));
    return user;
  });

  Future<bool> continueAsGuest() {
    final metadata = ref.read(signUpMetadataProvider);
    // TODO(config): pass a Turnstile/hCaptcha token here once CAPTCHA_SITE_KEY is configured.
    return _provider(AuthMethod.anonymous, (repo) => repo.continueAsGuest(metadata: metadata));
  }

  Future<bool> _provider(AuthMethod method, Future<AuthUser?> Function(AuthRepository repo) run) async {
    final repo = ref.read(authRepositoryProvider);
    if (repo == null) {
      state = state.copyWith(error: AuthFailureCode.notConfigured);
      return false;
    }
    if (state.isBusy) return false;
    final binding = ref.read(authBindingProvider);
    state = state.copyWith(busy: method, clearError: true);
    try {
      final user = await run(repo);
      if (user != null) await binding.bind(user);
      _set((s) => s.copyWith(clearBusy: true));
      return user != null;
    } on AuthFailure catch (e) {
      final cancelled = e.code == AuthFailureCode.cancelled;
      _set((s) => s.copyWith(clearBusy: true, error: cancelled ? null : e.code, clearError: cancelled));
      return false;
    }
  }

  /// "Use on this device only": local-only session even though cloud sync is configured
  /// (offline first launch, privacy). Signing in later claims the data (ADR-017).
  Future<void> useOnThisDeviceOnly() async {
    final container = ref.container;
    final db = ref.read(appDatabaseProvider);
    final session = ref.read(sessionProvider.notifier);
    await LocalOnlyChoice.choose(db);
    final id = await LocalAccount.ensureUserId(db);
    session.set(AppSession(userId: id, mode: SessionMode.localOnly));
    unawaited(runStartupTasks(container));
  }

  void clearError() => state = state.copyWith(clearError: true);
}
