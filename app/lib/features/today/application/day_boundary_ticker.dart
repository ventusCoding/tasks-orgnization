import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:everslot/features/today/domain/day_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Re-evaluates the logical day at every day boundary (local midnight or `dayStartsAt`, T8.1.01).
///
/// A timer fires just after the current window ends; [check] re-evaluates immediately (app
/// resume, clock changes). Timers are capped at [maxDelay] so a wall-clock change made while the
/// app sleeps is caught without relying on a single long timer.
class DayBoundaryTicker {
  DayBoundaryTicker({
    required this.compute,
    required this.onChange,
    required this.now,
    this.maxDelay = const Duration(hours: 1),
    this.grace = const Duration(seconds: 1),
  });

  /// Computes the window at the current instant.
  final DayWindow Function() compute;
  final void Function(DayWindow window) onChange;
  final DateTime Function() now;
  final Duration maxDelay;

  /// Delay after the boundary before re-evaluating (clock skew between timer and clock).
  final Duration grace;

  Timer? _timer;
  DayWindow? _current;
  bool _disposed = false;

  DayWindow? get current => _current;

  /// Computes the current window and schedules the next boundary; returns the window.
  DayWindow start() {
    final w = compute();
    _current = w;
    _schedule(w);
    return w;
  }

  /// Re-evaluates now; notifies when the window changed.
  void check() {
    if (_disposed) return;
    final w = compute();
    final changed = w != _current;
    _current = w;
    _schedule(w);
    if (changed) onChange(w);
  }

  void _schedule(DayWindow w) {
    _timer?.cancel();
    if (_disposed) return;
    var delay = w.endUtc.difference(now()) + grace;
    if (delay < grace) delay = grace;
    if (delay > maxDelay) delay = maxDelay;
    _timer = Timer(delay, check);
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
  }
}

/// Whether Today schedules real timers (day boundaries). Off with a [FakeClock]: tests drive time
/// explicitly (like `plannerAutoRefreshProvider`).
final todayAutoTickProvider = Provider<bool>((ref) => ref.watch(clockProvider) is! FakeClock);

/// The logical day shown by Today, in the device zone with the user's day start. Recomputed at
/// each day boundary, on app resume and whenever the zone or the day-start preference changes.
final todayWindowProvider = NotifierProvider.autoDispose<TodayWindowController, DayWindow>(
  TodayWindowController.new,
);

class TodayWindowController extends Notifier<DayWindow> {
  DayBoundaryTicker? _ticker;

  @override
  DayWindow build() {
    final clock = ref.watch(clockProvider);
    final zones = ref.watch(zoneResolverProvider);
    final zone = ref.watch(deviceZoneProvider);
    final dayStart = ref.watch(userPreferencesProvider.select((p) => p.dayStartMinutes)).clamp(0, 1439);
    DayWindow compute() => DayWindow.at(clock.nowUtc(), zone, zones, dayStartMinutes: dayStart);
    _ticker?.dispose();
    _ticker = null;
    if (!ref.watch(todayAutoTickProvider)) return compute();
    final ticker = DayBoundaryTicker(
      compute: compute,
      now: clock.nowUtc,
      onChange: (w) {
        if (ref.mounted) state = w;
      },
    );
    _ticker = ticker;
    final sub = ref.watch(lifecycleProvider).onResume.listen((_) => ticker.check());
    ref.onDispose(() {
      unawaited(sub.cancel());
      ticker.dispose();
    });
    return ticker.start();
  }

  /// Re-evaluates the day now (resume, debug time travel, tests with a fake clock).
  void check() {
    final ticker = _ticker;
    if (ticker != null) {
      ticker.check();
      return;
    }
    final clock = ref.read(clockProvider);
    final w = DayWindow.at(
      clock.nowUtc(),
      ref.read(deviceZoneProvider),
      ref.read(zoneResolverProvider),
      dayStartMinutes: ref.read(userPreferencesProvider).dayStartMinutes.clamp(0, 1439),
    );
    if (w != state) state = w;
  }
}
