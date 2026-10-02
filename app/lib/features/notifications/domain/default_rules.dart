import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// A section default seeded once per account (T7.1.07). Ids are deterministic:
/// `uuidv5(user_id | 'default-rule' | section | code)`.
@immutable
class DefaultRuleSeed {
  const DefaultRuleSeed({required this.section, required this.code, required this.profileCode, required this.spec});

  final NotificationSection section;
  final String code;
  final String profileCode;
  final NotificationRuleSpec spec;
}

abstract final class DefaultRules {
  /// Seeded defaults (all editable). Digests are off by default (created from settings).
  static final List<DefaultRuleSeed> seeds = [
    // Planner, timed: the user's own example — 10 min before start + at start.
    const DefaultRuleSeed(
      section: NotificationSection.planner,
      code: 'timed_before_10',
      profileCode: BuiltinProfiles.standard,
      spec: NotificationRuleSpec(
        trigger: RelativeTrigger(anchor: TriggerAnchor.start, offsetMinutes: -10),
        conditions: ConditionsSpec(itemKind: 'timed', onlyIfStatusIn: ['scheduled', 'in_progress']),
        delivery: DeliverySpec(actions: ['start', 'snooze', 'skip']),
      ),
    ),
    const DefaultRuleSeed(
      section: NotificationSection.planner,
      code: 'timed_at_start',
      profileCode: BuiltinProfiles.standard,
      spec: NotificationRuleSpec(
        trigger: RelativeTrigger(anchor: TriggerAnchor.start, offsetMinutes: 0),
        conditions: ConditionsSpec(itemKind: 'timed', onlyIfStatusIn: ['scheduled', 'in_progress']),
        delivery: DeliverySpec(actions: ['done', 'snooze', 'skip']),
      ),
    ),
    // Planner all-day / date-only: on the day at 09:00.
    DefaultRuleSeed(
      section: NotificationSection.planner,
      code: 'allday_on_day',
      profileCode: BuiltinProfiles.standard,
      spec: NotificationRuleSpec(
        trigger: RelativeTrigger(anchor: TriggerAnchor.start, dayOffset: 0, atTime: LocalTime(9, 0)),
        conditions: const ConditionsSpec(itemKind: 'all_day'),
        delivery: const DeliverySpec(actions: ['done', 'snooze', 'open']),
      ),
    ),
    DefaultRuleSeed(
      section: NotificationSection.planner,
      code: 'dateonly_on_day',
      profileCode: BuiltinProfiles.standard,
      spec: NotificationRuleSpec(
        trigger: RelativeTrigger(anchor: TriggerAnchor.start, dayOffset: 0, atTime: LocalTime(9, 0)),
        conditions: const ConditionsSpec(itemKind: 'date_only'),
        delivery: const DeliverySpec(actions: ['done', 'snooze', 'open']),
      ),
    ),
    // Checklists: follow-up of waiting/blocked items + at due.
    const DefaultRuleSeed(
      section: NotificationSection.checklists,
      code: 'follow_up',
      profileCode: BuiltinProfiles.standard,
      spec: NotificationRuleSpec(
        trigger: RelativeTrigger(anchor: TriggerAnchor.followUp, offsetMinutes: 0),
        delivery: DeliverySpec(actions: ['mark_ongoing', 'done', 'snooze']),
      ),
    ),
    const DefaultRuleSeed(
      section: NotificationSection.checklists,
      code: 'at_due',
      profileCode: BuiltinProfiles.standard,
      spec: NotificationRuleSpec(
        trigger: RelativeTrigger(anchor: TriggerAnchor.due, offsetMinutes: 0),
        delivery: DeliverySpec(actions: ['done', 'snooze', 'open']),
      ),
    ),
    // Habits: at each slot (09:00 when untimed) + streak at risk at 21:00 (Gentle).
    const DefaultRuleSeed(
      section: NotificationSection.habits,
      code: 'at_slot',
      profileCode: BuiltinProfiles.standard,
      spec: NotificationRuleSpec(
        trigger: RelativeTrigger(anchor: TriggerAnchor.slot, offsetMinutes: 0),
        delivery: DeliverySpec(actions: ['done', 'log_value', 'skip']),
      ),
    ),
    DefaultRuleSeed(
      section: NotificationSection.habits,
      code: 'streak_risk',
      profileCode: BuiltinProfiles.gentle,
      spec: NotificationRuleSpec(
        trigger: StreakRiskTrigger(atTime: LocalTime(21, 0), minStreak: 3),
        delivery: const DeliverySpec(actions: ['done', 'log_value', 'skip']),
      ),
    ),
    // Quit: milestone notifications.
    const DefaultRuleSeed(
      section: NotificationSection.quit,
      code: 'milestones',
      profileCode: BuiltinProfiles.standard,
      spec: NotificationRuleSpec(
        trigger: MilestoneTrigger(metric: 'clean_days'),
        delivery: DeliverySpec(actions: ['open']),
      ),
    ),
    const DefaultRuleSeed(
      section: NotificationSection.quit,
      code: 'health_milestones',
      profileCode: BuiltinProfiles.standard,
      spec: NotificationRuleSpec(
        trigger: MilestoneTrigger(metric: 'health'),
        delivery: DeliverySpec(actions: ['open']),
      ),
    ),
    const DefaultRuleSeed(
      section: NotificationSection.quit,
      code: 'money_milestones',
      profileCode: BuiltinProfiles.standard,
      spec: NotificationRuleSpec(
        trigger: MilestoneTrigger(metric: 'money_saved'),
        delivery: DeliverySpec(actions: ['open']),
      ),
    ),
    const DefaultRuleSeed(
      section: NotificationSection.quit,
      code: 'goal_milestones',
      profileCode: BuiltinProfiles.standard,
      spec: NotificationRuleSpec(
        trigger: MilestoneTrigger(metric: 'custom'),
        delivery: DeliverySpec(actions: ['open']),
      ),
    ),
  ];

  /// Off-peak default times for digests (FCM spikes at :00/:15/:30/:45 — arch §9.7).
  static final Map<String, LocalTime> digestDefaultTimes = {
    'daily_agenda': LocalTime(7, 7),
    'plan_tomorrow': LocalTime(20, 37),
    'evening_review': LocalTime(21, 7),
    'overdue_summary': LocalTime(12, 7),
    'weekly_review': LocalTime(18, 7),
    'monthly_report': LocalTime(9, 7),
  };

  /// [digestDefaultTimes] shifted by a stable per-user 0–4 minutes, so users don't all fire in
  /// the same minute (still never on a quarter hour: 07:07–07:11, 20:37–20:41…).
  static LocalTime digestDefaultTimeFor(String userId, String kind) {
    final base = digestDefaultTimes[kind] ?? LocalTime(7, 7);
    var hash = 0;
    for (final c in userId.codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    return LocalTime.fromMinuteOfDay(base.minuteOfDay + hash % 5);
  }

  /// Deterministic id of the digest rule of [kind] (one per user, T7.5.18).
  static String digestRuleId(String userId, String kind) => Ids.v5('$userId|digest-rule|$kind');

  /// Digest rule spec for [kind] at [time] (weekly/monthly kinds on [weekday]/day 1).
  static NotificationRuleSpec digestSpec(String kind, LocalTime time, {int weekday = 7}) {
    final schedule = switch (kind) {
      'weekly_review' => {
        'v': 1,
        'type': 'fixed',
        'freq': 'weekly',
        'interval': 1,
        'byWeekday': [
          {'day': Weekday.fromIso(weekday.clamp(1, 7)).code},
        ],
        'times': [time.toIso()],
      },
      'monthly_report' => {
        'v': 1,
        'type': 'fixed',
        'freq': 'monthly',
        'interval': 1,
        'byMonthDay': [1],
        'times': [time.toIso()],
      },
      _ => {
        'v': 1,
        'type': 'fixed',
        'freq': 'daily',
        'interval': 1,
        'times': [time.toIso()],
      },
    };
    return NotificationRuleSpec(
      trigger: DigestTrigger(kind: kind, schedule: schedule),
      delivery: const DeliverySpec(actions: ['open'], importance: 'low'),
    );
  }
}
