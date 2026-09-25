/// Everslot metrics: pure statistics and metric math for Insights (streaks, strength scores,
/// adherence ledgers, flow metrics, quit math, section catalogs PL-/CL-/HB-/QT-/GL-*).
///
/// Every function takes already-expanded inputs (occurrences, periods, logs, events), so the package
/// is independent of the recurrence engine and of the database. Results are `Stat`s — never `NaN`.
///
/// - Foundations (T6.1.01–T6.1.05, T6.1.14, T6.1.18, T6.1.19, T6.1.24–T6.1.26): `stat`,
///   `descriptive`, `rates`, `time_series`, `trend`, `period`, `min_data`, `circular`,
///   `group_tests`, `correlation`, `survival`, `forecast`, `goals`, `special_functions`.
/// - Core engines (T5.1.06, T5.3.03, T6.1.08–T6.1.11): `habit_period`, `occurrence_ledger`,
///   `streaks`, `strength`, `status_intervals`, `quit_calculator`.
/// - Section catalogs ([6.3]–[6.7]): `planner_facts`, `planner_metrics`, `checklist_metrics`,
///   `habit_metrics`, `quit_metrics`, `global_metrics`.
///
/// Wall-clock types (`LocalDate`, `LocalDateTime`, `LocalTime`, `Weekday`) come from
/// `package:everslot_recurrence`.
library;

export 'src/checklist_metrics.dart';
export 'src/circular.dart';
export 'src/correlation.dart';
export 'src/descriptive.dart';
export 'src/forecast.dart';
export 'src/global_metrics.dart';
export 'src/goals.dart';
export 'src/group_tests.dart';
export 'src/habit_metrics.dart';
export 'src/habit_period.dart';
export 'src/min_data.dart';
export 'src/occurrence_ledger.dart';
export 'src/period.dart';
export 'src/planner_facts.dart';
export 'src/planner_metrics.dart';
export 'src/quit_calculator.dart';
export 'src/quit_metrics.dart';
export 'src/rates.dart';
export 'src/special_functions.dart';
export 'src/stat.dart';
export 'src/status_intervals.dart';
export 'src/streaks.dart';
export 'src/strength.dart';
export 'src/survival.dart';
export 'src/time_series.dart';
export 'src/trend.dart';
