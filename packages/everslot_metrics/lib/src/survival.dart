/// Kaplan–Meier survival (T6.1.25): time-to-lapse across quit attempts ([6.6] QT-26).
library;

import 'dart:math' as math;

import 'package:everslot_metrics/src/stat.dart';
import 'package:meta/meta.dart';

/// One subject: observed [time] and whether the [event] happened (false = right-censored, e.g. the
/// current attempt).
@immutable
final class const SurvivalObservation(final double time, {required final bool event});

/// One step of the KM curve at an event time.
@immutable
final class const KaplanMeierStep(
  final double time, {
  required final int atRisk,
  required final int events,
  required final int censored,
  required final double survival,
  required final double? standardError,
  required final double? lower,
  required final double? upper,
});

/// Kaplan–Meier estimate.
@immutable
final class const KaplanMeierResult(
  final List<KaplanMeierStep> steps, {
  required final int n,
  required final int events,
  required final double? medianSurvival,
}) {
  /// S(t) of the step function (1 before the first event).
  double survivalAt(double t) {
    var s = 1.0;
    for (final step in steps) {
      if (step.time > t) break;
      s = step.survival;
    }
    return s;
  }

  bool get medianReached => medianSurvival != null;
}

/// Kaplan–Meier estimator S(t) = Π_{t_i ≤ t} (1 − d_i/n_i).
///
/// - Censored subjects at an event time are still at risk at that time (standard convention).
/// - Greenwood variance: Var(S) = S²·Σ d_i/(n_i(n_i − d_i)); the 95 % band uses R `survfit`'s
///   default `conf.type = "log"`: exp(ln S ± 1.96·se(ln S)), upper clipped to 1.
/// - Median survival = first t where S(t) ≤ 0.5, `null` = "not reached".
/// - Steps are emitted at event times (plus censor-only times, with unchanged S, so the curve can
///   show censor ticks).
Stat<KaplanMeierResult> kaplanMeier(
  List<SurvivalObservation> observations, {
  int minSubjects = 2,
}) {
  if (observations.length < minSubjects) {
    return Insufficient<KaplanMeierResult>(minSubjects, observations.length);
  }
  final sorted = [...observations]..sort((a, b) => a.time.compareTo(b.time));
  final times = sorted.map((o) => o.time).toSet().toList()..sort();
  var atRisk = sorted.length;
  var s = 1.0;
  var greenwood = 0.0;
  var greenwoodFinite = true;
  double? median;
  final steps = <KaplanMeierStep>[];
  var totalEvents = 0;
  var idx = 0;
  for (final t in times) {
    var d = 0;
    var c = 0;
    while (idx < sorted.length && sorted[idx].time == t) {
      if (sorted[idx].event) {
        d++;
      } else {
        c++;
      }
      idx++;
    }
    if (d > 0) {
      s *= 1 - d / atRisk;
      if (atRisk - d > 0) {
        greenwood += d / (atRisk * (atRisk - d));
      } else {
        greenwoodFinite = false;
      }
      totalEvents += d;
      if (median == null && s <= 0.5 + 1e-12) median = t;
    }
    double? se;
    double? lower;
    double? upper;
    if (s > 0 && greenwoodFinite) {
      final seLog = math.sqrt(greenwood);
      se = s * seLog;
      lower = math.exp(math.log(s) - 1.96 * seLog);
      upper = math.min(1, math.exp(math.log(s) + 1.96 * seLog));
    }
    steps.add(
      KaplanMeierStep(
        t,
        atRisk: atRisk,
        events: d,
        censored: c,
        survival: s,
        standardError: se,
        lower: lower,
        upper: upper,
      ),
    );
    atRisk -= d + c;
  }
  return Value<KaplanMeierResult>(
    KaplanMeierResult(
      steps,
      n: sorted.length,
      events: totalEvents,
      medianSurvival: median,
    ),
    sampleSize: sorted.length,
  );
}
