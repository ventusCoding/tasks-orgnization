/// Insights feed (T6.7.08): short, data-backed, non-judgmental sentences with "Why am I seeing
/// this?" (rule, numbers, the supporting metric), dismiss and mute. Each insight opens the entity
/// or metric that supports it.
library;

import 'dart:async';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/application/insights_feed.dart';
import 'package:everslot/features/stats/application/stats_providers.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/charts/chart_support.dart';
import 'package:everslot/features/stats/presentation/format/stat_format.dart';
import 'package:everslot/features/stats/presentation/l10n/stats_l10n.dart';
import 'package:everslot/features/stats/presentation/stats_navigation.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show InsightTrigger;
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate, Weekday;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Localized sentence of an insight.
String insightText(AppLocalizations l, StatFormat f, FeedInsight i) {
  final a = i.args;
  String name() => '${a['name'] ?? ''}';
  num n(String k) => a[k] is num ? a[k]! as num : 0;
  String pct(double ratio) => f.percent(ratio, decimals: 0);
  switch (i.trigger) {
    case InsightTrigger.newRecord:
      final type = RecordTypeName.of(a['type'] as String?);
      final record = [
        if (type != null) labelTokenText(l, type.$1),
        if (a['name'] case final String nm when nm.isNotEmpty) nm,
      ].join(' · ');
      final unit = type?.$2 ?? StatUnit.count;
      final value = f.value(n('value').toDouble(), unit);
      return a['previous'] is num
          ? l.statsInsightNewRecord(record, value, f.value((a['previous']! as num).toDouble(), unit))
          : l.statsInsightNewRecordFirst(record, value);
    case InsightTrigger.streakMilestone:
      return l.statsInsightStreak(name(), n('streak').toInt());
    case InsightTrigger.significantTrend:
      final pp = n('ppPerWeek').toDouble();
      final text = f.number(pp.abs(), decimals: 1);
      return pp >= 0 ? l.statsInsightTrendUp(name(), text) : l.statsInsightTrendDown(name(), text);
    case InsightTrigger.estimationBias:
      return l.statsInsightEstimationBias(pct(n('bias').toDouble()));
    case InsightTrigger.risingOverdue:
      return l.statsInsightRisingOverdue(n('count').toInt(), n('previous').toInt());
    case InsightTrigger.overbookedNextWeek:
      final days = [
        for (final d in (a['days'] as List?) ?? const [])
          if (LocalDate.tryParse('$d') case final date?) f.dayShort(date),
      ];
      return l.statsInsightOverbooked(days.join(', '));
    case InsightTrigger.blockerCluster:
      return l.statsInsightBlockerCluster(n('count').toInt(), i.entityId);
    case InsightTrigger.followUpsDue:
      return l.statsInsightFollowUps(n('count').toInt());
    case InsightTrigger.staleList:
      return l.statsInsightStaleList(name(), n('days').toInt());
    case InsightTrigger.fallingCravings:
      return l.statsInsightFallingCravings(pct(n('change').toDouble().abs()));
    case InsightTrigger.healthMilestone:
      final id = '${a['milestone'] ?? ''}';
      return l.statsInsightHealth(milestoneText(l, id) ?? id);
    case InsightTrigger.moneyMilestone:
      return l.statsInsightMoney(f.currency(n('amount').toDouble(), a['currency'] as String?), name());
    case InsightTrigger.perfectWeek:
      return l.statsInsightPerfectWeek;
    case InsightTrigger.bestWeekday:
      final code = a['weekday'];
      final day = code is String ? Weekday.values.where((w) => w.code == code).firstOrNull : null;
      return l.statsInsightBestWeekday(day == null ? '' : f.weekdayLong(day), pct(n('rate').toDouble()));
    case InsightTrigger.habitAtRisk:
      return l.statsInsightAtRisk(name());
    case InsightTrigger.strengthThreshold:
      return l.statsInsightStrength(name(), pct(n('threshold').toDouble()));
    case InsightTrigger.comeback:
      return l.statsInsightComeback(name());
    case InsightTrigger.correlation:
      String series(String key) {
        final raw = '${a[key] ?? ''}';
        final token = LabelToken.values.where((t) => t.name == raw).firstOrNull;
        return token == null ? raw : labelTokenText(l, token);
      }
      return n('coefficient') >= 0
          ? l.statsInsightCorrelationPos(series('aName'), series('bName'))
          : l.statsInsightCorrelationNeg(series('aName'), series('bName'));
  }
}

/// Record type token and unit by name (GL-06 `RecordType`).
abstract final class RecordTypeName {
  static (LabelToken, StatUnit)? of(String? name) => switch (name) {
    'habitStreak' => (LabelToken.recordHabitStreak, StatUnit.days),
    'tasksDay' => (LabelToken.recordTasksDay, StatUnit.count),
    'actualWeek' => (LabelToken.recordActualWeek, StatUnit.hours),
    'deepWorkWeek' => (LabelToken.recordDeepWorkWeek, StatUnit.hours),
    'habitMaxDay' => (LabelToken.recordHabitMaxDay, StatUnit.count),
    'habitVolumeWeek' => (LabelToken.recordHabitVolumeWeek, StatUnit.count),
    'abstinence' => (LabelToken.recordAbstinence, StatUnit.days),
    'itemsWeek' => (LabelToken.recordItemsWeek, StatUnit.count),
    'perfectStreak' => (LabelToken.recordPerfectStreak, StatUnit.days),
    'completionWeek' => (LabelToken.recordCompletionWeek, StatUnit.percent),
    'moneyMonth' => (LabelToken.recordMoneyMonth, StatUnit.currency),
    _ => null,
  };
}

String insightName(AppLocalizations l, InsightTrigger t) => switch (t) {
  InsightTrigger.newRecord => l.statsInsightNameNewRecord,
  InsightTrigger.streakMilestone => l.statsInsightNameStreakMilestone,
  InsightTrigger.significantTrend => l.statsInsightNameSignificantTrend,
  InsightTrigger.estimationBias => l.statsInsightNameEstimationBias,
  InsightTrigger.risingOverdue => l.statsInsightNameRisingOverdue,
  InsightTrigger.overbookedNextWeek => l.statsInsightNameOverbookedNextWeek,
  InsightTrigger.blockerCluster => l.statsInsightNameBlockerCluster,
  InsightTrigger.followUpsDue => l.statsInsightNameFollowUpsDue,
  InsightTrigger.staleList => l.statsInsightNameStaleList,
  InsightTrigger.fallingCravings => l.statsInsightNameFallingCravings,
  InsightTrigger.healthMilestone => l.statsInsightNameHealthMilestone,
  InsightTrigger.moneyMilestone => l.statsInsightNameMoneyMilestone,
  InsightTrigger.perfectWeek => l.statsInsightNamePerfectWeek,
  InsightTrigger.bestWeekday => l.statsInsightNameBestWeekday,
  InsightTrigger.habitAtRisk => l.statsInsightNameHabitAtRisk,
  InsightTrigger.strengthThreshold => l.statsInsightNameStrengthThreshold,
  InsightTrigger.comeback => l.statsInsightNameComeback,
  InsightTrigger.correlation => l.statsInsightNameCorrelation,
};

String insightRule(AppLocalizations l, InsightTrigger t) => switch (t) {
  InsightTrigger.newRecord => l.statsInsightRuleNewRecord,
  InsightTrigger.streakMilestone => l.statsInsightRuleStreakMilestone,
  InsightTrigger.significantTrend => l.statsInsightRuleSignificantTrend,
  InsightTrigger.estimationBias => l.statsInsightRuleEstimationBias,
  InsightTrigger.risingOverdue => l.statsInsightRuleRisingOverdue,
  InsightTrigger.overbookedNextWeek => l.statsInsightRuleOverbookedNextWeek,
  InsightTrigger.blockerCluster => l.statsInsightRuleBlockerCluster,
  InsightTrigger.followUpsDue => l.statsInsightRuleFollowUpsDue,
  InsightTrigger.staleList => l.statsInsightRuleStaleList,
  InsightTrigger.fallingCravings => l.statsInsightRuleFallingCravings,
  InsightTrigger.healthMilestone => l.statsInsightRuleHealthMilestone,
  InsightTrigger.moneyMilestone => l.statsInsightRuleMoneyMilestone,
  InsightTrigger.perfectWeek => l.statsInsightRulePerfectWeek,
  InsightTrigger.bestWeekday => l.statsInsightRuleBestWeekday,
  InsightTrigger.habitAtRisk => l.statsInsightRuleHabitAtRisk,
  InsightTrigger.strengthThreshold => l.statsInsightRuleStrengthThreshold,
  InsightTrigger.comeback => l.statsInsightRuleComeback,
  InsightTrigger.correlation => l.statsInsightRuleCorrelation,
};

IconData _icon(InsightTrigger t) => switch (t) {
  InsightTrigger.newRecord => Icons.emoji_events_outlined,
  InsightTrigger.streakMilestone => Icons.local_fire_department_outlined,
  InsightTrigger.significantTrend => Icons.trending_up,
  InsightTrigger.estimationBias => Icons.timelapse,
  InsightTrigger.risingOverdue => Icons.event_busy_outlined,
  InsightTrigger.overbookedNextWeek => Icons.event_available_outlined,
  InsightTrigger.blockerCluster => Icons.block,
  InsightTrigger.followUpsDue => Icons.reply_outlined,
  InsightTrigger.staleList => Icons.hourglass_bottom,
  InsightTrigger.fallingCravings => Icons.trending_down,
  InsightTrigger.healthMilestone => Icons.favorite_outline,
  InsightTrigger.moneyMilestone => Icons.savings_outlined,
  InsightTrigger.perfectWeek => Icons.star_outline,
  InsightTrigger.bestWeekday => Icons.calendar_today_outlined,
  InsightTrigger.habitAtRisk => Icons.warning_amber_rounded,
  InsightTrigger.strengthThreshold => Icons.fitness_center,
  InsightTrigger.comeback => Icons.waving_hand_outlined,
  InsightTrigger.correlation => Icons.scatter_plot_outlined,
};

/// Insights route of a supporting metric id.
String? insightsRouteOf(String metricId) => switch (metricId) {
  'GL-06' => 'records',
  'GL-08' || 'GL-13' => 'correlations',
  _ when metricId.startsWith('PL-') => 'planner',
  _ when metricId.startsWith('CL-') => 'checklists',
  _ when metricId.startsWith('HB-') => 'habits',
  _ when metricId.startsWith('QT-') => 'quit',
  _ => 'global',
};

void openInsight(BuildContext context, FeedInsight i) {
  if (i.ref case final ref?) {
    if (drillPath(ref) != null) return openDrillRef(context, ref);
  }
  openInsights(context, insightsRouteOf(i.metricId ?? '') ?? 'global');
}

/// The full feed (route `/insights/feed`).
class InsightsFeedView extends ConsumerWidget {
  const InsightsFeedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    ref.watch(insightsGenerationProvider);
    final feed = ref.watch(insightsFeedProvider);
    final muted = ref.watch(statsSettingsProvider.select((s) => s.mutedInsights));
    return AsyncValueView<List<FeedInsight>>(
      value: feed,
      data: (list) => ListView(
        padding: const EdgeInsetsDirectional.all(Space.lg),
        children: [
          if (list.isEmpty)
            EmptyState(icon: Icons.lightbulb_outline, title: l.statsFeedEmpty, message: l.statsFeedEmptyBody)
          else
            for (final i in list)
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: Space.sm),
                child: InsightCard(insight: i),
              ),
          if (muted.isNotEmpty) ...[
            const SizedBox(height: Space.lg),
            Semantics(header: true, child: Text(l.statsFeedMutedTypes, style: context.text.titleSmall)),
            for (final t in InsightTrigger.values)
              if (muted.contains(t.name))
                ListTile(
                  contentPadding: EdgeInsetsDirectional.zero,
                  leading: Icon(_icon(t)),
                  title: Text(insightName(l, t)),
                  trailing: TextButton(
                    onPressed: () => unawaited(ref.read(insightsFeedServiceProvider).setMuted(t, muted: false)),
                    child: Text(l.statsFeedUnmute),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

/// The latest insights on the Overview (up to [max]) with a link to the full feed.
class InsightsFeedPreview extends ConsumerWidget {
  const InsightsFeedPreview({super.key, this.max = 3});

  final int max;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(insightsGenerationProvider);
    final list = ref.watch(insightsFeedProvider).value ?? const <FeedInsight>[];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final i in list.take(max))
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: Space.xs),
            child: InsightCard(insight: i, compact: true),
          ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(onPressed: () => openInsights(context, 'feed'), child: Text(context.l10n.statsFeedSeeAll)),
        ),
      ],
    );
  }
}

class InsightCard extends ConsumerWidget {
  const InsightCard({required this.insight, super.key, this.compact = false});

  final FeedInsight insight;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = statFormatOf(context);
    final text = insightText(l, f, insight);
    final service = ref.read(insightsFeedServiceProvider);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: () => openInsight(context, insight),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.md, Space.sm, Space.xs, Space.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(top: Space.xs),
                child: Icon(_icon(insight.trigger), color: context.colors.primary),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text, style: context.text.bodyMedium),
                    if (!compact)
                      Text(
                        f.dateTime(insight.firedAt),
                        style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: l.actionMore,
                onSelected: (v) async {
                  switch (v) {
                    case 'why':
                      await showInsightWhySheet(context, insight);
                    case 'dismiss':
                      await service.dismiss(insight.key);
                    case 'mute':
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      await service.setMuted(insight.trigger, muted: true);
                      messenger?.showSnackBar(SnackBar(content: Text(l.statsFeedMutedSnack)));
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'why', child: Text(l.statsFeedWhy)),
                  PopupMenuItem(value: 'dismiss', child: Text(l.statsFeedDismiss)),
                  PopupMenuItem(value: 'mute', child: Text(l.statsFeedMute)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Why am I seeing this?": the rule, the numbers and the supporting metric.
Future<void> showInsightWhySheet(BuildContext context, FeedInsight i) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) {
    final l = context.l10n;
    final f = statFormatOf(context);
    final numbers = [
      for (final e in i.args.entries)
        if (e.value is num && e.key != 'n') '${e.key}: ${f.number((e.value! as num).toDouble(), decimals: 2)}',
      if (i.args['n'] is num) 'n = ${i.args['n']}',
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.statsFeedWhy, style: context.text.titleMedium),
            const SizedBox(height: Space.sm),
            Text(insightText(l, f, i), style: context.text.bodyLarge),
            const SizedBox(height: Space.md),
            Text(insightName(l, i.trigger), style: context.text.titleSmall),
            Text(insightRule(l, i.trigger), style: context.text.bodyMedium),
            if (numbers.isNotEmpty) ...[
              const SizedBox(height: Space.sm),
              Text(numbers.join(' · '), style: context.text.bodySmall?.copyWith(fontFeatures: AppTheme.tabular)),
            ],
            if (i.metricId case final id?) ...[
              const SizedBox(height: Space.sm),
              Text(l.statsFeedBasedOn(metricTitle(l, id) ?? id), style: context.text.bodySmall),
            ],
            const SizedBox(height: Space.md),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.tonal(
                onPressed: () {
                  Navigator.of(context).pop();
                  openInsight(context, i);
                },
                child: Text(l.statsFeedOpen),
              ),
            ),
          ],
        ),
      ),
    );
  },
);
