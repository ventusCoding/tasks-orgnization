import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/planner/notification_planner.dart';
import 'package:everslot/features/notifications/domain/planner/recurrence_adapter.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/domain/template_engine.dart';
import 'package:meta/meta.dart';

enum NotificationIssueSeverity { error, warning }

/// Typed validation issue codes (localized by the UI, T7.1.04).
enum NotificationIssueCode {
  anchorUnavailable,
  offsetOutOfRange,
  dayOffsetOutOfRange,
  repeatMaxTooHigh,
  repeatIntervalInvalid,
  tooManyActions,
  unknownVariable,
  emptyContent,
  scheduleInvalid,
  latenessTooSmall,
  noDeliveryChannel,
  unknownTrigger,
  thresholdsInvalid,
  statusesEmpty,

  /// Warning: Android Doze allows one exact alarm per ~9 minutes (T7.2.10).
  repeatMayBeDelayed,
}

@immutable
class NotificationRuleIssue {
  const NotificationRuleIssue(this.code, this.severity, {this.field, this.detail});

  final NotificationIssueCode code;
  final NotificationIssueSeverity severity;
  final String? field;

  /// Extra info (unknown variable names, schedule error codes…).
  final String? detail;

  bool get isError => severity == NotificationIssueSeverity.error;

  @override
  bool operator ==(Object other) =>
      other is NotificationRuleIssue &&
      other.code == code &&
      other.severity == severity &&
      other.field == field &&
      other.detail == detail;

  @override
  int get hashCode => Object.hash(code, severity, field, detail);

  @override
  String toString() => 'NotificationRuleIssue($code, $severity${detail == null ? '' : ', $detail'})';
}

/// Anchors each target type offers.
Set<TriggerAnchor> anchorsFor(NotificationTargetType type, {ItemKind kind = ItemKind.timed}) => switch (type) {
  // All-day spans have an end (the day after the last day); date-only tasks don't.
  NotificationTargetType.task =>
    kind == ItemKind.dateOnly ? {TriggerAnchor.start} : {TriggerAnchor.start, TriggerAnchor.end},
  NotificationTargetType.checklist => {TriggerAnchor.due},
  NotificationTargetType.checklistItem => {TriggerAnchor.due, TriggerAnchor.followUp},
  NotificationTargetType.habit => {TriggerAnchor.slot, TriggerAnchor.periodStart, TriggerAnchor.periodEnd},
  NotificationTargetType.digest || NotificationTargetType.custom => TriggerAnchor.values.toSet(),
};

/// Validates a rule spec (T7.1.04). Errors block saving; warnings don't.
abstract final class NotificationRuleValidator {
  static const maxActionsAndroid = 3;

  static List<NotificationRuleIssue> validate(
    NotificationRuleSpec spec, {
    NotificationTargetType? targetType,
    ItemKind itemKind = ItemKind.timed,
    bool acceptExtraActions = false,
    RecurrenceExpander? expander,
  }) {
    final schedules = expander ?? EngineRecurrenceExpander.shared;
    final issues = <NotificationRuleIssue>[];
    void error(NotificationIssueCode c, {String? field, String? detail}) =>
        issues.add(NotificationRuleIssue(c, NotificationIssueSeverity.error, field: field, detail: detail));
    void warn(NotificationIssueCode c, {String? field, String? detail}) =>
        issues.add(NotificationRuleIssue(c, NotificationIssueSeverity.warning, field: field, detail: detail));

    switch (spec.trigger) {
      case RelativeTrigger(:final anchor, :final offsetMinutes, :final dayOffset):
        if (targetType != null && !anchorsFor(targetType, kind: itemKind).contains(anchor)) {
          error(NotificationIssueCode.anchorUnavailable, field: 'trigger.anchor', detail: anchor.wire);
        }
        if (offsetMinutes != null && offsetMinutes.abs() > NotificationPlanner.maxOffsetMinutes) {
          error(NotificationIssueCode.offsetOutOfRange, field: 'trigger.offsetMinutes');
        }
        if (dayOffset != null && dayOffset.abs() > 30) {
          error(NotificationIssueCode.dayOffsetOutOfRange, field: 'trigger.dayOffset');
        }
      case ScheduleTrigger(:final recurrence):
        final errors = schedules.validate(recurrence);
        if (errors.isNotEmpty) {
          error(NotificationIssueCode.scheduleInvalid, field: 'trigger.recurrence', detail: errors.join(','));
        }
      case DigestTrigger(:final schedule):
        final errors = schedules.validate(schedule);
        if (errors.isNotEmpty) {
          error(NotificationIssueCode.scheduleInvalid, field: 'trigger.schedule', detail: errors.join(','));
        }
      case StatusAgeTrigger(:final statuses, :final afterMinutes):
        if (statuses.isEmpty) {
          error(NotificationIssueCode.statusesEmpty, field: 'trigger.statuses');
        }
        if (afterMinutes < 0) {
          error(NotificationIssueCode.offsetOutOfRange, field: 'trigger.afterMinutes');
        }
      case MilestoneTrigger(:final thresholds):
        if (thresholds != null && (thresholds.isEmpty || thresholds.any((t) => t <= 0))) {
          error(NotificationIssueCode.thresholdsInvalid, field: 'trigger.thresholds');
        }
      case UnknownTrigger():
        error(NotificationIssueCode.unknownTrigger, field: 'trigger.type');
      case AbsoluteTrigger() ||
          NotDoneByTrigger() ||
          OverdueTrigger() ||
          StreakRiskTrigger() ||
          QuotaBehindTrigger() ||
          InactivityTrigger() ||
          StatusChangeTrigger() ||
          ChildrenCompleteTrigger() ||
          ChildOverdueTrigger() ||
          StaleTrigger():
        break;
    }

    final repeat = spec.repeat;
    if (repeat != null) {
      if (repeat.maxTimes > RepeatSpec.hardMaxTimes) {
        error(NotificationIssueCode.repeatMaxTooHigh, field: 'repeat.maxTimes');
      }
      if (repeat.everyMinutes < 1) {
        error(NotificationIssueCode.repeatIntervalInvalid, field: 'repeat.everyMinutes');
      } else if (repeat.everyMinutes < 10) {
        warn(NotificationIssueCode.repeatMayBeDelayed, field: 'repeat.everyMinutes');
      }
    }

    final actions = spec.delivery.actions;
    if (actions != null && actions.length > maxActionsAndroid) {
      if (acceptExtraActions) {
        warn(NotificationIssueCode.tooManyActions, field: 'delivery.actions');
      } else {
        error(NotificationIssueCode.tooManyActions, field: 'delivery.actions');
      }
    }
    final lateness = spec.delivery.latenessMinutes;
    if (lateness != null && lateness < 1) {
      error(NotificationIssueCode.latenessTooSmall, field: 'delivery.latenessMinutes');
    }
    if (spec.delivery.system == false && spec.delivery.inbox == false && spec.delivery.banner == false) {
      error(NotificationIssueCode.noDeliveryChannel, field: 'delivery');
    }

    for (final (field, template) in [('content.title', spec.content.title), ('content.body', spec.content.body)]) {
      if (template == null) continue;
      if (field == 'content.title' && template.trim().isEmpty) {
        error(NotificationIssueCode.emptyContent, field: field);
      }
      final unknown = TemplateEngine.unknownIn(template);
      final unavailable = targetType == null
          ? const <String>{}
          : {
              for (final v in TemplateEngine.variablesIn(template))
                if (TemplateVariables.byName[v] != null && !TemplateVariables.byName[v]!.availableFor(targetType)) v,
            };
      if (unknown.isNotEmpty || unavailable.isNotEmpty) {
        error(NotificationIssueCode.unknownVariable, field: field, detail: {...unknown, ...unavailable}.join(','));
      }
    }
    return issues;
  }
}

/// Noise level of a rule (T7.1.04): warn > 48/day, confirm > 96/day, blocked > 1 440/day.
enum NoiseLevel { ok, warn, confirm, blocked }

@immutable
class NoiseEstimate {
  const NoiseEstimate({required this.firesPerDay, required this.level, this.sameMinuteClusters = 0});

  static const warnAbove = 48;
  static const confirmAbove = 96;
  static const hardCap = 1440;

  /// Fires per day of [result] over [window]. With [from], only firings in `[from, from + window)`
  /// count (catch-ups of the lateness window before "now" are not noise).
  static NoiseEstimate fromPlan(
    PlanResult result,
    Duration window, {
    List<DateTime> others = const [],
    DateTime? from,
  }) {
    final end = from?.add(window);
    final counted = from == null
        ? result.planned.length
        : result.planned.where((p) => !p.fireAt.isBefore(from) && p.fireAt.isBefore(end!)).length;
    final perDay = window.inMinutes <= 0 ? 0.0 : counted / (window.inMinutes / 1440);
    final level = perDay > hardCap
        ? NoiseLevel.blocked
        : perDay > confirmAbove
        ? NoiseLevel.confirm
        : perDay > warnAbove
        ? NoiseLevel.warn
        : NoiseLevel.ok;
    final minutes = {for (final o in others) o.millisecondsSinceEpoch ~/ 60000};
    final clusters = result.planned.where((p) => minutes.contains(p.fireAt.millisecondsSinceEpoch ~/ 60000)).length;
    return NoiseEstimate(firesPerDay: perDay, level: level, sameMinuteClusters: clusters);
  }

  final double firesPerDay;
  final NoiseLevel level;

  /// Firings sharing their minute with other reminders (Android plays one sound per second).
  final int sameMinuteClusters;
}
