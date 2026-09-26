import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/presentation/views/day_list_view.dart';
import 'package:everslot/features/planner/presentation/views/time_grid_view.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
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
];
