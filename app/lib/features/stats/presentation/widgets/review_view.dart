/// Weekly review report (T6.7.02): headline KPIs with Δ, wins, attention items (each opens its
/// entity), where the time went and next week's load vs capacity; last week or this week so far.
library;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/charts/chart_support.dart';
import 'package:everslot/features/stats/presentation/charts/simple_views.dart';
import 'package:everslot/features/stats/presentation/format/stat_format.dart';
import 'package:everslot/features/stats/presentation/l10n/stats_l10n.dart';
import 'package:everslot/features/stats/presentation/stats_navigation.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

class ReviewView extends StatelessWidget {
  const ReviewView({required this.data, super.key, this.current = false, this.onToggle});

  final ReviewData data;
  final bool current;
  final ValueChanged<bool>? onToggle;

  static String entryText(AppLocalizations l, StatFormat f, ReviewEntry e) {
    final title = e.title ?? '';
    return switch (e.kind) {
      ReviewEntryKind.streakMilestone => l.statsReviewStreak(title, '${e.value?.round() ?? 0}'),
      ReviewEntryKind.perfectDays => l.statsReviewPerfectDays((e.value ?? 0).round()),
      ReviewEntryKind.healthMilestone =>
        l.statsReviewHealth(milestoneText(l, title.isEmpty ? title : title[0].toLowerCase() + title.substring(1)) ?? title),
      ReviewEntryKind.newRecord => l.statsReviewRecord(title),
      ReviewEntryKind.overdueTasks => l.statsReviewOverdue(title),
      ReviewEntryKind.blockedWaiting => l.statsReviewBlocked(title),
      ReviewEntryKind.staleLists => l.statsReviewStale(title),
      ReviewEntryKind.overdueFollowUps => l.statsReviewFollowUp(title),
      ReviewEntryKind.habitsAtRisk => l.statsReviewAtRisk(title),
      ReviewEntryKind.overbookedDay => l.statsReviewOverbooked(
        e.date == null ? '' : f.dayShort(e.date!),
        f.duration(e.value ?? 0),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = statFormatOf(context);
    Widget header(String text) => Padding(
      padding: const EdgeInsetsDirectional.only(top: Space.lg, bottom: Space.xs),
      child: Semantics(header: true, child: Text(text, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
    );
    Widget entries(List<ReviewEntry> list) => list.isEmpty
        ? Text(l.statsReviewNothing, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant))
        : Column(
            children: [
              for (final e in list)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsetsDirectional.zero,
                  leading: Icon(_icon(e.kind), size: 20),
                  title: Text(entryText(l, f, e)),
                  trailing: e.ref == null ? null : const Icon(Icons.chevron_right),
                  onTap: e.ref == null ? null : () => openDrillRef(context, e.ref!),
                ),
            ],
          );
    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.statsReviewRange(f.date(data.from), f.date(data.to)),
                    style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (onToggle != null) ...[
              const SizedBox(height: Space.sm),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(l.statsReviewLastWeek)),
                  ButtonSegment(value: true, label: Text(l.statsReviewThisWeek)),
                ],
                selected: {current},
                onSelectionChanged: (s) => onToggle!(s.first),
              ),
            ],
            header(l.statsReviewHeadline),
            if (data.headline.isEmpty) Text(l.statsReviewNothing) else ValueTilesView(TilesData(data.headline)),
            header(labelTokenText(l, LabelToken.wins)),
            entries(data.wins),
            header(labelTokenText(l, LabelToken.attention)),
            entries(data.attention),
            if (data.topCategories.isNotEmpty) ...[
              header(l.statsReviewTime),
              for (final (label, minutes, delta) in data.topCategories)
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: Space.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(f.label(label))),
                      const SizedBox(width: Space.sm),
                      // Values wrap under each other at large text scales.
                      Flexible(
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: Space.sm,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(f.duration(minutes), style: context.text.labelLarge),
                            Text(
                              delta == null ? l.chartsDeltaNew : '${delta >= 0 ? '+' : '−'}${f.duration(delta.abs())}',
                              style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (data.nextWeek.isNotEmpty) ...[
              header(l.statsReviewNextWeek),
              for (final (date, planned, capacity, overbooked) in data.nextWeek)
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: Space.sm),
                  // Label line + full-width bar: never overflows, even at large text scales.
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(f.dayShort(date), style: context.text.labelMedium)),
                          Flexible(
                            child: Text(
                              l.statsReviewLoad(f.value(planned, StatUnit.minutes), f.value(capacity, StatUnit.minutes)),
                              style: context.text.labelSmall,
                              textAlign: TextAlign.end,
                            ),
                          ),
                          if (overbooked) ...[
                            const SizedBox(width: Space.xs),
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: context.appColors.warning,
                              semanticLabel: labelTokenText(l, LabelToken.over),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: Space.xxs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(Radii.pill),
                        child: LinearProgressIndicator(
                          value: capacity <= 0 ? 0 : (planned / capacity).clamp(0, 1),
                          minHeight: 8,
                          color: overbooked ? context.appColors.warning : context.colors.primary,
                          backgroundColor: context.colors.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  static IconData _icon(ReviewEntryKind kind) => switch (kind) {
    ReviewEntryKind.streakMilestone => Icons.local_fire_department_outlined,
    ReviewEntryKind.perfectDays => Icons.star_outline,
    ReviewEntryKind.healthMilestone => Icons.favorite_outline,
    ReviewEntryKind.newRecord => Icons.emoji_events_outlined,
    ReviewEntryKind.overdueTasks => Icons.event_busy_outlined,
    ReviewEntryKind.blockedWaiting => Icons.block,
    ReviewEntryKind.staleLists => Icons.hourglass_bottom,
    ReviewEntryKind.overdueFollowUps => Icons.reply_outlined,
    ReviewEntryKind.habitsAtRisk => Icons.warning_amber_rounded,
    ReviewEntryKind.overbookedDay => Icons.event_available_outlined,
  };
}
