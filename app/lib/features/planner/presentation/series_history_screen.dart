import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/occurrence_resolver.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot/features/planner/presentation/occurrence_panel.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Occurrence filter of the series history.
enum SeriesFilter { all, done, skipped, missed, moved }

/// Whether [o] passes [filter].
bool seriesFilterMatches(SeriesFilter filter, ResolvedOccurrence o) => switch (filter) {
  SeriesFilter.all => true,
  SeriesFilter.done => o.status == OccurrenceStatus.done,
  SeriesFilter.skipped => o.status == OccurrenceStatus.skipped,
  SeriesFilter.missed => o.status == OccurrenceStatus.missed,
  SeriesFilter.moved => o.isMoved,
};

/// Series history (T3.2.20): every occurrence of a series (across splits) month by month with
/// status, planned vs actual times and moves, filters, a mini month calendar and the entry to
/// the series statistics.
class SeriesHistoryScreen extends ConsumerStatefulWidget {
  const SeriesHistoryScreen({required this.seriesId, super.key, this.title, this.initialMonth});

  final String seriesId;
  final String? title;
  final LocalDate? initialMonth;

  @override
  ConsumerState<SeriesHistoryScreen> createState() => _SeriesHistoryScreenState();
}

class _SeriesHistoryScreenState extends ConsumerState<SeriesHistoryScreen> {
  late LocalDate _month = (widget.initialMonth ?? ref.read(plannerServiceProvider).nowLocal.date).firstDayOfMonth;
  SeriesFilter _filter = SeriesFilter.all;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final prefs = ref.watch(userPreferencesProvider);
    final format = AppFormat(context.localeName, use24h: prefs.use24h, l10n: l);
    final tasks = ref.watch(seriesTasksProvider(widget.seriesId)).value ?? const <Task>[];
    final ids = [for (final t in tasks) t.id];
    final query = SeriesRangeQuery(ids, _month.atStartOfDay, _month.plusMonths(1).atStartOfDay);
    final all = ids.isEmpty ? const <ResolvedOccurrence>[] : (ref.watch(seriesOccurrencesProvider(query)).value ?? const []);
    final shown = [for (final o in all) if (seriesFilterMatches(_filter, o)) o];
    return Scaffold(
      appBar: AppBar(title: Text(widget.title == null ? l.tasksSeriesHistoryTitle : '${l.tasksSeriesHistoryTitle} · ${widget.title}')),
      body: ListView(
        key: const ValueKey('series-history-list'),
        padding: const EdgeInsetsDirectional.only(bottom: Space.xxxl),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: l.tasksPrevMonth,
                onPressed: () => setState(() => _month = _month.plusMonths(-1)),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(child: Text(format.monthYear(_month), textAlign: TextAlign.center, style: context.text.titleMedium)),
              IconButton(
                tooltip: l.tasksNextMonth,
                onPressed: () => setState(() => _month = _month.plusMonths(1)),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          _MonthGrid(month: _month, occurrences: all, weekStart: prefs.weekStart),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, 0),
            child: Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final (f, label) in [
                  (SeriesFilter.all, l.tasksFilterAll),
                  (SeriesFilter.done, l.tasksFilterDone),
                  (SeriesFilter.skipped, l.tasksFilterSkipped),
                  (SeriesFilter.missed, l.tasksFilterMissed),
                  (SeriesFilter.moved, l.tasksFilterMoved),
                ])
                  ChoiceChip(
                    key: ValueKey('series-filter-${f.name}'),
                    label: Text(label),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
              ],
            ),
          ),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.all(Space.xl),
              child: Text(l.tasksSeriesEmpty, textAlign: TextAlign.center, key: const ValueKey('series-empty')),
            ),
          for (final o in shown) _row(context, o, format),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.md, Space.lg, 0),
            child: OutlinedButton.icon(
              key: const ValueKey('series-stats'),
              onPressed: () => GoRouter.of(context).push(AppLinks.insightsScope('series', widget.seriesId)),
              icon: const Icon(Icons.insights),
              label: Text(l.tasksSeriesStats),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, ResolvedOccurrence o, AppFormat format) {
    final l = context.l10n;
    final service = ref.read(plannerServiceProvider);
    final visual = occurrenceStatusVisual(context, o.status, overdue: o.isOverdue);
    final start = o.startLocalViewer;
    final planned = o.isAllDay ? format.dayLong(start.date) : '${format.dayLong(start.date)} · ${format.timeOf(start)}';
    final actual = o.record?.actualStartAt;
    final lines = <String>[
      if (actual != null && !o.isAllDay)
        l.tasksPlannedVsActual(format.timeOf(start), format.timeOf(service.zones.toLocal(actual, service.viewerZone))),
      if (o.isMoved) l.tasksMovedFrom(format.dateTime(o.originalStartLocal)),
    ];
    return ListTile(
      key: ValueKey('series-${o.identity}'),
      leading: Icon(visual.icon, color: visual.color),
      title: Text(planned),
      subtitle: lines.isEmpty ? null : Text(lines.join('\n')),
      trailing: StatusPill(dense: true, label: visual.label, color: visual.color),
      onTap: () => showOccurrenceSheet(context, o.toPlannerItem()),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.month, required this.occurrences, required this.weekStart});

  final LocalDate month;
  final List<ResolvedOccurrence> occurrences;
  final Weekday weekStart;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final byDay = <LocalDate, List<OccurrenceStatus>>{};
    for (final o in occurrences) {
      (byDay[o.startLocalViewer.date] ??= []).add(o.status);
    }
    Color? dot(List<OccurrenceStatus>? s) {
      if (s == null || s.isEmpty) return null;
      if (s.contains(OccurrenceStatus.missed)) return colors.missed;
      if (s.every((x) => x == OccurrenceStatus.done)) return colors.completed;
      if (s.every((x) => x == OccurrenceStatus.skipped || x == OccurrenceStatus.cancelled)) return colors.skipped;
      return colors.todo;
    }

    final first = month.startOfWeek(weekStart);
    final weeks = first.daysUntil(month.lastDayOfMonth) ~/ 7 + 1;
    final narrow = DateFormat.EEEEE(context.localeName);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
      child: Semantics(
        container: true,
        label: context.l10n.tasksSeriesHistoryTitle,
        child: Column(
          key: const ValueKey('series-month'),
          children: [
            Row(
              children: [
                for (final d in Weekday.ordered(weekStart))
                  Expanded(child: Center(child: Text(narrow.format(DateTime.utc(2024, 1, d.iso)), style: context.text.labelSmall))),
              ],
            ),
            for (var w = 0; w < weeks; w++)
              Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final day = first.plusDays(w * 7 + i);
                          if (day.month != month.month) return const SizedBox(height: 36);
                          final c = dot(byDay[day]);
                          return SizedBox(
                            height: 36,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${day.day}', style: context.text.labelSmall),
                                const SizedBox(height: 2),
                                Container(
                                  key: c == null ? null : ValueKey('series-dot-${day.toIso()}'),
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
