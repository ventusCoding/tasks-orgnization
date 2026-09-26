import 'package:everslot/core/providers.dart';
import 'package:everslot/features/notifications/application/notification_pipeline.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart';
import 'package:everslot/features/notifications/domain/effective_rules_resolver.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/planner/notification_planner.dart';
import 'package:everslot/features/notifications/domain/rule_validation.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// One row of the "next firings" preview (T7.1.11): planned or skipped with a reason.
@immutable
class PreviewEntry {
  const PreviewEntry({
    required this.fireAt,
    required this.ruleId,
    this.planned,
    this.skipReason,
  });

  final DateTime fireAt;
  final String ruleId;
  final PlannedNotification? planned;
  final SkipReason? skipReason;

  bool get skipped => skipReason != null;
}

final rulePreviewServiceProvider = Provider<RulePreviewService>(
  (ref) => RulePreviewService(ref.read),
);

/// Preview, noise estimate and test notifications share the planner code path with real
/// scheduling (T7.1.04 / T7.1.11).
class RulePreviewService {
  RulePreviewService(this.read);

  final ProviderReader read;

  NotificationPipeline get _pipeline => read(notificationPipelineProvider);

  /// Targets of one item from the registered sources (all occurrences in the horizon).
  Future<List<NotificationTarget>> targetsOf(
    NotificationTargetType type,
    String id,
  ) async {
    final now = read(clockProvider).nowUtc();
    final out = <NotificationTarget>[];
    for (final source in read(notificationTargetSourcesProvider)) {
      try {
        for (final t in await source.targetsBetween(
          now.subtract(const Duration(days: 1)),
          now.add(const Duration(days: 45)),
        )) {
          if (t.type == type && t.id == id) out.add(t);
        }
      } on Object {
        // ignore failing sources in previews
      }
    }
    return out;
  }

  /// A representative target when the item has no data yet (new drafts, section defaults).
  NotificationTarget sampleTarget(
    NotificationTargetType type,
    NotificationSection section, {
    ItemKind kind = ItemKind.timed,
    String id = 'preview',
  }) {
    final now = read(clockProvider).nowUtc();
    final zone = read(deviceZoneProvider);
    final zones = read(zoneResolverProvider);
    final tomorrow = zones.toLocal(now, zone).date.plusDays(1);
    DateTime at(int hour) =>
        zones.resolve(LocalDateTime(tomorrow, LocalTime(hour, 0)), zone).utc;
    final dayStart = zones.resolve(tomorrow.atStartOfDay, zone).utc;
    final dayEnd = zones.resolve(tomorrow.plusDays(1).atStartOfDay, zone).utc;
    return NotificationTarget(
      type: type,
      id: id,
      section: section,
      title: '…',
      occurrenceKey: kind == ItemKind.timed
          ? LocalDateTime(tomorrow, LocalTime(9, 0)).toIso()
          : tomorrow.toIso(),
      itemKind: kind,
      start: kind == ItemKind.timed ? at(9) : dayStart,
      end: kind == ItemKind.timed ? at(10) : dayEnd,
      due: at(9),
      followUp: at(9),
      slot: at(9),
      periodStart: dayStart,
      periodEnd: dayEnd,
      status: 'scheduled',
      streak: 7,
      milestoneBaseline: now,
      notifyMode: NotifyMode.custom,
    );
  }

  /// Next [limit] firings of [rules] for [targets] (planned + skipped with reasons).
  Future<List<PreviewEntry>> nextFirings(
    List<NotificationRule> rules,
    List<NotificationTarget> targets, {
    int limit = 5,
  }) async {
    if (rules.isEmpty || targets.isEmpty) return const [];
    final ctx = await _pipeline.buildContext(
      targetsOverride: targets,
      applyCaps: false,
    );
    final out = <PreviewEntry>[];
    for (final t in targets) {
      final resolved = t.notifyMode == NotifyMode.custom || t.id == 'preview'
          ? rules
          : [
              for (final e in EffectiveRulesResolver(
                RuleIndex(rules),
                ctx.settings,
              ).forTarget(t))
                e.rule,
            ];
      for (final rule in resolved) {
        final result = NotificationPlanner.planRule(ctx, rule, t);
        for (final p in result.planned) {
          if (p.fireAt.isBefore(ctx.now)) continue;
          out.add(PreviewEntry(fireAt: p.fireAt, ruleId: rule.id, planned: p));
        }
        for (final s in result.skipped) {
          if (s.fireAt.isBefore(ctx.now) || s.reason == SkipReason.expired)
            continue;
          out.add(
            PreviewEntry(
              fireAt: s.fireAt,
              ruleId: rule.id,
              skipReason: s.reason,
            ),
          );
        }
      }
    }
    out.sort((a, b) => a.fireAt.compareTo(b.fireAt));
    final seen = <String>{};
    return [
      for (final e in out)
        if (seen.add(
          '${e.ruleId}|${e.fireAt.toIso8601String()}|${e.planned?.repeatIdx ?? -1}',
        ))
          e,
    ].take(limit).toList();
  }

  /// Fires per day over the next 7 days (+ same-minute clusters with the current plan).
  Future<NoiseEstimate> noise(
    NotificationRule rule,
    NotificationTarget target,
  ) async {
    final ctx = await _pipeline.buildContext(
      targetsOverride: [target],
      applyCaps: false,
    );
    final week = PlanningContext(
      now: ctx.now,
      deviceZone: ctx.deviceZone,
      zones: ctx.zones,
      settings: ctx.settings,
      rules: ctx.rules,
      targets: ctx.targets,
      profiles: ctx.profiles,
      mutes: const [],
      texts: ctx.texts,
      horizon: const Duration(days: 7),
      applyCaps: false,
    );
    final result = NotificationPlanner.planRule(week, rule, target);
    final others = [
      for (final p
          in _pipeline.lastPlan?.planned ?? const <PlannedNotification>[])
        p.fireAt,
    ];
    return NoiseEstimate.fromPlan(
      result,
      const Duration(days: 7),
      others: others,
    );
  }

  /// "Send test now": a real local notification in 5 s with the rule's delivery and content.
  Future<void> sendTest(
    NotificationRule rule,
    NotificationTarget target,
  ) async {
    final ctx = await _pipeline.buildContext(
      targetsOverride: [target],
      applyCaps: false,
    );
    final first = NotificationPlanner.planRule(
      ctx,
      rule,
      target,
    ).planned.firstOrNull;
    final l = read(notificationTextsProvider).l10n;
    await read(localSchedulerProvider).showTest(
      title: first?.title ?? l.notifBodyTest,
      body: first?.body ?? l.notifBodyTest,
      channelId: first?.channelId ?? 'dl.system.v1',
      actions: first?.actions ?? const [],
      sound: first?.sound ?? 'default',
      importance: first?.importance ?? NotificationImportance.normal,
      interruptionLevel: first?.interruptionLevel ?? InterruptionLevel.active,
    );
  }
}
