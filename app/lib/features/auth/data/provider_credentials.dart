import 'package:everslot/features/auth/data/auth_config.dart';
import 'package:everslot/features/auth/domain/auth_models.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Tokens from the native Google flow.
typedef GoogleTokens = ({String idToken, String? accessToken});

/// Result of the native Apple flow (name only on the very first authorization).
typedef AppleCredential = ({String identityToken, String? givenName, String? familyName});

/// Native Google sign-in (google_sign_in 7, T1.5.09): ID token for `signInWithIdToken`.
abstract interface class GoogleIdTokenSource {
  Future<GoogleTokens> obtain();

  Future<void> signOut();
}

/// Native Sign in with Apple (iOS/macOS, T1.5.10).
abstract interface class AppleCredentialSource {
  /// True where the native sheet exists (iOS/macOS); elsewhere the Supabase web flow is used.
  bool get supportsNative;

  /// [hashedNonce] = SHA-256 of the raw nonce given to Supabase.
  Future<AppleCredential> credential({required String hashedNonce});
}

class GoogleSignInTokenSource implements GoogleIdTokenSource {
  GoogleSignInTokenSource(this.config);

  final AuthConfig config;
  Future<void>? _init;

  static const _scopes = ['email', 'profile'];

  Future<void> _ensureInitialized() => _init ??= GoogleSignIn.instance.initialize(
    clientId: defaultTargetPlatform == TargetPlatform.iOS && config.googleIosClientId.isNotEmpty
        ? config.googleIosClientId
        : null,
    serverClientId: config.googleWebClientId,
  );

  @override
  Future<GoogleTokens> obtain() async {
    if (!config.googleConfigured) {
      throw const AuthFailure(AuthFailureCode.providerNotConfigured, 'GOOGLE_WEB_CLIENT_ID missing');
    }
    try {
      await _ensureInitialized();
      final account = await GoogleSignIn.instance.authenticate(scopeHint: _scopes);
      final idToken = account.authentication.idToken;
      if (idToken == null) throw const AuthFailure(AuthFailureCode.unknown, 'no Google ID token');
      String? accessToken;
      try {
        final authz =
            await account.authorizationClient.authorizationForScopes(_scopes) ??
            await account.authorizationClient.authorizeScopes(_scopes);
        accessToken = authz.accessToken;
      } on Object {
        // The ID token alone is enough unless it carries `at_hash`; Supabase reports it if so.
      }
      return (idToken: idToken, accessToken: accessToken);
    } on GoogleSignInException catch (e) {
      throw AuthFailure(switch (e.code) {
        GoogleSignInExceptionCode.canceled || GoogleSignInExceptionCode.interrupted => AuthFailureCode.cancelled,
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError => AuthFailureCode.providerNotConfigured,
        _ => AuthFailureCode.unknown,
      }, e.description);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } on Object {
      // Not signed in with Google / plugin unavailable.
    }
  }
}

class SignInWithAppleCredentialSource implements AppleCredentialSource {
  const SignInWithAppleCredentialSource();

  @override
  bool get supportsNative =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS);

  @override
  Future<AppleCredential> credential({required String hashedNonce}) async {
    try {
      final c = await SignInWithApple.getAppleIDCredential(
        scopes: const [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: hashedNonce,
      );
      final token = c.identityToken;
      if (token == null) throw const AuthFailure(AuthFailureCode.unknown, 'no Apple identity token');
      return (identityToken: token, givenName: c.givenName, familyName: c.familyName);
    } on SignInWithAppleAuthorizationException catch (e) {
      throw AuthFailure(
        e.code == AuthorizationErrorCode.canceled ? AuthFailureCode.cancelled : AuthFailureCode.unknown,
        e.message,
      );
    } on SignInWithAppleNotSupportedException catch (e) {
      throw AuthFailure(AuthFailureCode.providerNotConfigured, e.message);
    }
  }
}
