import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_periods.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/domain/habit_settings.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

bool _tzReady = false;

/// Initializes the tz database once for pure tests.
void ensureTz() {
  if (_tzReady) return;
  tzdata.initializeTimeZones();
  _tzReady = true;
}

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);

HabitPeriodService periodService({
  String zone = 'UTC',
  int dayStartMinutes = 0,
  Weekday weekStart = Weekday.monday,
}) {
  ensureTz();
  return HabitPeriodService(
    engine: RecurrenceEngine(TzZoneResolver()),
    currentZone: zone,
    dayStartsAt: LocalTime.fromMinuteOfDay(dayStartMinutes),
    weekStart: weekStart,
  );
}

BuildHabit buildHabit({
  String id = 'h1',
  String name = 'Push-ups',
  LocalDate? start,
  LocalDate? end,
  RecurrenceRule? schedule,
  HabitTarget goal = const HabitTarget.check(),
  String? zone,
  HabitSettings settings = HabitSettings.defaults,
  SkipPolicy skipPolicy = SkipPolicy.neutral,
  int freezesPerMonth = 0,
}) => BuildHabit(
  id: id,
  name: name,
  startDate: start ?? d(2026, 9, 1),
  endDate: end,
  sortKey: 'a0',
  goal: goal,
  schedule: schedule ?? RecurrenceRule(),
  timeZone: zone,
  settings: settings,
  skipPolicy: skipPolicy,
  freezesPerMonth: freezesPerMonth,
);

var _seq = 0;

HabitLogEntry log(
  HabitLogKind kind, {
  required String key,
  required DateTime at,
  String habitId = 'h1',
  double? value,
  LocalDate? localDate,
  String? id,
}) => HabitLogEntry(
  id: id ?? 'log-${_seq++}',
  habitId: habitId,
  kind: kind,
  loggedAt: at,
  localDate: localDate ?? LocalDate.parse(key.substring(0, 10)),
  occurrenceKey: key,
  value: value,
);

HabitRevision revision(
  String id,
  LocalDate from, {
  String habitId = 'h1',
  RecurrenceRule? schedule,
  HabitGoalType? goalType,
  double? target,
  TargetOp? op,
  String? unit,
}) => HabitRevision(
  id: id,
  habitId: habitId,
  effectiveFrom: from,
  schedule: schedule,
  goalType: goalType,
  targetValue: target,
  targetOp: op,
  unit: unit,
);
