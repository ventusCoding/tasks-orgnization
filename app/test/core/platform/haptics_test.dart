import 'package:everslot/core/platform/haptics.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

/// Waits until [check] holds (settings arrive through a Drift stream).
Future<void> _until(bool Function() check) async {
  for (var i = 0; i < 100 && !check(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(check(), isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );

  List<String> feedback() => [
    for (final c in calls)
      if (c.method == 'HapticFeedback.vibrate')
        '${c.arguments}'
      else if (c.method == 'SystemSound.play')
        'sound:${c.arguments}',
  ];

  test('each moment maps to its platform pattern; sounds are off by default', () async {
    final h = TestHarness.create();
    final haptics = h.read(hapticsProvider);
    await haptics.selection();
    await haptics.lift();
    await haptics.light();
    await haptics.success();
    await haptics.warning();
    await haptics.denied();
    expect(feedback(), [
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.mediumImpact',
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.successNotification',
      'HapticFeedbackType.warningNotification',
      'HapticFeedbackType.errorNotification',
    ]);
    await h.dispose();
  });

  test('the user setting turns haptics off (read at each event, no rebuild needed)', () async {
    final h = TestHarness.create();
    // The app root watches the appearance namespace (EverslotApp); unlistened providers pause.
    final keep = h.container.listen(settingsProvider(SettingsNs.appearance), (_, _) {});
    final haptics = h.read(hapticsProvider);
    await _until(() => h.read(settingsProvider(SettingsNs.appearance)).value != null);
    await h.read(settingsRepositoryProvider).update(SettingsNs.appearance, {'haptics': false});
    await _until(() => !h.read(hapticsEnabledProvider));
    await haptics.success();
    await haptics.selection();
    expect(feedback(), isEmpty);
    expect(identical(haptics, h.read(hapticsProvider)), isTrue);
    keep.close();
    await h.dispose();
  });

  test('completion sound only when sounds are on', () async {
    final h = TestHarness.create();
    final keep = h.container.listen(settingsProvider(SettingsNs.appearance), (_, _) {});
    await h.read(settingsRepositoryProvider).update(SettingsNs.appearance, {'sounds': true});
    final haptics = h.read(hapticsProvider);
    await _until(() => h.read(uiSoundsEnabledProvider));
    await haptics.success();
    await haptics.selection();
    expect(feedback(), [
      'HapticFeedbackType.successNotification',
      'sound:SystemSoundType.click',
      'HapticFeedbackType.selectionClick',
    ]);
    keep.close();
    await h.dispose();
  });

  test('platform failures are swallowed', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => throw PlatformException(code: 'no_vibrator'),
    );
    final h = TestHarness.create();
    await expectLater(h.read(hapticsProvider).success(), completes);
    await h.dispose();
  });

  test('a custom output receives the events (features can fake it)', () async {
    final out = _RecordingOutput();
    final haptics = Haptics(output: out, hapticsEnabled: () => true, soundsEnabled: () => true);
    await haptics.success();
    await haptics.lift();
    expect(out.events, ['success', 'click', 'lift']);
  });
}

class _RecordingOutput implements HapticsOutput {
  final events = <String>[];

  @override
  Future<void> haptic(HapticEvent event) async => events.add(event.name);

  @override
  Future<void> sound(UiSound sound) async => events.add(sound.name);
}
