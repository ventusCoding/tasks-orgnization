import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/grid_commands.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/grid/time_grid.dart';
import 'package:everslot/features/planner/presentation/view_config/view_settings_sheet.dart';
import 'package:everslot/features/planner/presentation/views/heat_calendar.dart';
import 'package:everslot/features/planner/presentation/views/item_chip.dart';
import 'package:everslot/features/planner/presentation/views/month_view.dart';
import 'package:everslot/features/planner/presentation/views/planner_chrome.dart';
import 'package:everslot/features/planner/presentation/views/planner_keys.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

/// First day of the calendar quarter containing [date] (Jan, Apr, Jul or Oct 1).
LocalDate quarterStart(LocalDate date) => LocalDate(date.year, ((date.month - 1) ~/ 3) * 3 + 1, 1);

/// Quarter view (T3.6.12, Fantastical style): three months side by side (≥ 600 dp) or stacked
/// (phone) with dots or bars per day (`options.monthMode`). Tap a day → Day list, long-press → quick
/// create, a month name → Month view; arrows / swipes change quarter.
class QuarterView extends ConsumerStatefulWidget {
  const QuarterView({required this.args, super.key});

  final PlannerViewArgs args;

  @override
  ConsumerState<QuarterView> createState() => _QuarterViewState();
}

class _QuarterViewState extends ConsumerState<QuarterView> {
  late LocalDate _start;

  String get _key => widget.args.viewKey;

  @override
  void initState() {
    super.initState();
    _start = quarterStart(
      widget.args.date ?? ref.read(plannerAnchorProvider) ?? ref.read<LocalDate>(plannerTodayProvider),
    );
  }

  void _go(LocalDate date) {
    final start = quarterStart(date);
    setState(() => _start = start);
    ref.read(plannerAnchorProvider.notifier).set(start);
    ref.read(plannerViewStateProvider(_key).notifier).update((s) => s.copyWith(anchor: start));
  }

  Future<void> _pick() async {
    final picked = await pickDate(context, initial: _start);
    if (picked != null) _go(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(plannerViewConfigProvider(_key));
    final prefs = ref.watch(userPreferencesProvider);
    final weekStart = weekStartFor(config, prefs.weekStart);
    final today = ref.watch(plannerTodayProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final bars = MonthDensity.parse(config.option<String>('monthMode', 'dots')) == MonthDensity.bars;
    final months = [_start, addMonths(_start, 1), addMonths(_start, 2)];
    final end = addMonths(_start, 3);
    final items = filteredItems(ref, DayRange(_start, _start.daysUntil(end)), config).value ?? const <PlannerItem>[];
    final byDay = <LocalDate, List<PlannerItem>>{};
    for (final i in items) {
      byDay.putIfAbsent(i.startLocal.date, () => []).add(i);
    }
    final colors = viewColors(context, ref, config);
    final commands = PlannerCommands(context, ref);
    final nav = ref.read(plannerNavProvider);
    final f = context.plannerFormat(use24h: prefs.use24h);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final notifier = ref.read(plannerViewConfigProvider(_key).notifier);

    Widget cell(BuildContext context, LocalDate d) {
      final list = dayListOrder(byDay[d] ?? const []);
      return _QuarterCell(
        day: d,
        items: list,
        bars: bars,
        isToday: d == today,
        accent: (i) => colors.of(i).accent,
        label: '${f.dayLong(d)}, ${l.pvItemsCount(list.length)}',
        onTap: () => nav.openView(context, 'day_list', date: d),
        onLongPress: () => unawaited(commands.quickCreate(start: d.atStartOfDay, duration: 1440, allDay: true)),
      );
    }

    Widget month(LocalDate m) => Padding(
      padding: const EdgeInsets.all(Space.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextButton(
            key: ValueKey('quarter-month-${m.toIso()}'),
            onPressed: () => nav.openView(context, 'month', date: m),
            child: Text(f.monthYear(m), style: context.text.titleSmall),
          ),
          MonthCellGrid(month: m, weekStart: weekStart, cell: cell, aspectRatio: bars ? 0.8 : 1),
        ],
      ),
    );

    return PlannerViewScaffold(
      viewKey: _key,
      toolbar: DatePagedToolbar(
        title: DateFormat.yQQQ(locale).format(_start.toDateTimeUtc()),
        onPrevious: () => _go(addMonths(_start, -3)),
        onNext: () => _go(end),
        onToday: () => _go(today),
        onTitleTap: () => unawaited(_pick()),
        previousLabel: l.pvPrevious,
        nextLabel: l.pvNext,
        trailing: [
          PopupMenuButton<MonthDensity>(
            key: const Key('quarter-density'),
            tooltip: l.pvDensity,
            icon: const Icon(Icons.density_medium),
            onSelected: (d) => notifier.change((c) => c.withOption('monthMode', d.id)),
            itemBuilder: (_) => [
              CheckedPopupMenuItem(value: MonthDensity.dots, checked: !bars, child: Text(l.pvMonthDots)),
              CheckedPopupMenuItem(value: MonthDensity.bars, checked: bars, child: Text(l.pvMonthBars)),
            ],
          ),
          PlannerFilterButton(viewKey: _key),
          PlannerMoreMenu(viewKey: _key, kind: ViewSettingsKind.calendar),
        ],
      ),
      body: PlannerKeys(
        onPrevious: () => _go(addMonths(_start, -3)),
        onNext: () => _go(end),
        onToday: () => _go(today),
        child: Column(
          children: [
            ActiveFilterBar(viewKey: _key),
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (d) {
                  final v = d.primaryVelocity ?? 0;
                  if (v.abs() < 300) return;
                  final forward = rtl ? v > 0 : v < 0;
                  _go(forward ? end : addMonths(_start, -3));
                },
                child: LayoutBuilder(
                  builder: (context, box) => SingleChildScrollView(
                    key: ValueKey('quarter-${_start.toIso()}'),
                    padding: const EdgeInsets.only(bottom: 88),
                    child: box.maxWidth >= 600
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [for (final m in months) Expanded(child: month(m))],
                          )
                        : Column(children: [for (final m in months) month(m)]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      fab: PlannerFab(start: () => suggestedStart(today, ref.read(plannerNowProvider))),
    );
  }
}

/// A quarter day: number, then up to four colored dots or stacked bars.
class _QuarterCell extends StatelessWidget {
  const _QuarterCell({
    required this.day,
    required this.items,
    required this.bars,
    required this.isToday,
    required this.accent,
    required this.label,
    required this.onTap,
    required this.onLongPress,
  });

  final LocalDate day;
  final List<PlannerItem> items;
  final bool bars;
  final bool isToday;
  final Color Function(PlannerItem item) accent;
  final String label;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shown = items.take(bars ? 3 : 4).toList();
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      onLongPress: onLongPress,
      child: ExcludeSemantics(
        child: GestureDetector(
          key: ValueKey('quarter-day-${day.toIso()}'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: day.weekday.isWeekend ? c.surfaceContainerHighest.withValues(alpha: 0.4) : null,
              borderRadius: BorderRadius.circular(Radii.sm),
              border: isToday ? Border.all(color: c.primary, width: 1.5) : null,
            ),
            child: Column(
              children: [
                const SizedBox(height: 1),
                Text(
                  '${day.day}',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                    color: isToday ? c.primary : c.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                if (bars)
                  for (final i in shown)
                    Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
                      decoration: BoxDecoration(color: accent(i), borderRadius: BorderRadius.circular(2)),
                    )
                else
                  Wrap(
                    spacing: 1.5,
                    runSpacing: 1.5,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final i in shown)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(color: accent(i), shape: BoxShape.circle),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
