import 'package:everslot/core/env/env.dart';
import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/sync/sync_api.dart' show DeviceRegistration;
import 'package:everslot/features/settings/application/feedback_service.dart';
import 'package:everslot/features/settings/domain/feedback_diagnostics.dart';
import 'package:everslot/features/settings/presentation/pages/about_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

const _secret = 'Buy milk for Sam';

DeviceRegistration _device() => const DeviceRegistration(
  id: 'device-test',
  platform: 'android',
  model: 'Google Pixel 3a',
  osVersion: '14',
  appVersion: '1.4.0',
  appBuild: 42,
  locale: 'fr-FR',
  timeZone: 'Europe/Paris',
  deviceName: "Sam's phone",
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppLog.init();
    AppLog.clear();
  });

  test('error codes keep the exception type, never the message', () {
    expect(
      FeedbackDiagnostics.errorCode('planner.service', 'FormatException: $_secret'),
      'planner.service/FormatException',
    );
    expect(FeedbackDiagnostics.errorCode('sync', '$_secret broke'), 'sync');
    expect(FeedbackDiagnostics.errorCode('Not A Logger $_secret', 'StateError'), isNull);
    expect(FeedbackDiagnostics.token('Pixel 3a'), 'Pixel 3a');
    expect(FeedbackDiagnostics.token('x@y.com <script>'), isNull);
  });

  test('diagnostics contain no user content (T8.3.17)', () async {
    Logger('planner.service').severe('Saving "$_secret" failed', 'FormatException: $_secret', StackTrace.current);
    Logger('checklists').warning('item $_secret', StateError(_secret));
    Logger('ui').info('opened $_secret');
    final h = TestHarness.create(overrides: [feedbackDeviceInfoProvider.overrideWithValue(() async => _device())]);
    addTearDown(h.dispose);
    final text = (await h.read(feedbackDiagnosticsProvider.future)).toText();
    expect(text, contains('App: 1.4.0+42 (dev)'));
    expect(text, contains('Device model: Google Pixel 3a'));
    expect(text, contains('Device id: device-test'));
    expect(text, contains('Sync: local only'));
    expect(text, contains('Recent errors: planner.service/FormatException, checklists/StateError'));
    for (final forbidden in [_secret, 'milk', 'Sam', 'phone', 'Europe/Paris', 'user-1']) {
      expect(text, isNot(contains(forbidden)), reason: forbidden);
    }
  });

  testWidgets('the sheet shows the diagnostics verbatim and sends them by e-mail', (tester) async {
    final opened = <Uri>[];
    final h = TestHarness.create(
      env: const Env(
        flavor: Flavor.dev,
        supabaseUrl: '',
        supabasePublishableKey: '',
        firebaseEnabled: false,
        featureFlags: {},
        supportEmail: 'help@everslot.example',
      ),
      overrides: [
        feedbackDeviceInfoProvider.overrideWithValue(() async => _device()),
        externalLinkLauncherProvider.overrideWithValue((uri) async {
          opened.add(uri);
          return true;
        }),
      ],
    );
    await pumpInApp(tester, h, const Scaffold(body: FeedbackSheet()));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.enterText(find.byKey(const ValueKey('feedback-message')), 'The week view is great');
    await tester.tap(find.byKey(const ValueKey('feedback-preview')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Device model: Google Pixel 3a'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('feedback-send')));
    await tester.pump();
    final mail = opened.single;
    expect(mail.scheme, 'mailto');
    expect(mail.path, 'help@everslot.example');
    final body = Uri.decodeComponent(mail.query.split('body=').last);
    expect(body, startsWith('The week view is great\n\n---\nApp: 1.4.0+42'));

    // Without diagnostics only the message goes.
    opened.clear();
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpInApp(tester, h, const Scaffold(body: FeedbackSheet()));
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('feedback-message')), 'Hi');
    await tester.tap(find.byKey(const ValueKey('feedback-diagnostics')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('feedback-send')));
    await tester.pump();
    expect(Uri.decodeComponent(opened.single.query.split('body=').last), 'Hi');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(h.dispose);
  });
}
