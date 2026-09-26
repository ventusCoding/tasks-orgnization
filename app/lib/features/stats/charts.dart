/// Everslot chart kit ([6.2]) — the public, stable API other features reuse (Habits, Quit, Today).
///
/// Build a chart model from `chart_data.dart` (`TimeSeriesData`, `BarData`, `CalendarData`,
/// `RingData`, `StreakData`, `PunchCardData`, `MilestoneData`, `CounterData`…) and render it with
/// [ChartView] (bare chart) or [ChartFrame] (title, legend, ⓘ, "view as table", states). KPI numbers
/// use [KpiTile]. Wrap a subtree in [ChartPrefs] to pass 12/24 h, digits, week start and day start.
/// Charts never expose `fl_chart` types.
library;

export 'domain/chart_data.dart';
export 'domain/stats_types.dart' show ChartKind, MetricDirection, StatUnit;
export 'presentation/charts/bars_chart.dart' show BarsChart;
export 'presentation/charts/calendar_heatmap.dart' show CalendarHeatmap;
export 'presentation/charts/chart_frame.dart' show ChartFrame, ChartFrameStatus;
export 'presentation/charts/chart_support.dart' show ChartPrefs, chartWeekStart, lttb, niceScale, statFormatOf;
export 'presentation/charts/chart_table.dart' show ChartDataTable;
export 'presentation/charts/chart_theme.dart' show ChartPattern, ChartTheme;
export 'presentation/charts/chart_view.dart' show ChartGroupView, ChartView;
export 'presentation/charts/composition_charts.dart' show DonutChart, ParetoChart;
export 'presentation/charts/kpi_tile.dart' show DeltaChip, KpiSize, KpiTile, Sparkline;
export 'presentation/charts/pattern_charts.dart' show PunchCardChart, StreakChart;
export 'presentation/charts/progress_visuals.dart'
    show BulletChart, CounterTicker, LiveCounter, MilestoneBars, ProgressRings;
export 'presentation/charts/simple_views.dart' show RankedList, StatusTimelineBar, ValueTilesView;
export 'presentation/charts/time_series_chart.dart' show TimeSeriesChart;
export 'presentation/format/stat_format.dart' show DeltaArrow, DeltaView, StatFormat;
