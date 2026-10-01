import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/data/work_settings.dart';
import 'package:everslot/features/planner/presentation/grid/grid_controller.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/grid/time_grid.dart';
import 'package:everslot/features/planner/presentation/grid/timeline_page.dart';
import 'package:everslot/features/planner/presentation/view_config/slot_size_sheet.dart';
import 'package:everslot/features/planner/presentation/views/accessible_list.dart';
import 'package:everslot/features/planner/presentation/views/backlog_drawer.dart';
import 'package:everslot/features/planner/presentation/views/first_use_hints.dart';
import 'package:everslot/features/planner/presentation/views/mini_month.dart';
import 'package:everslot/features/planner/presentation/views/plan_summary_views.dart';
import 'package:everslot/features/planner/presentation/views/planner_chrome.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Work week (T3.6.05): the N-day preset limited to work days, with visible hours following the
/// settings' work hours until the user picks other hours.
PlannerViewConfig workWeekTransform(PlannerViewConfig c, WorkSettings work) {
  var next = c.option<bool>('workWeek', true) ? c : c.withOption('workWeek', true);
  if (next.option<bool>('followWorkHours', true) && next.dayWindow.isFull) next = next.copyWith(dayWindow: work.hours);
  return next;
}

/// Host of the time-grid views (week table T3.4.01, N-day T3.6.04, work week T3.6.05): toolbar
/// (range title → mini-month, previous / next, Today, slot size, filters, menu), active filters,
/// the engine (or the accessible list) and the contextual FAB.
class TimeGridView extends ConsumerStatefulWidget {
  const TimeGridView({
    required this.args,
    this.configTransform,
    this.tileLayout = overlapStrategy,
    this.overlays = const [],
    this.menuExtra = const [],
    this.header,
    super.key,
  });

  final PlannerViewArgs args;
  final PlannerViewConfig Function(PlannerViewConfig c, WorkSettings work)? configTransform;
  final TileLayoutStrategy tileLayout;
  final List<OverlayPainterBuilder> overlays;

  /// View-specific entries of the overflow menu (value, label, action).
  final List<(String, String, VoidCallback)> menuExtra;

  /// Built above the grid with the visible days (e.g. the swimlane legend).
  final Widget Function(List<LocalDate> visibleDays)? header;

  @override
  ConsumerState<TimeGridView> createState() => _TimeGridViewState();
}

class _TimeGridViewState extends ConsumerState<TimeGridView> {
  final _grid = PlannerGridController();
  final _gridKey = GlobalKey<TimeGridState>();
  final _drawer = BacklogDrawerController();

  String get _key => widget.args.viewKey;

  @override
  void dispose() {
    _grid.dispose();
    _drawer.dispose();
    super.dispose();
  }

  Future<void> _today() async {
    final now = ref.read(plannerNowProvider);
    await _grid.jumpTo(now.date, minute: now.time.minuteOfDay.toDouble(), anchorFraction: 1 / 3);
  }

  /// *Plan your first task* (empty week): the editor at the next sensible start, like the FAB.
  void _newTask() {
    final today = ref.read(plannerTodayProvider);
    final start = suggestedStart(
      _grid.visibleDays.contains(today) ? today : (_grid.firstVisibleDay ?? today),
      ref.read(plannerNowProvider),
    );
    ref
        .read(plannerNavProvider)
        .newTask(context, start: start, duration: ref.read(plannerWorkSettingsProvider).defaultDuration);
  }

  Future<void> _farJump() async {
    final today = ref.read(plannerTodayProvider);
    final picked = await pickDate(context, initial: _grid.firstVisibleDay ?? today);
    if (picked != null) await _grid.jumpTo(picked, animate: false);
  }

  Future<void> _miniMonth(Weekday weekStart) async {
    final today = ref.read(plannerTodayProvider);
    final first = _grid.firstVisibleDay ?? today;
    final picked = await showMiniMonth(context, initial: first, weekStart: weekStart, highlight: _grid.visibleDays);
    if (picked != null) await _grid.jumpTo(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(plannerViewConfigProvider(_key));
    final work = ref.watch(plannerWorkSettingsProvider);
    final prefs = ref.watch(userPreferencesProvider);
    final today = ref.watch(plannerTodayProvider);
    final f = context.plannerFormat(use24h: prefs.use24h);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final listMode = ref.watch(plannerViewStateProvider(_key).select((s) => s?.extra['listMode'] == true));
    final transform = widget.configTransform;
    PlannerViewConfig apply(PlannerViewConfig c) => transform == null ? c : transform(c, work);
    final effective = apply(config);
    final weekStart = weekStartFor(effective, prefs.weekStart);
    final weekly = effective.paging == PagingMode.week;
    return PlannerViewScaffold(
      viewKey: _key,
      toolbar: ListenableBuilder(
        listenable: _grid,
        builder: (context, _) {
          final days = _grid.visibleDays;
          return DatePagedToolbar(
            title: days.isEmpty
                ? ''
                : [
                    rangeTitle(locale, days.first, days.last),
                    // T3.4.19: the week number of the first visible day.
                    if (effective.showWeekNumbers) l.pvWeekNumber(days.first.weekOfYear(weekStart).week),
                  ].join(' · '),
            onPrevious: () => unawaited(_grid.previous()),
            onNext: () => unawaited(_grid.next()),
            onToday: () => unawaited(_today()),
            onTodayLongPress: () => unawaited(_farJump()),
            onTitleTap: () => unawaited(_miniMonth(weekStart)),
            previousLabel: weekly ? l.pvPreviousWeek : l.pvPrevious,
            nextLabel: weekly ? l.pvNextWeek : l.pvNext,
            trailing: [
              SlotSizeButton(
                label: slotLabel(f, config.slotMinutes),
                onPressed: () => unawaited(showSlotSizeSheet(context, ref, viewKey: _key)),
              ),
              // The drawer toggle sits in the toolbar from 560 dp, in the menu on phones.
              if (MediaQuery.sizeOf(context).width >= 560) BacklogDrawerButton(controller: _drawer),
              PlannerFilterButton(viewKey: _key),
              PlannerMoreMenu(
                viewKey: _key,
                extra: [
                  ...widget.menuExtra,
                  if (MediaQuery.sizeOf(context).width < 560) ('backlog', l.pvToggleBacklog, _drawer.toggle),
                ],
              ),
            ],
          );
        },
      ),
      body: Column(
        children: [
          ActiveFilterBar(viewKey: _key),
          if (!listMode) FirstUseHintCard(viewKey: _key, slotLabel: slotLabel(f, config.slotMinutes)),
          if (!listMode && widget.header != null)
            ListenableBuilder(listenable: _grid, builder: (context, _) => widget.header!(_grid.visibleDays)),
          Expanded(
            child: listMode
                ? AccessibleRangeList(
                    controller: _grid,
                    start: (ref.read(plannerAnchorProvider) ?? widget.args.date ?? today).startOfWeek(weekStart),
                  )
                : ListenableBuilder(
                    listenable: _grid,
                    builder: (context, child) => BacklogDrawerHost(
                      viewKey: _key,
                      controller: _drawer,
                      visibleDays: _grid.visibleDays,
                      dropSource: () => _gridKey.currentState,
                      child: child!,
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: TimeGrid(
                            key: _gridKey,
                            onDropOutside: (item, global) async =>
                                _drawer.contains(global) && await unscheduleToDrawer(context, ref, item),
                            viewKey: _key,
                            controller: _grid,
                            initialDate: widget.args.date,
                            configTransform: transform == null ? null : apply,
                            tileLayout: widget.tileLayout,
                            overlayPainters: widget.overlays,
                            onRulerDoubleTap: () => unawaited(showSlotSizeSheet(context, ref, viewKey: _key)),
                          ),
                        ),
                        Positioned.fill(
                          child: ListenableBuilder(
                            listenable: _grid,
                            builder: (context, _) => EmptyRangeCard(days: _grid.visibleDays, onPlan: _newTask),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomBar: ListenableBuilder(
        listenable: _grid,
        builder: (context, _) => PlanSummaryFooter(viewKey: _key, days: _grid.visibleDays),
      ),
      fab: PlannerFab(
        start: () => suggestedStart(
          _grid.visibleDays.contains(today) ? today : (_grid.firstVisibleDay ?? today),
          ref.read(plannerNowProvider),
        ),
      ),
    );
  }
}
