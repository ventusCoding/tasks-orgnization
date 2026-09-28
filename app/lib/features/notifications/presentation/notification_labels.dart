import 'package:everslot/design_system/formatting.dart';
import 'package:everslot/design_system/l10n_x.dart';
import 'package:everslot/features/notifications/application/notification_texts_l10n.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/planner/planned_notification.dart';
import 'package:everslot/features/notifications/domain/planner/recurrence_adapter.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/domain/rule_validation.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/widgets.dart';

/// Natural-language labels for rules, profiles, reasons and issues (T7.1.09 summaries).
class NotificationLabels {
  NotificationLabels(this.l, this.format);

  factory NotificationLabels.of(BuildContext context) => NotificationLabels(
    context.l10n,
    AppFormat(
      context.localeName,
      use24h: MediaQuery.alwaysUse24HourFormatOf(context),
      l10n: context.l10n,
    ),
  );

  final AppLocalizations l;
  final AppFormat format;

  String time(LocalTime t) => format.time(t);

  /// "10 min before start", "1 day before at 20:00", "If not done by 21:00"…
  String trigger(NotificationTrigger trigger) => switch (trigger) {
    RelativeTrigger(
      :final anchor,
      :final dayOffset,
      :final atTime,
      :final effectiveOffset,
      :final usesDayForm,
    ) =>
      usesDayForm
          ? (dayOffset == 0
                ? l.notifSumOnDayAt(time(atTime!))
                : (dayOffset! < 0
                      ? l.notifSumDaysBefore(-dayOffset, time(atTime!))
                      : l.notifSumDaysAfter(dayOffset, time(atTime!))))
          : _relative(anchor, effectiveOffset),
    AbsoluteTrigger(:final at) => l.notifSumAbsolute(format.dateTime(at)),
    ScheduleTrigger(:final recurrence) => _schedule(recurrence),
    NotDoneByTrigger(:final anchor, :final atTime) =>
      anchor == 'time' && atTime != null
          ? l.notifSumNotDoneBy(time(atTime))
          : l.notifSumNotDoneByEnd,
    StatusAgeTrigger(:final afterMinutes) => l.notifSumStatusAge(
      format.duration(afterMinutes),
    ),
    OverdueTrigger() => l.notifSumOverdue,
    StreakRiskTrigger(:final atTime) => l.notifSumStreakRisk(time(atTime)),
    QuotaBehindTrigger(:final atTime) => l.notifSumQuotaBehind(time(atTime)),
    MilestoneTrigger() => l.notifSumMilestones,
    InactivityTrigger(:final afterDays) => l.notifSumInactivity(afterDays),
    DigestTrigger(:final kind) => digestTitle(kind),
    StatusChangeTrigger(:final to) => l.notifSumStatusChange(status(to)),
    ChildrenCompleteTrigger() => l.notifSumChildrenComplete,
    ChildOverdueTrigger() => l.notifSumChildOverdue,
    StaleTrigger(:final afterDays) => l.notifSumStale(afterDays),
    UnknownTrigger() => l.notifSumUnknown,
  };

  String _relative(TriggerAnchor anchor, int offset) {
    final d = format.duration(offset.abs());
    return switch (anchor) {
      TriggerAnchor.start =>
        offset < 0
            ? l.notifSumBeforeStart(d)
            : (offset == 0 ? l.notifSumAtStart : l.notifSumAfterStart(d)),
      TriggerAnchor.end =>
        offset < 0
            ? l.notifSumBeforeEnd(d)
            : (offset == 0 ? l.notifSumAtEnd : l.notifSumAfterEnd(d)),
      TriggerAnchor.due =>
        offset < 0
            ? l.notifSumBeforeDue(d)
            : (offset == 0 ? l.notifSumAtDue : l.notifSumAfterDue(d)),
      TriggerAnchor.followUp => l.notifSumAtFollowUp,
      TriggerAnchor.slot => l.notifSumAtSlot,
      TriggerAnchor.periodStart => l.notifSumAtPeriodStart,
      TriggerAnchor.periodEnd => l.notifSumAtPeriodEnd,
    };
  }

  /// Localized schedule description ("Every Monday and Tuesday at 08:00") from the recurrence
  /// package's describer; falls back to a generic label for rules it can't read.
  String _schedule(Map<String, Object?> recurrence) {
    final parsed = EngineRecurrenceExpander.parse(recurrence);
    if (parsed == null) return l.notifSumSchedule;
    try {
      return const RecurrenceDescriber().describe(
        parsed.$1,
        parsed.$2,
        locale: l.localeName,
        use24h: format.use24h,
      );
    } on Object {
      return l.notifSumSchedule;
    }
  }

  /// "10 min before start · Standard · repeats every 5 min ×5"
  String rule(NotificationRule rule, {NotificationProfile? profile}) {
    final parts = [trigger(rule.spec.trigger)];
    if (profile != null) parts.add(profileName(profile));
    final repeat =
        rule.spec.repeat ??
        (rule.spec.repeatDisabled ? null : profile?.spec.repeat);
    if (repeat != null)
      parts.add(l.notifSumRepeat(repeat.everyMinutes, repeat.maxTimes));
    return parts.join(' · ');
  }

  String profileName(NotificationProfile p) =>
      p.isBuiltin && p.code != null ? builtinProfileName(l, p.code!) : p.name;

  String section(NotificationSection s) => sectionLabelOf(l, s);

  /// Localized status (`waiting` → "waiting" / "en attente" / "في الانتظار").
  String status(String wire) => statusLabelOf(l, wire);

  String action(String id) => actionLabelOf(l, id);

  String digestTitle(String kind) => switch (kind) {
    'daily_agenda' => l.notifDigestDailyAgenda,
    'plan_tomorrow' => l.notifDigestPlanTomorrow,
    'evening_review' => l.notifDigestEveningReview,
    'overdue_summary' => l.notifDigestOverdue,
    'weekly_review' => l.notifDigestWeekly,
    'monthly_report' => l.notifDigestMonthly,
    _ => l.notifSectionDigests,
  };

  String provenance(RuleProvenance p) => switch (p) {
    RuleProvenance.section => l.notifProvenanceSection,
    RuleProvenance.category => l.notifProvenanceCategory,
    RuleProvenance.global => l.notifProvenanceGlobal,
    RuleProvenance.ancestor => l.notifProvenanceAncestor,
    RuleProvenance.checklist => l.notifProvenanceChecklist,
    RuleProvenance.occurrence => l.notifProvenanceOccurrence,
    RuleProvenance.own => '',
  };

  String skipReason(SkipReason r) => switch (r) {
    SkipReason.quietHoursDrop => l.notifSkipQuiet,
    SkipReason.muted => l.notifSkipMuted,
    SkipReason.statusFilter => l.notifSkipStatus,
    SkipReason.weekdayFilter => l.notifSkipWeekday,
    SkipReason.timeWindowDrop => l.notifSkipWindow,
    SkipReason.guardClosed => l.notifSkipDone,
    SkipReason.expired => l.notifSkipExpired,
    SkipReason.acknowledged => l.notifSkipAck,
    SkipReason.cap => l.notifSkipCap,
    SkipReason.noChannel => l.notifSkipNoChannel,
  };

  String adjustment(PlanAdjustment a) => switch (a) {
    PlanAdjustment.deferredQuietHours => l.notifAdjDeferred,
    PlanAdjustment.silentQuietHours => l.notifAdjSilent,
    PlanAdjustment.paused => l.notifAdjPaused,
    PlanAdjustment.shiftedToWindow => l.notifAdjShifted,
    PlanAdjustment.catchUp => l.notifAdjCatchUp,
    PlanAdjustment.notLocal => l.notifAdjNotLocal,
  };

  String issue(NotificationRuleIssue i) => switch (i.code) {
    NotificationIssueCode.anchorUnavailable => l.notifIssueAnchorUnavailable,
    NotificationIssueCode.offsetOutOfRange ||
    NotificationIssueCode.dayOffsetOutOfRange => l.notifIssueOffsetOutOfRange,
    NotificationIssueCode.repeatMaxTooHigh => l.notifIssueRepeatMax,
    NotificationIssueCode.repeatIntervalInvalid => l.notifIssueRepeatInterval,
    NotificationIssueCode.tooManyActions => l.notifIssueTooManyActions,
    NotificationIssueCode.unknownVariable => l.notifIssueUnknownVariable(
      i.detail ?? '',
    ),
    NotificationIssueCode.emptyContent => l.notifIssueEmptyContent,
    NotificationIssueCode.scheduleInvalid => l.notifIssueSchedule,
    NotificationIssueCode.latenessTooSmall => l.notifIssueLateness,
    NotificationIssueCode.noDeliveryChannel => l.notifIssueNoChannel,
    NotificationIssueCode.unknownTrigger => l.notifIssueUnknownTrigger,
    NotificationIssueCode.thresholdsInvalid => l.notifIssueThresholds,
    NotificationIssueCode.statusesEmpty => l.notifIssueStatuses,
    NotificationIssueCode.repeatMayBeDelayed => l.notifIssueRepeatDoze,
  };

  String triggerType(TriggerType t) => switch (t) {
    TriggerType.relative => l.notifTriggerRelative,
    TriggerType.absolute => l.notifTriggerAbsolute,
    TriggerType.schedule => l.notifTriggerSchedule,
    TriggerType.notDoneBy => l.notifTriggerNotDoneBy,
    TriggerType.statusAge => l.notifTriggerStatusAge,
    TriggerType.overdue => l.notifTriggerOverdue,
    TriggerType.streakRisk => l.notifTriggerStreakRisk,
    TriggerType.quotaBehind => l.notifTriggerQuotaBehind,
    TriggerType.milestone => l.notifTriggerMilestone,
    TriggerType.inactivity => l.notifTriggerInactivity,
    TriggerType.digest => l.notifTriggerDigest,
    TriggerType.statusChange => l.notifTriggerStatusChange,
    TriggerType.childrenComplete => l.notifTriggerChildrenComplete,
    TriggerType.childOverdue => l.notifTriggerChildOverdue,
    TriggerType.stale => l.notifTriggerStale,
  };

  String anchor(TriggerAnchor a) => switch (a) {
    TriggerAnchor.start => l.notifAnchorStart,
    TriggerAnchor.end => l.notifAnchorEnd,
    TriggerAnchor.due => l.notifAnchorDue,
    TriggerAnchor.followUp => l.notifAnchorFollowUp,
    TriggerAnchor.slot => l.notifAnchorSlot,
    TriggerAnchor.periodStart => l.notifAnchorPeriodStart,
    TriggerAnchor.periodEnd => l.notifAnchorPeriodEnd,
  };

  String importance(NotificationImportance i) => switch (i) {
    NotificationImportance.min => l.notifImportanceMin,
    NotificationImportance.low => l.notifImportanceLow,
    NotificationImportance.normal => l.notifImportanceDefault,
    NotificationImportance.high => l.notifImportanceHigh,
    NotificationImportance.urgent => l.notifImportanceUrgent,
  };

  String interruption(InterruptionLevel i) => switch (i) {
    InterruptionLevel.passive => l.notifInterruptionPassive,
    InterruptionLevel.active => l.notifInterruptionActive,
    InterruptionLevel.timeSensitive => l.notifInterruptionTimeSensitive,
  };

  String sound(String key) => switch (key) {
    'default' => l.notifSoundDefault,
    'none' => l.notifSoundNone,
    'chime' => l.notifSoundChime,
    'bell' => l.notifSoundBell,
    'soft' => l.notifSoundSoft,
    'pop' => l.notifSoundPop,
    'alarm' => l.notifSoundAlarm,
    _ => key,
  };

  String vibration(String key) => switch (key) {
    'default' => l.notifVibrationDefault,
    'none' => l.notifVibrationNone,
    'short' => l.notifVibrationShort,
    'long' => l.notifVibrationLong,
    _ => key,
  };

  String category(InboxCategory c) => switch (c) {
    InboxCategory.reminder => l.notifCategoryReminder,
    InboxCategory.nag => l.notifCategoryNag,
    InboxCategory.digest => l.notifCategoryDigest,
    InboxCategory.milestone => l.notifCategoryMilestone,
    InboxCategory.streak => l.notifCategoryStreak,
    InboxCategory.system => l.notifCategorySystem,
  };

  String mode(NotifyMode m) => switch (m) {
    NotifyMode.inherit => l.notifModeInherit,
    NotifyMode.custom => l.notifModeCustom,
    NotifyMode.inheritPlus => l.notifModeInheritPlus,
    NotifyMode.off => l.notifModeOff,
  };

  static const curatedSounds = [
    'default',
    'none',
    'chime',
    'bell',
    'soft',
    'pop',
  ];
  static const vibrations = ['default', 'none', 'short', 'long'];
}
