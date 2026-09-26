import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/session/local_account.dart';
import 'package:everslot/core/session/local_only_choice.dart';
import 'package:everslot/core/session/session.dart';
import 'package:everslot/features/auth/application/auth_binding.dart';
import 'package:everslot/features/auth/application/auth_providers.dart';
import 'package:everslot/features/auth/domain/auth_models.dart';
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
      state = state.copyWith(
        step: SignInStep.code,
        clearBusy: true,
        resendAvailableAt: _now().add(resendCooldown),
      );
    } on AuthFailure catch (e) {
      state = state.copyWith(clearBusy: true, error: e.code);
    }
  }

  /// Returns true when the code was accepted and the session is bound.
  Future<bool> verifyCode(String code) async {
    final repo = ref.read(authRepositoryProvider);
    final digits = normalizeOtp(code);
    if (repo == null || digits.length != 6 || state.isBusy) return false;
    state = state.copyWith(busy: AuthMethod.email, clearError: true);
    try {
      final user = await repo.verifyEmailCode(state.email, digits);
      await ref.read(authBindingProvider).bind(user);
      state = state.copyWith(clearBusy: true);
      return true;
    } on AuthFailure catch (e) {
      state = state.copyWith(clearBusy: true, error: e.code);
      return false;
    }
  }

  Future<void> resend() async {
    final at = state.resendAvailableAt;
    if (at != null && _now().isBefore(at)) return;
    await submitEmail(state.email);
  }

  void changeEmail() => state = SignInState(email: state.email);

  Future<bool> signInWithGoogle() => _provider(AuthMethod.google, () async {
    final repo = ref.read(authRepositoryProvider)!;
    return repo.signInWithGoogle();
  });

  Future<bool> signInWithApple() => _provider(AuthMethod.apple, () async {
    final repo = ref.read(authRepositoryProvider)!;
    final user = await repo.signInWithApple();
    if (user == null) state = state.copyWith(browserFlowStarted: true);
    return user;
  });

  Future<bool> continueAsGuest() => _provider(AuthMethod.anonymous, () async {
    final repo = ref.read(authRepositoryProvider)!;
    // TODO(config): pass a Turnstile/hCaptcha token here once CAPTCHA_SITE_KEY is configured.
    return repo.continueAsGuest(metadata: ref.read(signUpMetadataProvider));
  });

  Future<bool> _provider(AuthMethod method, Future<AuthUser?> Function() run) async {
    if (ref.read(authRepositoryProvider) == null) {
      state = state.copyWith(error: AuthFailureCode.notConfigured);
      return false;
    }
    if (state.isBusy) return false;
    state = state.copyWith(busy: method, clearError: true);
    try {
      final user = await run();
      if (user != null) await ref.read(authBindingProvider).bind(user);
      state = state.copyWith(clearBusy: true);
      return user != null;
    } on AuthFailure catch (e) {
      state = state.copyWith(
        clearBusy: true,
        error: e.code == AuthFailureCode.cancelled ? null : e.code,
        clearError: e.code == AuthFailureCode.cancelled,
      );
      return false;
    }
  }

  /// "Use on this device only": local-only session even though cloud sync is configured
  /// (offline first launch, privacy). Signing in later claims the data (ADR-017).
  Future<void> useOnThisDeviceOnly() async {
    final db = ref.read(appDatabaseProvider);
    await LocalOnlyChoice.choose(db);
    final id = await LocalAccount.ensureUserId(db);
    ref.read(sessionProvider.notifier).set(AppSession(userId: id, mode: SessionMode.localOnly));
    unawaited(runStartupTasks(ref.container));
  }

  void clearError() => state = state.copyWith(clearError: true);
}
