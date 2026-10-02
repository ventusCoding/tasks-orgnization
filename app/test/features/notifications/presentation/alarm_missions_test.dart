import 'dart:async';
import 'dart:math' as math;

import 'package:everslot/features/notifications/application/alarm_sound.dart';
import 'package:everslot/features/notifications/domain/notification_actions.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/presentation/alarm_missions.dart';
import 'package:everslot/features/notifications/presentation/alarm_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';

class _FakeSound implements AlarmSound {
  final calls = <String>[];

  @override
  Future<void> start({required bool ramp}) async => calls.add('start(ramp: $ramp)');

  @override
  Future<void> stop() async => calls.add('stop');
}

/// Alarm dismissal missions (T7.2.25).
void main() {
  group('pure parts', () {
    test('shakes count peaks above the threshold, one per cooldown', () {
      final c = ShakeCounter();
      final t0 = DateTime(2026);
      expect(c.add(1, 1, 1, t0), isFalse, reason: 'too gentle');
      expect(c.add(15, 0, 0, t0), isTrue);
      expect(c.add(0, 15, 0, t0.add(const Duration(milliseconds: 100))), isFalse, reason: 'cooldown');
      expect(c.add(0, 0, 15, t0.add(const Duration(milliseconds: 400))), isTrue);
      expect(c.count, 2);
    });

    test('volume rises from 10 % to full over 30 s', () {
      expect(rampVolumeAt(Duration.zero), closeTo(0.1, 1e-9));
      expect(rampVolumeAt(const Duration(seconds: 15)), closeTo(0.55, 1e-9));
      expect(rampVolumeAt(const Duration(minutes: 2)), 1);
    });

    test('the generated beep is a valid PCM WAV', () {
      final wav = alarmBeepWav();
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
      expect(wav.length, 44 + 16000 * 2 * 0.8);
    });

    test('alarm options round-trip in delivery and payload', () {
      const options = AlarmOptions(
        mission: AlarmMission(type: AlarmMissionType.qr, code: 'kitchen'),
        maxSnoozes: 1,
        rampVolume: true,
      );
      final delivery = DeliverySpec.fromJson(const DeliverySpec(alarm: options).toJson());
      expect(delivery.alarm, options);
      final payload = NotificationPayload.tryDecode(
        const NotificationPayload(dedupeKey: 'k', alarm: true, alarmOptions: options).encode(),
      )!;
      expect(payload.alarmOptions, options);
      expect(const AlarmMission(type: AlarmMissionType.math).effectiveCount, 3);
      expect(const AlarmMission(type: AlarmMissionType.shake).effectiveCount, 20);
    });
  });

  group('mission views', () {
    late TestHarness h;
    late StreamController<(double, double, double, DateTime)> accel;
    setUp(() {
      accel = StreamController.broadcast();
      h = TestHarness.create(
        now: DateTime.utc(2026, 9, 22, 6),
        overrides: [
          accelerationStreamProvider.overrideWithValue(accel.stream),
          qrScannerBuilderProvider.overrideWithValue(
            (context, onCode) => Column(
              children: [
                TextButton(onPressed: () => onCode('wrong'), child: const Text('scan wrong')),
                TextButton(onPressed: () => onCode('kitchen'), child: const Text('scan right')),
              ],
            ),
          ),
        ],
      );
    });
    tearDown(() async {
      await accel.close();
      await h.dispose();
    });

    Future<int> pumpMission(WidgetTester tester, AlarmMission mission, {String? title}) async {
      var solved = 0;
      await pumpInApp(
        tester,
        h,
        Scaffold(
          body: AlarmMissionView(mission: mission, title: title, random: math.Random(7), onSolved: () => solved++),
        ),
      );
      return solved;
    }

    testWidgets('math: wrong answers are refused, N right answers solve it', (tester) async {
      var solved = 0;
      await pumpInApp(
        tester,
        h,
        Scaffold(
          body: AlarmMissionView(
            mission: const AlarmMission(type: AlarmMissionType.math, count: 2),
            random: math.Random(7),
            onSolved: () => solved++,
          ),
        ),
      );
      final r = math.Random(7);
      final first = MathProblem.random(r);
      await tester.enterText(find.byKey(const ValueKey('mission-input')), '${first.answer + 1}');
      await tester.tap(find.byKey(const ValueKey('mission-check')));
      await tester.pump();
      expect(find.text('Not quite — try again'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('mission-input')), '${first.answer}');
      await tester.tap(find.byKey(const ValueKey('mission-check')));
      await tester.pump();
      expect(find.text('Sum 2 of 2'), findsOneWidget);
      final second = MathProblem.random(r);
      await tester.enterText(find.byKey(const ValueKey('mission-input')), '${second.answer}');
      await tester.tap(find.byKey(const ValueKey('mission-check')));
      await tester.pump();
      expect(solved, 1);
    });

    testWidgets('type: the title, case-insensitive', (tester) async {
      var solved = 0;
      await pumpInApp(
        tester,
        h,
        Scaffold(
          body: AlarmMissionView(
            mission: const AlarmMission(type: AlarmMissionType.type),
            title: 'Take pills',
            onSolved: () => solved++,
          ),
        ),
      );
      await tester.enterText(find.byKey(const ValueKey('mission-input')), 'take pill');
      await tester.tap(find.byKey(const ValueKey('mission-check')));
      await tester.pump();
      expect(solved, 0);
      await tester.enterText(find.byKey(const ValueKey('mission-input')), ' TAKE PILLS ');
      await tester.tap(find.byKey(const ValueKey('mission-check')));
      await tester.pump();
      expect(solved, 1);
    });

    testWidgets('shake: counts accelerometer peaks', (tester) async {
      var solved = 0;
      await pumpInApp(
        tester,
        h,
        Scaffold(
          body: AlarmMissionView(
            mission: const AlarmMission(type: AlarmMissionType.shake, count: 3),
            onSolved: () => solved++,
          ),
        ),
      );
      final t0 = DateTime(2026);
      for (var i = 0; i < 3; i++) {
        accel.add((20, 0, 0, t0.add(Duration(seconds: i))));
        await tester.pump();
      }
      expect(solved, 1);
      expect(await pumpMission(tester, const AlarmMission(type: AlarmMissionType.shake)), 0);
    });

    testWidgets('qr: only the saved code stops it', (tester) async {
      var solved = 0;
      await pumpInApp(
        tester,
        h,
        Scaffold(
          body: AlarmMissionView(
            mission: const AlarmMission(type: AlarmMissionType.qr, code: 'kitchen'),
            onSolved: () => solved++,
          ),
        ),
      );
      await tester.tap(find.text('scan wrong'));
      expect(solved, 0);
      await tester.tap(find.text('scan right'));
      expect(solved, 1);
    });

    testWidgets('the alarm screen keeps Done / Stop locked and the sound on until the mission is done', (tester) async {
      final sound = _FakeSound();
      final app = TestHarness.create(
        now: DateTime.utc(2026, 9, 22, 6),
        overrides: [alarmSoundProvider.overrideWithValue(sound)],
      );
      addTearDown(app.dispose);
      await pumpInApp(
        tester,
        app,
        const AlarmScreen(
          payload: NotificationPayload(
            dedupeKey: 'k',
            title: 'Take pills',
            actions: ['done', 'snooze'],
            alarm: true,
            alarmOptions: AlarmOptions(mission: AlarmMission(type: AlarmMissionType.type), rampVolume: true),
          ),
        ),
      );
      expect(sound.calls, ['start(ramp: true)']);
      FilledButton done() => tester.widget<FilledButton>(find.byKey(const ValueKey('alarm-done')));
      OutlinedButton stop() => tester.widget<OutlinedButton>(find.byKey(const ValueKey('alarm-stop')));
      expect((done().onPressed, stop().onPressed), (null, null));
      expect(find.text('Complete the mission to stop the alarm'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('mission-input')), 'take pills');
      await tester.tap(find.byKey(const ValueKey('mission-check')));
      await tester.pump();
      expect(done().onPressed, isNotNull);
      expect(stop().onPressed, isNotNull);
      expect(sound.calls.last, 'stop');
    });
  });
}
