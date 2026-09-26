/// What the router needs to know to guard routes (T1.5.02). Pure data (the application layer maps
/// the session and profile onto it).
class AuthRouteState {
  const AuthRouteState({
    required this.cloudConfigured,
    required this.signedIn,
    this.localOnly = false,
    this.needsOnboarding = false,
  });

  /// Supabase is configured (otherwise the app runs in local-only mode, no sign-in needed).
  final bool cloudConfigured;

  /// A session exists (cloud account or local-only account).
  final bool signedIn;

  /// The session keeps data on this device only (ADR-017).
  final bool localOnly;

  /// The profile exists but first-run essentials / onboarding were never completed (T1.5.05,
  /// T8.3.11). Only true once the profile is known locally (after the first pull in cloud mode).
  final bool needsOnboarding;

  @override
  bool operator ==(Object other) =>
      other is AuthRouteState &&
      other.cloudConfigured == cloudConfigured &&
      other.signedIn == signedIn &&
      other.localOnly == localOnly &&
      other.needsOnboarding == needsOnboarding;

  @override
  int get hashCode => Object.hash(cloudConfigured, signedIn, localOnly, needsOnboarding);

  @override
  String toString() =>
      'AuthRouteState(cloud: $cloudConfigured, signedIn: $signedIn, localOnly: $localOnly, '
      'onboarding: $needsOnboarding)';
}

/// Pure router redirect: unauthenticated → sign-in (the original location is preserved in
/// `from` and resumed after sign-in), authenticated without essentials → onboarding, auth
/// callbacks (magic link / OAuth, `everslot://auth-callback`) → sign-in or home.
abstract final class AuthRedirect {
  static const signIn = '/auth/sign-in';
  static const onboarding = '/onboarding';
  static const home = '/today';

  /// Returns the location to go to, or null to stay on [uri].
  static String? resolve(Uri uri, String matchedLocation, AuthRouteState state) {
    if (isAuthCallback(uri)) return state.signedIn ? home : signIn;
    final atAuth = matchedLocation.startsWith('/auth');
    final atOnboarding = matchedLocation.startsWith(onboarding);
    if (!state.signedIn) {
      if (!state.cloudConfigured || atAuth) return null;
      return withFrom(signIn, uri);
    }
    if (atAuth) {
      // Kept reachable while signed in for: re-authentication / linking (explicit `mode`) and
      // local-only users who decide to sign in to sync (their data is claimed by the account).
      final explicitMode = uri.queryParameters['mode'] != null;
      if (explicitMode || (state.localOnly && state.cloudConfigured)) return null;
      return safeFrom(uri.queryParameters['from']) ?? home;
    }
    if (state.needsOnboarding && !atOnboarding) return withFrom(onboarding, uri);
    return null;
  }

  /// `everslot://auth-callback?code=…` (PKCE magic link / OAuth), in any of the shapes the
  /// router may receive it.
  static bool isAuthCallback(Uri uri) {
    if (uri.host == 'auth-callback') return true;
    final path = uri.path;
    if (path == '/auth-callback' || path == 'auth-callback') return true;
    final q = uri.queryParameters;
    final rootish = path.isEmpty || path == '/';
    return rootish &&
        (q.containsKey('code') || q.containsKey('error_description') || q.containsKey('access_token'));
  }

  /// [target] with `from=<location>` unless the location is the default home.
  static String withFrom(String target, Uri from) {
    final keep = safeFrom(from.toString());
    if (keep == null || keep == home || keep == '/') return target;
    return Uri(path: target, queryParameters: {'from': keep}).toString();
  }

  /// Validates a `from` location: in-app absolute path only, never an auth/onboarding route
  /// (no loops, no open redirects).
  static String? safeFrom(String? from) {
    if (from == null || from.isEmpty || from.length > 2048) return null;
    if (!from.startsWith('/') || from.startsWith('//')) return null;
    if (from.startsWith('/auth') || from.startsWith(onboarding)) return null;
    return from;
  }
}
