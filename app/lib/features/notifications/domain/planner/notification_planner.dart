import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/features/notifications/domain/delivery_resolution.dart';
import 'package:everslot/features/notifications/domain/effective_rules_resolver.dart';
import 'package:everslot/features/notifications/domain/json_fields.dart';
import 'package:everslot/features/notifications/domain/notification_actions.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_settings.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/planner/planned_notification.dart';
import 'package:everslot/features/notifications/domain/planner/recurrence_adapter.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/domain/template_engine.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

export 'package:everslot/features/notifications/domain/planner/planned_notification.dart';

/// Everything the planner needs (T7.2.06). Pure data — deterministic across devices.
@immutable
class PlanningContext {
  const PlanningContext({
    required this.now,
    required this.deviceZone,
    required this.zones,
    required this.settings,
    required this.rules,
    required this.targets,
    this.profiles = const [],
    this.mutes = const [],
    this.texts = const PlainNotificationTexts(),
    this.acknowledgedKeys = const {},
    this.deviceId = '',
    this.lastForegroundAt,
    this.userId = '',
    this.timeSensitiveAllowed = true,
    this.horizon,
    this.expander,
    this.applyCaps = true,
  });

  final DateTime now;
  final String deviceZone;
  final ZoneResolver zones;
  final NotificationSettings settings;
  final List<NotificationRule> rules;
  final List<NotificationTarget> targets;
  final List<NotificationProfile> profiles;
  final List<NotificationMute> mutes;
  final NotificationTexts texts;

  /// Base dedupe keys acknowledged on any device (inbox acted/opened/dismissed) — stops nags.
  final Set<String> acknowledgedKeys;
  final String deviceId;

  /// This device's last foreground (last-active policy, T7.4.19); null = unknown.
  final DateTime? lastForegroundAt;
  final String userId;
  final bool timeSensitiveAllowed;

  /// Overrides `settings.horizonDays`.
  final Duration? horizon;
  final RecurrenceExpander? expander;

  RecurrenceExpander get effectiveExpander => expander ?? EngineRecurrenceExpander.shared;
  final bool applyCaps;

  Duration get effectiveHorizon => horizon ?? Duration(days: settings.horizonDays);
}

/// Base candidate before policies.
class _Candidate {
  _Candidate(
    this.fireAt,
    this.occurrenceKey,
    this.kind, {
    this.count,
    this.anchor,
    this.extraVars = const {},
    this.repeatable = false,
  });

  final DateTime fireAt;
  final String occurrenceKey;
  final DefaultContentKind kind;
  final int? count;

  /// From an unbounded daily/weekly fixed-time `schedule` (T7.2.10).
  final bool repeatable;

  /// Anchor instant (for `{minutes_until}`).
  final DateTime? anchor;
  final Map<String, String> extraVars;
}

/// Pure planner: targets × effective rules → concrete firings (T7.2.06/T7.2.07).
abstract final class NotificationPlanner {
  /// Maximum minutes a relative offset may reach (±30 days, T7.1.04).
  static const maxOffsetMinutes = 30 * 1440;

  /// Plans every target of [ctx].
  static PlanResult plan(PlanningContext ctx) {
    final index = RuleIndex(ctx.rules);
    final resolver = EffectiveRulesResolver(index, ctx.settings);
    final profiles = {for (final p in ctx.profiles) p.id: p};
    final planned = <String, PlannedNotification>{};
    final skipped = <SkippedFiring>[];
    for (final target in ctx.targets) {
      final List<NotificationRule> rules;
      if (target.type == NotificationTargetType.digest) {
        rules = [
          for (final r in index.standalone)
            if (r.enabled && r.spec.trigger is DigestTrigger && (r.spec.trigger as DigestTrigger).kind == target.id) r,
        ];
      } else {
        rules = [for (final e in resolver.forTarget(target)) e.rule];
      }
      for (final rule in rules) {
        _planRule(ctx, rule, target, profiles, planned, skipped);
      }
    }
    _mergeUpNext(ctx.targets, planned);
    final sorted = planned.values.toList()
      ..sort((a, b) {
        final c = a.fireAt.compareTo(b.fireAt);
        if (c != 0) return c;
        final i = b.importance.rank.compareTo(a.importance.rank);
        return i != 0 ? i : a.dedupeKey.compareTo(b.dedupeKey);
      });
    return PlanResult(ctx.applyCaps ? _applyCaps(ctx, sorted, skipped) : sorted, skipped);
  }

  /// Back-to-back tasks (T7.5.04): a "done → up next" notification at the boundary replaces the next
  /// task's own reminders firing at that same instant, so the user gets one notification, not two.
  static void _mergeUpNext(List<NotificationTarget> targets, Map<String, PlannedNotification> planned) {
    final byKey = {for (final t in targets) '${t.targetKey}|${t.occurrenceKey ?? ''}': t};
    final drop = <String>{};
    for (final p in planned.values) {
      if (p.triggerType != 'up_next' || !p.occurrenceKey.endsWith('|un')) continue;
      final t = byKey['task:${p.targetId}|${p.occurrenceKey.substring(0, p.occurrenceKey.length - 3)}'];
      final nextId = t?.variables['next_task_id'];
      final nextOcc = t?.variables['next_occurrence_key'];
      if (nextId is! String || nextOcc is! String) continue;
      for (final q in planned.values) {
        if (q.targetId == nextId && q.occurrenceKey == nextOcc && q.triggerType == 'relative' && q.fireAt == p.fireAt) {
          drop.add(q.dedupeKey);
        }
      }
    }
    planned.removeWhere((k, _) => drop.contains(k));
  }

  /// Plans a single rule for one target (preview & noise estimate share this code path).
  static PlanResult planRule(PlanningContext ctx, NotificationRule rule, NotificationTarget target) {
    final planned = <String, PlannedNotification>{};
    final skipped = <SkippedFiring>[];
    _planRule(ctx, rule, target, {for (final p in ctx.profiles) p.id: p}, planned, skipped);
    final sorted = planned.values.toList()..sort((a, b) => a.fireAt.compareTo(b.fireAt));
    return PlanResult(sorted, skipped);
  }

  // ------------------------------------------------------------------------------ per rule --

  static void _planRule(
    PlanningContext ctx,
    NotificationRule rule,
    NotificationTarget target,
    Map<String, NotificationProfile> profiles,
    Map<String, PlannedNotification> planned,
    List<SkippedFiring> skipped,
  ) {
    final zone = target.timeZone ?? ctx.deviceZone;
    final horizonEnd = ctx.now.add(ctx.effectiveHorizon);
    final sectionDefault = profiles[ctx.settings.sectionDefaultProfileId(target.section) ?? ''];
    final delivery = resolveDelivery(
      spec: rule.spec,
      ruleProfile: profiles[rule.profileId ?? ''],
      sectionDefault: sectionDefault,
      targetDefaultActions: _triggerActions(rule.spec.trigger, target) ?? target.defaultActions,
    );
    final profileContent = profiles[rule.profileId ?? '']?.spec.content;
    final escalated = <EscalationStep, EffectiveDelivery>{};
    final candidates = _candidates(ctx, rule, target, zone, horizonEnd);
    for (final c in candidates) {
      final occurrenceKey = c.occurrenceKey;
      void skip(SkipReason reason, DateTime at) => skipped.add(
        SkippedFiring(
          ruleId: rule.id,
          targetKey: target.targetKey,
          occurrenceKey: occurrenceKey,
          fireAt: at,
          reason: reason,
        ),
      );
      final baseKey = dedupeKeyFor(ruleId: rule.id, targetId: target.id, occurrenceKey: occurrenceKey);
      final base = _applyPolicies(ctx, rule, target, delivery, c.fireAt, zone, skip, nag: false);
      if (base == null) continue;
      if (base.fireAt.isAfter(horizonEnd)) continue;
      final instance = _build(
        ctx,
        rule,
        target,
        delivery,
        profileContent,
        c,
        base,
        dedupeKey: baseKey,
        baseKey: baseKey,
        repeatIdx: 0,
      );
      planned.putIfAbsent(instance.dedupeKey, () => instance);

      final repeat = delivery.repeat;
      if (repeat == null || repeat.everyMinutes < 1) continue;
      if (repeat.until != RepeatUntil.max && ctx.acknowledgedKeys.contains(baseKey)) {
        skip(SkipReason.acknowledged, base.fireAt);
        continue;
      }
      final times = [
        repeat.maxTimes,
        ctx.settings.maxNagRepeats,
        RepeatSpec.hardMaxTimes,
      ].reduce((a, b) => a < b ? a : b);
      for (var i = 1; i <= times; i++) {
        final at = base.fireAt.add(Duration(minutes: repeat.everyMinutes * i));
        if (at.isAfter(horizonEnd)) break;
        // Escalation (T7.2.23): later nags may use a louder profile and every device.
        final step = repeat.stepFor(i);
        final d = step == null
            ? delivery
            : escalated.putIfAbsent(step, () => _escalate(rule, target, profiles, sectionDefault, step) ?? delivery);
        final allDevices = step?.allDevices ?? false;
        final nag = _applyPolicies(ctx, rule, target, d, at, zone, skip, nag: true, allDevices: allDevices);
        if (nag == null) continue;
        final key = dedupeKeyFor(ruleId: rule.id, targetId: target.id, occurrenceKey: occurrenceKey, repeatIdx: i);
        final n = _build(
          ctx,
          rule,
          target,
          d,
          profileContent,
          c,
          nag,
          dedupeKey: key,
          baseKey: baseKey,
          repeatIdx: i,
          allDevices: allDevices,
        );
        planned.putIfAbsent(n.dedupeKey, () => n);
      }
    }
  }

  /// Delivery of the nags covered by escalation [step]: the step's profile (by id or built-in
  /// code) replaces the rule's own delivery fields except its actions; null when unknown.
  static EffectiveDelivery? _escalate(
    NotificationRule rule,
    NotificationTarget target,
    Map<String, NotificationProfile> profiles,
    NotificationProfile? sectionDefault,
    EscalationStep step,
  ) {
    final profile = profiles[step.profile] ?? profiles.values.where((p) => p.code == step.profile).firstOrNull;
    if (profile == null) return null;
    return resolveDelivery(
      spec: rule.spec.copyWith(delivery: DeliverySpec(actions: rule.spec.delivery.actions)),
      ruleProfile: profile,
      sectionDefault: sectionDefault,
      targetDefaultActions: _triggerActions(rule.spec.trigger, target) ?? target.defaultActions,
    );
  }

  // ---------------------------------------------------------------------------- candidates --

  static List<_Candidate> _candidates(
    PlanningContext ctx,
    NotificationRule rule,
    NotificationTarget target,
    String zone,
    DateTime horizonEnd,
  ) {
    final zones = ctx.zones;
    final occ = target.occurrenceKey ?? '';
    DateTime at(LocalDate date, LocalTime time) => zones.resolve(LocalDateTime(date, time), zone).utc;
    LocalDate dateOf(DateTime instant) => zones.toLocal(instant, zone).date;
    String localKey(DateTime instant) => zones.toLocal(instant, zone).toIso();
    final dateOnlyTime = ctx.settings.effectiveDateOnlyTime;

    switch (rule.spec.trigger) {
      case RelativeTrigger(:final anchor, :final dayOffset, :final atTime, :final effectiveOffset, :final usesDayForm):
        var anchorAt = _anchor(target, anchor);
        var fallbackUsed = false;
        if (anchorAt == null && anchor == TriggerAnchor.slot && target.periodStart != null) {
          anchorAt = at(dateOf(target.periodStart!), dateOnlyTime);
          fallbackUsed = true;
        }
        if (anchorAt == null) return const [];
        if (usesDayForm) {
          // End-like anchors are exclusive instants (an all-day span ends at the next midnight):
          // their day is the last included one, so "on the last day at 18:00" = end, dayOffset 0.
          final anchorDate = anchor.isEndLike
              ? dateOf(anchorAt.subtract(const Duration(minutes: 1)))
              : dateOf(anchorAt);
          final date = anchorDate.plusDays(dayOffset!);
          return [
            _Candidate(
              at(date, atTime!),
              occ,
              dayOffset == 0 ? DefaultContentKind.onDay : DefaultContentKind.daysBefore,
              count: dayOffset.abs(),
              anchor: anchorAt,
              extraVars: {'date': ctx.texts.date(anchorDate)},
            ),
          ];
        }
        final kind = _relativeKind(anchor, effectiveOffset, fallbackUsed);
        return [
          _Candidate(
            anchorAt.add(Duration(minutes: effectiveOffset)),
            occ,
            kind,
            count: effectiveOffset.abs(),
            anchor: anchorAt,
          ),
        ];

      case AbsoluteTrigger(at: final local, :final timeZone):
        final instant = zones.resolve(local, timeZone ?? zone).utc;
        return [_Candidate(instant, 'abs:${local.toIso()}', DefaultContentKind.absolute)];

      case ScheduleTrigger(:final recurrence):
        final from = ctx.now.subtract(Duration(minutes: ctx.settings.latenessMinutes));
        final repeatable = isSimpleRepeating(recurrence);
        return [
          for (final instant in ctx.effectiveExpander.instantsBetween(
            recurrence,
            zone: zone,
            fromUtc: from,
            toUtc: horizonEnd,
            zones: zones,
          ))
            _Candidate(instant, 'sch:${localKey(instant)}', DefaultContentKind.schedule, repeatable: repeatable),
        ];

      case DigestTrigger(:final schedule, :final kind):
        final from = target.periodStart ?? ctx.now.subtract(Duration(minutes: ctx.settings.digestLatenessMinutes));
        final to = target.periodEnd ?? horizonEnd;
        return [
          for (final instant in ctx.effectiveExpander.instantsBetween(
            schedule,
            zone: zone,
            fromUtc: from,
            toUtc: to,
            zones: zones,
          ))
            _Candidate(instant, 'dg:${dateOf(instant).toIso()}', DefaultContentKind.digest, extraVars: {'kind': kind}),
        ];

      case NotDoneByTrigger(anchor: final a, :final effectiveOffset, :final atTime):
        final DateTime? base;
        if (a == 'end') {
          base = target.end ?? target.due;
        } else if (a == 'time') {
          final day = target.periodStart ?? target.slot ?? target.start ?? target.due;
          base = day == null || atTime == null ? null : at(dateOf(day), atTime);
        } else {
          base = target.periodEnd ?? target.end;
        }
        if (base == null) return const [];
        return [_Candidate(base.add(Duration(minutes: effectiveOffset)), occ, DefaultContentKind.notDoneBy)];

      case StatusAgeTrigger(:final statuses, :final afterMinutes):
        if (target.status == null || !statuses.contains(target.status) || target.statusChangedAt == null) {
          return const [];
        }
        final changed = target.statusChangedAt!;
        return [
          _Candidate(
            changed.add(Duration(minutes: afterMinutes)),
            '$occ|sa:${changed.toUtc().toIso8601String()}',
            DefaultContentKind.statusAge,
            count: afterMinutes,
          ),
        ];

      case OverdueTrigger(:final afterMinutes):
        // Events have no "done" state: they never go overdue (T7.5.03).
        if (target.variables['tracking_mode'] == 'event') return const [];
        final base = target.end ?? target.due;
        if (base == null) return const [];
        final after = afterMinutes ?? asInt(target.variables['missed_grace_minutes']) ?? 0;
        return [_Candidate(base.add(Duration(minutes: after)), occ, DefaultContentKind.overdue)];

      case StreakRiskTrigger(atTime: final time, :final effectiveMinStreak):
        if ((target.streak ?? 0) < effectiveMinStreak) return const [];
        final day = target.periodStart ?? target.slot ?? target.start;
        if (day == null) return const [];
        return [_Candidate(at(dateOf(day), time), occ, DefaultContentKind.streakRisk, count: target.streak)];

      case QuotaBehindTrigger(atTime: final time):
        final quota = target.quota;
        if (quota == null || !quota.behind) return const [];
        final day = target.slot ?? target.periodStart ?? ctx.now;
        return [
          _Candidate(
            at(dateOf(day), time),
            '$occ|qb:${dateOf(day).toIso()}',
            DefaultContentKind.quotaBehind,
            count: quota.remaining,
            extraVars: {
              'done': ctx.texts.number(quota.done),
              'target': ctx.texts.number(quota.target),
              'days_left': '${quota.eligibleDaysLeft}',
            },
          ),
        ];

      case MilestoneTrigger(:final metric, :final thresholds, :final effectiveThresholds):
        final out = <_Candidate>[];
        if (metric == 'clean_days' && target.milestoneBaseline != null) {
          for (final t in effectiveThresholds) {
            final instant = target.milestoneBaseline!.add(Duration(minutes: (t * 1440).round()));
            out.add(
              _Candidate(
                instant,
                'm:$metric:$t:${target.milestoneBaseline!.toUtc().toIso8601String()}',
                DefaultContentKind.milestone,
                count: t.round(),
                extraVars: {'next_milestone': ctx.texts.number(t), 'days_free': ctx.texts.number(t)},
              ),
            );
          }
        }
        for (final m in target.milestones) {
          if (m.metric != metric) continue;
          if (thresholds != null && !thresholds.contains(m.threshold)) continue;
          out.add(
            _Candidate(
              m.at,
              m.runKey == null ? 'm:$metric:${m.threshold}' : 'm:$metric:${m.threshold}:${m.runKey}',
              DefaultContentKind.milestone,
              count: m.threshold.round(),
              extraVars: {'next_milestone': m.label ?? ctx.texts.number(m.threshold)},
            ),
          );
        }
        return out;

      case InactivityTrigger(:final afterDays, atTime: final time):
        final last = target.lastActivityAt;
        if (last == null) return const [];
        final day = dateOf(last).plusDays(afterDays);
        return [
          _Candidate(
            at(day, time ?? dateOnlyTime),
            'ina:${dateOf(last).toIso()}',
            DefaultContentKind.inactivity,
            count: afterDays,
          ),
        ];

      case StaleTrigger(:final afterDays, atTime: final time):
        final last = target.lastActivityAt;
        if (last == null) return const [];
        final day = dateOf(last).plusDays(afterDays);
        return [
          _Candidate(
            at(day, time ?? dateOnlyTime),
            'stale:${dateOf(last).toIso()}',
            DefaultContentKind.stale,
            count: afterDays,
          ),
        ];

      case StatusChangeTrigger(:final from, :final to, atTime: final time):
        return [
          for (final e in target.events)
            if (e.kind == 'status_change' && e.data['to'] == to && (from == null || e.data['from'] == from))
              _Candidate(
                time == null ? e.at : _laterOf(e.at, at(dateOf(e.at), time)),
                'evt:status:$to:${e.at.toUtc().toIso8601String()}',
                DefaultContentKind.statusChange,
                extraVars: {'status': ctx.texts.status(to)},
              ),
        ];

      case ChildrenCompleteTrigger():
        return [
          for (final e in target.events)
            if (e.kind == 'children_complete')
              _Candidate(e.at, 'evt:children:${dateOf(e.at).toIso()}', DefaultContentKind.childrenComplete),
        ];

      case ChildOverdueTrigger():
        return [
          for (final e in target.events)
            if (e.kind == 'child_overdue')
              _Candidate(
                e.at,
                'evt:child_overdue:${e.data['childId'] ?? ''}:${dateOf(e.at).toIso()}',
                DefaultContentKind.childOverdue,
              ),
        ];

      case UpNextTrigger(:final beforeMinutes):
        // The planner source names the next timed task of the day (T7.5.04).
        final nextStart = DateTime.tryParse('${target.variables['next_start'] ?? ''}')?.toUtc();
        final nextTitle = target.variables['next_title'];
        if (nextStart == null || nextTitle is! String || target.end == null) return const [];
        final backToBack = beforeMinutes == null && !nextStart.isAfter(target.end!);
        final fire = beforeMinutes == null ? target.end! : nextStart.subtract(Duration(minutes: beforeMinutes));
        return [
          _Candidate(
            fire,
            '$occ|un',
            backToBack ? DefaultContentKind.upNextMerged : DefaultContentKind.upNext,
            anchor: nextStart,
            extraVars: {'next_title': nextTitle, 'next_start_time': ctx.texts.time(zones.toLocal(nextStart, zone))},
          ),
        ];

      case ListResetTrigger(atTime: final time):
        return [
          for (final e in target.events)
            if (e.kind == 'list_reset')
              _Candidate(
                time == null ? e.at : _laterOf(e.at, at(dateOf(e.at), time)),
                'evt:reset:${dateOf(e.at).toIso()}',
                DefaultContentKind.listReset,
              ),
        ];

      case TimerEndTrigger():
        // Only while the timer runs: starting it replans; stopping closes the alert (T7.5.04).
        if (target.variables['tracking_mode'] != 'timer' || target.status != 'in_progress') return const [];
        final end = target.end;
        if (end == null) return const [];
        return [_Candidate(end, '$occ|te', DefaultContentKind.timerEnd)];

      case QuitRitualTrigger(:final kind, atTime: final time, :final effectiveMinutesBefore):
        return _ritual(kind, time, effectiveMinutesBefore, target, ctx.now, horizonEnd, at, dateOf);

      case UnknownTrigger():
        return const [];
    }
  }

  /// Quit rituals (T7.5.14) over every local day from today to the horizon. Target inputs: events
  /// `pledge` / `review` (that day's ritual is already done) and `relapse`; variables
  /// `pledge_time`, `review_time`, `craving_count`, `craving_hours` (comma-separated local hours),
  /// `coping_tip` and `reason`.
  static List<_Candidate> _ritual(
    String kind,
    LocalTime? time,
    int minutesBefore,
    NotificationTarget target,
    DateTime now,
    DateTime horizonEnd,
    DateTime Function(LocalDate, LocalTime) at,
    LocalDate Function(DateTime) dateOf,
  ) {
    String? v(String key) => target.variables[key]?.toString();
    LocalTime? timeVar(String key) => v(key) == null ? null : LocalTime.tryParse(v(key)!);
    final last = dateOf(horizonEnd);
    final days = [for (var d = dateOf(now); d.compareTo(last) <= 0; d = d.plusDays(1)) d];
    bool done(String event, LocalDate d) => target.events.any((e) => e.kind == event && dateOf(e.at) == d);
    switch (kind) {
      case QuitRitualTrigger.pledge:
        final t = time ?? timeVar('pledge_time') ?? LocalTime(8, 0);
        return [
          for (final d in days)
            if (!done('pledge', d)) _Candidate(at(d, t), 'qr:pledge:${d.toIso()}', DefaultContentKind.pledge),
        ];
      case QuitRitualTrigger.eveningReview:
        final t = time ?? timeVar('review_time') ?? LocalTime(21, 0);
        return [
          for (final d in days)
            if (!done('review', d)) _Candidate(at(d, t), 'qr:review:${d.toIso()}', DefaultContentKind.eveningReview),
        ];
      case QuitRitualTrigger.cravingSupport:
        final count = int.tryParse(v('craving_count') ?? '') ?? 0;
        if (count < QuitRitualTrigger.cravingSupportMinCravings) return const [];
        final hours = [
          for (final h in (v('craving_hours') ?? '').split(','))
            if (int.tryParse(h.trim()) case final hour? when hour >= 0 && hour < 24) hour,
        ];
        return [
          for (final d in days)
            for (final h in hours)
              _Candidate(
                at(d, LocalTime(h, 0)).subtract(Duration(minutes: minutesBefore)),
                'qr:crave:${d.toIso()}:$h',
                DefaultContentKind.cravingSupport,
                extraVars: {'tip': ?v('coping_tip')},
              ),
        ];
      case QuitRitualTrigger.encouragement:
        final t = time ?? LocalTime(8, 0);
        return [
          for (final e in target.events)
            if (e.kind == 'relapse')
              _Candidate(
                at(dateOf(e.at).plusDays(1), t),
                'qr:enc:${dateOf(e.at).toIso()}',
                DefaultContentKind.encouragement,
              ),
        ];
      case QuitRitualTrigger.motivation:
        final reason = v('reason')?.trim() ?? '';
        if (reason.isEmpty) return const [];
        final t = time ?? LocalTime(12, 0);
        return [for (final d in days) _Candidate(at(d, t), 'qr:mot:${d.toIso()}', DefaultContentKind.motivation)];
      default:
        return const [];
    }
  }

  static DateTime _laterOf(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

  /// Trigger-specific default actions (used when neither the rule nor its profile sets any).
  static List<String>? _triggerActions(NotificationTrigger trigger, NotificationTarget target) => switch (trigger) {
    OverdueTrigger() when target.type == NotificationTargetType.task => const [
      NotificationActionIds.done,
      NotificationActionIds.reschedule,
      NotificationActionIds.skip,
    ],
    UpNextTrigger() => const [NotificationActionIds.done, NotificationActionIds.open],
    // "All sub-items are done — complete it?" (T7.5.09).
    ChildrenCompleteTrigger() when target.type == NotificationTargetType.checklistItem => const [
      NotificationActionIds.completeItem,
      NotificationActionIds.open,
    ],
    ListResetTrigger() => const [NotificationActionIds.open],
    TimerEndTrigger() => const [NotificationActionIds.stop, NotificationActionIds.extend],
    QuitRitualTrigger(:final kind) => switch (kind) {
      QuitRitualTrigger.pledge => const [NotificationActionIds.pledge, NotificationActionIds.open],
      QuitRitualTrigger.eveningReview => const [
        NotificationActionIds.cleanDay,
        NotificationActionIds.logRelapse,
        NotificationActionIds.logCraving,
      ],
      QuitRitualTrigger.cravingSupport => const [NotificationActionIds.logCraving, NotificationActionIds.open],
      _ => const [NotificationActionIds.open],
    },
    _ => null,
  };

  static DateTime? _anchor(NotificationTarget t, TriggerAnchor anchor) => switch (anchor) {
    TriggerAnchor.start => t.start,
    TriggerAnchor.end => t.end,
    TriggerAnchor.due => t.due,
    TriggerAnchor.followUp => t.followUp,
    TriggerAnchor.slot => t.slot ?? (t.type == NotificationTargetType.habit ? null : t.start),
    TriggerAnchor.periodStart => t.periodStart,
    TriggerAnchor.periodEnd => t.periodEnd,
  };

  static DefaultContentKind _relativeKind(TriggerAnchor anchor, int offset, bool slotFallback) {
    if (slotFallback) return DefaultContentKind.slot;
    return switch (anchor) {
      TriggerAnchor.start =>
        offset < 0
            ? DefaultContentKind.beforeStart
            : (offset == 0 ? DefaultContentKind.atStart : DefaultContentKind.afterStart),
      TriggerAnchor.end || TriggerAnchor.periodEnd =>
        offset < 0
            ? DefaultContentKind.beforeEnd
            : (offset == 0 ? DefaultContentKind.atEnd : DefaultContentKind.afterEnd),
      TriggerAnchor.due => offset < 0 ? DefaultContentKind.beforeDue : DefaultContentKind.atDue,
      TriggerAnchor.followUp => DefaultContentKind.followUp,
      TriggerAnchor.slot || TriggerAnchor.periodStart => DefaultContentKind.slot,
    };
  }

  // ------------------------------------------------------------------------------ policies --

  static _Policed? _applyPolicies(
    PlanningContext ctx,
    NotificationRule rule,
    NotificationTarget target,
    EffectiveDelivery delivery,
    DateTime fireAt,
    String zone,
    void Function(SkipReason reason, DateTime at) skip, {
    required bool nag,
    bool allDevices = false,
  }) {
    final zones = ctx.zones;
    final conditions = rule.spec.conditions;
    final adjustments = <PlanAdjustment>{};
    var at = fireAt;
    DateTime? anchorFireAt;

    if (!target.isOpen) {
      skip(SkipReason.guardClosed, at);
      return null;
    }
    final statuses = conditions.onlyIfStatusIn;
    if (statuses != null && statuses.isNotEmpty && target.status != null && !statuses.contains(target.status)) {
      skip(SkipReason.statusFilter, at);
      return null;
    }
    if (!nag) {
      final weekdays = conditions.weekdays;
      if (weekdays != null && weekdays.isNotEmpty && !weekdays.contains(zones.toLocal(at, zone).date.weekday.iso)) {
        skip(SkipReason.weekdayFilter, at);
        return null;
      }
      final window = conditions.timeWindow;
      if (window != null) {
        final local = zones.toLocal(at, zone);
        if (!window.contains(local.time)) {
          switch (window.outside) {
            case OutsideWindow.drop:
              skip(SkipReason.timeWindowDrop, at);
              return null;
            case OutsideWindow.shiftStart:
              final date = local.time.isBefore(window.from) ? local.date : local.date.plusDays(1);
              anchorFireAt = at;
              at = zones.resolve(LocalDateTime(date, window.from), zone).utc;
              adjustments.add(PlanAdjustment.shiftedToWindow);
            case OutsideWindow.shiftEnd:
              final end = window.to.isEndOfDay ? LocalTime(23, 59) : window.to;
              final date = local.time.isAfter(end) ? local.date : local.date.minusDays(1);
              anchorFireAt = at;
              at = zones.resolve(LocalDateTime(date, end), zone).utc;
              adjustments.add(PlanAdjustment.shiftedToWindow);
          }
        }
      }
    }
    if (_muted(ctx, rule, target, at)) {
      skip(SkipReason.muted, at);
      return null;
    }

    var silent = false;
    if (delivery.respectQuietHours && ctx.settings.quietHours.isNotEmpty) {
      final local = zones.toLocal(at, ctx.deviceZone);
      for (final w in ctx.settings.quietHours) {
        final end = w.endIfInside(local);
        if (end == null) continue;
        final mode = nag && w.mode == QuietHoursMode.defer ? QuietHoursMode.drop : w.mode;
        switch (mode) {
          case QuietHoursMode.drop:
            skip(SkipReason.quietHoursDrop, at);
            return null;
          case QuietHoursMode.silent:
            silent = true;
            adjustments.add(PlanAdjustment.silentQuietHours);
          case QuietHoursMode.defer:
            anchorFireAt ??= at;
            at = zones.resolve(end, ctx.deviceZone).utc;
            adjustments.add(PlanAdjustment.deferredQuietHours);
        }
        break;
      }
    }

    var system = delivery.system;
    var banner = delivery.banner;
    if (ctx.settings.pausedAt(at)) {
      system = false;
      banner = false;
      adjustments.add(PlanAdjustment.paused);
    }
    if (!system && !banner && !delivery.inbox) {
      skip(SkipReason.noChannel, at);
      return null;
    }

    final isDigest = rule.spec.trigger is DigestTrigger;
    final lateness =
        delivery.latenessMinutes ?? (isDigest ? ctx.settings.digestLatenessMinutes : ctx.settings.latenessMinutes);
    final expiresAt = at.add(Duration(minutes: lateness < 1 ? 1 : lateness));
    if (at.isBefore(ctx.now)) {
      if (!expiresAt.isAfter(ctx.now)) {
        skip(SkipReason.expired, at);
        return null;
      }
      adjustments.add(PlanAdjustment.catchUp);
    }

    final devices = conditions.devices;
    final local =
        ctx.settings.localSchedulingAllowed(ctx.deviceId, lastForegroundAt: ctx.lastForegroundAt, now: ctx.now) &&
        (allDevices || devices == null || devices.isEmpty || devices.contains(ctx.deviceId));
    if (!local) adjustments.add(PlanAdjustment.notLocal);

    return _Policed(
      fireAt: at,
      expiresAt: expiresAt,
      system: system,
      banner: banner,
      silent: silent || delivery.silent,
      quietSilent: silent,
      scheduleLocally: local,
      adjustments: adjustments,
      anchorFireAt: anchorFireAt,
    );
  }

  static bool _muted(PlanningContext ctx, NotificationRule rule, NotificationTarget target, DateTime at) {
    for (final m in ctx.mutes) {
      if (!m.activeAt(at)) continue;
      final hit = switch (m.targetType) {
        'rule' => m.targetId == rule.id,
        'section' => (m.section ?? m.targetId) == target.section.wire,
        'checklist' =>
          m.targetId == target.id && target.type == NotificationTargetType.checklist ||
              m.targetId == target.checklistId,
        'checklist_item' => m.targetId == target.id || target.ancestors.contains(m.targetId),
        _ => m.targetType == target.type.wire && m.targetId == target.id,
      };
      if (hit) return true;
    }
    return false;
  }

  // --------------------------------------------------------------------------------- build --

  static PlannedNotification _build(
    PlanningContext ctx,
    NotificationRule rule,
    NotificationTarget target,
    EffectiveDelivery delivery,
    ContentSpec? profileContent,
    _Candidate c,
    _Policed p, {
    required String dedupeKey,
    required String baseKey,
    required int repeatIdx,
    bool allDevices = false,
  }) {
    final zone = target.timeZone ?? ctx.deviceZone;
    final vars = _variables(ctx, target, zone, c, p.fireAt);
    final texts = ctx.texts;
    final content = rule.spec.content.isEmpty ? (profileContent ?? ContentSpec.empty) : rule.spec.content;
    var titleTpl = content.title;
    var bodyTpl = content.body;
    var variants = content.variants;
    if ((variants == null || variants.isEmpty) && content.pack != null) {
      // Curated pack: only variants whose variables this target has (T7.1.17).
      variants = [
        for (final v in texts.packVariants(content.pack!))
          if ({
            ...TemplateEngine.variablesIn(v.title ?? ''),
            ...TemplateEngine.variablesIn(v.body ?? ''),
          }.every((name) => vars[name]?.isNotEmpty ?? false))
            v,
      ];
    }
    if (variants != null && variants.isNotEmpty) {
      final v = variants[int.parse(dedupeKey.substring(0, 8), radix: 16) % variants.length];
      titleTpl = v.title ?? titleTpl;
      bodyTpl = v.body ?? bodyTpl;
    }
    final defaults = texts.defaultContent(c.kind, vars, count: c.count);
    final title = titleTpl == null
        ? TemplateEngine.truncate(defaults.title, TemplateEngine.titleMax)
        : TemplateEngine.render(titleTpl, vars, rtl: texts.isRtl, maxLength: TemplateEngine.titleMax);
    final body = bodyTpl == null
        ? (defaults.body == null ? null : TemplateEngine.truncate(defaults.body!, TemplateEngine.bodyMax))
        : TemplateEngine.render(bodyTpl, vars, rtl: texts.isRtl, maxLength: TemplateEngine.bodyMax);

    final trigger = rule.spec.trigger;
    final category = switch (trigger) {
      DigestTrigger() => InboxCategory.digest,
      MilestoneTrigger() => InboxCategory.milestone,
      StreakRiskTrigger() => InboxCategory.streak,
      _ => repeatIdx > 0 ? InboxCategory.nag : InboxCategory.reminder,
    };
    final channelId = channelIdFor(
      section: target.section,
      profileCode: delivery.profileCode,
      version: delivery.channelVersion,
      digest: category == InboxCategory.digest,
      quiet: p.quietSilent,
    );
    final guard = target.guard ?? NotificationGuard.always;
    final effectiveGuard = repeatIdx > 0 && delivery.repeat?.until != RepeatUntil.max
        ? NotificationGuard(guard.kind, {...guard.params, 'inboxNotActed': baseKey})
        : guard;
    return PlannedNotification(
      dedupeKey: dedupeKey,
      baseKey: baseKey,
      targetKey: target.targetKey,
      targetType: target.type,
      targetId: target.id,
      ruleId: rule.id,
      occurrenceKey: c.occurrenceKey,
      triggerType: trigger.typeWire,
      fireAt: p.fireAt,
      expiresAt: p.expiresAt,
      category: category,
      section: target.section,
      channelId: channelId,
      importance: delivery.importance,
      interruptionLevel: effectiveInterruptionLevel(
        p.quietSilent ? InterruptionLevel.passive : delivery.interruptionLevel,
        timeSensitiveAllowed: ctx.timeSensitiveAllowed,
      ),
      relevance: delivery.relevance,
      sound: p.silent ? 'none' : delivery.sound,
      vibration: p.silent ? 'none' : delivery.vibration,
      sticky: delivery.sticky,
      alarmStyle: delivery.alarmStyle,
      alarmOptions: delivery.alarm,
      actions: delivery.actions,
      snoozeOptions: delivery.snoozeOptionsMinutes,
      title: ctx.settings.hideContent ? texts.redactedTitle : title,
      body: ctx.settings.hideContent ? texts.redactedBody : body,
      // iOS subtitle / Android sub-text: where the item lives (T7.2.26), never when hidden.
      subtitle: ctx.settings.hideContent
          ? null
          : [vars['parent_path'], vars['category']].firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null),
      inboxTitle: title,
      inboxBody: body,
      threadId: repeatIdx > 0 || delivery.repeat != null ? 'nag:$baseKey' : 'sec:${target.section.wire}',
      deepLink: target.deepLink ?? defaultDeepLink(target),
      guard: effectiveGuard,
      deliverSystem: p.system,
      deliverInbox: delivery.inbox,
      deliverBanner: p.banner,
      scheduleLocally: p.scheduleLocally,
      repeatIdx: repeatIdx,
      userId: ctx.userId,
      adjustments: p.adjustments,
      anchorFireAt: p.anchorFireAt,
      silent: p.silent,
      targetDevices: allDevices ? null : rule.spec.conditions.devices,
      repeatable:
          c.repeatable &&
          repeatIdx == 0 &&
          delivery.repeat == null &&
          p.adjustments.isEmpty &&
          !p.silent &&
          !p.quietSilent &&
          p.system &&
          p.scheduleLocally &&
          !delivery.alarmStyle &&
          !delivery.sticky &&
          targetLevelGuards.contains(effectiveGuard.kind) &&
          (target.timeZone == null || target.timeZone == ctx.deviceZone),
    );
  }

  /// Guards that hold for every occurrence of a target alike — a repeating OS trigger can't
  /// skip one day, so per-occurrence guards (task occurrence, habit period) never repeat.
  static const targetLevelGuards = {'always', 'item_not_completed'};

  /// Unbounded daily or weekly rule at fixed times, without exceptions: the only shape an OS
  /// calendar trigger (`time` / `dayOfWeekAndTime`) reproduces exactly (T7.2.10).
  static bool isSimpleRepeating(Map<String, Object?> json) {
    final r = EngineRecurrenceExpander.parse(json)?.$1;
    if (r == null) return false;
    final plainWeekdays = r.byWeekday == null || r.byWeekday!.every((w) => w.n == null);
    return r.type == RuleType.fixed &&
        (r.freq == Frequency.daily || r.freq == Frequency.weekly) &&
        r.interval == 1 &&
        plainWeekdays &&
        r.times.isNotEmpty &&
        r.window == null &&
        r.until == null &&
        r.count == null &&
        r.exdates.isEmpty &&
        r.rdates.isEmpty &&
        r.byMonthDay.isEmpty &&
        r.byMonth.isEmpty &&
        r.byYearDay.isEmpty &&
        r.byWeekNo.isEmpty &&
        r.bySetPos.isEmpty &&
        r.byHour.isEmpty &&
        r.byMinute.isEmpty &&
        r.afterCompletion == null &&
        r.quota == null;
  }

  static Map<String, String> _variables(
    PlanningContext ctx,
    NotificationTarget target,
    String zone,
    _Candidate c,
    DateTime fireAt,
  ) {
    final texts = ctx.texts;
    final zones = ctx.zones;
    String fmtTime(DateTime instant) => texts.time(zones.toLocal(instant, zone));
    final vars = <String, String>{'title': target.title};
    final dayInstant = target.start ?? target.due ?? target.slot ?? target.periodStart ?? c.anchor ?? fireAt;
    final day = zones.toLocal(dayInstant, zone).date;
    vars['date'] = texts.date(day);
    vars['weekday'] = texts.weekday(day);
    if (target.start != null && target.itemKind == ItemKind.timed) {
      vars['start_time'] = fmtTime(target.start!);
    }
    if (target.end != null && target.itemKind == ItemKind.timed) {
      vars['end_time'] = fmtTime(target.end!);
    }
    if (target.start != null && target.end != null) {
      vars['duration'] = texts.duration(target.end!.difference(target.start!).inMinutes);
    }
    if (c.anchor != null) {
      final minutes = c.anchor!.difference(fireAt).inMinutes;
      vars['minutes_until'] = texts.number(minutes < 0 ? 0 : minutes);
    }
    if (target.due != null) {
      vars['due_relative'] = texts.relative(target.due!.difference(fireAt).inMinutes);
    }
    if (target.status != null) {
      vars['status'] = texts.status(target.status!);
      vars['status_wire'] = target.status!;
    }
    if (target.statusChangedAt != null) {
      vars['status_age'] = texts.duration(fireAt.difference(target.statusChangedAt!).inMinutes.abs());
    }
    if (target.streak != null) vars['streak'] = texts.number(target.streak!);
    for (final e in target.variables.entries) {
      final v = e.value;
      vars[e.key] = switch (v) {
        null => '',
        String() => v,
        num() => texts.number(v),
        DateTime() => fmtTime(v),
        _ => v.toString(),
      };
    }
    vars.addAll(c.extraVars);
    return vars;
  }

  /// Android channel id: `dl.<section>.<profile>.v<n>` + special channels (T7.2.02).
  static String channelIdFor({
    required NotificationSection section,
    required String profileCode,
    required int version,
    bool digest = false,
    bool quiet = false,
  }) {
    if (quiet) return 'dl.quiet.v1';
    if (digest) return 'dl.digest.v1';
    if (section == NotificationSection.system) return 'dl.system.v1';
    return 'dl.${section.wire}.$profileCode.v$version';
  }

  /// Router path opened when a notification of [target] is tapped.
  static String defaultDeepLink(NotificationTarget target) => switch (target.type) {
    NotificationTargetType.task => AppLinks.task(target.id, occurrenceKey: target.occurrenceKey),
    NotificationTargetType.checklist => AppLinks.checklist(target.id),
    NotificationTargetType.checklistItem =>
      target.checklistId == null ? AppLinks.lists() : AppLinks.checklist(target.checklistId!, itemId: target.id),
    NotificationTargetType.habit =>
      target.section == NotificationSection.quit ? AppLinks.quit(target.id) : AppLinks.habit(target.id),
    NotificationTargetType.digest => switch (target.id) {
      'weekly_review' || 'monthly_report' => AppLinks.insights(),
      'plan_tomorrow' => AppLinks.planDay(),
      _ => AppLinks.today(),
    },
    NotificationTargetType.custom => AppLinks.inbox(),
  };

  // ----------------------------------------------------------------------------------- caps --

  static List<PlannedNotification> _applyCaps(
    PlanningContext ctx,
    List<PlannedNotification> sorted,
    List<SkippedFiring> skipped,
  ) {
    final perDay = <String, int>{};
    final perTargetDay = <String, int>{};
    final out = <PlannedNotification>[];
    for (final p in sorted) {
      final day = ctx.zones.toLocal(p.fireAt, ctx.deviceZone).date.toIso();
      final dayCount = perDay[day] ?? 0;
      final targetDayKey = '${p.targetKey}|$day';
      final targetCount = perTargetDay[targetDayKey] ?? 0;
      if (dayCount >= ctx.settings.dailyCap || targetCount >= ctx.settings.perTargetDailyCap) {
        skipped.add(
          SkippedFiring(
            ruleId: p.ruleId,
            targetKey: p.targetKey,
            occurrenceKey: p.occurrenceKey,
            fireAt: p.fireAt,
            reason: SkipReason.cap,
          ),
        );
        continue;
      }
      perDay[day] = dayCount + 1;
      perTargetDay[targetDayKey] = targetCount + 1;
      out.add(p);
    }
    return out;
  }
}

class _Policed {
  _Policed({
    required this.fireAt,
    required this.expiresAt,
    required this.system,
    required this.banner,
    required this.silent,
    required this.quietSilent,
    required this.scheduleLocally,
    required this.adjustments,
    required this.anchorFireAt,
  });

  final DateTime fireAt;
  final DateTime expiresAt;
  final bool system;
  final bool banner;
  final bool silent;
  final bool quietSilent;
  final bool scheduleLocally;
  final Set<PlanAdjustment> adjustments;
  final DateTime? anchorFireAt;
}
