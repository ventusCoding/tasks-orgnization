import 'dart:math' as math;

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/presentation/check_in_sheets.dart';
import 'package:everslot/features/habits/presentation/habit_ui.dart';
import 'package:everslot/features/habits/presentation/today_view.dart';
import 'package:everslot_metrics/everslot_metrics.dart'
    show DateRange, HabitSeries, PeriodResult, PeriodStatus, dailyCompletionHeatmap;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Share of due habits completed per day of [range] (null = nothing due), with the [6.5] perfect-day
/// definition: excused, paused and not-due habits don't count as due (T5.2.11).
final monthCompletionProvider = Provider.family<Map<LocalDate, double?>, DateRange>((ref, range) {
  final habits = ref.watch(habitsProvider).value ?? const <Habit>[];
  final series = <HabitSeries>[];
  for (final h in habits) {
    if (h is! BuildHabit) continue;
    final s = ref.watch(habitSnapshotProvider(h.id)).value;
    final e = s?.evaluation;
    if (e == null) continue;
    series.add(HabitSeries(h.id, results: e.units, skipPolicy: h.skipPolicy));
  }
  return {for (final p in dailyCompletionHeatmap(series, range: range)) p.bucket: p.value};
});

/// Multi-habit month overview (T5.2.11): each day shows the share of due habits completed (ring),
/// perfect days are highlighted; tapping a day lists every habit with inline editing.
class MonthOverview extends ConsumerStatefulWidget {
  const MonthOverview({required this.initialMonth, super.key});

  final LocalDate initialMonth;

  @override
  ConsumerState<MonthOverview> createState() => _MonthOverviewState();
}

class _MonthOverviewState extends ConsumerState<MonthOverview> {
  late LocalDate _month = widget.initialMonth.firstDayOfMonth;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final prefs = ref.watch(userPreferencesProvider);
    final today = ref.watch(habitTodayProvider);
    final fmt = AppFormat(context.localeName);
    final first = _month;
    final last = _month.lastDayOfMonth;
    final ratios = ref.watch(monthCompletionProvider(DateRange(first, last)));
    final gridStart = first.startOfWeek(prefs.weekStart);
    final weeks = ((gridStart.daysUntil(last) + 1) / 7).ceil();
    final perfect = ratios.values.where((r) => r == 1).length;
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.md, 0, Space.md, 96),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: l.habitsPreviousMonth,
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() => _month = _month.plusMonths(-1)),
            ),
            Expanded(child: Text(fmt.monthYear(_month), textAlign: TextAlign.center, style: context.text.titleMedium)),
            IconButton(
              tooltip: l.habitsNextMonth,
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() => _month = _month.plusMonths(1)),
            ),
          ],
        ),
        Semantics(
          label: l.habitsPerfectDays(perfect),
          child: Text(l.habitsPerfectDays(perfect), style: context.text.labelLarge, textAlign: TextAlign.center),
        ),
        const SizedBox(height: Space.sm),
        Row(
          children: [
            for (final w in Weekday.ordered(prefs.weekStart))
              Expanded(child: Text(fmt.weekdayShort(w), textAlign: TextAlign.center, style: context.text.labelSmall)),
          ],
        ),
        for (var week = 0; week < weeks; week++)
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: () {
                    final d = gridStart.plusDays(week * 7 + i);
                    if (d.month != _month.month) return const SizedBox(height: 56);
                    final ratio = ratios[d];
                    final isPerfect = ratio == 1;
                    return Semantics(
                      button: true,
                      label: '${fmt.dayLong(d)}${ratio == null ? '' : ', ${fmt.percent(ratio)}'}',
                      excludeSemantics: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(Radii.md),
                        onTap: () => _openDay(context, d),
                        child: Container(
                          height: 56,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isPerfect ? context.appColors.success.withValues(alpha: 0.16) : null,
                            borderRadius: BorderRadius.circular(Radii.md),
                            border: d == today ? Border.all(color: context.colors.primary) : null,
                          ),
                          child: Center(
                            child: ProgressRing(
                              progress: ratio ?? 0,
                              size: 34,
                              stroke: 3,
                              color: isPerfect ? context.appColors.success : context.colors.primary,
                              child: Text(fmt.number(d.day), style: context.text.labelSmall),
                            ),
                          ),
                        ),
                      ),
                    );
                  }(),
                ),
            ],
          ),
      ],
    );
  }

  Future<void> _openDay(BuildContext context, LocalDate date) => showAppSheet<void>(
    context,
    title: AppFormat(context.localeName).dayLong(date),
    builder: (ctx) => SizedBox(
      height: MediaQuery.sizeOf(ctx).height * 0.6,
      child: TodayList(date: date),
    ),
  );
}

/// GitHub-style year grid of one habit (T5.2.10): columns = weeks, rows = weekdays from the week
/// start, today at the trailing edge; status colors for yes/no, intensity = achieved ÷ target for
/// measurable goals. Tap a day to open the day editor; a legend and an accessible summary.
class YearHeatmap extends ConsumerStatefulWidget {
  const YearHeatmap({required this.habitId, super.key, this.cellSize = 13});

  final String habitId;
  final double cellSize;

  @override
  ConsumerState<YearHeatmap> createState() => _YearHeatmapState();
}

class _YearHeatmapState extends ConsumerState<YearHeatmap> {
  int _yearsBack = 0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final snapshot = ref.watch(habitSnapshotProvider(widget.habitId)).value;
    final habit = snapshot?.build;
    if (snapshot == null || habit == null) return const SizedBox(height: 120);
    final prefs = ref.watch(userPreferencesProvider);
    final end = _yearsBack == 0 ? snapshot.today : LocalDate(snapshot.today.year - _yearsBack, 12, 31);
    final start = end.minusDays(52 * 7).startOfWeek(prefs.weekStart);
    final e = snapshot.evaluation!;
    final accent = habitAccent(context, habit);
    var scheduled = 0;
    var done = 0;
    final cells = <LocalDate, Color>{};
    for (var d = start; !d.isAfter(end); d = d.plusDays(1)) {
      final r = e.dayOn(d);
      cells[d] = _color(context, habit, r, accent);
      if (r != null && r.status != PeriodStatus.notDue && r.status != PeriodStatus.pending) {
        if (d.year == end.year) scheduled++;
        if (r.status == PeriodStatus.done && d.year == end.year) done++;
      }
    }
    final summary = l.habitsYearSummary(done, scheduled, '${end.year}');
    final weeks = (start.daysUntil(end) ~/ 7) + 1;
    final size = widget.cellSize;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: l.habitsPreviousYear,
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() => _yearsBack++),
            ),
            Expanded(child: Text('${end.year}', textAlign: TextAlign.center, style: context.text.titleSmall)),
            IconButton(
              tooltip: l.habitsNextYear,
              icon: const Icon(Icons.chevron_right),
              onPressed: _yearsBack == 0 ? null : () => setState(() => _yearsBack--),
            ),
          ],
        ),
        Semantics(
          label: summary,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: GestureDetector(
              onTapUp: (details) {
                final col = (details.localPosition.dx / (size + 2)).floor();
                final row = (details.localPosition.dy / (size + 2)).floor();
                final visualCol = context.isRtl ? weeks - 1 - col : col;
                final d = start.plusDays(visualCol * 7 + row);
                if (d.isAfter(end) || d.isBefore(habit.startDate)) return;
                showDayEditor(context, ref, habit.id, d);
              },
              child: CustomPaint(
                size: Size(weeks * (size + 2), 7 * (size + 2)),
                painter: _HeatmapPainter(
                  start: start,
                  end: end,
                  cells: cells,
                  size: size,
                  rtl: context.isRtl,
                  empty: context.colors.surfaceContainerHighest,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: Space.xs),
        Text(summary, style: context.text.bodySmall),
        const SizedBox(height: Space.xs),
        Wrap(
          spacing: Space.md,
          runSpacing: Space.xs,
          children: [
            for (final s in [PeriodStatus.done, PeriodStatus.partial, PeriodStatus.failed, PeriodStatus.missed, PeriodStatus.skipped])
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ColorDot(StatusStyle.of(context, s).color),
                  const SizedBox(width: Space.xs),
                  Text(l.statusLabel(s), style: context.text.labelSmall),
                ],
              ),
          ],
        ),
      ],
    );
  }

  static Color _color(BuildContext context, BuildHabit habit, PeriodResult? r, Color accent) {
    if (r == null) return Colors.transparent;
    switch (r.status) {
      case PeriodStatus.notDue:
      case PeriodStatus.pending:
        return Colors.transparent;
      case PeriodStatus.done:
        if (habit.goal.isMeasurable && r.target > 0 && !habit.goal.isLimit) {
          return accent.withValues(alpha: 0.35 + 0.65 * math.min(1, r.achieved / r.target));
        }
        return accent;
      case PeriodStatus.partial:
        return accent.withValues(alpha: 0.2 + 0.5 * math.min(1, r.target <= 0 ? 0 : r.achieved / r.target));
      default:
        return StatusStyle.of(context, r.status).color.withValues(alpha: 0.7);
    }
  }
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({
    required this.start,
    required this.end,
    required this.cells,
    required this.size,
    required this.rtl,
    required this.empty,
  });

  final LocalDate start;
  final LocalDate end;
  final Map<LocalDate, Color> cells;
  final double size;
  final bool rtl;
  final Color empty;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final weeks = (start.daysUntil(end) ~/ 7) + 1;
    final paint = Paint();
    for (var d = start; !d.isAfter(end); d = d.plusDays(1)) {
      final index = start.daysUntil(d);
      final col = index ~/ 7;
      final row = index % 7;
      final x = (rtl ? weeks - 1 - col : col) * (size + 2);
      final y = row * (size + 2);
      final c = cells[d] ?? Colors.transparent;
      paint.color = c == Colors.transparent ? empty : c;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, size, size), const Radius.circular(2)), paint);
    }
  }

  @override
  bool shouldRepaint(_HeatmapPainter old) => old.cells != cells || old.rtl != rtl || old.end != end;
}

/// Year view of the Habits tab: one compact year grid per habit.
class HabitsYearView extends ConsumerWidget {
  const HabitsYearView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final habits = [for (final h in ref.watch(habitsProvider).value ?? const <Habit>[]) if (h is BuildHabit) h];
    if (habits.isEmpty) return EmptyState(icon: Icons.calendar_view_month, title: l.habitsEmptyTitle, message: l.habitsEmptyBody);
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, 96),
      children: [
        for (final h in habits) ...[
          SectionHeader(h.name, padding: const EdgeInsetsDirectional.only(top: Space.lg, bottom: Space.xs)),
          YearHeatmap(habitId: h.id, cellSize: 10),
        ],
      ],
    );
  }
}
