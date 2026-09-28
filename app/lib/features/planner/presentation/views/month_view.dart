import 'dart:async';
import 'dart:math' as math;

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/grid_commands.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/grid/time_grid.dart';
import 'package:everslot/features/planner/presentation/view_config/view_settings_sheet.dart';
import 'package:everslot/features/planner/presentation/views/item_chip.dart';
import 'package:everslot/features/planner/presentation/views/mini_month.dart';
import 'package:everslot/features/planner/presentation/views/planner_chrome.dart';
import 'package:everslot/features/planner/presentation/views/planner_keys.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Month cell density (T3.6.08, iOS 18 style): dots → bars → titles → titles + times.
enum MonthDensity {
  dots,
  bars,
  titles,
  titlesTimes;

  static MonthDensity parse(String? s) => switch (s) {
    'dots' => dots,
    'bars' => bars,
    'titles_times' || 'titlesTimes' => titlesTimes,
    _ => titles,
  };

  String get id => this == titlesTimes ? 'titles_times' : name;

  MonthDensity step(int dir) => MonthDensity.values[(index + dir).clamp(0, MonthDensity.values.length - 1)];
}

/// Weeks (rows of 7 days) covering [month] with weeks starting on [weekStart]: 4–6 rows.
List<List<LocalDate>> monthWeeks(LocalDate month, Weekday weekStart) {
  final first = month.firstDayOfMonth;
  final last = month.lastDayOfMonth;
  final weeks = <List<LocalDate>>[];
  for (var d = first.startOfWeek(weekStart); !d.isAfter(last); d = d.plusDays(7)) {
    weeks.add([for (var i = 0; i < 7; i++) d.plusDays(i)]);
  }
  return weeks;
}

/// First day of the month [months] after the month of [date].
LocalDate addMonths(LocalDate date, int months) {
  final index = date.year * 12 + (date.month - 1) + months;
  return LocalDate(index ~/ 12, index % 12 + 1, 1);
}

int monthsBetween(LocalDate a, LocalDate b) => (b.year * 12 + b.month) - (a.year * 12 + a.month);

/// Month view (T3.6.07 / T3.6.08): 4–6 week rows honouring the week start, weekend shading, chips
/// or dots per day by density (pinch to change), tap → Day list / inline expansion / list below,
/// long-press an empty spot to create, drag a chip to another day (keeps its time). Months page
/// vertically (or horizontally, setting).
class MonthView extends ConsumerStatefulWidget {
  const MonthView({required this.args, super.key});

  final PlannerViewArgs args;

  @override
  ConsumerState<MonthView> createState() => _MonthViewState();
}

class _MonthViewState extends ConsumerState<MonthView> {
  static const _base = 1200;
  late final LocalDate _origin;
  late final PageController _pages = PageController(initialPage: _base);
  late LocalDate _month;
  LocalDate? _selected;

  // Pinch (T3.6.08): two pointers; the density steps each time the span grows / shrinks by 35 %.
  final Map<int, Offset> _pointers = {};
  double? _pinchStart;

  String get _key => widget.args.viewKey;

  @override
  void initState() {
    super.initState();
    final LocalDate start = widget.args.date ?? ref.read(plannerAnchorProvider) ?? ref.read(plannerTodayProvider);
    _origin = start.firstDayOfMonth;
    _month = _origin;
    _selected = start;
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  LocalDate _monthAt(int index) => addMonths(_origin, index - _base);

  void _onPage(int index) {
    final m = _monthAt(index);
    setState(() => _month = m);
    ref.read(plannerAnchorProvider.notifier).set(m);
    ref.read(plannerViewStateProvider(_key).notifier).update((s) => s.copyWith(anchor: m));
  }

  void _goTo(LocalDate date, {bool animate = true}) {
    final target = _base + monthsBetween(_origin, date);
    setState(() => _selected = date);
    if (!_pages.hasClients) return;
    if (animate && !MediaQuery.disableAnimationsOf(context) && (target - (_pages.page?.round() ?? _base)).abs() <= 2) {
      unawaited(_pages.animateToPage(target, duration: Motion.normal, curve: Motion.curve));
    } else {
      _pages.jumpToPage(target);
    }
  }

  void _setDensity(MonthDensity d) =>
      ref.read(plannerViewConfigProvider(_key).notifier).change((c) => c.withOption('monthMode', d.id));

  void _onPointerDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.position;
    if (_pointers.length == 2) _pinchStart = _span();
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.position;
    final start = _pinchStart;
    if (_pointers.length != 2 || start == null || start <= 0) return;
    final ratio = _span() / start;
    if (ratio > 1.35 || ratio < 1 / 1.35) {
      final config = ref.read(plannerViewConfigProvider(_key));
      final current = MonthDensity.parse(config.option<String>('monthMode', 'titles'));
      final next = current.step(ratio > 1 ? 1 : -1);
      if (next != current) _setDensity(next);
      _pinchStart = _span();
    }
  }

  void _onPointerUp(PointerEvent e) {
    _pointers.remove(e.pointer);
    if (_pointers.length < 2) _pinchStart = null;
  }

  double _span() {
    final p = _pointers.values.toList();
    return p.length < 2 ? 0 : (p[0] - p[1]).distance;
  }

  Future<void> _pick() async {
    final weekStart = weekStartFor(ref.read(plannerViewConfigProvider(_key)), ref.read(userPreferencesProvider).weekStart);
    final picked = await showMiniMonth(context, initial: _month, weekStart: weekStart, highlight: [?_selected]);
    if (picked != null) _goTo(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(plannerViewConfigProvider(_key));
    final prefs = ref.watch(userPreferencesProvider);
    final today = ref.watch(plannerTodayProvider);
    final f = context.plannerFormat(use24h: prefs.use24h);
    final density = MonthDensity.parse(config.option<String>('monthMode', 'titles'));
    final listBelow = config.option<bool>('listBelow', false);
    final vertical = config.option<String>('swipe', 'vertical') == 'vertical';
    final expandInline = config.option<String>('tapAction', 'open_day') == 'expand';
    final notifier = ref.read(plannerViewConfigProvider(_key).notifier);
    return PlannerViewScaffold(
      viewKey: _key,
      toolbar: DatePagedToolbar(
        title: f.monthYear(_month),
        onPrevious: () => _goTo(addMonths(_month, -1)),
        onNext: () => _goTo(addMonths(_month, 1)),
        onToday: () => _goTo(today),
        onTitleTap: () => unawaited(_pick()),
        previousLabel: l.pvPrevious,
        nextLabel: l.pvNext,
        trailing: [
          PopupMenuButton<MonthDensity>(
            key: const Key('month-density'),
            tooltip: l.pvDensity,
            icon: const Icon(Icons.density_medium),
            initialValue: density,
            onSelected: _setDensity,
            itemBuilder: (_) => [
              for (final (d, label) in [
                (MonthDensity.dots, l.pvMonthDots),
                (MonthDensity.bars, l.pvMonthBars),
                (MonthDensity.titles, l.pvMonthTitles),
                (MonthDensity.titlesTimes, l.pvMonthTitlesTimes),
              ])
                CheckedPopupMenuItem(value: d, checked: d == density, child: Text(label)),
            ],
          ),
          PlannerFilterButton(viewKey: _key),
          PlannerMoreMenu(
            viewKey: _key,
            kind: ViewSettingsKind.calendar,
            extra: [
              ('listBelow', l.pvListBelow, () => notifier.change((c) => c.withOption('listBelow', !listBelow))),
              ('expand', l.pvExpandInline, () => notifier.change((c) => c.withOption('tapAction', expandInline ? 'open_day' : 'expand'))),
              ('swipe', l.pvSwipeVertical, () => notifier.change((c) => c.withOption('swipe', vertical ? 'horizontal' : 'vertical'))),
            ],
          ),
        ],
      ),
      body: PlannerKeys(
        onPrevious: () => _goTo(addMonths(_month, -1)),
        onNext: () => _goTo(addMonths(_month, 1)),
        onToday: () => _goTo(today),
        child: Column(
          children: [
            ActiveFilterBar(viewKey: _key),
            Expanded(
              flex: listBelow ? 5 : 1,
              child: Listener(
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerUp,
                child: PageView.builder(
                  key: const Key('month-pages'),
                  controller: _pages,
                  scrollDirection: vertical ? Axis.vertical : Axis.horizontal,
                  physics: _pinchStart != null ? const NeverScrollableScrollPhysics() : null,
                  onPageChanged: _onPage,
                  itemBuilder: (context, index) => _MonthPage(
                    viewKey: _key,
                    month: _monthAt(index),
                    config: config,
                    density: listBelow ? MonthDensity.dots : density,
                    selected: _selected,
                    expanded: expandInline && !listBelow ? _selected : null,
                    onTapDay: (d) {
                      if (listBelow || expandInline) {
                        setState(() => _selected = _selected == d && expandInline ? null : d);
                        ref.read(plannerAnchorProvider.notifier).set(d);
                      } else {
                        ref.read(plannerNavProvider).openView(context, 'day_list', date: d);
                      }
                    },
                  ),
                ),
              ),
            ),
            if (listBelow && _selected != null) Expanded(flex: 4, child: _DayItemsList(viewKey: _key, day: _selected!, config: config)),
          ],
        ),
      ),
      fab: PlannerFab(start: () => suggestedStart(_selected ?? today, ref.read(plannerNowProvider))),
    );
  }
}

class _MonthPage extends ConsumerWidget {
  const _MonthPage({
    required this.viewKey,
    required this.month,
    required this.config,
    required this.density,
    required this.selected,
    required this.expanded,
    required this.onTapDay,
  });

  final String viewKey;
  final LocalDate month;
  final PlannerViewConfig config;
  final MonthDensity density;
  final LocalDate? selected;
  final LocalDate? expanded;
  final ValueChanged<LocalDate> onTapDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = weekStartFor(config, ref.watch(userPreferencesProvider).weekStart);
    final weeks = monthWeeks(month, weekStart);
    final range = DayRange(weeks.first.first, weeks.length * 7);
    final items = filteredItems(ref, range, config).value ?? const <PlannerItem>[];
    final today = ref.watch(plannerTodayProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final narrow = DateFormat('EEEEE', locale);
    final c = context.colors;
    final expandedWeek = expanded == null ? -1 : weeks.indexWhere((w) => w.contains(expanded));
    return Column(
      key: ValueKey('month-${month.toIso()}'),
      children: [
        Row(
          children: [
            for (final d in weeks.first)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Space.xxs),
                  child: Text(
                    narrow.format(d.toDateTimeUtc()),
                    textAlign: TextAlign.center,
                    style: context.text.labelSmall?.copyWith(color: d.weekday.isWeekend ? c.outline : c.onSurfaceVariant),
                  ),
                ),
              ),
          ],
        ),
        for (final (i, week) in weeks.indexed) ...[
          Expanded(
            flex: 10,
            child: Row(
              children: [
                for (final d in week)
                  Expanded(
                    child: _DayCell(
                      viewKey: viewKey,
                      day: d,
                      inMonth: d.month == month.month,
                      isToday: d == today,
                      selected: d == selected,
                      density: density,
                      items: dayListOrder(itemsOnDay(items, d)),
                      config: config,
                      onTap: () => onTapDay(d),
                    ),
                  ),
              ],
            ),
          ),
          if (i == expandedWeek) Expanded(flex: 16, child: _DayItemsList(viewKey: viewKey, day: expanded!, config: config)),
        ],
      ],
    );
  }
}

class _DayCell extends ConsumerWidget {
  const _DayCell({
    required this.viewKey,
    required this.day,
    required this.inMonth,
    required this.isToday,
    required this.selected,
    required this.density,
    required this.items,
    required this.config,
    required this.onTap,
  });

  final String viewKey;
  final LocalDate day;
  final bool inMonth;
  final bool isToday;
  final bool selected;
  final MonthDensity density;
  final List<PlannerItem> items;
  final PlannerViewConfig config;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final f = context.plannerFormat(use24h: ref.watch(userPreferencesProvider).use24h);
    final colors = viewColors(context, ref, config);
    final commands = PlannerCommands(context, ref);
    Future<void> drop(PlannerItem item) async {
      if (item.startLocal.date == day) return;
      final start = item.allDay ? day.atStartOfDay : day.atTime(item.startLocal.time);
      await commands.reschedule(item, start: start, message: l.pvMovedSnack(f.dayShort(day)));
    }

    final weekend = day.weekday.isWeekend;
    return DragTarget<PlannerItem>(
      onAcceptWithDetails: (d) => unawaited(drop(d.data)),
      builder: (context, candidates, _) => Semantics(
        button: true,
        selected: selected,
        label: '${f.dayLong(day)}, ${l.pvItemsCount(items.length)}',
        onTap: onTap,
        child: GestureDetector(
          key: ValueKey('month-day-${day.toIso()}'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onLongPress: () => unawaited(commands.quickCreate(start: day.atStartOfDay, duration: 1440, allDay: true)),
          child: Container(
            decoration: BoxDecoration(
              color: candidates.isNotEmpty
                  ? c.primaryContainer.withValues(alpha: 0.5)
                  : (weekend ? c.surfaceContainerHighest.withValues(alpha: 0.4) : null),
              border: BorderDirectional(
                top: BorderSide(color: c.outlineVariant.withValues(alpha: 0.6), width: 0.5),
                end: BorderSide(color: c.outlineVariant.withValues(alpha: 0.6), width: 0.5),
              ),
            ),
            child: Opacity(
              opacity: inMonth ? 1 : 0.45,
              child: LayoutBuilder(
                builder: (context, box) => ClipRect(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Center(
                          child: Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isToday ? c.primary : (selected ? c.secondaryContainer : null),
                            ),
                            child: Text(
                              f.number(day.day),
                              style: context.text.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isToday ? c.onPrimary : c.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(child: _content(context, box, colors, f)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, BoxConstraints box, ItemColorResolver colors, AppFormat f) {
    if (items.isEmpty) return const SizedBox.shrink();
    switch (density) {
      case MonthDensity.dots:
        final shown = items.take(4).toList();
        return Center(
          child: Wrap(
            spacing: 2,
            runSpacing: 2,
            alignment: WrapAlignment.center,
            children: [
              for (final i in shown)
                Container(width: 5, height: 5, decoration: BoxDecoration(color: colors.of(i).accent, shape: BoxShape.circle)),
              if (items.length > shown.length)
                Text('+${items.length - shown.length}', style: const TextStyle(fontSize: 8)),
            ],
          ),
        );
      case MonthDensity.bars:
        final fit = math.max(1, ((box.maxHeight - 26) / 6).floor());
        return Column(
          children: [
            for (final i in items.take(fit))
              Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                decoration: BoxDecoration(color: colors.of(i).accent, borderRadius: BorderRadius.circular(2)),
              ),
          ],
        );
      case MonthDensity.titles:
      case MonthDensity.titlesTimes:
        const chipHeight = 15.0;
        final fit = math.max(0, ((box.maxHeight - 26) / (chipHeight + 1)).floor());
        final overflow = items.length > fit;
        final shown = items.take(overflow ? math.max(0, fit - 1) : fit).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final i in shown) _MonthChip(viewKey: viewKey, item: i, colors: colors.of(i), times: density == MonthDensity.titlesTimes, format: f),
            if (overflow)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 2),
                child: Text('+${items.length - shown.length}', style: context.text.labelSmall?.copyWith(fontSize: 9)),
              ),
          ],
        );
    }
  }
}

/// A one-line chip in a month cell; long-press drags it to another day.
class _MonthChip extends StatelessWidget {
  const _MonthChip({required this.viewKey, required this.item, required this.colors, required this.times, required this.format});

  final String viewKey;
  final PlannerItem item;
  final TileColors colors;
  final bool times;
  final AppFormat format;

  @override
  Widget build(BuildContext context) {
    final text = times && !item.allDay ? '${format.timeOf(item.startLocal)} ${item.title}' : item.title;
    final chip = Container(
      height: 15,
      margin: const EdgeInsets.only(left: 1, right: 1, bottom: 1),
      padding: const EdgeInsetsDirectional.only(start: 2),
      decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(3)),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: TextStyle(
          fontSize: 9.5,
          height: 1.4,
          color: colors.foreground,
          decoration: item.isDone ? TextDecoration.lineThrough : null,
        ),
      ),
    );
    return LongPressDraggable<PlannerItem>(
      data: item,
      feedback: Material(elevation: 4, borderRadius: BorderRadius.circular(3), child: SizedBox(width: 96, child: chip)),
      childWhenDragging: Opacity(opacity: 0.3, child: chip),
      child: KeyedSubtree(key: ValueKey('month-chip-${item.key}'), child: chip),
    );
  }
}

/// The items of one day as chips (list-below mode and inline expansion).
class _DayItemsList extends ConsumerWidget {
  const _DayItemsList({required this.viewKey, required this.day, required this.config});

  final String viewKey;
  final LocalDate day;
  final PlannerViewConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = context.plannerFormat(use24h: ref.watch(userPreferencesProvider).use24h);
    final items = dayListOrder(filteredItems(ref, DayRange(day, 1), config).value ?? const <PlannerItem>[]);
    final colors = viewColors(context, ref, config);
    return Container(
      key: ValueKey('month-day-list-${day.toIso()}'),
      color: context.colors.surfaceContainerLow,
      child: ListView(
        padding: const EdgeInsets.all(Space.sm),
        children: [
          Row(
            children: [
              Expanded(child: Text(f.dayLong(day), style: context.text.titleSmall)),
              TextButton(
                onPressed: () => ref.read(plannerNavProvider).openView(context, 'day_list', date: day),
                child: Text(l.pvOpenDay),
              ),
            ],
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(Space.sm),
              child: Text(l.pvEmptyDay, style: context.text.bodySmall),
            ),
          for (final i in items)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xs),
              child: PlannerItemChip(viewKey: viewKey, item: i, colors: colors.of(i), dense: true),
            ),
        ],
      ),
    );
  }
}
