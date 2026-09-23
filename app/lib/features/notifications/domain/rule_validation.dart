import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/planner/notification_planner.dart';
import 'package:everslot/features/notifications/domain/planner/recurrence_adapter.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/domain/template_engine.dart';
import 'package:meta/meta.dart';

enum IssueSeverity { error, warning }

/// Typed validation issue codes (localized by the UI, T7.1.04).
enum RuleIssueCode {
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
}

@immutable
class RuleIssue {
  const RuleIssue(this.code, this.severity, {this.field, this.detail});

  final RuleIssueCode code;
  final IssueSeverity severity;
  final String? field;

  /// Extra info (unknown variable names, schedule error codes…).
  final String? detail;

  bool get isError => severity == IssueSeverity.error;

  @override
  bool operator ==(Object other) =>
      other is RuleIssue && other.code == code && other.severity == severity && other.field == field && other.detail == detail;

  @override
  int get hashCode => Object.hash(code, severity, field, detail);

  @override
  String toString() => 'RuleIssue($code, $severity${detail == null ? '' : ', $detail'})';
}

/// Anchors each target type offers.
Set<TriggerAnchor> anchorsFor(NotificationTargetType type, {ItemKind kind = ItemKind.timed}) => switch (type) {
  NotificationTargetType.task => kind == ItemKind.timed
      ? {TriggerAnchor.start, TriggerAnchor.end}
      : {TriggerAnchor.start},
  NotificationTargetType.checklist => {TriggerAnchor.due},
  NotificationTargetType.checklistItem => {TriggerAnchor.due, TriggerAnchor.followUp},
  NotificationTargetType.habit => {TriggerAnchor.slot, TriggerAnchor.periodStart, TriggerAnchor.periodEnd},
  NotificationTargetType.digest || NotificationTargetType.custom => TriggerAnchor.values.toSet(),
};

/// Validates a rule spec (T7.1.04). Errors block saving; warnings don't.
abstract final class RuleValidator {
  static const maxActionsAndroid = 3;

  static List<RuleIssue> validate(
    NotificationRuleSpec spec, {
    NotificationTargetType? targetType,
    ItemKind itemKind = ItemKind.timed,
    bool acceptExtraActions = false,
    RecurrenceExpander expander = const BasicRecurrenceExpander(),
  }) {
    final issues = <RuleIssue>[];
    void error(RuleIssueCode c, {String? field, String? detail}) =>
        issues.add(RuleIssue(c, IssueSeverity.error, field: field, detail: detail));
    void warn(RuleIssueCode c, {String? field, String? detail}) =>
        issues.add(RuleIssue(c, IssueSeverity.warning, field: field, detail: detail));

    switch (spec.trigger) {
      case RelativeTrigger(:final anchor, :final offsetMinutes, :final dayOffset):
        if (targetType != null && !anchorsFor(targetType, kind: itemKind).contains(anchor)) {
          error(RuleIssueCode.anchorUnavailable, field: 'trigger.anchor', detail: anchor.wire);
        }
        if (offsetMinutes != null && offsetMinutes.abs() > NotificationPlanner.maxOffsetMinutes) {
          error(RuleIssueCode.offsetOutOfRange, field: 'trigger.offsetMinutes');
        }
        if (dayOffset != null && dayOffset.abs() > 30) {
          error(RuleIssueCode.dayOffsetOutOfRange, field: 'trigger.dayOffset');
        }
      case ScheduleTrigger(:final recurrence):
        final errors = expander.validate(recurrence);
        if (errors.isNotEmpty) error(RuleIssueCode.scheduleInvalid, field: 'trigger.recurrence', detail: errors.join(','));
      case DigestTrigger(:final schedule):
        final errors = expander.validate(schedule);
        if (errors.isNotEmpty) error(RuleIssueCode.scheduleInvalid, field: 'trigger.schedule', detail: errors.join(','));
      case StatusAgeTrigger(:final statuses, :final afterMinutes):
        if (statuses.isEmpty) error(RuleIssueCode.statusesEmpty, field: 'trigger.statuses');
        if (afterMinutes < 0) error(RuleIssueCode.offsetOutOfRange, field: 'trigger.afterMinutes');
      case MilestoneTrigger(:final thresholds):
        if (thresholds != null && (thresholds.isEmpty || thresholds.any((t) => t <= 0))) {
          error(RuleIssueCode.thresholdsInvalid, field: 'trigger.thresholds');
        }
      case UnknownTrigger():
        error(RuleIssueCode.unknownTrigger, field: 'trigger.type');
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
      if (repeat.maxTimes > RepeatSpec.hardMaxTimes) error(RuleIssueCode.repeatMaxTooHigh, field: 'repeat.maxTimes');
      if (repeat.everyMinutes < 1) error(RuleIssueCode.repeatIntervalInvalid, field: 'repeat.everyMinutes');
    }

    final actions = spec.delivery.actions;
    if (actions != null && actions.length > maxActionsAndroid) {
      if (acceptExtraActions) {
        warn(RuleIssueCode.tooManyActions, field: 'delivery.actions');
      } else {
        error(RuleIssueCode.tooManyActions, field: 'delivery.actions');
      }
    }
    final lateness = spec.delivery.latenessMinutes;
    if (lateness != null && lateness < 1) error(RuleIssueCode.latenessTooSmall, field: 'delivery.latenessMinutes');
    if (spec.delivery.system == false && spec.delivery.inbox == false && spec.delivery.banner == false) {
      error(RuleIssueCode.noDeliveryChannel, field: 'delivery');
    }

    for (final (field, template) in [('content.title', spec.content.title), ('content.body', spec.content.body)]) {
      if (template == null) continue;
      if (field == 'content.title' && template.trim().isEmpty) error(RuleIssueCode.emptyContent, field: field);
      final unknown = TemplateEngine.unknownIn(template);
      final unavailable = targetType == null
          ? const <String>{}
          : {
              for (final v in TemplateEngine.variablesIn(template))
                if (TemplateVariables.byName[v] != null && !TemplateVariables.byName[v]!.availableFor(targetType)) v,
            };
      if (unknown.isNotEmpty || unavailable.isNotEmpty) {
        error(RuleIssueCode.unknownVariable, field: field, detail: {...unknown, ...unavailable}.join(','));
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

  static NoiseEstimate fromPlan(PlanResult result, Duration window, {List<DateTime> others = const []}) {
    final perDay = result.firesPerDay(window);
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
