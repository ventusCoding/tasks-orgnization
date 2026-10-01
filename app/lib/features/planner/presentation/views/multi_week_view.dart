import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/time_grid.dart';
import 'package:everslot/features/planner/presentation/view_config/view_settings_sheet.dart';
import 'package:everslot/features/planner/presentation/views/item_chip.dart';
import 'package:everslot/features/planner/presentation/views/mini_month.dart';
import 'package:everslot/features/planner/presentation/views/month_view.dart';
import 'package:everslot/features/planner/presentation/views/planner_chrome.dart';
import 'package:everslot/features/planner/presentation/views/planner_keys.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

/// Number of week rows of the multi-week view (view config `options.weeks`, 2–6).
int multiWeekCount(PlannerViewConfig config) => config.option<int>('weeks', 4).clamp(2, 6);

/// Multi-week view (T3.6.11, BusyCal style): 2–6 rolling week rows starting this week with
/// month-style chips. Arrows and vertical swipes move by one week; a vertical pinch changes the
/// number of weeks (spread = fewer, pinch = more). Tap a day → Day list; long-press creates; drag a
/// chip to another day keeps its time.
class MultiWeekView extends ConsumerStatefulWidget {
  const MultiWeekView({required this.args, super.key});

  final PlannerViewArgs args;

  @override
  ConsumerState<MultiWeekView> createState() => _MultiWeekViewState();
}

class _MultiWeekViewState extends ConsumerState<MultiWeekView> {
  late LocalDate _anchor;

  // Vertical pinch: two pointers; one week per 30 % change of their vertical distance.
  final Map<int, Offset> _pointers = {};
  double? _pinchStart;

  String get _key => widget.args.viewKey;

  @override
  void initState() {
    super.initState();
    _anchor =
        widget.args.date ??
        ref.read(plannerAnchorProvider) ??
        ref.read(plannerViewStateProvider(_key))?.anchor ??
        ref.read<LocalDate>(plannerTodayProvider);
  }

  Weekday get _weekStart =>
      weekStartFor(ref.read(plannerViewConfigProvider(_key)), ref.read(userPreferencesProvider).weekStart);

  void _go(LocalDate date) {
    final start = date.startOfWeek(_weekStart);
    setState(() => _anchor = start);
    ref.read(plannerAnchorProvider.notifier).set(start);
    ref.read(plannerViewStateProvider(_key).notifier).update((s) => s.copyWith(anchor: start));
  }

  void _setWeeks(int weeks) =>
      ref.read(plannerViewConfigProvider(_key).notifier).change((c) => c.withOption('weeks', weeks.clamp(2, 6)));

  Future<void> _pick() async {
    final picked = await showMiniMonth(context, initial: _anchor, weekStart: _weekStart, highlight: [_anchor]);
    if (picked != null) _go(picked);
  }

  void _onPointerDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.position;
    if (_pointers.length == 2) setState(() => _pinchStart = _span());
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.position;
    final start = _pinchStart;
    if (_pointers.length != 2 || start == null || start <= 0) return;
    final ratio = _span() / start;
    if (ratio > 1.3 || ratio < 1 / 1.3) {
      final weeks = multiWeekCount(ref.read(plannerViewConfigProvider(_key)));
      _setWeeks(weeks + (ratio > 1 ? -1 : 1));
      _pinchStart = _span();
    }
  }

  void _onPointerUp(PointerEvent e) {
    _pointers.remove(e.pointer);
    if (_pointers.length < 2 && _pinchStart != null) setState(() => _pinchStart = null);
  }

  double _span() {
    final p = _pointers.values.toList();
    return p.length < 2 ? 0 : (p[0].dy - p[1].dy).abs();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(plannerViewConfigProvider(_key));
    final prefs = ref.watch(userPreferencesProvider);
    final weekStart = weekStartFor(config, prefs.weekStart);
    final today = ref.watch(plannerTodayProvider);
    final weeks = multiWeekCount(config);
    final start = _anchor.startOfWeek(weekStart);
    final last = start.plusDays(weeks * 7 - 1);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final density = MonthDensity.parse(config.option<String>('monthMode', 'titles'));
    final items = filteredItems(ref, DayRange(start, weeks * 7), config).value ?? const <PlannerItem>[];
    final monthDay = DateFormat.MMMd(locale);
    return PlannerViewScaffold(
      viewKey: _key,
      toolbar: DatePagedToolbar(
        title: rangeTitle(locale, start, last),
        onPrevious: () => _go(start.plusDays(-7)),
        onNext: () => _go(start.plusDays(7)),
        onToday: () => _go(today),
        onTitleTap: () => unawaited(_pick()),
        previousLabel: l.pvPreviousWeek,
        nextLabel: l.pvNextWeek,
        trailing: [
          PopupMenuButton<int>(
            key: const Key('multi-week-count'),
            tooltip: l.pvWeeksCount(weeks),
            icon: const Icon(Icons.view_week_outlined),
            initialValue: weeks,
            onSelected: _setWeeks,
            itemBuilder: (_) => [
              for (var n = 2; n <= 6; n++)
                CheckedPopupMenuItem(value: n, checked: n == weeks, child: Text(l.pvWeeksCount(n))),
            ],
          ),
          PlannerFilterButton(viewKey: _key),
          PlannerMoreMenu(viewKey: _key, kind: ViewSettingsKind.calendar),
        ],
      ),
      body: PlannerKeys(
        onPrevious: () => _go(start.plusDays(-7)),
        onNext: () => _go(start.plusDays(7)),
        onToday: () => _go(today),
        child: Column(
          children: [
            ActiveFilterBar(viewKey: _key),
            _WeekdayHeader(weekStart: weekStart),
            Expanded(
              child: Listener(
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerUp,
                child: GestureDetector(
                  onVerticalDragEnd: _pinchStart != null
                      ? null
                      : (d) {
                          final v = d.primaryVelocity ?? 0;
                          if (v.abs() < 300) return;
                          _go(start.plusDays(v < 0 ? 7 : -7));
                        },
                  child: Column(
                    key: ValueKey('multi-week-${start.toIso()}-$weeks'),
                    children: [
                      for (var w = 0; w < weeks; w++)
                        Expanded(
                          child: Row(
                            children: [
                              for (var i = 0; i < 7; i++)
                                Expanded(
                                  child: Builder(
                                    builder: (context) {
                                      final d = start.plusDays(w * 7 + i);
                                      return MonthDayCell(
                                        viewKey: _key,
                                        day: d,
                                        inMonth: true,
                                        isToday: d == today,
                                        selected: false,
                                        density: density,
                                        items: dayListOrder(itemsOnDay(items, d)),
                                        config: config,
                                        numberText: d.day == 1 || (w == 0 && i == 0)
                                            ? monthDay.format(d.toDateTimeUtc())
                                            : null,
                                        onTap: () =>
                                            ref.read(plannerNavProvider).openView(context, 'day_list', date: d),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
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

/// Narrow weekday initials in week-start order.
class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.weekStart});

  final Weekday weekStart;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final narrow = DateFormat('EEEEE', locale);
    final c = context.colors;
    return Row(
      children: [
        for (final w in Weekday.ordered(weekStart))
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.xxs),
              child: Text(
                narrow.format(DateTime.utc(2024, 1, w.iso)),
                textAlign: TextAlign.center,
                style: context.text.labelSmall?.copyWith(color: w.isWeekend ? c.outline : c.onSurfaceVariant),
              ),
            ),
          ),
      ],
    );
  }
}
