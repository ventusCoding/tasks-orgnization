import 'package:everslot/core/providers.dart';
import 'package:everslot/features/auth/data/auth_config.dart';
import 'package:everslot/features/auth/data/supabase_auth_repository.dart';
import 'package:everslot/features/auth/domain/auth_models.dart';
import 'package:everslot/features/auth/domain/auth_redirect.dart';
import 'package:everslot/features/auth/domain/auth_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compile-time auth configuration (client ids, redirect URL, CAPTCHA key — see guide.md).
final authConfigProvider = Provider<AuthConfig>((ref) => AuthConfig.fromEnvironment());

/// Supabase Auth, or null when cloud sync isn't configured (local-only mode).
final authRepositoryProvider = Provider<AuthRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseAuthRepository(client, config: ref.watch(authConfigProvider));
});

/// True when sign-in is possible on this build.
final cloudAuthAvailableProvider = Provider<bool>((ref) => ref.watch(authRepositoryProvider) != null);

/// Coarse auth state derived from the session (T1.5.02).
final authStatusProvider = Provider<AuthStatus>((ref) {
  final session = ref.watch(sessionProvider);
  if (session == null) return AuthStatus.signedOut;
  if (session.isLocalOnly) return AuthStatus.localOnly;
  return session.isAnonymous ? AuthStatus.anonymous : AuthStatus.signedIn;
});

/// Session problems shown by the session guard (T1.5.14).
final sessionIssuesProvider = NotifierProvider<SessionIssuesController, Set<SessionIssue>>(SessionIssuesController.new);

class SessionIssuesController extends Notifier<Set<SessionIssue>> {
  @override
  Set<SessionIssue> build() => const {};

  void raise(SessionIssue issue) {
    if (!state.contains(issue)) state = {...state, issue};
  }

  void resolve(SessionIssue issue) {
    if (state.contains(issue)) state = {...state}..remove(issue);
  }

  void clear() => state = const {};
}

/// The profile exists but onboarding / first-run essentials were never completed (T1.5.05,
/// T8.3.11). In cloud mode the profile only exists locally after the first pull, so a second
/// device of the same account never sees onboarding.
final needsOnboardingProvider = Provider<bool>((ref) {
  if (ref.watch(sessionProvider) == null) return false;
  final profile = ref.watch(profileRowProvider).value;
  return profile != null && profile.onboardingCompletedAt == null;
});

/// Everything the router redirect depends on (router.dart refreshes when it changes).
final authRouteStateProvider = Provider<AuthRouteState>((ref) {
  final session = ref.watch(sessionProvider);
  return AuthRouteState(
    cloudConfigured: ref.watch(cloudAuthAvailableProvider),
    signedIn: session != null,
    localOnly: session?.isLocalOnly ?? false,
    needsOnboarding: ref.watch(needsOnboardingProvider),
  );
});

/// Metadata sent with a new sign-up so the server-created profile starts with the right zone
/// and language (T1.5.04 trigger reads `time_zone` / `locale`).
final signUpMetadataProvider = Provider<Map<String, Object?>>(
  (ref) => {
    'time_zone': ref.read(deviceZoneProvider),
    'locale': ref.read(userPreferencesProvider).localeCode ?? PlatformDispatcher.instance.locale.languageCode,
  },
);
