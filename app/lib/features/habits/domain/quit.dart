import 'package:decimal/decimal.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot_metrics/everslot_metrics.dart'
    show DayBoundaries, HabitLogKind, MilestoneProgress, QuitCalculator, QuitLog, QuitMilestone, QuitTracker;
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate;
import 'package:meta/meta.dart';

/// Log kinds that matter for quit trackers.
const quitLogKinds = {
  HabitLogKind.relapse,
  HabitLogKind.use,
  HabitLogKind.restart,
  HabitLogKind.clean,
  HabitLogKind.craving,
  HabitLogKind.pledge,
  HabitLogKind.note,
};

/// The metrics tracker of [habit] (economics piecewise over [revisions]).
QuitTracker quitTrackerOf(QuitHabit habit, List<HabitRevision> revisions, DayBoundaries days) => QuitTracker(
  habit.quitStartedAt,
  mode: habit.mode,
  days: days,
  autoSuccess: habit.autoSuccess,
  baselinePerDay: habit.baselinePerDay,
  unitCost: habit.unitCost,
  dailyLimit: habit.dailyLimit,
  revisions: [
    for (final r in revisions)
      if (r.habitId == habit.id) r.toQuitRevision(),
  ],
  timePerUnitMinutes: habit.timePerUnitMinutes,
  lifeMinutesPerUnit: habit.lifeMinutesPerUnit,
  substance: habit.substance?.db,
  currency: habit.currency,
);

/// Quit-relevant logs of [habitId] (metrics form).
List<QuitLog> quitLogsOf(Iterable<HabitLogEntry> logs, String habitId) => [
  for (final l in logs)
    if (l.habitId == habitId && quitLogKinds.contains(l.kind)) l.toQuitLog(),
];

/// The quit calculator of [habit] at [now] — the single implementation of quit math (T5.3.03).
QuitCalculator quitCalculatorOf(
  QuitHabit habit, {
  required List<HabitRevision> revisions,
  required Iterable<HabitLogEntry> logs,
  required DayBoundaries days,
  required DateTime now,
}) => QuitCalculator(quitTrackerOf(habit, revisions, days), quitLogsOf(logs, habit.id), now: now);

/// Pledge streak (T5.3.13): consecutive days up to [today] (or yesterday when today has no pledge
/// yet) with a `pledge` log.
int pledgeStreak(Iterable<HabitLogEntry> logs, String habitId, LocalDate today) {
  final days = {
    for (final l in logs)
      if (l.habitId == habitId && l.kind == HabitLogKind.pledge) l.localDate,
  };
  var d = today;
  if (!days.contains(d)) d = d.minusDays(1);
  var n = 0;
  while (days.contains(d)) {
    n++;
    d = d.minusDays(1);
  }
  return n;
}

/// One source of a health milestone.
@immutable
class MilestoneSource {
  const MilestoneSource(this.name, this.url);

  factory MilestoneSource.fromJson(Map<String, Object?> json) =>
      MilestoneSource(json['name']! as String, json['url']! as String);

  final String name;
  final String url;
}

/// Localized texts of one milestone row.
@immutable
class MilestoneText {
  const MilestoneText({required this.title, required this.body, this.range});

  factory MilestoneText.fromJson(Map<String, Object?> json) => MilestoneText(
    title: json['title']! as String,
    body: json['body']! as String,
    range: json['range'] as String?,
  );

  final String title;
  final String body;

  /// Range note where sources differ ("WHO 1–9 months, NHS 3–9, CDC/ACS 1–12").
  final String? range;
}

/// A smoking-cessation health milestone (T5.3.11): offset (or range), localized texts, sources.
@immutable
class HealthMilestone {
  const HealthMilestone({
    required this.id,
    required this.tMin,
    required this.texts,
    required this.sources,
    this.tMax,
    this.info = false,
  });

  factory HealthMilestone.fromJson(Map<String, Object?> json) => HealthMilestone(
    id: json['id']! as String,
    tMin: Duration(minutes: (json['tMinMinutes']! as num).toInt()),
    tMax: json['tMaxMinutes'] == null ? null : Duration(minutes: (json['tMaxMinutes']! as num).toInt()),
    info: json['info'] == true,
    texts: {
      for (final e in (json['text']! as Map).entries)
        e.key as String: MilestoneText.fromJson(Map<String, Object?>.from(e.value as Map)),
    },
    sources: [
      for (final s in json['sources']! as List) MilestoneSource.fromJson(Map<String, Object?>.from(s as Map)),
    ],
  );

  final String id;
  final Duration tMin;
  final Duration? tMax;

  /// Information row without a progress bar (life-expectancy notes).
  final bool info;

  /// Language code → texts.
  final Map<String, MilestoneText> texts;
  final List<MilestoneSource> sources;

  bool get isRange => tMax != null && tMax! > tMin;

  MilestoneText textFor(String languageCode) => texts[languageCode] ?? texts['en']!;

  QuitMilestone toMetrics() => QuitMilestone(id, tMin: tMin, tMax: tMax);
}

/// A withdrawal phase note (days 1–3 peak, week 1, weeks 2–4).
@immutable
class WithdrawalPhase {
  const WithdrawalPhase({required this.id, required this.fromDay, required this.toDay, required this.texts});

  factory WithdrawalPhase.fromJson(Map<String, Object?> json) => WithdrawalPhase(
    id: json['id']! as String,
    fromDay: (json['fromDay']! as num).toInt(),
    toDay: (json['toDay']! as num).toInt(),
    texts: {for (final e in (json['text']! as Map).entries) e.key as String: e.value as String},
  );

  final String id;
  final int fromDay;
  final int toDay;
  final Map<String, String> texts;

  String textFor(String languageCode) => texts[languageCode] ?? texts['en']!;
}

/// Life-regained constants with citations (population estimates).
@immutable
class LifeEstimate {
  const LifeEstimate({required this.key, required this.minutesPerUnit, required this.source});

  factory LifeEstimate.fromJson(Map<String, Object?> json) => LifeEstimate(
    key: json['key']! as String,
    minutesPerUnit: (json['minutesPerUnit']! as num).toDouble(),
    source: MilestoneSource.fromJson(Map<String, Object?>.from(json['source']! as Map)),
  );

  final String key;
  final double minutesPerUnit;
  final MilestoneSource source;
}

/// The bundled smoking health-milestone content (`assets/content/quit_milestones_smoking.json`).
@immutable
class MilestoneContent {
  const MilestoneContent({
    required this.version,
    required this.substance,
    required this.disclaimer,
    required this.clockNote,
    required this.milestones,
    required this.withdrawal,
    required this.lifeEstimates,
  });

  /// Parses and validates the asset; throws [FormatException] when a rule is broken (every row has
  /// ≥ 1 source URL and texts in en, fr and ar).
  factory MilestoneContent.fromJson(Map<String, Object?> json) {
    Map<String, String> texts(Object? value) => {
      for (final e in (value! as Map).entries) e.key as String: e.value as String,
    };
    final content = MilestoneContent(
      version: (json['v']! as num).toInt(),
      substance: json['substance']! as String,
      disclaimer: texts(json['disclaimer']),
      clockNote: texts(json['clockNote']),
      milestones: [
        for (final m in json['milestones']! as List) HealthMilestone.fromJson(Map<String, Object?>.from(m as Map)),
      ],
      withdrawal: [
        for (final w in (json['withdrawal'] as List?) ?? const <Object?>[])
          WithdrawalPhase.fromJson(Map<String, Object?>.from(w as Map)),
      ],
      lifeEstimates: [
        for (final l in (json['lifeEstimates'] as List?) ?? const <Object?>[])
          LifeEstimate.fromJson(Map<String, Object?>.from(l as Map)),
      ],
    );
    final problems = content.validate();
    if (problems.isNotEmpty) throw FormatException('Invalid milestone content: ${problems.join('; ')}');
    return content;
  }

  static const languages = ['en', 'fr', 'ar'];

  final int version;
  final String substance;
  final Map<String, String> disclaimer;

  /// "The milestone clock restarts after a lapse; percentages show elapsed time only."
  final Map<String, String> clockNote;
  final List<HealthMilestone> milestones;
  final List<WithdrawalPhase> withdrawal;
  final List<LifeEstimate> lifeEstimates;

  String disclaimerFor(String languageCode) => disclaimer[languageCode] ?? disclaimer['en']!;

  String clockNoteFor(String languageCode) => clockNote[languageCode] ?? clockNote['en']!;

  /// Milestones with a progress bar (info rows excluded), in metrics form.
  List<QuitMilestone> get progressMilestones => [
    for (final m in milestones)
      if (!m.info) m.toMetrics(),
  ];

  HealthMilestone? byId(String id) {
    for (final m in milestones) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Validation problems (empty = valid).
  List<String> validate() {
    final problems = <String>[];
    for (final lang in languages) {
      if ((disclaimer[lang] ?? '').trim().isEmpty) problems.add('disclaimer.$lang missing');
      if ((clockNote[lang] ?? '').trim().isEmpty) problems.add('clockNote.$lang missing');
    }
    final ids = <String>{};
    for (final m in milestones) {
      if (!ids.add(m.id)) problems.add('duplicate id ${m.id}');
      if (m.sources.isEmpty) problems.add('${m.id}: no source');
      for (final s in m.sources) {
        if (!s.url.startsWith('https://')) problems.add('${m.id}: source URL ${s.url}');
      }
      for (final lang in languages) {
        final t = m.texts[lang];
        if (t == null || t.title.trim().isEmpty || t.body.trim().isEmpty) problems.add('${m.id}: $lang text missing');
      }
      if (m.tMax != null && m.tMax! < m.tMin) problems.add('${m.id}: tMax < tMin');
    }
    for (final w in withdrawal) {
      for (final lang in languages) {
        if ((w.texts[lang] ?? '').trim().isEmpty) problems.add('withdrawal ${w.id}: $lang text missing');
      }
    }
    return problems;
  }
}

/// A milestone row with its live progress (timeline, T5.3.12).
@immutable
class MilestoneRow {
  const MilestoneRow(this.milestone, this.progress, {this.health});

  final QuitMilestone milestone;
  final MilestoneProgress progress;

  /// Health content (smoking) or null for day milestones.
  final HealthMilestone? health;
}

/// Money helper: a decimal from a user-entered double (no binary rounding surprises).
Decimal decimalOf(double value) => Decimal.parse(value.toString());
