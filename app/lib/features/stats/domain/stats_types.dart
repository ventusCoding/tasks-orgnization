/// Core enums of the Insights feature (T6.1.06, T6.1.07). Pure Dart.
library;

/// Scope a metric is declared for (arch §6.12).
enum MetricScope {
  task,
  series,
  planner,
  checklistItem,
  checklist,
  checklists,
  habit,
  habits,
  quit,
  global;

  /// Data domains the scope reads (used for invalidation).
  Set<StatsDomain> get domains => switch (this) {
    task || series || planner => const {StatsDomain.planner},
    checklistItem || checklist || checklists => const {StatsDomain.checklists},
    habit || habits || quit => const {StatsDomain.habits},
    global => StatsDomain.values.toSet(),
  };

  /// Whether the scope needs an entity id.
  bool get needsId => switch (this) {
    task || series || checklistItem || checklist || habit || quit => true,
    _ => false,
  };
}

/// Per-domain data version counters (T6.1.13).
enum StatsDomain { planner, checklists, habits, settings, notifications }

/// Unit of a metric value (drives formatting, T6.1.07).
enum StatUnit {
  count,

  /// Minutes (formatted "1 h 25 min" / "1:25").
  minutes,
  hours,
  days,

  /// A ratio in [0, 1] shown as a percentage.
  percent,

  /// Percentage points (rate deltas).
  pp,

  /// A plain ratio (e.g. 1.3×).
  ratio,
  currency,

  /// 0–100 score (strength is stored 0–1 and shown as 0–100).
  score,
  perDay,
  perWeek,

  /// Minute of the day (clock time).
  clock,

  /// A calendar date (value = epoch day).
  date,

  /// Seconds (craving durations).
  seconds,

  /// Bytes (attachments).
  bytes,
}

/// Whether higher or lower values are better (drives delta colors, never the only signal).
enum MetricDirection { higherIsBetter, lowerIsBetter, neutral }

/// Roadmap priority of a metric (P0 → P2).
enum MetricPriority { p0, p1, p2 }

/// Default visualization of a metric ([6.2]).
enum ChartKind {
  kpi,
  line,
  area,
  bars,
  stackedBars,
  groupedBars,
  horizontalBars,
  percentBars,
  donut,
  pareto,
  calendar,
  yearGrid,
  punchCard,
  streakBars,
  gantt,
  histogram,
  boxPlot,
  scatter,
  cfd,
  stackedArea,
  burn,
  radar,
  rose,
  treemap,
  matrix,
  km,
  forecast,
  bullet,
  ring,
  milestones,
  counter,
  tiles,
  list,
  statusTimeline,
  moveTimeline,
}

/// Tables a metric reads (registry metadata, T6.1.06 `requires`).
enum StatsTable {
  tasks,
  taskOccurrences,
  timeEntries,
  activityEvents,
  categories,
  entityTags,
  checklists,
  checklistItems,
  checklistRuns,
  attachments,
  habits,
  habitLogs,
  habitPauses,
  habitRevisions,
  goals,
  notifications,
  userSettings,
  syncOutbox,
}

/// Stable id normalization: `PL-X-01` → `PlX01` (used for l10n keys).
String metricKeyStem(String id) {
  final parts = id.split('-');
  final buffer = StringBuffer();
  for (final p in parts) {
    if (p.isEmpty) continue;
    final isNumber = int.tryParse(p) != null;
    buffer.write(
      isNumber ? p : p[0].toUpperCase() + p.substring(1).toLowerCase(),
    );
  }
  return buffer.toString();
}
