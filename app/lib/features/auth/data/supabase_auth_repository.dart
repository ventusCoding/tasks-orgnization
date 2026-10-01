import 'dart:async';
import 'dart:io';

import 'package:everslot/features/auth/data/auth_config.dart';
import 'package:everslot/features/auth/data/provider_credentials.dart';
import 'package:everslot/features/auth/domain/apple_nonce.dart';
import 'package:everslot/features/auth/domain/auth_models.dart';
import 'package:everslot/features/auth/domain/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// [AuthRepository] over Supabase Auth (T1.5.02–T1.5.12).
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(
    this._client, {
    required this.config,
    GoogleIdTokenSource? google,
    AppleCredentialSource? apple,
  }) : _google = google ?? GoogleSignInTokenSource(config),
       _apple = apple ?? const SignInWithAppleCredentialSource();

  final sb.SupabaseClient _client;
  final AuthConfig config;
  final GoogleIdTokenSource _google;
  final AppleCredentialSource _apple;

  sb.GoTrueClient get _auth => _client.auth;

  @override
  AuthUser? get currentUser => mapUser(_auth.currentUser);

  @override
  Stream<AuthUser?> get userChanges => _auth.onAuthStateChange.map((s) => mapUser(s.session?.user)).distinct();

  @override
  bool get googleAvailable => config.googleConfigured;

  @override
  bool get appleAvailable => config.appleSignInEnabled;

  @override
  Future<void> sendEmailCode(String email, {Map<String, Object?> metadata = const {}}) => _guard(() async {
    final normalized = email.trim().toLowerCase();
    if (!isValidEmail(normalized)) throw const AuthFailure(AuthFailureCode.invalidEmail);
    await _auth.signInWithOtp(email: normalized, emailRedirectTo: config.redirectUrl, data: metadata);
  });

  @override
  Future<AuthUser> verifyEmailCode(String email, String code) => _guard(() async {
    final res = await _auth.verifyOTP(
      email: email.trim().toLowerCase(),
      token: normalizeOtp(code),
      type: sb.OtpType.email,
    );
    return _requireUser(res.user);
  });

  @override
  Future<AuthUser> signInWithGoogle() => _guard(() async {
    final tokens = await _google.obtain();
    final res = await _auth.signInWithIdToken(
      provider: sb.OAuthProvider.google,
      idToken: tokens.idToken,
      accessToken: tokens.accessToken,
    );
    return _requireUser(res.user);
  });

  @override
  Future<AuthUser?> signInWithApple() => _guard(() async {
    if (!config.appleSignInEnabled) throw const AuthFailure(AuthFailureCode.providerNotConfigured);
    if (!_apple.supportsNative) {
      // Android: Supabase web OAuth flow, back through everslot://auth-callback (PKCE).
      await _auth.signInWithOAuth(
        sb.OAuthProvider.apple,
        redirectTo: config.redirectUrl,
        authScreenLaunchMode: sb.LaunchMode.externalApplication,
      );
      return null;
    }
    final nonce = AppleNonce.generate();
    final credential = await _apple.credential(hashedNonce: nonce.hashed);
    final res = await _auth.signInWithIdToken(
      provider: sb.OAuthProvider.apple,
      idToken: credential.identityToken,
      nonce: nonce.raw,
    );
    await _persistAppleName(credential);
    return _requireUser(res.user ?? _auth.currentUser);
  });

  /// Apple sends the name only on the very first authorization: keep it in user metadata.
  Future<void> _persistAppleName(AppleCredential credential) async {
    final name = [credential.givenName, credential.familyName].whereType<String>().where((s) => s.isNotEmpty).join(' ');
    if (name.isEmpty) return;
    try {
      await _auth.updateUser(sb.UserAttributes(data: {'full_name': name, 'display_name': name}));
    } on Object {
      // Non-fatal; the profile name can be edited later.
    }
  }

  @override
  Future<AuthUser> continueAsGuest({String? captchaToken, Map<String, Object?> metadata = const {}}) =>
      _guard(() async {
        final res = await _auth.signInAnonymously(captchaToken: captchaToken, data: metadata);
        return _requireUser(res.user);
      });

  @override
  Future<void> startEmailUpgrade(String email) => _guard(() async {
    final normalized = email.trim().toLowerCase();
    if (!isValidEmail(normalized)) throw const AuthFailure(AuthFailureCode.invalidEmail);
    await _auth.updateUser(sb.UserAttributes(email: normalized), emailRedirectTo: config.redirectUrl);
  });

  @override
  Future<AuthUser> confirmEmailUpgrade(String email, String code) => _guard(() async {
    final res = await _auth.verifyOTP(
      email: email.trim().toLowerCase(),
      token: normalizeOtp(code),
      type: sb.OtpType.emailChange,
    );
    return _requireUser(res.user ?? _auth.currentUser);
  });

  @override
  Future<AuthUser> linkGoogle() => _guard(() async {
    final tokens = await _google.obtain();
    final res = await _auth.linkIdentityWithIdToken(
      provider: sb.OAuthProvider.google,
      idToken: tokens.idToken,
      accessToken: tokens.accessToken,
    );
    return _requireUser(res.user ?? _auth.currentUser);
  });

  @override
  Future<AuthUser?> linkApple() => _guard(() async {
    if (!config.appleSignInEnabled) throw const AuthFailure(AuthFailureCode.providerNotConfigured);
    if (!_apple.supportsNative) {
      await _auth.linkIdentity(
        sb.OAuthProvider.apple,
        redirectTo: config.redirectUrl,
        authScreenLaunchMode: sb.LaunchMode.externalApplication,
      );
      return null;
    }
    final nonce = AppleNonce.generate();
    final credential = await _apple.credential(hashedNonce: nonce.hashed);
    final res = await _auth.linkIdentityWithIdToken(
      provider: sb.OAuthProvider.apple,
      idToken: credential.identityToken,
      nonce: nonce.raw,
    );
    return _requireUser(res.user ?? _auth.currentUser);
  });

  @override
  Future<List<AuthIdentity>> identities() => _guard(() async {
    final list = await _auth.getUserIdentities();
    return [
      for (final i in list)
        AuthIdentity(provider: i.provider, identityId: i.identityId, email: i.identityData?['email'] as String?),
    ];
  });

  @override
  Future<void> unlink(AuthIdentity identity) => _guard(() async {
    final list = await _auth.getUserIdentities();
    if (list.length <= 1) throw const AuthFailure(AuthFailureCode.lastIdentity);
    final match = list.where((i) => i.identityId == identity.identityId).firstOrNull;
    if (match == null) return;
    await _auth.unlinkIdentity(match);
  });

  @override
  Future<void> updateDisplayName(String? name) => _guard(() async {
    await _auth.updateUser(sb.UserAttributes(data: {'display_name': name}));
  });

  @override
  Future<void> deleteAccount() => _guard(() async {
    await _client.schema('app').rpc<dynamic>('request_account_deletion');
    final res = await _client.functions.invoke('account-delete');
    final data = res.data;
    if (res.status >= 300 || (data is Map && data['deleted'] != true)) {
      throw AuthFailure(AuthFailureCode.unknown, 'account-delete: ${res.status}');
    }
  });

  @override
  Future<void> signOut() async {
    await _google.signOut();
    try {
      await _auth.signOut();
    } on Object {
      // Offline: the local session is removed anyway (scope local).
    }
  }

  @override
  Future<bool> refreshSession() async {
    try {
      await _auth.refreshSession();
      return true;
    } on sb.AuthRetryableFetchException {
      rethrow;
    } on Object {
      return false;
    }
  }

  AuthUser _requireUser(sb.User? user) {
    final mapped = mapUser(user);
    if (mapped == null) throw const AuthFailure(AuthFailureCode.unknown, 'no user in response');
    return mapped;
  }

  static AuthUser? mapUser(sb.User? user) {
    if (user == null) return null;
    final providers = <String>{
      for (final i in user.identities ?? const <sb.UserIdentity>[]) i.provider,
      ...[for (final p in (user.appMetadata['providers'] as List?) ?? const []) '$p'],
    }..remove('anonymous');
    final meta = user.userMetadata ?? const {};
    final name = (meta['display_name'] ?? meta['full_name'] ?? meta['name']) as String?;
    return AuthUser(
      id: user.id,
      email: (user.email?.isEmpty ?? true) ? null : user.email,
      isAnonymous: user.isAnonymous,
      providers: providers.toList()..sort(),
      displayName: name,
      pendingEmail: user.newEmail,
    );
  }

  static Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on AuthFailure {
      rethrow;
    } on sb.AuthRetryableFetchException catch (e) {
      throw AuthFailure(AuthFailureCode.offline, e.message);
    } on sb.AuthException catch (e) {
      throw mapAuthException(e);
    } on SocketException catch (e) {
      throw AuthFailure(AuthFailureCode.offline, e.message);
    } on TimeoutException {
      throw const AuthFailure(AuthFailureCode.offline, 'timeout');
    } on sb.FunctionException catch (e) {
      throw AuthFailure(AuthFailureCode.unknown, 'function ${e.status}');
    } on sb.PostgrestException catch (e) {
      throw AuthFailure(AuthFailureCode.unknown, e.code);
    } on Exception catch (e) {
      final s = e.toString();
      if (s.contains('SocketException') || s.contains('ClientException') || s.contains('Failed host lookup')) {
        throw AuthFailure(AuthFailureCode.offline, s);
      }
      throw AuthFailure(AuthFailureCode.unknown, e.runtimeType.toString());
    }
  }

  /// Supabase Auth error codes → [AuthFailureCode].
  static AuthFailure mapAuthException(sb.AuthException e) {
    final code = e.code ?? '';
    final status = e.statusCode ?? '';
    final failure = switch (code) {
      'otp_expired' ||
      'invalid_credentials' ||
      'bad_code_verifier' ||
      'flow_state_expired' => AuthFailureCode.invalidCode,
      'over_email_send_rate_limit' ||
      'over_request_rate_limit' ||
      'over_sms_send_rate_limit' => AuthFailureCode.rateLimited,
      'email_exists' || 'user_already_exists' || 'email_conflict_identity_not_deletable' => AuthFailureCode.emailInUse,
      'identity_already_exists' => AuthFailureCode.identityInUse,
      'captcha_failed' => AuthFailureCode.captchaRequired,
      'anonymous_provider_disabled' => AuthFailureCode.guestDisabled,
      'provider_disabled' ||
      'oauth_provider_not_supported' ||
      'email_provider_disabled' => AuthFailureCode.providerNotConfigured,
      'email_address_invalid' || 'validation_failed' => AuthFailureCode.invalidEmail,
      'session_expired' ||
      'session_not_found' ||
      'refresh_token_not_found' ||
      'refresh_token_already_used' => AuthFailureCode.sessionExpired,
      'single_identity_not_deletable' => AuthFailureCode.lastIdentity,
      _ when status == '429' => AuthFailureCode.rateLimited,
      _ => AuthFailureCode.unknown,
    };
    return AuthFailure(failure, code.isEmpty ? status : code);
  }
}
