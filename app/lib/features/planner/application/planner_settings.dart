import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/features/planner/domain/occurrence_resolver.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/planning_rules.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:meta/meta.dart';

/// Typed view of the `planner` settings namespace (arch §8.5).
@immutable
class PlannerSettings {
  const PlannerSettings({
    this.missedGraceMinutes = 15,
    this.overdueLookbackDays = 7,
    this.askActualTimeOnDone = AskActualTimeOnDone.ifOffSchedule,
    this.timerPolicy = TimerPolicy.single,
    this.defaultTaskDurationMinutes = 30,
    this.defaultTrackingMode = TrackingMode.check,
    this.rollOverIncomplete = RollOverPolicy.off,
    this.overlapHint = true,
    this.overlapIncludesEvents = false,
    this.showCancelled = false,
    this.skipAdvancesAfterCompletion = true,
    this.maxOccurrencesPerRange = 20000,
  });

  factory PlannerSettings.fromMap(Map<String, dynamic> m) => PlannerSettings(
    missedGraceMinutes: m.get<int>('missedGraceMinutes', 15).clamp(0, 1440),
    overdueLookbackDays: m.get<int>('overdueLookbackDays', 7).clamp(0, 365),
    askActualTimeOnDone: AskActualTimeOnDone.fromJson(m['askActualTimeOnDone']),
    timerPolicy: TimerPolicy.fromJson(m['timerPolicy']),
    defaultTaskDurationMinutes: m.get<int>('defaultTaskDurationMinutes', 30).clamp(1, 1440),
    defaultTrackingMode: TrackingModeJson.fromJson(m['defaultTrackingMode']),
    rollOverIncomplete: RollOverPolicy.fromJson(m['rollOverIncomplete']),
    overlapHint: m.get<bool>('overlapHint', true),
    overlapIncludesEvents: m.get<bool>('overlapIncludesEvents', false),
    showCancelled: m.get<bool>('showCancelled', false),
    skipAdvancesAfterCompletion: m.get<bool>('skipAdvancesAfterCompletion', true),
    maxOccurrencesPerRange: m.get<int>('maxOccurrencesPerRange', 20000).clamp(100, 200000),
  );

  static const defaults = PlannerSettings();

  /// `planner.missedGraceMinutes` (default 15).
  final int missedGraceMinutes;
  final int overdueLookbackDays;
  final AskActualTimeOnDone askActualTimeOnDone;
  final TimerPolicy timerPolicy;
  final int defaultTaskDurationMinutes;
  final TrackingMode defaultTrackingMode;
  final RollOverPolicy rollOverIncomplete;
  final bool overlapHint;
  final bool overlapIncludesEvents;
  final bool showCancelled;
  final bool skipAdvancesAfterCompletion;
  final int maxOccurrencesPerRange;

  ResolverSettings get resolver => ResolverSettings(
    missedGraceMinutes: missedGraceMinutes,
    overdueLookbackDays: overdueLookbackDays,
    showCancelled: showCancelled,
    skipAdvancesAfterCompletion: skipAdvancesAfterCompletion,
    maxOccurrences: maxOccurrencesPerRange,
  );

  @override
  bool operator ==(Object other) =>
      other is PlannerSettings &&
      other.missedGraceMinutes == missedGraceMinutes &&
      other.overdueLookbackDays == overdueLookbackDays &&
      other.askActualTimeOnDone == askActualTimeOnDone &&
      other.timerPolicy == timerPolicy &&
      other.defaultTaskDurationMinutes == defaultTaskDurationMinutes &&
      other.defaultTrackingMode == defaultTrackingMode &&
      other.rollOverIncomplete == rollOverIncomplete &&
      other.overlapHint == overlapHint &&
      other.overlapIncludesEvents == overlapIncludesEvents &&
      other.showCancelled == showCancelled &&
      other.skipAdvancesAfterCompletion == skipAdvancesAfterCompletion &&
      other.maxOccurrencesPerRange == maxOccurrencesPerRange;

  @override
  int get hashCode => Object.hash(
    missedGraceMinutes,
    overdueLookbackDays,
    askActualTimeOnDone,
    timerPolicy,
    defaultTaskDurationMinutes,
    defaultTrackingMode,
    rollOverIncomplete,
    overlapHint,
    overlapIncludesEvents,
    showCancelled,
    skipAdvancesAfterCompletion,
    maxOccurrencesPerRange,
  );
}
