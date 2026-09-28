/// Insights entry points other features embed or open (stable API, like `charts.dart`).
///
/// - [TaskStatsPanel]: the "Stats" tab of the planner's occurrence / task sheet (T6.3.17).
/// - [openInsights]: pushes `/insights/<scope>[/<id>]` (habit detail "See all stats", checklist
///   menu, series history…); [drillPath] maps a chart drill reference to its entity route.
library;

export 'presentation/stats_navigation.dart' show drillPath, openDrillRef, openInsights;
export 'presentation/task_stats_panel.dart' show SeriesStatsLink, TaskStatsPanel;
