import 'package:everslot/core/providers.dart';
import 'package:everslot/core/session/local_data_owner.dart';
import 'package:everslot/core/session/local_only_choice.dart';
import 'package:everslot/core/session/session.dart';
import 'package:everslot/features/auth/application/auth_providers.dart';
import 'package:everslot/features/auth/domain/auth_models.dart';
import 'package:everslot/features/auth/presentation/sign_in_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import 'support/fake_auth_repository.dart';
import 'support/widget_helpers.dart';

void main() {
  testWidgets('e-mail → code → signed in; errors are localized; resend has a countdown', (tester) async {
    final repo = FakeAuthRepository();
    final h = cloudHarness(repo);
    await pumpInApp(tester, h, const SignInScreen());
    await settle(tester);
    expect(find.text('Welcome to Everslot'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('sign-in-email')), 'not-an-email');
    await tester.tap(find.byKey(const ValueKey('sign-in-send-code')));
    await settle(tester);
    expect(find.text('Please enter a valid email address.'), findsOneWidget);
    expect(repo.calls, isEmpty);

    await tester.enterText(find.byKey(const ValueKey('sign-in-email')), '  Me@Example.com ');
    await tester.tap(find.byKey(const ValueKey('sign-in-send-code')));
    await settle(tester);
    expect(repo.sentCodes, ['me@example.com']);
    expect(find.textContaining('me@example.com'), findsOneWidget);
    expect(find.text('Resend code in 60 seconds'), findsOneWidget);
    final resend = find.byKey(const ValueKey('sign-in-resend'));
    expect(tester.widget<TextButton>(resend).onPressed, isNull);

    await tester.enterText(find.byKey(const ValueKey('sign-in-code')), '000000');
    await settle(tester);
    expect(find.text('This code is invalid or has expired.'), findsOneWidget);
    expect(h.read(sessionProvider), isNull);

    // Cooldown over → resend enabled.
    h.clock.advance(const Duration(seconds: 61));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Resend code'), findsOneWidget);
    expect(tester.widget<TextButton>(resend).onPressed, isNotNull);

    // Pasting a code with spaces and Arabic-Indic digits works too.
    await tester.enterText(find.byKey(const ValueKey('sign-in-code')), '١٢٣ ٤٥٦');
    await settle(tester);
    final session = h.read(sessionProvider)!;
    expect(session.userId, 'user-me');
    expect(session.mode, SessionMode.cloud);
    expect(await tester.runAsync(() => LocalDataOwner.read(h.db)), 'user-me');
    await finish(tester, h);
  });

  testWidgets('change e-mail goes back to the first step, keeping the address', (tester) async {
    final h = cloudHarness(FakeAuthRepository());
    await pumpInApp(tester, h, const SignInScreen());
    await tester.enterText(find.byKey(const ValueKey('sign-in-email')), 'a@b.co');
    await tester.tap(find.byKey(const ValueKey('sign-in-send-code')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('sign-in-change-email')));
    await settle(tester);
    expect(find.byKey(const ValueKey('sign-in-email')), findsOneWidget);
    await finish(tester, h);
  });

  testWidgets('offline and rate-limit failures show friendly messages', (tester) async {
    final repo = FakeAuthRepository()..nextFailure = const AuthFailure(AuthFailureCode.offline);
    final h = cloudHarness(repo);
    await pumpInApp(tester, h, const SignInScreen());
    await tester.enterText(find.byKey(const ValueKey('sign-in-email')), 'a@b.co');
    await tester.tap(find.byKey(const ValueKey('sign-in-send-code')));
    await settle(tester);
    expect(find.text("You're offline. Check your connection and try again."), findsOneWidget);
    repo.nextFailure = const AuthFailure(AuthFailureCode.rateLimited);
    await tester.tap(find.byKey(const ValueKey('sign-in-send-code')));
    await settle(tester);
    expect(find.text('Too many attempts. Please wait a moment and try again.'), findsOneWidget);
    await finish(tester, h);
  });

  testWidgets('Google sign-in binds the session; cancelling shows nothing', (tester) async {
    final repo = FakeAuthRepository()..nextFailure = const AuthFailure(AuthFailureCode.cancelled);
    final h = cloudHarness(repo);
    await pumpInApp(tester, h, const SignInScreen());
    await tester.tap(find.byKey(const ValueKey('sign-in-google')));
    await settle(tester);
    expect(find.text('Something went wrong. Please try again.'), findsNothing);
    expect(h.read(sessionProvider), isNull);

    await tester.tap(find.byKey(const ValueKey('sign-in-google')));
    await settle(tester);
    expect(h.read(sessionProvider)?.userId, 'google-user');
    await finish(tester, h);
  });

  testWidgets('guest mode creates an anonymous cloud session', (tester) async {
    final h = cloudHarness(FakeAuthRepository());
    await pumpInApp(tester, h, const SignInScreen());
    await tester.ensureVisible(find.byKey(const ValueKey('sign-in-guest')));
    await tester.pump();
    await tester.tap(
      find.descendant(of: find.byKey(const ValueKey('sign-in-guest')), matching: find.byType(TextButton)),
    );
    await settle(tester);
    final session = h.read(sessionProvider)!;
    expect(session.isAnonymous, isTrue);
    expect(h.read(authStatusProvider), AuthStatus.anonymous);
    await finish(tester, h);
  });

  testWidgets('"use on this device only" starts a local-only session that survives restarts', (tester) async {
    final h = cloudHarness(FakeAuthRepository());
    await pumpInApp(tester, h, const SignInScreen());
    final button = find.descendant(
      of: find.byKey(const ValueKey('sign-in-local-only')),
      matching: find.byType(TextButton),
    );
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await settle(tester);
    expect(h.read(sessionProvider)?.isLocalOnly, isTrue);
    expect(await tester.runAsync(() => LocalOnlyChoice.isChosen(h.db)), isTrue);
    await finish(tester, h);
  });

  testWidgets('without cloud configuration the screen explains and continues locally', (tester) async {
    final h = TestHarness.create();
    await pumpInApp(tester, h, const SignInScreen());
    await settle(tester);
    expect(find.text("Cloud sync isn't configured"), findsOneWidget);
    expect(find.byKey(const ValueKey('sign-in-email')), findsNothing);
    await finish(tester, h);
  });

  testWidgets('Arabic: right-to-left layout, translated strings, code field stays LTR', (tester) async {
    final h = cloudHarness(FakeAuthRepository());
    await pumpInApp(tester, h, const SignInScreen(), locale: const Locale('ar'));
    await settle(tester);
    expect(find.text('مرحبًا بك في Everslot'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(ListView))), TextDirection.rtl);
    await tester.enterText(find.byKey(const ValueKey('sign-in-email')), 'a@b.co');
    await tester.tap(find.byKey(const ValueKey('sign-in-send-code')));
    await settle(tester);
    final field = tester.widget<TextField>(
      find.descendant(of: find.byKey(const ValueKey('sign-in-code')), matching: find.byType(TextField)),
    );
    expect(field.textDirection, TextDirection.ltr);
    expect(tester.takeException(), isNull);
    await finish(tester, h);
  });

  testWidgets('re-auth mode prefills the account e-mail and hides guest options', (tester) async {
    final h = cloudHarness(FakeAuthRepository(), signedOut: false);
    h.container
        .read(sessionProvider.notifier)
        .set(const AppSession(userId: 'u1', mode: SessionMode.cloud, email: 'me@example.com'));
    await pumpInApp(tester, h, const SignInScreen(mode: 'reauth'));
    await settle(tester);
    expect(find.text('Sign in again'), findsWidgets);
    expect(find.text('me@example.com'), findsOneWidget);
    expect(find.byKey(const ValueKey('sign-in-guest')), findsNothing);
    await finish(tester, h);
  });
}
