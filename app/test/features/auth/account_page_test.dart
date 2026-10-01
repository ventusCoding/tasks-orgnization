import 'package:everslot/core/providers.dart';
import 'package:everslot/core/session/session.dart';
import 'package:everslot/features/auth/application/account_service.dart';
import 'package:everslot/features/auth/domain/auth_models.dart';
import 'package:everslot/features/auth/presentation/session_banner_host.dart';
import 'package:everslot/features/profile/presentation/account_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import 'support/cloud_sync_harness.dart';
import 'support/widget_helpers.dart';

/// Bounded frames (dialog transitions; never `pumpAndSettle`).
Future<void> _frames(WidgetTester tester, {int n = 8}) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Lets the flow's async work (fake repository, database, binding) progress between frames.
Future<void> _run(WidgetTester tester) async {
  await settle(tester, rounds: 8);
  await _frames(tester);
}

Future<void> _enterIn(WidgetTester tester, Key field, String text) =>
    tester.enterText(find.descendant(of: find.byKey(field), matching: find.byType(EditableText)), text);

Future<CloudDevice> _device(WidgetTester tester, {bool guest = false}) async {
  final d = (await tester.runAsync(CloudDevice.create))!;
  if (guest) {
    d.h.read(sessionProvider.notifier).set(const AppSession(userId: 'u1', mode: SessionMode.cloud, isAnonymous: true));
    d.repo.currentUser = const AuthUser(id: 'u1', isAnonymous: true);
  } else {
    d.repo.currentUser = const AuthUser(id: 'u1', email: 'u1@x.io', providers: ['email']);
    d.repo.accounts['u1@x.io'] = 'u1';
  }
  await tester.binding.setSurfaceSize(const Size(800, 2000));
  return d;
}

Future<void> _done(WidgetTester tester, CloudDevice d) async {
  await tester.binding.setSurfaceSize(null);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.runAsync(d.dispose);
}

void main() {
  group('guest upgrade (T1.5.11)', () {
    testWidgets('adding an e-mail keeps the same user id and all data', (tester) async {
      final d = await _device(tester, guest: true);
      await pumpInApp(tester, d.h, const AccountPage());
      await _run(tester);
      expect(find.byKey(const ValueKey('account-upgrade')), findsOneWidget);
      expect(find.byKey(const ValueKey('account-delete')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('account-upgrade-email')));
      await _frames(tester);
      await _enterIn(tester, const ValueKey('value-dialog-email'), ' Ana@Example.com ');
      await tester.tap(find.byKey(const ValueKey('value-dialog-confirm')));
      await _run(tester);
      expect(find.byKey(const ValueKey('upgrade-code-dialog')), findsOneWidget);
      await _enterIn(tester, const ValueKey('value-dialog-code'), '123456');
      await tester.tap(find.byKey(const ValueKey('value-dialog-confirm')));
      await _run(tester);

      final session = d.h.read(sessionProvider)!;
      expect(session.userId, 'u1');
      expect(session.isAnonymous, isFalse);
      expect(session.email, 'ana@example.com');
      expect(d.repo.calls, contains('confirmEmailUpgrade:ana@example.com:123456'));
      expect(find.text('Your account is secured.'), findsOneWidget);
      expect(find.byKey(const ValueKey('account-upgrade')), findsNothing);
      await _done(tester, d);
    });

    testWidgets('an e-mail that already has an account shows the resolution path', (tester) async {
      final d = await _device(tester, guest: true);
      await pumpInApp(tester, d.h, const AccountPage());
      await _run(tester);
      await tester.tap(find.byKey(const ValueKey('account-upgrade-email')));
      await _frames(tester);
      await _enterIn(tester, const ValueKey('value-dialog-email'), 'taken@example.com');
      await tester.tap(find.byKey(const ValueKey('value-dialog-confirm')));
      await _run(tester);
      expect(find.byKey(const ValueKey('upgrade-email-in-use')), findsOneWidget);
      expect(find.textContaining('taken@example.com already has an Everslot account'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await _frames(tester);
      expect(d.h.read(sessionProvider)!.isAnonymous, isTrue, reason: 'still the same guest');
      await _done(tester, d);
    });
  });

  group('account deletion (T1.5.12)', () {
    testWidgets('acknowledge, re-authenticate with a fresh code, then everything is wiped', (tester) async {
      final d = await _device(tester);
      await tester.runAsync(() => d.addCategory('c1', 'Work'));
      await pumpInApp(tester, d.h, const AccountPage());
      await _run(tester);
      await tester.tap(find.byKey(const ValueKey('account-delete')));
      await _frames(tester);
      final proceed = find.byKey(const ValueKey('delete-continue'));
      expect(tester.widget<FilledButton>(proceed).onPressed, isNull, reason: 'needs the acknowledgement');
      await tester.tap(find.byKey(const ValueKey('delete-understand')));
      await tester.pump();
      await tester.tap(proceed);
      await _run(tester);
      expect(d.repo.sentCodes, ['u1@x.io'], reason: 'a fresh code for re-authentication');
      expect(find.byKey(const ValueKey('delete-code-dialog')), findsOneWidget);

      await _enterIn(tester, const ValueKey('value-dialog-code'), '000000');
      await tester.tap(find.byKey(const ValueKey('value-dialog-confirm')));
      await _run(tester);
      expect(find.text('This code is invalid or has expired.'), findsOneWidget);
      expect(d.repo.deleted, isFalse);

      await _enterIn(tester, const ValueKey('value-dialog-code'), '123456');
      await tester.tap(find.byKey(const ValueKey('value-dialog-confirm')));
      await _run(tester);
      expect(d.repo.deleted, isTrue);
      expect(d.h.read(sessionProvider), isNull);
      expect(await tester.runAsync(() => d.count('categories')), 0);
      expect(find.text('Your account has been deleted.'), findsOneWidget);
      await _done(tester, d);
    });

    testWidgets('"export my data first" leaves the account untouched', (tester) async {
      final d = await _device(tester);
      await pumpInApp(tester, d.h, const AccountPage());
      await _run(tester);
      await tester.tap(find.byKey(const ValueKey('account-delete')));
      await _frames(tester);
      await tester.tap(find.byKey(const ValueKey('delete-export')));
      await _run(tester);
      expect(d.repo.calls.where((c) => c.startsWith('sendEmailCode') || c == 'deleteAccount'), isEmpty);
      expect(d.h.read(sessionProvider), isNotNull);
      await _done(tester, d);
    });
  });

  testWidgets('sign-in methods: unlink (never the last one) and link Google (T1.5.13)', (tester) async {
    final d = await _device(tester);
    d.repo.identityList = const [
      AuthIdentity(provider: 'email', identityId: 'eid', email: 'u1@x.io'),
      AuthIdentity(provider: 'google', identityId: 'gid', email: 'u1@gmail.com'),
    ];
    await pumpInApp(tester, d.h, const AccountPage());
    await _run(tester);
    expect(find.byKey(const ValueKey('identity-email')), findsOneWidget);
    expect(find.byKey(const ValueKey('identity-google')), findsOneWidget);
    expect(find.byKey(const ValueKey('link-google')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('unlink-google')));
    await _frames(tester);
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Unlink')));
    await _run(tester);
    expect(d.repo.calls, contains('unlink:google'));
    expect(find.byKey(const ValueKey('identity-google')), findsNothing);
    expect(find.byKey(const ValueKey('unlink-email')), findsNothing, reason: 'the last method stays');

    await tester.tap(find.descendant(of: find.byKey(const ValueKey('link-google')), matching: find.text('Link')));
    await _run(tester);
    expect(d.repo.calls, contains('linkGoogle'));
    expect(find.text('Google linked'), findsOneWidget);
    expect(find.byKey(const ValueKey('identity-google')), findsOneWidget);
    await _done(tester, d);
  });

  group('guest banner (T1.5.11)', () {
    Widget host(List<String> opened) => SessionBannerHost(
      onOpen: opened.add,
      child: const Scaffold(body: Text('app')),
    );

    testWidgets('shown to guests, dismissible, back after a week', (tester) async {
      final d = await _device(tester, guest: true);
      final opened = <String>[];
      await pumpInApp(tester, d.h, host(opened));
      await _run(tester);
      expect(find.byKey(const ValueKey('banner-guest')), findsOneWidget);
      await tester.tap(find.text('Secure my data'));
      expect(opened, ['/settings/account']);

      await tester.tap(find.text('Close'));
      await _run(tester);
      expect(find.byKey(const ValueKey('banner-guest')), findsNothing);

      d.h.clock.advance(const Duration(days: 8));
      d.h.container.invalidate(guestBannerProvider);
      await _run(tester);
      expect(find.byKey(const ValueKey('banner-guest')), findsOneWidget);
      await _done(tester, d);
    });

    testWidgets('never shown to regular or local-only accounts', (tester) async {
      final d = await _device(tester);
      await pumpInApp(tester, d.h, host([]));
      await _run(tester);
      expect(find.byKey(const ValueKey('banner-guest')), findsNothing);
      await _done(tester, d);
      final h = TestHarness.create();
      await pumpInApp(tester, h, host([]));
      await settle(tester);
      expect(find.byKey(const ValueKey('banner-guest')), findsNothing);
      await finish(tester, h);
    });
  });
}
