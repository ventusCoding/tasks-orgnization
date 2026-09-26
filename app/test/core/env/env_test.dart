import 'package:everslot/core/env/env.dart';
import 'package:flutter_test/flutter_test.dart';

Env _env({
  Flavor flavor = Flavor.dev,
  String url = '',
  String key = '',
  bool firebase = false,
  Set<String> flags = const {},
}) => Env(
  flavor: flavor,
  supabaseUrl: url,
  supabasePublishableKey: key,
  firebaseEnabled: firebase,
  featureFlags: flags,
);

void main() {
  group('Env (T1.1.11)', () {
    test('empty values mean local-only mode with explicit warnings', () {
      final env = _env();
      expect(env.isSupabaseConfigured, isFalse);
      expect(env.warnings, hasLength(2));
    });

    test(
      'the committed example placeholders are not treated as configured',
      () {
        final env = _env(
          url: 'https://YOUR_PROJECT_REF.supabase.co',
          key: 'sb_publishable_YOUR_KEY',
        );
        expect(env.isSupabaseConfigured, isFalse);
      },
    );

    test('a real URL and publishable key enable cloud mode', () {
      final env = _env(
        url: 'http://127.0.0.1:54321',
        key: 'sb_publishable_abc123',
        firebase: true,
      );
      expect(env.isSupabaseConfigured, isTrue);
      expect(env.warnings, isEmpty);
    });

    test('a URL without a key is still local-only', () {
      expect(
        _env(url: 'https://abc.supabase.co').isSupabaseConfigured,
        isFalse,
      );
    });

    test('non-http URLs are rejected', () {
      expect(
        _env(
          url: 'abc.supabase.co',
          key: 'sb_publishable_abc',
        ).isSupabaseConfigured,
        isFalse,
      );
    });
  });

  group('Flavor (T1.1.10)', () {
    test('isDev follows the flavor', () {
      expect(_env().isDev, isTrue);
      expect(_env(flavor: Flavor.prod).isDev, isFalse);
    });

    test('fromEnvironment honours an explicit flavor and defaults to local-only in tests', () {
      final prod = Env.fromEnvironment(flavor: Flavor.prod);
      expect(prod.flavor, Flavor.prod);
      expect(prod.isSupabaseConfigured, isFalse);
      expect(prod.featureFlags, isEmpty);
      expect(Env.fromEnvironment().flavor, Flavor.dev);
    });
  });
}
