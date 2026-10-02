import 'dart:io';

import 'package:everslot/core/database/database_encryption.dart';
import 'package:everslot/core/lifecycle/app_lifecycle.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/session/secure_session_storage.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/features/privacy/application/app_lock_controller.dart';
import 'package:everslot/features/privacy/data/authenticator.dart';
import 'package:everslot/features/privacy/data/privacy_window.dart';
import 'package:everslot/features/privacy/domain/app_lock.dart';
import 'package:everslot/features/privacy/presentation/app_lock_gate.dart';
import 'package:everslot/features/privacy/presentation/privacy_page.dart';
import 'package:everslot/features/settings/application/settings_providers.dart';
import 'package:everslot/features/settings/domain/settings_models.dart';
import 'package:everslot/l10n/generated/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

class FakeAuthenticator implements Authenticator {
  bool supported = true;
  bool result = true;
  int calls = 0;

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<bool> authenticate(String reason) async {
    calls++;
    return result;
  }
}

class FakePrivacyWindow extends PrivacyWindow {
  final calls = <bool>[];

  @override
  Future<void> setSecure({required bool secure}) async => calls.add(secure);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final l10n = AppLocalizationsEn();

  test('AppLockPolicy locks only after a real background stay of at least the timeout', () {
    bool lock(int timeout, Duration away, {bool enabled = true}) =>
        AppLockPolicy.lockOnReturn(enabled: enabled, timeoutSeconds: timeout, away: away);
    expect(lock(0, Duration.zero), isFalse, reason: 'inactive only (system dialog)');
    expect(lock(0, const Duration(seconds: 1)), isTrue);
    expect(lock(60, const Duration(seconds: 59)), isFalse);
    expect(lock(60, const Duration(seconds: 60)), isTrue);
    expect(lock(0, const Duration(hours: 1), enabled: false), isFalse);
  });

  group('AppLockController', () {
    late TestHarness h;
    late FakeAuthenticator auth;
    late FakePrivacyWindow window;

    AppLifecycleService lifecycle() => h.read(lifecycleProvider);
    AppLockState lock() => h.read(appLockProvider);
    void move(AppLifecycleState s) => lifecycle().didChangeAppLifecycleState(s);

    void background(Duration away) {
      move(AppLifecycleState.inactive);
      move(AppLifecycleState.hidden);
      move(AppLifecycleState.paused);
      h.clock.advance(away);
      move(AppLifecycleState.hidden);
      move(AppLifecycleState.inactive);
      move(AppLifecycleState.resumed);
    }

    Future<void> start(Map<String, Object?> privacy) async {
      auth = FakeAuthenticator();
      window = FakePrivacyWindow();
      h = TestHarness.create(
        overrides: [
          authenticatorProvider.overrideWithValue(auth),
          privacyWindowProvider.overrideWithValue(window),
          lifecycleProvider.overrideWith((ref) {
            final service = AppLifecycleService(clock: ref.read(clockProvider));
            ref.onDispose(service.dispose);
            return service;
          }),
        ],
      );
      if (privacy.isNotEmpty) await h.read(settingsRepositoryProvider).update(SettingsNs.privacy, privacy);
      h.container.listen(appLockProvider, (_, _) {});
      for (var i = 0; i < 200 && !lock().ready; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(lock().ready, isTrue);
    }

    tearDown(() => h.dispose());

    test('stays open when the lock is off', () async {
      await start({});
      expect(lock().covered, isFalse);
      background(const Duration(hours: 2));
      expect(lock().covered, isFalse);
      expect(window.calls.last, isFalse);
    });

    test('a cold start locks; unlock succeeds or keeps the content covered', () async {
      await start({'appLockEnabled': true});
      expect(lock().locked, isTrue);
      expect(window.calls.last, isTrue, reason: 'FLAG_SECURE while the lock is on');

      auth.result = false;
      expect(await h.read(appLockProvider.notifier).unlock(l10n), isFalse);
      expect(lock().locked, isTrue);

      auth.result = true;
      expect(await h.read(appLockProvider.notifier).unlock(l10n), isTrue);
      expect(lock().covered, isFalse);
      expect(auth.calls, 2);
    });

    test('locks again after the configured time in the background', () async {
      await start({'appLockEnabled': true, 'appLockTimeoutSeconds': 60});
      await h.read(appLockProvider.notifier).unlock(l10n);

      background(const Duration(seconds: 30));
      expect(lock().locked, isFalse);

      background(const Duration(seconds: 61));
      expect(lock().locked, isTrue);
    });

    test('a system dialog (inactive only) does not lock, even with an immediate timeout', () async {
      await start({'appLockEnabled': true});
      await h.read(appLockProvider.notifier).unlock(l10n);
      move(AppLifecycleState.inactive);
      expect(lock().obscured, isTrue);
      move(AppLifecycleState.resumed);
      expect(lock().covered, isFalse);
    });

    test('the return from a credential screen opened by the prompt does not relock', () async {
      await start({'appLockEnabled': true});
      // The device-credential activity backgrounds the app; auth completes before `resumed`.
      move(AppLifecycleState.inactive);
      move(AppLifecycleState.hidden);
      move(AppLifecycleState.paused);
      h.clock.advance(const Duration(seconds: 8));
      expect(await h.read(appLockProvider.notifier).unlock(l10n), isTrue);
      move(AppLifecycleState.hidden);
      move(AppLifecycleState.inactive);
      move(AppLifecycleState.resumed);
      expect(lock().covered, isFalse);

      background(const Duration(seconds: 5));
      expect(lock().locked, isTrue, reason: 'only that one return is ignored');
    });

    test('app-switcher privacy covers the content while inactive without a lock', () async {
      await start({'appSwitcherPrivacy': true});
      expect(window.calls.last, isTrue);
      move(AppLifecycleState.inactive);
      expect(lock().covered, isTrue);
      expect(lock().locked, isFalse);
      move(AppLifecycleState.resumed);
      expect(lock().covered, isFalse);
    });

    test('turning the lock off unlocks', () async {
      await start({'appLockEnabled': true});
      await h.read(settingsWriterProvider).update(PrivacySettings.codec, (p) => p.copyWith(appLockEnabled: false));
      for (var i = 0; i < 100 && lock().locked; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(lock().locked, isFalse);
    });
  });

  group('widgets', () {
    late TestHarness h;
    late FakeAuthenticator auth;

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump();
      }
    }

    Future<void> pump(
      WidgetTester tester,
      Widget child, {
      Map<String, Object?> privacy = const {},
      bool authResult = true,
      bool supported = true,
    }) async {
      auth = FakeAuthenticator()
        ..result = authResult
        ..supported = supported;
      h = TestHarness.create(
        overrides: [
          authenticatorProvider.overrideWithValue(auth),
          privacyWindowProvider.overrideWithValue(FakePrivacyWindow()),
          databaseEncryptionProvider.overrideWithValue(
            DatabaseEncryption(
              store: MemorySecureStore(),
              file: () async => File('${Directory.systemTemp.path}/everslot-absent.sqlite'),
            ),
          ),
        ],
      );
      addTearDown(h.dispose);
      await tester.runAsync(() async {
        if (privacy.isNotEmpty) await h.read(settingsRepositoryProvider).update(SettingsNs.privacy, privacy);
      });
      await pumpInApp(tester, h, child);
      await settle(tester);
    }

    testWidgets('no lock screen when the lock is off', (tester) async {
      await pump(tester, const AppLockGate(child: Text('secret')));
      expect(find.byKey(const ValueKey('lock-screen')), findsNothing);
      expect(find.text('secret'), findsOneWidget);
      expect(auth.calls, 0);
    });

    testWidgets('the lock screen prompts on show and unlocks from its button', (tester) async {
      await pump(
        tester,
        const AppLockGate(child: Text('secret')),
        privacy: {'appLockEnabled': true},
        authResult: false,
      );
      expect(find.byKey(const ValueKey('lock-screen')), findsOneWidget);
      expect(auth.calls, 1, reason: 'automatic prompt');
      expect(find.text('Everslot is locked'), findsOneWidget);

      auth.result = true;
      await tester.tap(find.byKey(const ValueKey('lock-unlock')));
      await settle(tester);
      expect(auth.calls, 2);
      expect(find.byKey(const ValueKey('lock-screen')), findsNothing);
      expect(find.text('secret'), findsOneWidget);
    });

    testWidgets('privacy page: enabling the lock requires authenticating first', (tester) async {
      await pump(tester, const PrivacyPage(), authResult: false);
      await tester.tap(find.byKey(const ValueKey('privacy-app-lock')));
      await settle(tester);
      expect(auth.calls, 1);
      expect(h.read(privacySettingsProvider).appLockEnabled, isFalse);
      expect(find.byKey(const ValueKey('privacy-lock-timeout')), findsNothing);

      auth.result = true;
      await tester.tap(find.byKey(const ValueKey('privacy-app-lock')));
      await settle(tester);
      expect(h.read(privacySettingsProvider).appLockEnabled, isTrue);
      expect(find.byKey(const ValueKey('privacy-lock-timeout')), findsOneWidget);
    });

    testWidgets('privacy page: no lock without a device screen lock', (tester) async {
      await pump(tester, const PrivacyPage(), supported: false);
      await tester.tap(find.byKey(const ValueKey('privacy-app-lock')));
      await settle(tester);
      expect(auth.calls, 0);
      expect(find.text('Set up a screen lock on this device first.'), findsOneWidget);
      expect(h.read(privacySettingsProvider).appLockEnabled, isFalse);
    });

    testWidgets('privacy page: hiding notification content writes both keys', (tester) async {
      await pump(tester, const PrivacyPage());
      await tester.tap(find.byKey(const ValueKey('privacy-hide-notifications')));
      await settle(tester);
      expect(h.read(privacySettingsProvider).hideNotificationContent, isTrue);
    });

    testWidgets('privacy page: database encryption is applied at the next start', (tester) async {
      final store = MemorySecureStore();
      final tmp = Directory.systemTemp.createTempSync('everslot_enc_ui_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      auth = FakeAuthenticator();
      h = TestHarness.create(
        overrides: [
          authenticatorProvider.overrideWithValue(auth),
          privacyWindowProvider.overrideWithValue(FakePrivacyWindow()),
          databaseEncryptionProvider.overrideWithValue(
            DatabaseEncryption(store: store, file: () async => File('${tmp.path}/everslot.sqlite')),
          ),
        ],
      );
      addTearDown(h.dispose);
      await pumpInApp(tester, h, const PrivacyPage());
      await settle(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('privacy-encrypt-db')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('privacy-encrypt-db')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await settle(tester);
      expect(store.values[DatabaseEncryption.wantedName], 'true');
      expect(find.text('Encryption starts the next time Everslot opens'), findsOneWidget);
    });
  });
}
