import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/engine/calendar_metrics.dart';
import 'package:everslot/features/planner/presentation/grid/grid_commands.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/grid/time_grid.dart';
import 'package:everslot/features/planner/presentation/view_config/view_settings_sheet.dart';
import 'package:everslot/features/planner/presentation/views/heat_calendar.dart';
import 'package:everslot/features/planner/presentation/views/planner_chrome.dart';
import 'package:everslot/features/planner/presentation/views/planner_keys.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

/// Year heatmap (T3.6.10): twelve mini-months colored by a selectable metric — planned hours,
/// completion rate or number of items (`options.heatMetric`). Tap a day → its Day list, long-press
/// → create an all-day task, tap a month name → the Month view; swipe or use the arrows to change
/// year.
class YearView extends ConsumerStatefulWidget {
  const YearView({required this.args, super.key});

  final PlannerViewArgs args;

  @override
  ConsumerState<YearView> createState() => _YearViewState();
}

class _YearViewState extends ConsumerState<YearView> {
  late int _year;

  /// Per-day values of the last items list and metric (recomputed only when either changes).
  ({List<PlannerItem> raw, ItemFilter filter, HeatMetric metric, Map<LocalDate, double> values})? _memo;

  String get _key => widget.args.viewKey;

  @override
  void initState() {
    super.initState();
    final start = widget.args.date ?? ref.read(plannerAnchorProvider) ?? ref.read<LocalDate>(plannerTodayProvider);
    _year = start.year;
  }

  void _go(int year) {
    setState(() => _year = year);
    final today = ref.read(plannerTodayProvider);
    final anchor = year == today.year ? today : LocalDate(year, 1, 1);
    ref.read(plannerAnchorProvider.notifier).set(anchor);
    ref.read(plannerViewStateProvider(_key).notifier).update((s) => s.copyWith(anchor: anchor));
  }

  Future<void> _pick() async {
    final picked = await pickDate(context, initial: LocalDate(_year, 1, 1));
    if (picked != null) _go(picked.year);
  }

  Map<LocalDate, double> _values(List<PlannerItem> raw, ItemFilter filter, HeatMetric metric) {
    final memo = _memo;
    if (memo != null && identical(memo.raw, raw) && memo.filter == filter && memo.metric == metric) {
      return memo.values;
    }
    final values = dayMetric(filter.apply(raw), metric);
    _memo = (raw: raw, filter: filter, metric: metric, values: values);
    return values;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(plannerViewConfigProvider(_key));
    final prefs = ref.watch(userPreferencesProvider);
    final today = ref.watch(plannerTodayProvider);
    final f = context.plannerFormat(use24h: prefs.use24h);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final metric = HeatMetric.parse(config.option<String>('heatMetric', 'planned'));
    final weekStart = weekStartFor(config, prefs.weekStart);
    final raw = ref.watch(viewItemsProvider(DayRange(LocalDate(_year, 1, 1), LocalDate.daysInYear(_year)))).value;
    final values = raw == null ? const <LocalDate, double>{} : _values(raw, viewItemFilter(ref, config), metric);
    final commands = PlannerCommands(context, ref);
    final nav = ref.read(plannerNavProvider);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final metricLabel = switch (metric) {
      HeatMetric.planned => l.pvMetricPlanned,
      HeatMetric.completion => l.pvMetricCompletion,
      HeatMetric.count => l.pvMetricCount,
    };
    return PlannerViewScaffold(
      viewKey: _key,
      toolbar: DatePagedToolbar(
        title: yearLabel(locale, _year),
        onPrevious: () => _go(_year - 1),
        onNext: () => _go(_year + 1),
        onToday: () => _go(today.year),
        onTitleTap: () => unawaited(_pick()),
        previousLabel: l.pvPrevious,
        nextLabel: l.pvNext,
        trailing: [
          PopupMenuButton<HeatMetric>(
            key: const Key('year-metric'),
            tooltip: '${l.pvHeatMetric}: $metricLabel',
            icon: const Icon(Icons.palette_outlined),
            initialValue: metric,
            onSelected: (m) =>
                ref.read(plannerViewConfigProvider(_key).notifier).change((c) => c.withOption('heatMetric', m.name)),
            itemBuilder: (_) => [
              for (final (m, label) in [
                (HeatMetric.planned, l.pvMetricPlanned),
                (HeatMetric.completion, l.pvMetricCompletion),
                (HeatMetric.count, l.pvMetricCount),
              ])
                CheckedPopupMenuItem(value: m, checked: m == metric, child: Text(label)),
            ],
          ),
          PlannerFilterButton(viewKey: _key),
          PlannerMoreMenu(viewKey: _key, kind: ViewSettingsKind.calendar),
        ],
      ),
      body: PlannerKeys(
        onPrevious: () => _go(_year - 1),
        onNext: () => _go(_year + 1),
        onToday: () => _go(today.year),
        child: Column(
          children: [
            ActiveFilterBar(viewKey: _key),
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (d) {
                  final v = d.primaryVelocity ?? 0;
                  if (v.abs() < 300) return;
                  final forward = rtl ? v > 0 : v < 0;
                  _go(_year + (forward ? 1 : -1));
                },
                child: LayoutBuilder(
                  builder: (context, box) {
                    final cols = box.maxWidth >= 900 ? 6 : (box.maxWidth >= 600 ? 4 : 3);
                    const gutter = Space.md;
                    const gap = Space.sm;
                    final width = (box.maxWidth - 2 * gutter - (cols - 1) * gap) / cols;
                    return SingleChildScrollView(
                      key: const Key('year-scroll'),
                      padding: const EdgeInsets.fromLTRB(gutter, Space.sm, gutter, 88),
                      child: Column(
                        children: [
                          Wrap(
                            spacing: gap,
                            runSpacing: Space.md,
                            children: [
                              for (var m = 1; m <= 12; m++)
                                SizedBox(
                                  width: width,
                                  child: _YearMonth(
                                    month: LocalDate(_year, m, 1),
                                    weekStart: weekStart,
                                    metric: metric,
                                    values: values,
                                    today: today,
                                    format: f,
                                    locale: locale,
                                    onDay: (d) => nav.openView(context, 'day_list', date: d),
                                    onCreate: (d) => unawaited(
                                      commands.quickCreate(start: d.atStartOfDay, duration: 1440, allDay: true),
                                    ),
                                    onMonth: (d) => nav.openView(context, 'month', date: d),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: Space.lg),
                          const HeatLegend(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      fab: PlannerFab(
        start: () => suggestedStart(today.year == _year ? today : LocalDate(_year, 1, 1), ref.read(plannerNowProvider)),
      ),
    );
  }
}

class _YearMonth extends StatelessWidget {
  const _YearMonth({
    required this.month,
    required this.weekStart,
    required this.metric,
    required this.values,
    required this.today,
    required this.format,
    required this.locale,
    required this.onDay,
    required this.onCreate,
    required this.onMonth,
  });

  final LocalDate month;
  final Weekday weekStart;
  final HeatMetric metric;
  final Map<LocalDate, double> values;
  final LocalDate today;
  final AppFormat format;
  final String locale;
  final ValueChanged<LocalDate> onDay;
  final ValueChanged<LocalDate> onCreate;
  final ValueChanged<LocalDate> onMonth;

  @override
  Widget build(BuildContext context) {
    final name = DateFormat.MMMM(locale).format(month.toDateTimeUtc());
    return Column(
      key: ValueKey('year-month-${month.toIso()}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: format.monthYear(month),
          child: ExcludeSemantics(
            child: InkWell(
              key: ValueKey('year-month-title-${month.month}'),
              borderRadius: BorderRadius.circular(Radii.sm),
              onTap: () => onMonth(month),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 32),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.xxs),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        MonthCellGrid(
          month: month,
          weekStart: weekStart,
          cell: (context, d) {
            final v = values[d];
            return HeatCell(
              day: d,
              level: heatLevel(metric, v),
              isToday: d == today,
              numberText: format.number(d.day),
              label: '${format.dayLong(d)}, ${heatValueLabel(context, format, metric, v)}',
              onTap: () => onDay(d),
              onLongPress: () => onCreate(d),
            );
          },
        ),
      ],
    );
  }
}
