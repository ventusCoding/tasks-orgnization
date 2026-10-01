import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/presentation/views/agenda_view.dart';
import 'package:everslot/features/planner/presentation/views/day_list_view.dart';
import 'package:everslot/features/planner/presentation/views/month_view.dart';
import 'package:everslot/features/planner/presentation/views/multi_week_view.dart';
import 'package:everslot/features/planner/presentation/views/quarter_view.dart';
import 'package:everslot/features/planner/presentation/views/time_grid_view.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:everslot/features/planner/presentation/views/week_list_view.dart';
import 'package:everslot/features/planner/presentation/views/year_view.dart';
import 'package:material_ui/material_ui.dart';

/// Every planner view (T3.6.01). Adding a view = one entry here; P2 views ship dark (tier m3).
List<PlannerViewEntry> buildPlannerViewEntries() => [
  PlannerViewEntry(
    id: 'week_table',
    type: PlannerViewType.weekTable,
    icon: Icons.calendar_view_week,
    label: (l) => l.pvViewWeekTable,
    builder: (a) => TimeGridView(args: a),
    tier: ViewTier.mvp,
    timeBased: true,
    supportsSlotSize: true,
    supportsDrag: true,
  ),
  PlannerViewEntry(
    id: 'day_list',
    type: PlannerViewType.dayList,
    icon: Icons.view_day_outlined,
    label: (l) => l.pvViewDayList,
    builder: (a) => DayListView(args: a),
    tier: ViewTier.mvp,
    timeBased: true,
    supportsSlotSize: true,
    supportsDrag: true,
  ),
  PlannerViewEntry(
    id: 'n_day',
    type: PlannerViewType.nDay,
    icon: Icons.view_column_outlined,
    label: (l) => l.pvViewNDay,
    builder: (a) => TimeGridView(args: a),
    timeBased: true,
    supportsSlotSize: true,
    supportsDrag: true,
  ),
  PlannerViewEntry(
    id: 'work_week',
    type: PlannerViewType.nDay,
    icon: Icons.work_outline,
    label: (l) => l.pvViewWorkWeek,
    builder: (a) => TimeGridView(args: a, configTransform: workWeekTransform),
    timeBased: true,
    supportsSlotSize: true,
    supportsDrag: true,
  ),
  PlannerViewEntry(
    id: 'week_list',
    type: PlannerViewType.weekList,
    icon: Icons.view_agenda_outlined,
    label: (l) => l.pvViewWeekList,
    builder: (a) => WeekListView(args: a),
    supportsDrag: true,
  ),
  PlannerViewEntry(
    id: 'month',
    type: PlannerViewType.month,
    icon: Icons.calendar_month_outlined,
    label: (l) => l.pvViewMonth,
    builder: (a) => MonthView(args: a),
    supportsDrag: true,
  ),
  PlannerViewEntry(
    id: 'agenda',
    type: PlannerViewType.agenda,
    icon: Icons.view_list_outlined,
    label: (l) => l.pvViewAgenda,
    builder: (a) => AgendaView(args: a),
  ),
  PlannerViewEntry(
    id: 'year',
    type: PlannerViewType.year,
    icon: Icons.grid_view_outlined,
    label: (l) => l.pvViewYear,
    builder: (a) => YearView(args: a),
  ),
  PlannerViewEntry(
    id: 'multi_week',
    type: PlannerViewType.multiWeek,
    icon: Icons.calendar_view_month,
    label: (l) => l.pvViewMultiWeek,
    builder: (a) => MultiWeekView(args: a),
    tier: ViewTier.m3,
    supportsDrag: true,
  ),
  PlannerViewEntry(
    id: 'quarter',
    type: PlannerViewType.quarter,
    icon: Icons.view_module_outlined,
    label: (l) => l.pvViewQuarter,
    builder: (a) => QuarterView(args: a),
    tier: ViewTier.m3,
  ),
];
