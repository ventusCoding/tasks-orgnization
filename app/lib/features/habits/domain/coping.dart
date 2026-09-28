import 'package:meta/meta.dart';

/// How long a craving usually lasts (HSE: most pass within 3–5 minutes).
const cravingTimerDuration = Duration(minutes: 3);

/// The craving timer of the coping toolbox (T5.3.16): derived from its start instant, so it
/// survives rebuilds and never drifts.
@immutable
class CravingTimer {
  const CravingTimer(this.startedAt, {this.duration = cravingTimerDuration});

  final DateTime startedAt;
  final Duration duration;

  Duration elapsed(DateTime now) {
    final e = now.difference(startedAt);
    return e.isNegative ? Duration.zero : e;
  }

  Duration remaining(DateTime now) {
    final r = duration - elapsed(now);
    return r.isNegative ? Duration.zero : r;
  }

  bool finished(DateTime now) => remaining(now) == Duration.zero;

  /// 0…1 of the time elapsed.
  double progress(DateTime now) => (elapsed(now).inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

  /// Seconds to store as the craving's `duration_seconds` (capped at the timer length when the
  /// user stops late).
  int durationSeconds(DateTime now) {
    final e = elapsed(now);
    return (e > duration ? duration : e).inSeconds;
  }
}

enum BreathPhase { inhale, hold, exhale, holdEmpty }

/// A paced-breathing pattern: seconds per phase, in order (a zero-length phase is skipped).
@immutable
class BreathingPattern {
  const BreathingPattern(this.id, {required this.inhale, required this.hold, required this.exhale, this.holdEmpty = 0});

  /// Box breathing 4-4-4-4.
  static const box = BreathingPattern('box', inhale: 4, hold: 4, exhale: 4, holdEmpty: 4);

  /// 4-7-8 relaxing breath.
  static const relax478 = BreathingPattern('478', inhale: 4, hold: 7, exhale: 8);

  static const all = [box, relax478];

  final String id;
  final int inhale;
  final int hold;
  final int exhale;
  final int holdEmpty;

  List<(BreathPhase, int)> get phases => [
    for (final p in [
      (BreathPhase.inhale, inhale),
      (BreathPhase.hold, hold),
      (BreathPhase.exhale, exhale),
      (BreathPhase.holdEmpty, holdEmpty),
    ])
      if (p.$2 > 0) p,
  ];

  int get cycleSeconds => inhale + hold + exhale + holdEmpty;

  /// The phase at [elapsed] (cycles repeat): the phase, whole seconds left in it (≥ 1) and the
  /// 1-based cycle number.
  ({BreathPhase phase, int secondsLeft, int cycle}) at(Duration elapsed) {
    final total = elapsed.inSeconds < 0 ? 0 : elapsed.inSeconds;
    var t = total % cycleSeconds;
    for (final (phase, seconds) in phases) {
      if (t < seconds) return (phase: phase, secondsLeft: seconds - t, cycle: total ~/ cycleSeconds + 1);
      t -= seconds;
    }
    return (phase: phases.first.$1, secondsLeft: phases.first.$2, cycle: total ~/ cycleSeconds + 1);
  }
}
