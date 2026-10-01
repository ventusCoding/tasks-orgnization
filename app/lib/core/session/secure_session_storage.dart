import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Minimal async key/value store for secrets (fake in tests, Keychain/Keystore in the app).
abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// [SecureStore] backed by `flutter_secure_storage` (iOS Keychain, Android Keystore-encrypted
/// preferences). Values stay on the device (`first_unlock_this_device` → no iCloud Keychain sync).
class FlutterSecureStore implements SecureStore {
  const FlutterSecureStore([
    this._storage = const FlutterSecureStorage(
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
    ),
  ]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// In-memory [SecureStore] (tests, platforms without a keychain).
class MemorySecureStore implements SecureStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

/// Supabase session persistence in secure storage (arch §6.17, T1.5.02) — the refresh token is
/// never written to plain SharedPreferences. Wired in `bootstrap.dart` via
/// `FlutterAuthClientOptions(localStorage: SecureSessionStorage(), pkceAsyncStorage: SecurePkceStorage())`.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({SecureStore? store, this.key = defaultKey}) : _store = store ?? const FlutterSecureStore();

  static const defaultKey = 'everslot_supabase_session';

  final SecureStore _store;
  final String key;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    try {
      return (await _store.read(key)) != null;
    } on Object {
      return false;
    }
  }

  @override
  Future<String?> accessToken() async {
    try {
      return await _store.read(key);
    } on Object {
      // A corrupted keychain entry must not crash startup: behave as signed out.
      return null;
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) => _store.write(key, persistSessionString);

  @override
  Future<void> removePersistedSession() => _store.delete(key);
}

/// PKCE code-verifier storage (magic links / OAuth redirects) in secure storage.
class SecurePkceStorage extends GotrueAsyncStorage {
  SecurePkceStorage({SecureStore? store, this.prefix = 'everslot_pkce_'})
    : _store = store ?? const FlutterSecureStore();

  final SecureStore _store;
  final String prefix;

  @override
  Future<String?> getItem({required String key}) async {
    try {
      return await _store.read('$prefix$key');
    } on Object {
      return null;
    }
  }

  @override
  Future<void> setItem({required String key, required String value}) => _store.write('$prefix$key', value);

  @override
  Future<void> removeItem({required String key}) => _store.delete('$prefix$key');
}
