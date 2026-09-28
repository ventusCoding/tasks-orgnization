import 'package:everslot/features/habits/domain/coping.dart';
import 'package:test/test.dart';

void main() {
  group('craving timer (T5.3.16)', () {
    final start = DateTime.utc(2026, 9, 22, 10);

    test('counts down three minutes from its start instant', () {
      final t = CravingTimer(start);
      expect(t.remaining(start), cravingTimerDuration);
      expect(t.remaining(start.add(const Duration(seconds: 70))), const Duration(seconds: 110));
      expect(t.progress(start.add(const Duration(seconds: 90))), 0.5);
      expect(t.finished(start.add(const Duration(minutes: 3))), isTrue);
      expect(t.remaining(start.add(const Duration(minutes: 5))), Duration.zero);
    });

    test('stored duration is the elapsed time, capped at the timer length', () {
      final t = CravingTimer(start);
      expect(t.durationSeconds(start.add(const Duration(seconds: 95))), 95);
      expect(t.durationSeconds(start.add(const Duration(minutes: 10))), 180);
      expect(t.durationSeconds(start.subtract(const Duration(seconds: 5))), 0, reason: 'clock skew');
    });
  });

  group('breathing patterns', () {
    test('box breathing: 4 s per phase, cycles of 16 s', () {
      const p = BreathingPattern.box;
      expect(p.cycleSeconds, 16);
      expect(p.at(Duration.zero), (phase: BreathPhase.inhale, secondsLeft: 4, cycle: 1));
      expect(p.at(const Duration(seconds: 5)), (phase: BreathPhase.hold, secondsLeft: 3, cycle: 1));
      expect(p.at(const Duration(seconds: 12)), (phase: BreathPhase.holdEmpty, secondsLeft: 4, cycle: 1));
      expect(p.at(const Duration(seconds: 17)), (phase: BreathPhase.inhale, secondsLeft: 3, cycle: 2));
    });

    test('4-7-8 skips the empty hold', () {
      const p = BreathingPattern.relax478;
      expect(p.phases.map((e) => e.$1), [BreathPhase.inhale, BreathPhase.hold, BreathPhase.exhale]);
      expect(p.at(const Duration(seconds: 11)), (phase: BreathPhase.exhale, secondsLeft: 8, cycle: 1));
      expect(p.at(const Duration(seconds: 19)), (phase: BreathPhase.inhale, secondsLeft: 4, cycle: 2));
    });
  });
}
