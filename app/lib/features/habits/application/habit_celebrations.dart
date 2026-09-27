import 'package:everslot/core/providers.dart';
import 'package:everslot/features/habits/application/check_in_service.dart';
import 'package:everslot/features/habits/application/habit_day_view.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show PeriodStatus;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:meta/meta.dart';

/// Streak lengths worth a celebration (T5.2.13).
const streakMilestones = <int>[7, 14, 30, 60, 100, 200, 365, 500, 730, 1000];

enum CelebrationKind { streak, perfectDay }

/// Something to celebrate after a check-in (non-blocking overlay, T5.2.13).
@immutable
class Celebration {
  const Celebration(this.kind, {required this.dedupeKey, this.habitId, this.habitName, this.count = 0});

  final CelebrationKind kind;

  /// One celebration per key per app session (undo + redo does not celebrate twice).
  final String dedupeKey;
  final String? habitId;
  final String? habitName;

  /// Streak length (streak celebrations).
  final int count;

  @override
  bool operator ==(Object other) =>
      other is Celebration && other.kind == kind && other.dedupeKey == dedupeKey && other.count == count;

  @override
  int get hashCode => Object.hash(kind, dedupeKey, count);
}

/// Perfect day ([6.5]): every due habit done; excused, paused and not-due habits don't count.
bool isPerfectDay(Iterable<HabitDayView> views) {
  final due = [
    for (final v in views)
      if (v.status != PeriodStatus.notDue && v.status != PeriodStatus.paused && v.status != PeriodStatus.excused) v,
  ];
  return due.isNotEmpty && due.every((v) => v.status == PeriodStatus.done);
}

/// Pure detection: what [snapshot] (taken right after a check-in on [date]) and the day views of all
/// habits on that date earn. A streak milestone counts only when the checked period is done and the
/// current streak lands exactly on a milestone.
List<Celebration> celebrationsAfter({
  required HabitSnapshot snapshot,
  required LocalDate date,
  required List<HabitDayView> dayViews,
}) {
  final habit = snapshot.build;
  if (habit == null) return const [];
  final out = <Celebration>[];
  final streak = snapshot.summary?.currentStreak ?? 0;
  final day = snapshot.evaluation?.dayOn(date);
  if (day?.status == PeriodStatus.done && streakMilestones.contains(streak)) {
    out.add(
      Celebration(
        CelebrationKind.streak,
        dedupeKey: 'streak|${habit.id}|$streak',
        habitId: habit.id,
        habitName: habit.name,
        count: streak,
      ),
    );
  }
  if (isPerfectDay(dayViews)) {
    out.add(Celebration(CelebrationKind.perfectDay, dedupeKey: 'perfect|${date.toIso()}'));
  }
  return out;
}

/// Detects celebrations after check-ins from fresh repository reads (the reactive snapshots may
/// not have updated yet when the event arrives) and remembers what was already shown this session.
class CelebrationService {
  CelebrationService(this._read);

  final T Function<T>(ProviderListenable<T> provider) _read;
  final Set<String> _shown = {};

  /// Celebrations earned by [event] (only done / progress check-ins celebrate).
  Future<List<Celebration>> onCheckIn(HabitCheckInEvent event) async {
    if (event.kind != HabitLogKind.done && event.kind != HabitLogKind.progress) return const [];
    final habits = await _read(habitsRepositoryProvider).all(includeArchived: false, kind: HabitKind.build);
    final habit = habits.where((h) => h.id == event.habitId).firstOrNull;
    if (habit == null) return const [];
    final now = _read(clockProvider).nowUtc();
    final date = LocalDate.tryParse(event.key.substring(0, 10));
    if (date == null) return const [];
    final service = _read(habitPeriodServiceProvider);
    final views = <HabitDayView>[];
    HabitSnapshot? checked;
    for (final h in habits) {
      final s = await loadHabitSnapshot(_read, h, now);
      if (h.id == habit.id) checked = s;
      final v = habitDayView(s, date, service);
      if (v != null) views.add(v);
    }
    if (checked == null) return const [];
    return [
      for (final c in celebrationsAfter(snapshot: checked, date: date, dayViews: views))
        if (_shown.add(c.dedupeKey)) c,
    ];
  }
}

final celebrationServiceProvider = Provider<CelebrationService>((ref) => CelebrationService(ref.read));
