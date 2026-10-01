import 'dart:convert';

import 'package:everslot/features/auth/data/auth_config.dart';
import 'package:everslot/features/auth/data/provider_credentials.dart';
import 'package:everslot/features/auth/data/supabase_auth_repository.dart';
import 'package:everslot/features/auth/domain/apple_nonce.dart';
import 'package:everslot/features/auth/domain/auth_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// A recorded HTTP call to the fake Supabase backend.
typedef Call = ({
  String method,
  String path,
  Map<String, String> query,
  Map<String, dynamic> body,
  Map<String, String> headers,
});

String _b64(Map<String, Object?> json) => base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');

String _jwt(String sub) =>
    '${_b64({'alg': 'HS256', 'typ': 'JWT'})}.${_b64({'sub': sub, 'exp': 4102444800, 'role': 'authenticated'})}.sig';

Map<String, Object?> _user({
  String id = 'user-1',
  String? email = 'ana@example.com',
  bool anonymous = false,
  List<String> providers = const ['email'],
  Map<String, Object?> meta = const {},
  String? newEmail,
}) => {
  'id': id,
  'aud': 'authenticated',
  'role': 'authenticated',
  'email': email ?? '',
  'new_email': ?newEmail,
  'created_at': '2026-09-01T00:00:00Z',
  'is_anonymous': anonymous,
  'app_metadata': {
    'provider': anonymous ? 'anonymous' : providers.first,
    'providers': anonymous ? <String>[] : providers,
  },
  'user_metadata': meta,
  'identities': [
    for (final p in providers)
      {
        'id': 'identity-$p',
        'identity_id': 'identity-$p',
        'user_id': id,
        'provider': p,
        'identity_data': {'email': email, 'sub': 'sub-$p'},
        'created_at': '2026-09-01T00:00:00Z',
        'last_sign_in_at': '2026-09-01T00:00:00Z',
        'updated_at': '2026-09-01T00:00:00Z',
      },
  ],
};

Map<String, Object?> _session(Map<String, Object?> user) => {
  'access_token': _jwt(user['id']! as String),
  'token_type': 'bearer',
  'expires_in': 3600,
  'refresh_token': 'refresh-1',
  'user': user,
};

class _Backend {
  final calls = <Call>[];

  /// Next response per `METHOD path` (default: a sensible success).
  final responses = <String, http.Response Function(Call call)>{};

  late final client = MockClient((request) async {
    var body = const <String, dynamic>{};
    if (request.body.isNotEmpty) {
      final decoded = jsonDecode(request.body);
      if (decoded is Map) body = Map<String, dynamic>.from(decoded);
    }
    final call = (
      method: request.method,
      path: request.url.path,
      query: request.url.queryParameters,
      body: body,
      headers: request.headers,
    );
    calls.add(call);
    final key = '${request.method} ${request.url.path}';
    final handler = responses[key];
    final response = handler != null ? handler(call) : _default(key, call);
    // postgrest reads `response.request`.
    return http.Response(response.body, response.statusCode, headers: response.headers, request: request);
  });

  http.Response _default(String key, Call call) {
    return switch (key) {
      'POST /auth/v1/token' => _json(_session(_user(providers: [call.body['provider'] as String]))),
      'POST /auth/v1/signup' => _json(_session(_user(email: null, anonymous: true, providers: const []))),
      'POST /auth/v1/verify' => _json(_session(_user())),
      'PUT /auth/v1/user' => _json(_user(meta: Map<String, Object?>.from(call.body['data'] as Map? ?? {}))),
      'GET /auth/v1/user' => _json(_user(providers: const ['email', 'google'])),
      'POST /rest/v1/rpc/request_account_deletion' => _json({'status': 'requested'}),
      'POST /functions/v1/account-delete' => _json({'deleted': true}),
      'POST /auth/v1/logout' => http.Response('', 204),
      _ => http.Response('{"code":404,"error_code":"not_found","msg":"no route $key"}', 404),
    };
  }

  static http.Response _json(Object? body, [int status = 200]) =>
      http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

  static http.Response authError(String code, int status) =>
      _json({'code': status, 'error_code': code, 'msg': code}, status);

  Call? find(String method, String path) {
    for (final c in calls.reversed) {
      if (c.method == method && c.path == path) return c;
    }
    return null;
  }
}

/// PKCE verifiers (e-mail change with a redirect uses the PKCE flow).
class _MemoryAsyncStorage extends sb.GotrueAsyncStorage {
  final _items = <String, String>{};

  @override
  Future<String?> getItem({required String key}) async => _items[key];

  @override
  Future<void> removeItem({required String key}) async => _items.remove(key);

  @override
  Future<void> setItem({required String key, required String value}) async => _items[key] = value;
}

class _FakeGoogle implements GoogleIdTokenSource {
  _FakeGoogle({this.failure});

  final AuthFailure? failure;
  int signOuts = 0;

  @override
  Future<GoogleTokens> obtain() async {
    if (failure != null) throw failure!;
    return (idToken: 'google-id-token', accessToken: 'google-access-token');
  }

  @override
  Future<void> signOut() async => signOuts++;
}

class _FakeApple implements AppleCredentialSource {
  String? hashedNonce;

  @override
  bool get supportsNative => true;

  @override
  Future<AppleCredential> credential({required String hashedNonce}) async {
    this.hashedNonce = hashedNonce;
    return (identityToken: 'apple-id-token', givenName: 'Ana', familyName: 'Ben Salah');
  }
}

void main() {
  late _Backend backend;
  late sb.SupabaseClient client;
  late _FakeGoogle google;
  late _FakeApple apple;

  SupabaseAuthRepository repo({
    AuthConfig config = const AuthConfig(googleWebClientId: 'web-id', appleSignInEnabled: true),
  }) => SupabaseAuthRepository(client, config: config, google: google, apple: apple);

  setUp(() {
    backend = _Backend();
    client = sb.SupabaseClient(
      'https://project.supabase.test',
      'sb_publishable_test',
      httpClient: backend.client,
      authOptions: sb.AuthClientOptions(autoRefreshToken: false, pkceAsyncStorage: _MemoryAsyncStorage()),
    );
    google = _FakeGoogle();
    apple = _FakeApple();
  });

  tearDown(() => client.dispose());

  group('Google (T1.5.09)', () {
    test('the native ID token (and access token) go to signInWithIdToken', () async {
      final user = await repo().signInWithGoogle();
      final call = backend.find('POST', '/auth/v1/token')!;
      expect(call.query['grant_type'], 'id_token');
      expect(call.body['provider'], 'google');
      expect(call.body['id_token'], 'google-id-token');
      expect(call.body['access_token'], 'google-access-token');
      expect(call.body['nonce'], isNull);
      expect(user.id, 'user-1');
      expect(user.providers, ['google']);
    });

    test('cancel and configuration problems surface as stable codes', () async {
      google = _FakeGoogle(failure: const AuthFailure(AuthFailureCode.cancelled));
      await expectLater(
        repo().signInWithGoogle(),
        throwsA(isA<AuthFailure>().having((f) => f.code, 'code', AuthFailureCode.cancelled)),
      );
      expect(backend.calls, isEmpty);
      await expectLater(
        GoogleSignInTokenSource(const AuthConfig()).obtain(),
        throwsA(isA<AuthFailure>().having((f) => f.code, 'code', AuthFailureCode.providerNotConfigured)),
      );
      expect(repo(config: const AuthConfig()).googleAvailable, isFalse);
    });

    test('an e-mail already used by another account: identity-linking rules apply', () async {
      backend.responses['POST /auth/v1/token'] = (_) => _Backend.authError('email_exists', 422);
      await expectLater(
        repo().signInWithGoogle(),
        throwsA(isA<AuthFailure>().having((f) => f.code, 'code', AuthFailureCode.emailInUse)),
      );
    });
  });

  group('Apple (T1.5.10)', () {
    test('Apple gets the SHA-256 of the nonce, Supabase the raw nonce; the name is kept once', () async {
      final user = await repo().signInWithApple();
      final token = backend.find('POST', '/auth/v1/token')!;
      expect(token.body['provider'], 'apple');
      expect(token.body['id_token'], 'apple-id-token');
      final raw = token.body['nonce'] as String;
      expect(raw, hasLength(32));
      expect(AppleNonce.sha256Hex(raw), apple.hashedNonce);
      expect(apple.hashedNonce, isNot(raw));
      final update = backend.find('PUT', '/auth/v1/user')!;
      expect(update.body['data'], {'full_name': 'Ana Ben Salah', 'display_name': 'Ana Ben Salah'});
      expect(user!.providers, ['apple']);
    });

    test('nonces are random, URL-safe and hashed as lowercase hex', () {
      final a = AppleNonce.generate();
      final b = AppleNonce.generate();
      expect(a.raw, isNot(b.raw));
      expect(RegExp(r'^[0-9A-Za-z._-]{32}$').hasMatch(a.raw), isTrue);
      expect(AppleNonce.sha256Hex('abc'), 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(a.hashed), isTrue);
    });

    test('disabled on this build → provider not configured, nothing sent', () async {
      await expectLater(
        repo(config: const AuthConfig()).signInWithApple(),
        throwsA(isA<AuthFailure>().having((f) => f.code, 'code', AuthFailureCode.providerNotConfigured)),
      );
      expect(backend.calls, isEmpty);
    });
  });

  group('guest & upgrade (T1.5.11)', () {
    test('continue as guest: anonymous sign-up with metadata and the CAPTCHA token', () async {
      final user = await repo().continueAsGuest(captchaToken: 'captcha-1', metadata: {'time_zone': 'Africa/Tunis'});
      final call = backend.find('POST', '/auth/v1/signup')!;
      expect(call.body['data'], {'time_zone': 'Africa/Tunis'});
      expect((call.body['gotrue_meta_security'] as Map)['captcha_token'], 'captcha-1');
      expect(user.isAnonymous, isTrue);
      expect(user.email, isNull);
    });

    test('upgrade by e-mail keeps the user id (updateUser + email_change code)', () async {
      final r = repo();
      final guest = await r.continueAsGuest();
      await r.startEmailUpgrade('  Ana@Example.com ');
      expect(backend.find('PUT', '/auth/v1/user')!.body['email'], 'ana@example.com');
      final upgraded = await r.confirmEmailUpgrade('ana@example.com', '123 456');
      final verify = backend.find('POST', '/auth/v1/verify')!;
      expect(verify.body['type'], 'email_change');
      expect(verify.body['token'], '123456');
      expect(upgraded.id, guest.id);
      expect(upgraded.isAnonymous, isFalse);
    });

    test('upgrading to an e-mail already in use gives a clear code', () async {
      final r = repo();
      await r.continueAsGuest();
      backend.responses['PUT /auth/v1/user'] = (_) => _Backend.authError('email_exists', 422);
      await expectLater(
        r.startEmailUpgrade('taken@example.com'),
        throwsA(isA<AuthFailure>().having((f) => f.code, 'code', AuthFailureCode.emailInUse)),
      );
    });

    test('guest mode disabled / CAPTCHA required map to their codes', () async {
      backend.responses['POST /auth/v1/signup'] = (_) => _Backend.authError('anonymous_provider_disabled', 422);
      await expectLater(
        repo().continueAsGuest(),
        throwsA(isA<AuthFailure>().having((f) => f.code, 'code', AuthFailureCode.guestDisabled)),
      );
      backend.responses['POST /auth/v1/signup'] = (_) => _Backend.authError('captcha_failed', 400);
      await expectLater(
        repo().continueAsGuest(),
        throwsA(isA<AuthFailure>().having((f) => f.code, 'code', AuthFailureCode.captchaRequired)),
      );
    });

    test('linking Google to the signed-in account uses the ID token (same user)', () async {
      final r = repo();
      final guest = await r.continueAsGuest();
      backend.responses['POST /auth/v1/token'] = (call) =>
          _Backend._json(_session(_user(id: guest.id, providers: const ['google'])));
      final linked = await r.linkGoogle();
      final call = backend.find('POST', '/auth/v1/token')!;
      expect(call.query['grant_type'], 'id_token');
      expect(call.body['link_identity'], isTrue);
      expect(linked.id, guest.id);
      expect(linked.providers, ['google']);
    });
  });

  group('account deletion (T1.5.12)', () {
    test('records the request, then calls the account-delete function', () async {
      final r = repo();
      await r.verifyEmailCode('ana@example.com', '123456');
      await r.deleteAccount();
      final rpc = backend.find('POST', '/rest/v1/rpc/request_account_deletion')!;
      expect(rpc.headers['content-profile'], 'app');
      final fn = backend.find('POST', '/functions/v1/account-delete')!;
      expect(fn.headers['authorization'], startsWith('Bearer '));
      expect(
        backend.calls.indexWhere((c) => c.path == '/rest/v1/rpc/request_account_deletion'),
        lessThan(backend.calls.indexWhere((c) => c.path == '/functions/v1/account-delete')),
      );
    });

    test('a failed deletion is reported (nothing is wiped by the caller)', () async {
      final r = repo();
      await r.verifyEmailCode('ana@example.com', '123456');
      backend.responses['POST /functions/v1/account-delete'] = (_) => _Backend._json({'deleted': false}, 500);
      await expectLater(r.deleteAccount(), throwsA(isA<AuthFailure>()));
    });
  });

  group('identities & errors', () {
    test('the last identity cannot be unlinked', () async {
      final r = repo();
      await r.verifyEmailCode('ana@example.com', '123456');
      backend.responses['GET /auth/v1/user'] = (_) => _Backend._json(_user());
      await expectLater(
        r.unlink(const AuthIdentity(provider: 'email', identityId: 'identity-email')),
        throwsA(isA<AuthFailure>().having((f) => f.code, 'code', AuthFailureCode.lastIdentity)),
      );
    });

    test('Supabase Auth error codes map to stable failure codes', () {
      final table = {
        'otp_expired': AuthFailureCode.invalidCode,
        'over_email_send_rate_limit': AuthFailureCode.rateLimited,
        'email_exists': AuthFailureCode.emailInUse,
        'identity_already_exists': AuthFailureCode.identityInUse,
        'captcha_failed': AuthFailureCode.captchaRequired,
        'anonymous_provider_disabled': AuthFailureCode.guestDisabled,
        'provider_disabled': AuthFailureCode.providerNotConfigured,
        'refresh_token_not_found': AuthFailureCode.sessionExpired,
        'single_identity_not_deletable': AuthFailureCode.lastIdentity,
        'something_new': AuthFailureCode.unknown,
      };
      for (final e in table.entries) {
        expect(
          SupabaseAuthRepository.mapAuthException(sb.AuthException('x', code: e.key)).code,
          e.value,
          reason: e.key,
        );
      }
      expect(
        SupabaseAuthRepository.mapAuthException(const sb.AuthException('x', statusCode: '429')).code,
        AuthFailureCode.rateLimited,
      );
    });
  });
}
