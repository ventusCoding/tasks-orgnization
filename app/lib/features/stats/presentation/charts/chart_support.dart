/// Shared chart plumbing (T6.2.01): formatting access (no Riverpod needed, so other features can
/// embed charts), "nice" axis ticks, LTTB downsampling and RTL helpers.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/presentation/format/stat_format.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show Weekday;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:material_ui/material_ui.dart';

/// Formatting preferences for charts below this widget (12/24 h, digits). Screens provide it from
/// the user's preferences; without it charts use 24 h and the locale's digits.
class ChartPrefs extends InheritedWidget {
  const ChartPrefs({
    required super.child,
    super.key,
    this.use24h = true,
    this.arabicDigits = false,
    this.hideNames = false,
    this.weekStart = Weekday.monday,
    this.dayStartMinutes = 0,
    this.haptics = true,
  });

  /// Selection haptics (`appearance.haptics`).
  final bool haptics;

  final bool use24h;
  final bool arabicDigits;

  /// First weekday of calendars and punch cards.
  final Weekday weekStart;

  /// Habit day start (punch cards and roses rotate to it).
  final int dayStartMinutes;

  /// Share-as-image anonymization: user content labels become "Item 1…".
  final bool hideNames;

  static ChartPrefs? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ChartPrefs>();

  @override
  bool updateShouldNotify(ChartPrefs oldWidget) =>
      use24h != oldWidget.use24h ||
      arabicDigits != oldWidget.arabicDigits ||
      hideNames != oldWidget.hideNames ||
      weekStart != oldWidget.weekStart ||
      dayStartMinutes != oldWidget.dayStartMinutes ||
      haptics != oldWidget.haptics;
}

/// The formatter of [context] (locale from the app, preferences from [ChartPrefs]).
StatFormat statFormatOf(BuildContext context) {
  final prefs = ChartPrefs.maybeOf(context);
  return StatFormat(
    context.l10n,
    Localizations.localeOf(context).toLanguageTag(),
    use24h: prefs?.use24h ?? true,
    arabicDigits: prefs?.arabicDigits ?? false,
  );
}

/// Week start for charts below [context].
Weekday chartWeekStart(BuildContext context) => ChartPrefs.maybeOf(context)?.weekStart ?? Weekday.monday;

/// Haptic tick when a chart element is selected (respects the haptics setting, T6.2.10).
void chartSelectionFeedback(BuildContext context) {
  if (ChartPrefs.maybeOf(context)?.haptics ?? true) unawaited(HapticFeedback.selectionClick());
}

/// Animation duration of charts (250 ms, none under reduce-motion).
Duration chartAnimation(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false ? Duration.zero : const Duration(milliseconds: 250);

/// "Nice" axis scale: 1-2-5 steps, at most [maxTicks] ticks, starting at 0 for counts and rates.
({double min, double max, double step}) niceScale(double lo, double hi, {int maxTicks = 5, bool zeroBased = true}) {
  var min = zeroBased ? math.min<double>(0, lo) : lo;
  var max = hi;
  if (!min.isFinite || !max.isFinite) return (min: 0, max: 1, step: 1);
  if (max <= min) {
    max = min + (min.abs() < 1e-9 ? 1 : min.abs());
  }
  final raw = (max - min) / math.max(1, maxTicks);
  final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  final norm = raw / mag;
  final nice = norm <= 1 ? 1 : (norm <= 2 ? 2 : (norm <= 5 ? 5 : 10));
  final step = nice * mag;
  min = (min / step).floor() * step;
  max = (max / step).ceil() * step;
  return (min: min, max: max, step: step);
}

/// Largest-Triangle-Three-Buckets downsampling to [threshold] points; `null` gaps are kept as gaps
/// (each contiguous run is downsampled on its own) and extrema survive (T6.2.03).
List<(int, double?)> lttb(List<double?> values, int threshold) {
  final points = [for (var i = 0; i < values.length; i++) (i, values[i])];
  if (threshold >= values.length || threshold < 3) return points;
  final runs = <List<(int, double)>>[];
  var current = <(int, double)>[];
  for (final (i, v) in points) {
    if (v == null) {
      if (current.isNotEmpty) runs.add(current);
      current = [];
    } else {
      current.add((i, v));
    }
  }
  if (current.isNotEmpty) runs.add(current);
  final total = runs.fold<int>(0, (a, r) => a + r.length);
  final result = <(int, double?)>[];
  for (var r = 0; r < runs.length; r++) {
    final run = runs[r];
    final budget = math.max(3, (threshold * run.length / total).round());
    result.addAll(_lttbRun(run, budget));
    if (r + 1 < runs.length) result.add((run.last.$1 + 1, null));
  }
  return result;
}

List<(int, double)> _lttbRun(List<(int, double)> data, int threshold) {
  if (threshold >= data.length || threshold < 3) return data;
  final sampled = <(int, double)>[data.first];
  final every = (data.length - 2) / (threshold - 2);
  var a = 0;
  for (var i = 0; i < threshold - 2; i++) {
    final avgStart = ((i + 1) * every).floor() + 1;
    final avgEnd = math.min(((i + 2) * every).floor() + 1, data.length);
    var avgX = 0.0;
    var avgY = 0.0;
    for (var j = avgStart; j < avgEnd; j++) {
      avgX += data[j].$1;
      avgY += data[j].$2;
    }
    final len = math.max(1, avgEnd - avgStart);
    avgX /= len;
    avgY /= len;
    final rangeStart = (i * every).floor() + 1;
    final rangeEnd = math.min(((i + 1) * every).floor() + 1, data.length - 1);
    var maxArea = -1.0;
    var next = rangeStart;
    for (var j = rangeStart; j < rangeEnd; j++) {
      final area = ((data[a].$1 - avgX) * (data[j].$2 - data[a].$2) - (data[a].$1 - data[j].$1) * (avgY - data[a].$2))
          .abs();
      if (area > maxArea) {
        maxArea = area;
        next = j;
      }
    }
    sampled.add(data[next]);
    a = next;
  }
  sampled.add(data.last);
  return sampled;
}

/// Physical horizontal anchor of text painted on a canvas (positions are already mirrored for RTL
/// by the painter, so this is deliberately not directional).
enum TextAnchor { leftEdge, center, rightEdge }

/// Maps a category index to its visual position (time axes run right-to-left in RTL).
int visualIndex(int index, int count, {required bool rtl}) => rtl ? count - 1 - index : index;
