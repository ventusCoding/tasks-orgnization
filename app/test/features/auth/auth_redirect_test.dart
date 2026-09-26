import 'package:everslot/features/auth/domain/auth_redirect.dart';
import 'package:flutter_test/flutter_test.dart';

String? go(String location, AuthRouteState state) {
  final uri = Uri.parse(location);
  return AuthRedirect.resolve(uri, uri.path, state);
}

void main() {
  const signedOut = AuthRouteState(cloudConfigured: true, signedIn: false);
  const signedIn = AuthRouteState(cloudConfigured: true, signedIn: true);
  const localOnlyWithCloud = AuthRouteState(cloudConfigured: true, signedIn: true, localOnly: true);
  const localOnlyNoCloud = AuthRouteState(cloudConfigured: false, signedIn: true, localOnly: true);
  const onboarding = AuthRouteState(cloudConfigured: true, signedIn: true, needsOnboarding: true);

  group('signed out (cloud configured)', () {
    test('any location goes to sign-in', () {
      expect(go('/today', signedOut), '/auth/sign-in');
      expect(go('/settings/sync', signedOut), '/auth/sign-in?from=%2Fsettings%2Fsync');
    });

    test('the original deep link is preserved (query included)', () {
      final target = go('/task/42?occ=2026-09-22T08:00', signedOut)!;
      expect(Uri.parse(target).path, '/auth/sign-in');
      expect(Uri.parse(target).queryParameters['from'], '/task/42?occ=2026-09-22T08:00');
    });

    test('the sign-in screen itself is allowed', () {
      expect(go('/auth/sign-in', signedOut), isNull);
      expect(go('/auth/sign-in?from=%2Ftask%2F1', signedOut), isNull);
    });

    test('without cloud configuration nothing is guarded (local-only mode)', () {
      expect(go('/today', const AuthRouteState(cloudConfigured: false, signedIn: false)), isNull);
    });
  });

  group('signed in', () {
    test('leaving sign-in resumes the preserved location', () {
      expect(go('/auth/sign-in?from=%2Ftask%2F42%3Focc%3Dx', signedIn), '/task/42?occ=x');
      expect(go('/auth/sign-in', signedIn), '/today');
    });

    test('unsafe `from` values never redirect outside the app or back into auth', () {
      expect(go('/auth/sign-in?from=%2F%2Fevil.example', signedIn), '/today');
      expect(go('/auth/sign-in?from=https%3A%2F%2Fevil.example', signedIn), '/today');
      expect(go('/auth/sign-in?from=%2Fauth%2Fsign-in', signedIn), '/today');
      expect(go('/auth/sign-in?from=%2Fonboarding', signedIn), '/today');
      expect(AuthRedirect.safeFrom('/${'a' * 3000}'), isNull);
    });

    test('explicit auth modes (re-auth, linking) stay on the auth screen', () {
      expect(go('/auth/sign-in?mode=reauth', signedIn), isNull);
    });

    test('local-only users may open sign-in to start syncing when the cloud is configured', () {
      expect(go('/auth/sign-in', localOnlyWithCloud), isNull);
      expect(go('/auth/sign-in', localOnlyNoCloud), '/today');
      expect(go('/today', localOnlyNoCloud), isNull);
    });

    test('regular locations are left alone', () {
      expect(go('/plan/week', signedIn), isNull);
      expect(go('/settings', signedIn), isNull);
    });
  });

  group('first-run essentials / onboarding', () {
    test('an incomplete profile goes to onboarding, keeping the target', () {
      expect(go('/today', onboarding), '/onboarding');
      expect(go('/habits/7', onboarding), '/onboarding?from=%2Fhabits%2F7');
      expect(go('/onboarding', onboarding), isNull);
    });

    test('onboarding stays reachable afterwards (re-run from Settings)', () {
      expect(go('/onboarding', signedIn), isNull);
    });
  });

  group('auth callbacks (magic link / OAuth)', () {
    test('every shape of everslot://auth-callback is recognised', () {
      for (final raw in [
        'everslot://auth-callback?code=abc',
        '/auth-callback?code=abc',
        '/?code=abc',
        '/?error_description=expired',
      ]) {
        expect(AuthRedirect.isAuthCallback(Uri.parse(raw)), isTrue, reason: raw);
      }
      expect(AuthRedirect.isAuthCallback(Uri.parse('/today?code=1')), isFalse);
    });

    test('callbacks land on sign-in until the session is bound, then home', () {
      final callback = Uri.parse('everslot://auth-callback?code=abc');
      expect(AuthRedirect.resolve(callback, '', signedOut), '/auth/sign-in');
      expect(AuthRedirect.resolve(callback, '', signedIn), '/today');
    });
  });
}
