/// Task stats (T6.3.17): the "Stats" tab content of an occurrence / one-off task — PL-T-01…07 with
/// the planned-vs-actual bullet and a "See series stats" link for recurring tasks. The planner's
/// occurrence sheet embeds [TaskStatsPanel]; `/insights/task/:id?occurrence=<key>` shows it full
/// screen.
library;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/application/stats_providers.dart';
import 'package:everslot/features/stats/domain/scope_entity.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/stats_navigation.dart';
import 'package:everslot/features/stats/presentation/stats_scope_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class TaskStatsPanel extends ConsumerWidget {
  const TaskStatsPanel({required this.taskId, super.key, this.occurrenceKey, this.showHeader = false});

  final String taskId;

  /// Occurrence of a recurring task (null = the task's own / first occurrence).
  final String? occurrenceKey;

  /// Show the task name header (full-screen use; the sheet already shows it).
  final bool showHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entity = ref.watch(scopeEntityProvider(('task', taskId))).value;
    return StatsScopeView(
      key: ValueKey('task/$taskId/$occurrenceKey'),
      scope: MetricScope.task,
      scopeId: taskId,
      extra: occurrenceKey,
      entity: showHeader ? entity : null,
      showPeriod: false,
      header: entity == null ? null : SeriesStatsLink(entity: entity),
    );
  }
}

/// "See series stats" for a task of a recurring series (nothing for one-off tasks).
class SeriesStatsLink extends StatelessWidget {
  const SeriesStatsLink({required this.entity, super.key});

  final ScopeEntity entity;

  @override
  Widget build(BuildContext context) {
    final series = entity.parentId;
    if (!entity.recurring || series == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, 0),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: () => openInsights(context, 'series', series),
          icon: const Icon(Icons.insights_outlined),
          label: Text(context.l10n.statsSeeSeries),
        ),
      ),
    );
  }
}
