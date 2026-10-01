import 'package:everslot/features/auth/domain/auth_models.dart';

/// Authentication port (implemented over Supabase Auth in `data/`, faked in tests).
///
/// Every method throws [AuthFailure] with a stable code on failure.
abstract interface class AuthRepository {
  AuthUser? get currentUser;

  /// Emits the user after every auth change (sign-in, token refresh with changed claims, user
  /// update) and `null` when the session ends (sign-out or an unrecoverable refresh failure).
  Stream<AuthUser?> get userChanges;

  /// Google sign-in is configured (client ids present) on this build.
  bool get googleAvailable;

  /// Sign in with Apple is offered (native on iOS/macOS, web flow elsewhere).
  bool get appleAvailable;

  /// Sends a 6-digit code (and magic link) to [email]. [metadata] (time zone, locale) seeds the
  /// profile of a new account (server trigger, T1.5.04).
  Future<void> sendEmailCode(String email, {Map<String, Object?> metadata = const {}});

  Future<AuthUser> verifyEmailCode(String email, String code);

  Future<AuthUser> signInWithGoogle();

  /// Returns null when a browser flow was started (Android): completion arrives through the
  /// `everslot://auth-callback` deep link and [userChanges].
  Future<AuthUser?> signInWithApple();

  /// Guest mode (anonymous sign-in, T1.5.11).
  Future<AuthUser> continueAsGuest({String? captchaToken, Map<String, Object?> metadata = const {}});

  /// Guest → e-mail account: sends a confirmation code to [email] (same user id).
  Future<void> startEmailUpgrade(String email);

  Future<AuthUser> confirmEmailUpgrade(String email, String code);

  Future<AuthUser> linkGoogle();

  /// Returns null when a browser flow was started.
  Future<AuthUser?> linkApple();

  Future<List<AuthIdentity>> identities();

  Future<void> unlink(AuthIdentity identity);

  Future<void> updateDisplayName(String? name);

  /// Authenticator-app factors of the account, verified or pending (T1.5.17).
  Future<List<MfaFactor>> mfaFactors();

  /// Starts a TOTP enrollment; pending enrollments left over from an earlier attempt are removed.
  Future<TotpEnrollment> enrollTotp();

  /// Checks [code] for [factorId]: confirms a pending enrollment, and steps the session up to aal2.
  Future<void> verifyTotp(String factorId, String code);

  /// Removes a factor (Supabase requires an aal2 session for a verified one).
  Future<void> unenrollMfa(String factorId);

  /// The account has a verified factor but this session is not aal2 yet.
  bool get mfaStepUpRequired;

  /// Records the deletion request and calls the `account-delete` Edge Function (T1.5.12).
  Future<void> deleteAccount();

  /// Ends the session on this device only.
  Future<void> signOut();

  /// Tries to refresh the session; false when the refresh token is no longer valid.
  Future<bool> refreshSession();
}
