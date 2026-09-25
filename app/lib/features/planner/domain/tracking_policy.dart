import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:meta/meta.dart';

/// Primary action shown for an occurrence (T3.2.05).
enum OccurrencePrimaryAction { done, skip, start, pause, resume, stop, reopen }

/// Behaviour of a tracking mode, shared by the resolver, the UI and stats (T3.2.13).
///
/// | mode  | checkbox | can be missed        | completion rate | busy time | timer |
/// |-------|----------|----------------------|-----------------|-----------|-------|
/// | check | yes      | yes                  | yes             | yes       | no    |
/// | event | no       | never                | excluded        | yes       | no    |
/// | timer | yes      | yes (never started)  | yes             | yes       | yes   |
@immutable
class TrackingPolicy {
  const TrackingPolicy._({
    required this.mode,
    required this.hasCheckbox,
    required this.canBeMissed,
    required this.countsInCompletionRate,
    required this.countsAsBusyTime,
    required this.usesTimer,
  });

  factory TrackingPolicy.of(TrackingMode mode) => switch (mode) {
    TrackingMode.check => check,
    TrackingMode.event => event,
    TrackingMode.timer => timer,
  };

  static const check = TrackingPolicy._(
    mode: TrackingMode.check,
    hasCheckbox: true,
    canBeMissed: true,
    countsInCompletionRate: true,
    countsAsBusyTime: true,
    usesTimer: false,
  );

  static const event = TrackingPolicy._(
    mode: TrackingMode.event,
    hasCheckbox: false,
    canBeMissed: false,
    countsInCompletionRate: false,
    countsAsBusyTime: true,
    usesTimer: false,
  );

  static const timer = TrackingPolicy._(
    mode: TrackingMode.timer,
    hasCheckbox: true,
    canBeMissed: true,
    countsInCompletionRate: true,
    countsAsBusyTime: true,
    usesTimer: true,
  );

  final TrackingMode mode;
  final bool hasCheckbox;
  final bool canBeMissed;
  final bool countsInCompletionRate;
  final bool countsAsBusyTime;
  final bool usesTimer;

  /// Primary actions for an occurrence in [status]; [timerRunning] for timer tasks.
  List<OccurrencePrimaryAction> primaryActions(OccurrenceStatus status, {bool timerRunning = false}) {
    switch (status) {
      case OccurrenceStatus.done:
      case OccurrenceStatus.skipped:
      case OccurrenceStatus.cancelled:
        return const [OccurrencePrimaryAction.reopen];
      case OccurrenceStatus.inProgress:
        if (usesTimer) {
          return timerRunning
              ? const [OccurrencePrimaryAction.pause, OccurrencePrimaryAction.stop]
              : const [OccurrencePrimaryAction.resume, OccurrencePrimaryAction.stop];
        }
        return const [OccurrencePrimaryAction.done, OccurrencePrimaryAction.skip];
      case OccurrenceStatus.scheduled:
      case OccurrenceStatus.missed:
        return switch (mode) {
          TrackingMode.check => const [OccurrencePrimaryAction.done, OccurrencePrimaryAction.skip],
          TrackingMode.event => const [OccurrencePrimaryAction.skip],
          TrackingMode.timer => const [
            OccurrencePrimaryAction.start,
            OccurrencePrimaryAction.done,
            OccurrencePrimaryAction.skip,
          ],
        };
    }
  }
}
