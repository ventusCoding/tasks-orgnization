/// Sign-in methods (T1.5.03, T1.5.09–T1.5.11).
enum AuthMethod { email, google, apple, anonymous }

/// Coarse authentication state (T1.5.02). "Signing in" is transient UI state of the sign-in
/// controller; the session itself is either absent, local-only, a guest or a full account.
enum AuthStatus {
  signedOut,

  /// Data stays on this device (Supabase not configured, or "use on this device only").
  localOnly,

  /// Cloud guest account (anonymous sign-in) — upgradeable without changing its id.
  anonymous,
  signedIn,
}

/// A signed-in Supabase user as the app sees it (no tokens here).
class AuthUser {
  const AuthUser({
    required this.id,
    this.email,
    this.isAnonymous = false,
    this.providers = const [],
    this.displayName,
    this.pendingEmail,
  });

  final String id;
  final String? email;

  /// Guest account (anonymous sign-in) that can be upgraded without changing its id.
  final bool isAnonymous;

  /// Linked identity providers (`email`, `google`, `apple`).
  final List<String> providers;
  final String? displayName;

  /// New e-mail waiting for confirmation (guest upgrade / e-mail change).
  final String? pendingEmail;

  bool hasProvider(String provider) => providers.contains(provider);

  @override
  bool operator ==(Object other) =>
      other is AuthUser &&
      other.id == id &&
      other.email == email &&
      other.isAnonymous == isAnonymous &&
      _listEq(other.providers, providers) &&
      other.displayName == displayName &&
      other.pendingEmail == pendingEmail;

  @override
  int get hashCode => Object.hash(id, email, isAnonymous, Object.hashAll(providers), displayName, pendingEmail);

  @override
  String toString() => 'AuthUser($id, anonymous: $isAnonymous, providers: $providers)';
}

bool _listEq(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// A linked sign-in identity (Settings › Account).
class AuthIdentity {
  const AuthIdentity({required this.provider, required this.identityId, this.email});

  final String provider;
  final String identityId;
  final String? email;

  @override
  bool operator ==(Object other) =>
      other is AuthIdentity && other.provider == provider && other.identityId == identityId && other.email == email;

  @override
  int get hashCode => Object.hash(provider, identityId, email);
}

/// Why an auth operation failed — mapped to localized messages by the UI.
enum AuthFailureCode {
  invalidEmail,
  invalidCode,
  rateLimited,
  offline,
  cancelled,
  emailInUse,
  identityInUse,
  notConfigured,
  providerNotConfigured,
  captchaRequired,
  guestDisabled,
  sessionExpired,
  lastIdentity,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.code, [this.details]);

  final AuthFailureCode code;

  /// Developer details (never shown to users, never containing tokens).
  final String? details;

  @override
  String toString() => 'AuthFailure(${code.name}${details == null ? '' : ': $details'})';
}

/// Account-level problems surfaced by the session guard (T1.5.14).
enum SessionIssue {
  /// The refresh token was rejected online: the app stays usable, writes keep queuing, and a
  /// non-blocking prompt asks the user to sign in again (outbox preserved).
  reauthRequired,

  /// The device was revoked from another device: final export offer, then sign-out.
  deviceRevoked,

  /// The server refuses this app build (`unsupported_client`): update prompt.
  updateRequired,
}

/// Simple e-mail sanity check (the server validates for real).
bool isValidEmail(String value) {
  final v = value.trim();
  if (v.length > 254) return false;
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
}

/// Normalizes a pasted/typed one-time code: keeps digits only, max [length].
String normalizeOtp(String value, {int length = 6}) {
  final digits = value.replaceAll(RegExp('[^0-9٠-٩۰-۹]'), '');
  final ascii = StringBuffer();
  for (final rune in digits.runes) {
    // Arabic-Indic (U+0660–0669) and Extended Arabic-Indic (U+06F0–06F9) digits → ASCII.
    if (rune >= 0x0660 && rune <= 0x0669) {
      ascii.writeCharCode(0x30 + rune - 0x0660);
    } else if (rune >= 0x06F0 && rune <= 0x06F9) {
      ascii.writeCharCode(0x30 + rune - 0x06F0);
    } else {
      ascii.writeCharCode(rune);
    }
  }
  final s = ascii.toString();
  return s.length > length ? s.substring(0, length) : s;
}
