import 'package:everslot/core/session/secure_session_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// A keychain whose entries can't be read (corrupted after a restore, locked device…).
class _BrokenStore implements SecureStore {
  @override
  Future<String?> read(String key) async => throw StateError('keychain unavailable');

  @override
  Future<void> write(String key, String value) async => throw StateError('keychain unavailable');

  @override
  Future<void> delete(String key) async {}
}

void main() {
  group('SecureSessionStorage (T1.5.02)', () {
    test('persists, restores and removes the session in secure storage only', () async {
      final store = MemorySecureStore();
      final storage = SecureSessionStorage(store: store);
      await storage.initialize();
      expect(await storage.hasAccessToken(), isFalse);
      expect(await storage.accessToken(), isNull);

      await storage.persistSession('{"access_token":"a","refresh_token":"r"}');
      expect(store.values, {SecureSessionStorage.defaultKey: '{"access_token":"a","refresh_token":"r"}'});
      expect(await storage.hasAccessToken(), isTrue);
      expect(await storage.accessToken(), contains('refresh_token'));

      await storage.removePersistedSession();
      expect(store.values, isEmpty);
      expect(await storage.hasAccessToken(), isFalse);
    });

    test('a restart reads the same persisted session (signed in offline)', () async {
      final store = MemorySecureStore();
      await SecureSessionStorage(store: store).persistSession('{"s":1}');
      final afterRestart = SecureSessionStorage(store: store);
      expect(await afterRestart.hasAccessToken(), isTrue);
      expect(await afterRestart.accessToken(), '{"s":1}');
    });

    test('an unreadable keychain behaves as signed out instead of crashing startup', () async {
      final storage = SecureSessionStorage(store: _BrokenStore());
      expect(await storage.hasAccessToken(), isFalse);
      expect(await storage.accessToken(), isNull);
    });
  });

  group('SecurePkceStorage', () {
    test('keeps code verifiers under a prefix and removes them', () async {
      final store = MemorySecureStore();
      final pkce = SecurePkceStorage(store: store);
      await pkce.setItem(key: 'supabase.auth.token-code-verifier', value: 'v');
      expect(store.values.keys.single, 'everslot_pkce_supabase.auth.token-code-verifier');
      expect(await pkce.getItem(key: 'supabase.auth.token-code-verifier'), 'v');
      await pkce.removeItem(key: 'supabase.auth.token-code-verifier');
      expect(await pkce.getItem(key: 'supabase.auth.token-code-verifier'), isNull);
    });

    test('read failures return null', () async {
      expect(await SecurePkceStorage(store: _BrokenStore()).getItem(key: 'k'), isNull);
    });
  });
}
