import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/domain/habit_settings.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';

/// Row ↔ domain mapping of the habit tables (T5.1.02). Wall-clock columns are ISO text; JSON
/// columns are text; money is stored as REAL and read back as an exact [Decimal].
abstract final class HabitMappers {
  static RecurrenceRule? _rule(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      return RecurrenceRule.decode(json);
    } on FormatException {
      return null;
    }
  }

  static HabitSettings _settings(String json) {
    try {
      return HabitSettings.fromJson(jsonDecode(json));
    } on FormatException {
      return HabitSettings.defaults;
    }
  }

  static Decimal? _decimal(double? value) => value == null ? null : Decimal.parse(value.toString());

  static Habit habit(HabitRow r) {
    final start = LocalDate.tryParse(r.startDate) ?? LocalDate.fromDateTime(r.createdAt);
    final end = r.endDate == null ? null : LocalDate.tryParse(r.endDate!);
    final settings = _settings(r.settings);
    if (r.kind == 'quit') {
      return QuitHabit(
        id: r.id,
        name: r.name,
        description: r.description,
        icon: r.icon,
        color: r.color,
        categoryId: r.categoryId,
        sectionId: r.sectionId,
        startDate: start,
        endDate: end,
        timeZone: r.timeZone,
        settings: settings,
        sortKey: r.sortKey,
        archivedAt: r.archivedAt,
        notifyMode: r.notifyMode,
        createdAt: r.createdAt,
        autoSuccess: r.autoSuccess,
        motivation: r.motivation,
        mode: QuitModeDb.parse(r.quitMode),
        substance: QuitSubstance.parse(r.quitSubstance),
        quitStartedAt: (r.quitStartedAt ?? r.createdAt).toUtc(),
        dailyLimit: r.dailyLimit,
        baselinePerDay: r.baselinePerDay ?? 0,
        unitCost: _decimal(r.unitCost),
        currency: r.currency,
        timePerUnitMinutes: r.timePerUnitMinutes,
        lifeMinutesPerUnit: r.lifeMinutesPerUnit,
        unit: r.unit,
      );
    }
    return BuildHabit(
      id: r.id,
      name: r.name,
      description: r.description,
      icon: r.icon,
      color: r.color,
      categoryId: r.categoryId,
      sectionId: r.sectionId,
      startDate: start,
      endDate: end,
      timeZone: r.timeZone,
      settings: settings,
      sortKey: r.sortKey,
      archivedAt: r.archivedAt,
      notifyMode: r.notifyMode,
      createdAt: r.createdAt,
      autoSuccess: r.autoSuccess,
      motivation: r.motivation,
      goal: HabitTarget(
        type: HabitGoalTypeDb.parse(r.goalType),
        target: r.targetValue,
        op: TargetOpDb.parse(r.targetOp),
        unit: r.unit,
      ),
      schedule: _rule(r.schedule) ?? RecurrenceRule(),
      skipPolicy: SkipPolicyDb.parse(r.skipPolicy),
      freezesPerMonth: r.freezesPerMonth,
    );
  }

  /// Column values of [h] (snake_case, SyncWriter conventions) — every user-editable column.
  static Map<String, Object?> habitColumns(Habit h) {
    final common = <String, Object?>{
      'kind': h.kind.name,
      'name': h.name.trim(),
      'description': _blankToNull(h.description),
      'icon': h.icon,
      'color': h.color,
      'category_id': h.categoryId,
      'section_id': h.sectionId,
      'start_date': h.startDate,
      'end_date': h.endDate,
      'time_zone': h.timeZone,
      'settings': h.settings.toJson(),
      'sort_key': h.sortKey,
      'archived_at': h.archivedAt,
      'notify_mode': h.notifyMode,
      'auto_success': h.autoSuccess,
      'motivation': _blankToNull(h.motivation),
    };
    switch (h) {
      case BuildHabit():
        return {
          ...common,
          'goal_type': h.goal.type.db,
          'target_value': h.goal.isMeasurable ? h.goal.target : null,
          'target_op': h.goal.isMeasurable ? h.goal.op.db : 'gte',
          'unit': h.goal.isMeasurable ? h.goal.unit : null,
          'schedule': h.schedule.toJson(),
          'skip_policy': h.skipPolicy.db,
          'freezes_per_month': h.freezesPerMonth,
        };
      case QuitHabit():
        return {
          ...common,
          'goal_type': 'check',
          'target_op': 'gte',
          'unit': h.unit,
          'quit_mode': h.mode.db,
          'quit_substance': h.substance?.db,
          'quit_started_at': h.quitStartedAt.toUtc(),
          'daily_limit': h.dailyLimit,
          'baseline_per_day': h.baselinePerDay,
          'unit_cost': h.unitCost?.toDouble(),
          'currency': h.currency,
          'time_per_unit_minutes': h.timePerUnitMinutes,
          'life_minutes_per_unit': h.lifeMinutesPerUnit,
        };
    }
  }

  static String? _blankToNull(String? s) => s == null || s.trim().isEmpty ? null : s.trim();

  static HabitLogEntry log(HabitLogRow r) => HabitLogEntry(
    id: r.id,
    habitId: r.habitId,
    kind: HabitLogKind.values.firstWhere((k) => k.name == r.kind, orElse: () => HabitLogKind.note),
    loggedAt: r.loggedAt.toUtc(),
    localDate: LocalDate.tryParse(r.localDate) ?? LocalDate.fromDateTime(r.loggedAt),
    occurrenceKey: r.occurrenceKey,
    value: r.value,
    mood: r.mood,
    intensity: r.intensity,
    resisted: r.resisted,
    trigger: r.trigger,
    place: r.place,
    coping: r.coping,
    durationSeconds: r.durationSeconds,
    note: r.note,
    source: r.source,
    createdAt: r.createdAt.toUtc(),
  );

  /// Column values of a log entry.
  static Map<String, Object?> logColumns(HabitLogEntry e) => {
    'habit_id': e.habitId,
    'occurrence_key': e.occurrenceKey,
    'kind': e.kind.name,
    'value': e.value,
    'logged_at': e.loggedAt.toUtc(),
    'local_date': e.localDate,
    'mood': e.mood,
    'intensity': e.kind == HabitLogKind.craving ? e.intensity : null,
    'resisted': e.resisted,
    'trigger': e.trigger,
    'place': e.place,
    'coping': e.coping,
    'duration_seconds': e.durationSeconds,
    'note': e.note,
    'source': e.source,
  };

  static PauseSpan pause(HabitPauseRow r) => PauseSpan(
    id: r.id,
    habitId: r.habitId,
    start: LocalDate.parse(r.startDate),
    end: r.endDate == null ? null : LocalDate.tryParse(r.endDate!),
    reason: r.reason,
  );

  static HabitRevision revision(HabitRevisionRow r) => HabitRevision(
    id: r.id,
    habitId: r.habitId,
    effectiveFrom: LocalDate.parse(r.effectiveFrom),
    schedule: _rule(r.schedule),
    goalType: r.goalType == null ? null : HabitGoalTypeDb.parse(r.goalType),
    targetValue: r.targetValue,
    targetOp: r.targetOp == null ? null : TargetOpDb.parse(r.targetOp),
    unit: r.unit,
    baselinePerDay: r.baselinePerDay,
    unitCost: _decimal(r.unitCost),
    dailyLimit: r.dailyLimit,
  );

  /// Revision snapshot columns of [h] (schedule/goal for build habits, economics for quit).
  static Map<String, Object?> revisionColumns(Habit h) => switch (h) {
    BuildHabit() => {
      'schedule': h.schedule.toJson(),
      'goal_type': h.goal.type.db,
      'target_value': h.goal.isMeasurable ? h.goal.target : null,
      'target_op': h.goal.isMeasurable ? h.goal.op.db : 'gte',
      'unit': h.goal.isMeasurable ? h.goal.unit : null,
      'baseline_per_day': null,
      'unit_cost': null,
      'daily_limit': null,
    },
    QuitHabit() => {
      'schedule': null,
      'goal_type': null,
      'target_value': null,
      'target_op': null,
      'unit': h.unit,
      'baseline_per_day': h.baselinePerDay,
      'unit_cost': h.unitCost?.toDouble(),
      'daily_limit': h.dailyLimit,
    },
  };

  static HabitSection section(HabitSectionRow r, String userId) {
    String? defaultKey;
    for (final (key, _, _, _) in DefaultSections.all) {
      if (Ids.habitSection(userId, key) == r.id) defaultKey = key;
    }
    return HabitSection(
      id: r.id,
      name: r.name,
      sortKey: r.sortKey,
      icon: r.icon,
      startTime: r.startTime == null ? null : LocalTime.tryParse(r.startTime!),
      endTime: r.endTime == null ? null : LocalTime.tryParse(r.endTime!),
      archived: r.archivedAt != null,
      defaultKey: defaultKey,
    );
  }

  static VocabEntry vocab(HabitVocabRow r) => VocabEntry(
    id: r.id,
    kind: VocabKind.parse(r.kind),
    name: r.name,
    sortKey: r.sortKey,
    icon: r.icon,
    color: r.color,
    archived: r.archivedAt != null,
  );
}

/// Deterministic ids of the habit feature (arch §9.2) that are not in `core/ids`.
abstract final class HabitIds {
  /// Revisions converge per (habit, effective date) — the server enforces the uniqueness.
  static String revision(String habitId, LocalDate effectiveFrom) =>
      Ids.v5('$habitId|${effectiveFrom.toIso()}|revision');

  /// Note log of a period (yes/no habit without a state row, T5.2.09).
  static String periodNote(String habitId, String key) => Ids.v5('$habitId|$key|note');

  /// The day's automatic health progress log (T8.2.14).
  static String healthProgress(String habitId, String day) => Ids.v5('$habitId|$day|health');

  /// Default vocabulary entries per user.
  static String vocab(String userId, String kind, String key) => Ids.v5('$userId|habit_vocab|$kind|$key');
}
