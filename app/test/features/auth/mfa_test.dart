import 'package:everslot/core/providers.dart';
import 'package:everslot/features/auth/application/account_service.dart';
import 'package:everslot/features/auth/domain/auth_models.dart';
import 'package:everslot/features/auth/presentation/sign_in_screen.dart';
import 'package:everslot/features/profile/presentation/account_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import 'support/cloud_sync_harness.dart';
import 'support/fake_auth_repository.dart';
import 'support/widget_helpers.dart';

/// T1.5.17: optional TOTP two-step verification — set up, turn off, sign-in step-up, and the
/// authenticator step before account deletion.
void main() {
  Future<void> frames(WidgetTester tester, {int n = 8}) async {
    for (var i = 0; i < n; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> run(WidgetTester tester) async {
    await settle(tester, rounds: 8);
    await frames(tester);
  }

  Future<void> enterIn(WidgetTester tester, Key field, String text) =>
      tester.enterText(find.descendant(of: find.byKey(field), matching: find.byType(EditableText)), text);

  Future<void> submitCode(WidgetTester tester, String code) async {
    await enterIn(tester, const ValueKey('value-dialog-code'), code);
    await tester.tap(find.byKey(const ValueKey('value-dialog-confirm')));
    await run(tester);
  }

  Future<CloudDevice> device(WidgetTester tester) async {
    final d = (await tester.runAsync(CloudDevice.create))!;
    d.repo.currentUser = const AuthUser(id: 'u1', email: 'u1@x.io', providers: ['email']);
    d.repo.accounts['u1@x.io'] = 'u1';
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    return d;
  }

  Future<void> done(WidgetTester tester, CloudDevice d) async {
    await tester.binding.setSurfaceSize(null);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(d.dispose);
  }

  testWidgets('set up: key shown, a wrong code is refused, the right one turns it on', (tester) async {
    final d = await device(tester);
    await pumpInApp(tester, d.h, const AccountPage());
    await run(tester);
    expect(find.text('Two-step verification'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('account-mfa-action')));
    await run(tester);

    expect(find.byKey(const ValueKey('mfa-enroll-dialog')), findsOneWidget);
    expect(find.text('JBSW Y3DP EHPK 3PXP'), findsOneWidget, reason: 'grouped for typing');
    await submitCode(tester, '000000');
    expect(find.text('This code is invalid or has expired.'), findsOneWidget);
    expect(d.repo.factors.single.verified, isFalse);

    await submitCode(tester, '654321');
    expect(d.repo.factors.single.verified, isTrue);
    expect(find.text('Two-step verification is on.'), findsWidgets);
    expect(find.text('Turn off'), findsOneWidget);
    await done(tester, d);
  });

  testWidgets('turn off needs a current code, then every factor is removed', (tester) async {
    final d = await device(tester);
    d.repo.factors.add(const MfaFactor(id: 'f1', verified: true));
    await pumpInApp(tester, d.h, const AccountPage());
    await run(tester);
    await tester.tap(find.byKey(const ValueKey('account-mfa-action')));
    await run(tester);
    expect(find.byKey(const ValueKey('mfa-disable-dialog')), findsOneWidget);
    await submitCode(tester, '654321');
    expect(d.repo.factors, isEmpty);
    expect(d.repo.calls, containsAllInOrder(['verifyTotp:f1:654321', 'unenrollMfa:f1']));
    expect(find.text('Two-step verification is off.'), findsOneWidget);
    await done(tester, d);
  });

  testWidgets('deletion asks for the authenticator code after the e-mail code', (tester) async {
    final d = await device(tester);
    d.repo.factors.add(const MfaFactor(id: 'f1', verified: true));
    await pumpInApp(tester, d.h, const AccountPage());
    await run(tester);
    await tester.tap(find.byKey(const ValueKey('account-delete')));
    await frames(tester);
    await tester.tap(find.byKey(const ValueKey('delete-understand')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('delete-continue')));
    await run(tester);

    await submitCode(tester, '123456');
    expect(d.repo.deleted, isFalse);
    expect(find.byKey(const ValueKey('delete-mfa-dialog')), findsOneWidget);
    await submitCode(tester, '111111');
    expect(find.text('This code is invalid or has expired.'), findsOneWidget);
    expect(d.repo.deleted, isFalse);

    await submitCode(tester, '654321');
    expect(d.repo.deleted, isTrue);
    expect(d.h.read(sessionProvider), isNull);
    expect(d.repo.calls.where((c) => c.startsWith('verifyEmailCode')), hasLength(1), reason: 'e-mail code used once');
    await done(tester, d);
  });

  test('without MFA deletion needs no authenticator code; with it, a stale re-auth is refused', () async {
    final repo = FakeAuthRepository();
    final h = cloudHarness(repo, signedOut: false);
    addTearDown(h.dispose);
    final service = h.read(accountServiceProvider);
    expect(service.mfaStepUpRequired, isFalse);

    repo.factors.add(const MfaFactor(id: 'f1', verified: true));
    expect(service.mfaStepUpRequired, isTrue);
    await expectLater(
      service.deleteAccount(mfaCode: '654321'),
      throwsA(isA<AuthFailure>()),
      reason: 'no recent e-mail re-authentication',
    );
    expect(repo.deleted, isFalse);
  });

  testWidgets('sign-in: the authenticator code completes it; declining signs out again', (tester) async {
    for (final accept in [true, false]) {
      final repo = FakeAuthRepository()..factors.add(const MfaFactor(id: 'f1', verified: true));
      final h = cloudHarness(repo);
      await pumpInApp(tester, h, const SignInScreen());
      await settle(tester);
      await tester.enterText(find.byKey(const ValueKey('sign-in-email')), 'me@example.com');
      await tester.tap(find.byKey(const ValueKey('sign-in-send-code')));
      await settle(tester);
      await tester.enterText(find.byKey(const ValueKey('sign-in-code')), '123456');
      await run(tester);

      expect(find.byKey(const ValueKey('mfa-step-up-dialog')), findsOneWidget, reason: 'accept: $accept');
      if (accept) {
        await submitCode(tester, '654321');
        expect(repo.mfaStepUpRequired, isFalse);
        expect(h.read(sessionProvider), isNotNull);
      } else {
        await tester.tap(find.text('Sign out').last);
        await run(tester);
        // The usual sign-out confirmation, then the session ends.
        await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
        await run(tester);
        expect(repo.calls, contains('signOut'));
        expect(h.read(sessionProvider), isNull);
      }
      await finish(tester, h);
    }
  });
}
