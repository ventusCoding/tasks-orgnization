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
export 'presentation/charts/chart_samples.dart' show ChartSample, advancedChartSamples, allChartSamples, p0ChartSamples;
export 'presentation/charts/chart_share.dart'
    show
        ChartImageSharer,
        ChartShareCard,
        ChartShareSheet,
        ChartShareSheetState,
        PlatformChartImageSharer,
        captureChartPng,
        chartImageSharer,
        showChartShareSheet;
export 'presentation/charts/chart_support.dart'
    show ChartPrefs, anonymousNamesOf, chartWeekStart, lttb, niceScale, statFormatOf;
export 'presentation/charts/chart_table.dart' show ChartDataTable;
export 'presentation/charts/chart_theme.dart' show ChartPattern, ChartTheme;
export 'presentation/charts/chart_view.dart' show ChartGroupView, ChartView;
export 'presentation/charts/composition_charts.dart' show DonutChart, ParetoChart;
export 'presentation/charts/distribution_charts.dart' show BoxPlotChart, ForecastChart, HistogramChart, KmChart;
export 'presentation/charts/flow_charts.dart' show StackedAreaChart, StackedBands;
export 'presentation/charts/grid_charts.dart' show MatrixHeatmap, MatrixPainter, TreemapChart, squarify;
export 'presentation/charts/kpi_tile.dart' show DeltaChip, KpiSize, KpiTile, Sparkline;
export 'presentation/charts/pattern_charts.dart' show PunchCardChart, StreakChart;
export 'presentation/charts/progress_visuals.dart'
    show BulletChart, CounterTicker, LiveCounter, MilestoneBars, ProgressRings;
export 'presentation/charts/radial_charts.dart' show RadarChart, RoseChart, RosePainter;
export 'presentation/charts/scatter_chart.dart' show ScatterChart, ScatterPainter;
export 'presentation/charts/simple_views.dart' show RankedList, StatusTimelineBar, ValueTilesView;
export 'presentation/charts/time_series_chart.dart'
    show BucketWindow, ChartCrosshairScope, TimeSeriesChart, TimeSeriesChartState;
export 'presentation/charts/timeline_charts.dart' show GanttChart, MoveTimelineChart, assignLanes, sessionTone;
export 'presentation/format/stat_format.dart' show DeltaArrow, DeltaView, StatFormat;
