import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/features/auth/application/auth_binding.dart';
import 'package:everslot/features/auth/application/auth_providers.dart';
import 'package:everslot/features/auth/domain/auth_models.dart';
import 'package:everslot/features/auth/domain/auth_repository.dart';

import '../../../support/test_app.dart';

/// In-memory [AuthRepository]: e-mail codes, providers, guests, identities, deletion.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.googleAvailable = true, this.appleAvailable = false});

  final _changes = StreamController<AuthUser?>.broadcast(sync: true);

  @override
  AuthUser? currentUser;

  @override
  bool googleAvailable;

  @override
  bool appleAvailable;

  String code = '123456';

  /// Users by e-mail (existing accounts).
  final Map<String, String> accounts = {'taken@example.com': 'existing-user'};

  /// Next call of any method fails with this.
  AuthFailure? nextFailure;

  /// Provider results.
  AuthUser? googleUser = const AuthUser(id: 'google-user', email: 'g@example.com', providers: ['google']);

  final calls = <String>[];
  final sentCodes = <String>[];
  List<AuthIdentity> identityList = const [];
  bool refreshSucceeds = true;
  bool deleted = false;
  String? pendingUpgradeEmail;
  var _guests = 0;

  void _maybeFail() {
    final f = nextFailure;
    if (f != null) {
      nextFailure = null;
      throw f;
    }
  }

  AuthUser _signIn(AuthUser user) {
    currentUser = user;
    _changes.add(user);
    return user;
  }

  /// Simulates Supabase ending the session (refresh token rejected, other device…).
  void endSession() {
    currentUser = null;
    _changes.add(null);
  }

  @override
  Stream<AuthUser?> get userChanges => _changes.stream;

  @override
  Future<void> sendEmailCode(String email, {Map<String, Object?> metadata = const {}}) async {
    calls.add('sendEmailCode:$email');
    _maybeFail();
    if (!isValidEmail(email)) throw const AuthFailure(AuthFailureCode.invalidEmail);
    sentCodes.add(email);
  }

  @override
  Future<AuthUser> verifyEmailCode(String email, String code) async {
    calls.add('verifyEmailCode:$email:$code');
    _maybeFail();
    if (code != this.code) throw const AuthFailure(AuthFailureCode.invalidCode);
    final id = accounts.putIfAbsent(email, () => 'user-${email.split('@').first}');
    return _signIn(AuthUser(id: id, email: email, providers: const ['email']));
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    calls.add('google');
    _maybeFail();
    return _signIn(googleUser!);
  }

  @override
  Future<AuthUser?> signInWithApple() async {
    calls.add('apple');
    _maybeFail();
    return null; // browser flow started
  }

  @override
  Future<AuthUser> continueAsGuest({String? captchaToken, Map<String, Object?> metadata = const {}}) async {
    calls.add('guest');
    _maybeFail();
    return _signIn(AuthUser(id: 'guest-${++_guests}', isAnonymous: true));
  }

  @override
  Future<void> startEmailUpgrade(String email) async {
    calls.add('startEmailUpgrade:$email');
    _maybeFail();
    if (accounts.containsKey(email)) throw const AuthFailure(AuthFailureCode.emailInUse);
    pendingUpgradeEmail = email;
  }

  @override
  Future<AuthUser> confirmEmailUpgrade(String email, String code) async {
    calls.add('confirmEmailUpgrade:$email:$code');
    _maybeFail();
    if (code != this.code || pendingUpgradeEmail != email) throw const AuthFailure(AuthFailureCode.invalidCode);
    final user = AuthUser(id: currentUser!.id, email: email, providers: const ['email']);
    accounts[email] = user.id;
    return _signIn(user);
  }

  @override
  Future<AuthUser> linkGoogle() async {
    calls.add('linkGoogle');
    _maybeFail();
    final user = AuthUser(
      id: currentUser!.id,
      email: currentUser!.email ?? googleUser!.email,
      providers: {...currentUser!.providers, 'google'}.toList()..sort(),
    );
    identityList = [...identityList, const AuthIdentity(provider: 'google', identityId: 'gid')];
    return _signIn(user);
  }

  @override
  Future<AuthUser?> linkApple() async {
    calls.add('linkApple');
    _maybeFail();
    return null;
  }

  @override
  Future<List<AuthIdentity>> identities() async {
    _maybeFail();
    return identityList;
  }

  @override
  Future<void> unlink(AuthIdentity identity) async {
    calls.add('unlink:${identity.provider}');
    _maybeFail();
    if (identityList.length <= 1) throw const AuthFailure(AuthFailureCode.lastIdentity);
    identityList = [for (final i in identityList) if (i.identityId != identity.identityId) i];
  }

  @override
  Future<void> updateDisplayName(String? name) async {
    calls.add('updateDisplayName:$name');
    _maybeFail();
  }

  @override
  Future<void> deleteAccount() async {
    calls.add('deleteAccount');
    _maybeFail();
    deleted = true;
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    currentUser = null;
    _changes.add(null);
  }

  @override
  Future<bool> refreshSession() async {
    calls.add('refresh');
    return refreshSucceeds;
  }
}

/// Harness with cloud auth available (fake repository) and, by default, no session.
TestHarness cloudHarness(FakeAuthRepository repo, {bool signedOut = true}) {
  final h = TestHarness.create(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      accountStartupProvider.overrideWithValue((_) async {}),
    ],
  );
  if (signedOut) h.container.read(sessionProvider.notifier).set(null);
  return h;
}
