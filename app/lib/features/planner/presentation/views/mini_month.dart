import 'dart:math' as math;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/engine/day_slices.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Mini-month jump sheet (T3.4.04): swipeable months with load dots; tapping a day returns it
/// (views jump to the week or day containing it).
Future<LocalDate?> showMiniMonth(
  BuildContext context, {
  required LocalDate initial,
  required Weekday weekStart,
  List<LocalDate> highlight = const [],
}) => showAppSheet<LocalDate>(
  context,
  builder: (ctx) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(Space.md, 0, Space.md, Space.lg),
    child: MiniMonth(initial: initial, weekStart: weekStart, highlight: highlight, onPick: (d) => Navigator.pop(ctx, d)),
  ),
);

/// Items per day of a range (load dots; multi-day items count on every day they cover).
Map<LocalDate, int> countsByDay(List<PlannerItem> items, DayRange range) {
  final counts = <LocalDate, int>{};
  for (final i in items) {
    var d = i.startLocal.date;
    final last = isLaneItem(i) ? laneEndDate(i) : i.endLocal.date;
    if (d.isBefore(range.start)) d = range.start;
    for (var guard = 0; !d.isAfter(last) && d.isBefore(range.endExclusive) && guard < 400; guard++) {
      counts[d] = (counts[d] ?? 0) + 1;
      d = d.plusDays(1);
    }
  }
  return counts;
}

class MiniMonth extends StatefulWidget {
  const MiniMonth({required this.initial, required this.weekStart, required this.onPick, this.highlight = const [], super.key});

  final LocalDate initial;
  final Weekday weekStart;
  final ValueChanged<LocalDate> onPick;

  /// Days drawn as the current selection (e.g. the visible week).
  final List<LocalDate> highlight;

  @override
  State<MiniMonth> createState() => _MiniMonthState();
}

class _MiniMonthState extends State<MiniMonth> {
  static const _base = 1200;
  late final PageController _pages = PageController(initialPage: _base);
  int _index = _base;

  LocalDate _monthAt(int i) => widget.initial.firstDayOfMonth.plusMonths(i - _base);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final month = _monthAt(_index);
    final narrow = DateFormat('EEEEE', locale);
    final weekdays = Weekday.ordered(widget.weekStart);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: l.pvPrevious,
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _pages.previousPage(duration: Motion.normal, curve: Motion.curve),
            ),
            Expanded(
              child: Text(
                DateFormat.yMMMM(locale).format(month.toDateTimeUtc()),
                key: const Key('mini-month-title'),
                textAlign: TextAlign.center,
                style: context.text.titleMedium,
              ),
            ),
            IconButton(
              tooltip: l.pvNext,
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _pages.nextPage(duration: Motion.normal, curve: Motion.curve),
            ),
          ],
        ),
        Row(
          children: [
            for (final w in weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    narrow.format(DateTime.utc(2024, 1, w.iso)),
                    style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(
          height: 6 * 44,
          child: PageView.builder(
            controller: _pages,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => _MonthGrid(
              month: _monthAt(i),
              weekStart: widget.weekStart,
              highlight: widget.highlight,
              onPick: widget.onPick,
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthGrid extends ConsumerWidget {
  const _MonthGrid({required this.month, required this.weekStart, required this.highlight, required this.onPick});

  final LocalDate month;
  final Weekday weekStart;
  final List<LocalDate> highlight;
  final ValueChanged<LocalDate> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final start = month.startOfWeek(weekStart);
    final range = DayRange(start, 42);
    final items = ref.watch(viewItemsProvider(range)).value ?? const <PlannerItem>[];
    final counts = countsByDay(items, range);
    final today = ref.watch(plannerTodayProvider);
    final f = context.plannerFormatSimple();
    final l = context.l10n;
    return Column(
      children: [
        for (var w = 0; w < 6; w++)
          Expanded(
            child: Row(
              children: [
                for (var d = 0; d < 7; d++)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final day = start.plusDays(w * 7 + d);
                        final inMonth = day.month == month.month;
                        final count = counts[day] ?? 0;
                        final selected = highlight.contains(day);
                        final isToday = day == today;
                        return Semantics(
                          button: true,
                          selected: selected,
                          label: '${f.dayLong(day)}, ${l.pvItemsCount(count)}',
                          child: ExcludeSemantics(
                            child: InkWell(
                              key: Key('mini-${day.toIso()}'),
                              borderRadius: BorderRadius.circular(Radii.sm),
                              onTap: () => onPick(day),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: selected ? context.colors.primaryContainer.withValues(alpha: 0.6) : null,
                                  borderRadius: BorderRadius.circular(Radii.sm),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      alignment: Alignment.center,
                                      decoration: isToday ? BoxDecoration(color: context.colors.primary, shape: BoxShape.circle) : null,
                                      child: FittedBox(
                                        child: Text(
                                          f.number(day.day),
                                          style: context.text.bodySmall?.copyWith(
                                            color: isToday
                                                ? context.colors.onPrimary
                                                : (inMonth ? context.colors.onSurface : context.colors.outline),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 6,
                                      child: count == 0
                                          ? null
                                          : Center(
                                              child: ColorDot(
                                                context.colors.primary.withValues(alpha: inMonth ? 1 : 0.4),
                                                size: math.min(6, 3 + count.toDouble()),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

extension on BuildContext {
  AppFormat plannerFormatSimple() => AppFormat(Localizations.localeOf(this).toLanguageTag(), l10n: l10n);
}
