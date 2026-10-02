/// Guided weekly review (T6.7.03): six steps over last week's report — wins, overdue tasks,
/// waiting / blocked items, stale lists, habits at risk and next week's overbooked days. Each
/// action is a normal entity change with an Undo snackbar; the current step survives an app kill;
/// "Finish" records the completed review (GL-04 streak).
library;

import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/board.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/stats/application/guided_review.dart';
import 'package:everslot/features/stats/application/stats_compute_service.dart';
import 'package:everslot/features/stats/application/stats_providers.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/charts/chart_support.dart';
import 'package:everslot/features/stats/presentation/stats_navigation.dart';
import 'package:everslot/features/stats/presentation/widgets/review_view.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show StatsPeriod;
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

const _reviewRequest = StatsRequest(
  MetricScope.global,
  selection: PeriodSelection(StatsPeriod.thisWeek(), compare: false),
  metricIds: {'GL-03'},
);

const _atRiskRequest = StatsRequest(
  MetricScope.habits,
  selection: PeriodSelection(StatsPeriod.thisWeek(), compare: false),
  metricIds: {'HB-X-07'},
);

class GuidedReviewScreen extends ConsumerStatefulWidget {
  const GuidedReviewScreen({super.key});

  @override
  ConsumerState<GuidedReviewScreen> createState() => _GuidedReviewScreenState();
}

class _GuidedReviewScreenState extends ConsumerState<GuidedReviewScreen> {
  int? _step;
  bool _finishing = false;

  static const _steps = GuidedReviewStep.values;

  LocalDate? _week(StatsBatch? batch) => LocalDate.tryParse('${batch?['GL-03']?.args['week'] ?? ''}');

  Future<void> _restore(LocalDate week) async {
    final saved = await ref.read(guidedReviewServiceProvider).savedStep(week);
    if (!mounted) return;
    setState(() => _step = (saved ?? 0).clamp(0, _steps.length - 1));
  }

  void _go(LocalDate week, int step) {
    setState(() => _step = step);
    unawaited(ref.read(guidedReviewServiceProvider).saveStep(week, step));
  }

  Future<void> _finish(LocalDate week) async {
    setState(() => _finishing = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final text = context.l10n.statsGuidedCompleted;
    await ref.read(guidedReviewServiceProvider).complete(week);
    messenger?.showSnackBar(SnackBar(content: Text(text)));
    if (mounted) await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final batch = ref.watch(metricsBatchProvider(_reviewRequest));
    final week = _week(batch.value);
    if (week != null && _step == null) unawaited(_restore(week));
    final step = _step;
    if (week == null || step == null) {
      return batch.hasError
          ? ErrorState(error: batch.error, onRetry: () => ref.invalidate(metricsBatchProvider(_reviewRequest)))
          : const Center(child: CircularProgressIndicator());
    }
    final review = batch.value?['GL-03']?.chart;
    final current = _steps[step];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.md, Space.lg, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.statsGuidedStepOf(step + 1, _steps.length),
                style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: Space.xs),
              LinearProgressIndicator(value: (step + 1) / _steps.length, minHeight: 4),
              const SizedBox(height: Space.sm),
              Semantics(header: true, child: Text(_title(l, current), style: context.text.titleLarge)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.all(Space.lg),
            children: switch (current) {
              GuidedReviewStep.wins => _wins(review is ReviewData ? review : null),
              GuidedReviewStep.overdue => [const _OverdueStep()],
              GuidedReviewStep.waiting => [const _WaitingStep()],
              GuidedReviewStep.stale => _stale(review is ReviewData ? review : null),
              GuidedReviewStep.habits => [const _HabitsStep()],
              GuidedReviewStep.rebalance => _rebalance(review is ReviewData ? review : null),
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, Space.md),
            child: Row(
              children: [
                if (step > 0) TextButton(onPressed: () => _go(week, step - 1), child: Text(l.statsGuidedBack)),
                const Spacer(),
                if (step < _steps.length - 1)
                  FilledButton(onPressed: () => _go(week, step + 1), child: Text(l.statsGuidedNext))
                else
                  FilledButton.icon(
                    key: const ValueKey('guided-finish'),
                    onPressed: _finishing ? null : () => unawaited(_finish(week)),
                    icon: const Icon(Icons.check),
                    label: Text(l.statsGuidedFinish),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _title(AppLocalizations l, GuidedReviewStep s) => switch (s) {
    GuidedReviewStep.wins => l.statsGuidedStepWins,
    GuidedReviewStep.overdue => l.statsGuidedStepOverdue,
    GuidedReviewStep.waiting => l.statsGuidedStepWaiting,
    GuidedReviewStep.stale => l.statsGuidedStepStale,
    GuidedReviewStep.habits => l.statsGuidedStepHabits,
    GuidedReviewStep.rebalance => l.statsGuidedStepRebalance,
  };

  List<Widget> _wins(ReviewData? r) {
    final l = context.l10n;
    final f = statFormatOf(context);
    final wins = r?.wins ?? const <ReviewEntry>[];
    if (wins.isEmpty) return [_Nothing(text: l.statsReviewNothing)];
    return [
      for (final w in wins)
        ListTile(
          contentPadding: EdgeInsetsDirectional.zero,
          leading: const Icon(Icons.celebration_outlined),
          title: Text(ReviewView.entryText(l, f, w)),
          onTap: w.ref == null ? null : () => openDrillRef(context, w.ref!),
        ),
    ];
  }

  List<Widget> _stale(ReviewData? r) {
    final l = context.l10n;
    final lists = [
      for (final a in r?.attention ?? const <ReviewEntry>[])
        if (a.kind == ReviewEntryKind.staleLists && a.ref != null) a,
    ];
    if (lists.isEmpty) return [_Nothing(text: l.statsReviewNothing)];
    return [
      for (final a in lists)
        _ActionRow(
          title: a.title ?? '',
          actions: [
            (l.statsGuidedArchive, () => ref.read(guidedReviewServiceProvider).archiveList(a.ref!.id)),
            (l.statsGuidedOpen, null),
          ],
          onOpen: () => openDrillRef(context, a.ref!),
        ),
    ];
  }

  List<Widget> _rebalance(ReviewData? r) {
    final l = context.l10n;
    final f = statFormatOf(context);
    final days = [
      for (final d in r?.nextWeek ?? const <(LocalDate, double, double, bool)>[])
        if (d.$4) d,
    ];
    if (days.isEmpty) return [_Nothing(text: l.statsReviewNothing)];
    return [
      for (final (date, planned, capacity, _) in days)
        ListTile(
          contentPadding: EdgeInsetsDirectional.zero,
          leading: Icon(Icons.warning_amber_rounded, color: context.appColors.warning),
          title: Text(f.dayShort(date)),
          subtitle: Text(l.statsReviewLoad(f.value(planned, StatUnit.minutes), f.value(capacity, StatUnit.minutes))),
          trailing: TextButton(
            onPressed: () => unawaited(context.push(AppLinks.planDay(date: date.toIso()))),
            child: Text(l.statsGuidedOpen),
          ),
        ),
    ];
  }
}

class _Nothing extends StatelessWidget {
  const _Nothing({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(vertical: Space.lg),
    child: Text(text, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
  );
}

/// A row with a title and action buttons; each action writes and offers Undo.
class _ActionRow extends ConsumerWidget {
  const _ActionRow({required this.title, required this.actions, this.subtitle, this.onOpen});

  final String title;
  final String? subtitle;

  /// (label, write) — a null write is the "open" action ([onOpen]).
  final List<(String, Future<OpRecord?> Function()?)> actions;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.text.titleSmall),
            if (subtitle != null)
              Text(subtitle!, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final (label, write) in actions)
                  OutlinedButton(
                    onPressed: write == null
                        ? onOpen
                        : () async {
                            final record = await write();
                            if (record != null && context.mounted) {
                              showUndoSnackBar(context, ref, message: l.statsGuidedUpdated, record: record);
                            }
                          },
                    child: Text(label),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverdueStep extends ConsumerWidget {
  const _OverdueStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = statFormatOf(context);
    final items = ref.watch(overdueItemsProvider).value ?? const <PlannerItem>[];
    if (items.isEmpty) return _Nothing(text: l.statsReviewNothing);
    final service = ref.read(guidedReviewServiceProvider);
    final today = LocalDate.fromDateTime(ref.read(clockProvider).nowUtc().toLocal());
    return Column(
      children: [
        for (final i in items)
          _ActionRow(
            title: i.title,
            subtitle: f.date(i.startLocal.date),
            actions: [
              (l.statsGuidedTomorrow, () => service.moveToTomorrow(i, today)),
              (l.statsGuidedSkip, () => service.skip(i)),
              (l.statsGuidedDrop, () => service.drop(i)),
              (l.statsGuidedOpen, null),
            ],
            onOpen: () => unawaited(context.push(AppLinks.task(i.taskId, occurrenceKey: i.occurrenceKey))),
          ),
      ],
    );
  }
}

class _WaitingStep extends ConsumerWidget {
  const _WaitingStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final items = [
      ...?ref.watch(smartItemsProvider(SmartKind.waiting)).value,
      ...?ref.watch(smartItemsProvider(SmartKind.blocked)).value,
    ];
    if (items.isEmpty) return _Nothing(text: l.statsReviewNothing);
    final service = ref.read(guidedReviewServiceProvider);
    final tomorrow = ref.read(clockProvider).nowUtc().add(const Duration(days: 1));
    return Column(
      children: [
        for (final s in items)
          _ActionRow(
            title: s.item.text,
            subtitle: s.checklistTitle,
            actions: [
              (l.statsGuidedFollowUp, () => service.followUpTomorrow(s.item.checklistId, s.item.id, tomorrow)),
              (l.statsGuidedUnblock, () => service.unblock(s.item.checklistId, s.item.id)),
              (l.statsGuidedOpen, null),
            ],
            onOpen: () => unawaited(context.push(AppLinks.checklist(s.item.checklistId, itemId: s.item.id))),
          ),
      ],
    );
  }
}

class _HabitsStep extends ConsumerWidget {
  const _HabitsStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = statFormatOf(context);
    final chart = ref.watch(metricsBatchProvider(_atRiskRequest)).value?['HB-X-07']?.chart;
    final rows = chart is ListData ? chart.rows.where((r) => r.ref != null).toList() : const <ListRow>[];
    if (rows.isEmpty) return _Nothing(text: l.statsReviewNothing);
    final service = ref.read(guidedReviewServiceProvider);
    final today = LocalDate.fromDateTime(ref.read(clockProvider).nowUtc().toLocal());
    return Column(
      children: [
        for (final r in rows)
          _ActionRow(
            title: f.label(r.label),
            subtitle: r.secondary == null ? null : f.label(r.secondary!),
            actions: [(l.statsGuidedPause, () => service.pauseWeek(r.ref!.id, today)), (l.statsGuidedOpen, null)],
            onOpen: () => unawaited(context.push(AppLinks.habitEdit(r.ref!.id))),
          ),
      ],
    );
  }
}
