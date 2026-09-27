import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/core/time/recurrence_service.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/habits/application/habit_day_view.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/habit_service.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/presentation/calendar_views.dart';
import 'package:everslot/features/habits/presentation/check_in_sheets.dart';
import 'package:everslot/features/habits/presentation/habit_routes.dart';
import 'package:everslot/features/habits/presentation/habit_ui.dart';
import 'package:everslot/features/habits/presentation/pause_sheet.dart';
import 'package:everslot/features/habits/presentation/today_view.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show PeriodStatus;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// "At least 15 reps", "At most 2 cups", "Yes / No".
String goalSentence(BuildContext context, HabitTarget goal) {
  final l = context.l10n;
  if (!goal.isMeasurable) return l.habitsGoalTypeCheck;
  return l.habitsGoalSentence(l.opLabel(goal.op), formatAmount(context, goal.target ?? 0, goal.unit));
}

/// Localized schedule sentence of [habit] ("Every Monday and Tuesday").
String scheduleSentence(BuildContext context, WidgetRef ref, BuildHabit habit) {
  final recurrence = ref.watch(recurrenceServiceProvider);
  final prefs = ref.watch(userPreferencesProvider);
  try {
    return recurrence.describe(
      habit.schedule,
      RecurrenceAnchor.allDayOn(habit.startDate, habit.timeZone),
      locale: context.localeName,
      use24h: prefs.use24h,
    );
  } on Object {
    return '';
  }
}

/// One screen per habit (T5.2.07): header (schedule sentence, goal), current & best streak,
/// strength and 30-day rate from `everslot_metrics`, the counts of the last 90 days, a month
/// calendar (tap a day → day editor), the year heatmap, recent entries and actions.
class HabitDetailScreen extends ConsumerWidget {
  const HabitDetailScreen({required this.habitId, super.key});

  final String habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapAsync = ref.watch(habitSnapshotProvider(habitId));
    return AsyncValueView(
      value: snapAsync,
      loading: const Scaffold(body: LoadingState()),
      data: (snapshot) {
        final habit = snapshot.habit;
        if (habit is QuitHabit) {
          // Quit trackers have their own dashboard.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) unawaited(HabitRoutes.quit(context, habit.id));
          });
          return const Scaffold(body: LoadingState());
        }
        return _Detail(snapshot: snapshot, habit: habit as BuildHabit);
      },
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.snapshot, required this.habit});

  final HabitSnapshot snapshot;
  final BuildHabit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final summary = snapshot.summary!;
    final fmt = AppFormat(context.localeName, use24h: ref.watch(userPreferencesProvider).use24h, l10n: l);
    final todayView = habitDayView(snapshot, snapshot.today, ref.watch(habitPeriodServiceProvider));
    final pause = snapshot.pauseOn(snapshot.today);
    final counts = summary.counts90;
    final rate = summary.rate30.valueOrNull;
    final recent = [
      for (final e in snapshot.logs.reversed)
        if (e.kind != HabitLogKind.freeze) e,
    ].take(10).toList();
    final zone = ref.watch(habitPeriodServiceProvider).zoneOf(habit);
    final resolver = ref.watch(zoneResolverProvider);

    Future<void> menu(String v) async {
      final service = ref.read(habitServiceProvider);
      switch (v) {
        case 'pause':
          await showPauseSheet(context, ref, habitId: habit.id);
        case 'archive':
          final record = await service.setArchived(habit.id, archived: !habit.isArchived);
          if (context.mounted) {
            showUndoSnackBar(context, ref, message: habit.isArchived ? l.habitsUnarchivedSnack : l.habitsArchivedSnack, record: record);
          }
        case 'delete':
          final ok = await confirmDialog(
            context,
            title: l.habitsDeleteTitle(habit.name),
            body: l.habitsDeleteBody,
            confirmLabel: l.actionDelete,
            destructive: true,
          );
          if (!ok || !context.mounted) return;
          final record = await service.delete(habit.id);
          if (!context.mounted) return;
          showUndoSnackBar(context, ref, message: l.habitsDeletedSnack, record: record);
          Navigator.of(context).maybePop();
        case 'stats':
          await HabitNav.push(context, AppLinks.insightsScope('habit', habit.id), (_) => const SizedBox());
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
        actions: [
          IconButton(tooltip: l.actionEdit, icon: const Icon(Icons.edit_outlined), onPressed: () => HabitRoutes.edit(context, habit.id)),
          PopupMenuButton<String>(
            tooltip: l.actionMore,
            onSelected: (v) => unawaited(menu(v)),
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'stats', child: Text(l.habitsAllStats)),
              PopupMenuItem(value: 'pause', child: Text(l.habitsActionPause)),
              PopupMenuItem(value: 'archive', child: Text(habit.isArchived ? l.habitsUnarchive : l.actionArchive)),
              PopupMenuItem(value: 'delete', child: Text(l.actionDelete)),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.only(bottom: Space.xxxl),
        children: [
          if (pause != null) PauseBanner(pause: pause),
          Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HabitAvatar(habit: habit, size: 56),
                const SizedBox(width: Space.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(scheduleSentence(context, ref, habit), style: context.text.titleSmall),
                      const SizedBox(height: Space.xs),
                      Text(goalSentence(context, habit.goal), style: context.text.bodyMedium),
                      if (habit.description != null) ...[
                        const SizedBox(height: Space.xs),
                        Text(habit.description!, style: context.text.bodySmall),
                      ],
                      if (habit.isChallenge && habit.endDate != null) ...[
                        const SizedBox(height: Space.xs),
                        Text(
                          l.habitsChallengeDay(
                            (habit.startDate.daysUntil(snapshot.today) + 1).clamp(1, habit.startDate.daysUntil(habit.endDate!) + 1),
                            habit.startDate.daysUntil(habit.endDate!) + 1,
                          ),
                          style: context.text.labelLarge?.copyWith(color: context.colors.primary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (todayView != null && !habit.isArchived)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.sm),
              child: Card(child: HabitRow(view: todayView)),
            ),
          Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                _StatChip(label: l.habitsCurrentStreak, value: l.habitsDays(summary.currentStreak), icon: Icons.local_fire_department),
                _StatChip(label: l.habitsBestStreak, value: l.habitsDays(summary.bestStreak), icon: Icons.emoji_events_outlined),
                _StatChip(label: l.habitsStrength, value: fmt.percent(summary.strengthScore), icon: Icons.fitness_center),
                _StatChip(
                  label: l.habitsRate30,
                  value: rate == null ? l.habitsNotEnoughData : fmt.percent(rate),
                  icon: Icons.percent,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
            child: Semantics(
              label: l.habitsLast90,
              child: Text(
                l.habitsCounts(counts.success, counts.failed, counts.missed, counts.skipped),
                style: context.text.bodyMedium,
              ),
            ),
          ),
          SectionHeader(l.habitsCalendar),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.md),
            child: HabitMonthCalendar(habitId: habit.id),
          ),
          SectionHeader(l.habitsYear),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
            child: YearHeatmap(habitId: habit.id),
          ),
          SectionHeader(l.habitsRecentEntries),
          if (recent.isEmpty)
            Padding(padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg), child: Text(l.habitsNoEntries))
          else
            for (final e in recent)
              ListTile(
                leading: e.mood == null
                    ? Icon(StatusStyle.of(context, _statusOfLog(e)).icon, color: StatusStyle.of(context, _statusOfLog(e)).color)
                    : Text(MoodSelector.emojis[e.mood! - 1], style: context.text.titleLarge),
                title: Text(_logTitle(context, habit, e)),
                subtitle: Text(
                  [
                    fmt.dateTime(resolver.toLocal(e.loggedAt, zone)),
                    if (e.note != null) e.note!,
                  ].join(' · '),
                ),
                onTap: () => showDayEditor(context, ref, habit.id, e.localDate),
              ),
        ],
      ),
    );
  }

  static PeriodStatus _statusOfLog(HabitLogEntry e) => switch (e.kind) {
    HabitLogKind.done || HabitLogKind.progress => PeriodStatus.done,
    HabitLogKind.fail => PeriodStatus.failed,
    HabitLogKind.skip => PeriodStatus.skipped,
    HabitLogKind.excuse => PeriodStatus.excused,
    HabitLogKind.freeze => PeriodStatus.frozen,
    _ => PeriodStatus.pending,
  };

  static String _logTitle(BuildContext context, BuildHabit habit, HabitLogEntry e) {
    final l = context.l10n;
    return switch (e.kind) {
      HabitLogKind.progress => formatAmount(context, e.value ?? 0, habit.goal.unit),
      HabitLogKind.done => l.habitsStatusDone,
      HabitLogKind.fail => l.habitsStatusFailed,
      HabitLogKind.skip => l.habitsStatusSkipped,
      HabitLogKind.excuse => l.habitsStatusExcused,
      HabitLogKind.note => l.habitsNoteMoodTitle,
      _ => e.kind.name,
    };
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: $value',
    excludeSemantics: true,
    child: Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: context.colors.primary),
              const SizedBox(width: Space.xs),
              Text(label, style: context.text.labelMedium),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(value, style: context.text.titleLarge),
        ],
      ),
    ),
  );
}

/// Month calendar of one habit with the status of each day (week start honoured; tap → day editor).
class HabitMonthCalendar extends ConsumerStatefulWidget {
  const HabitMonthCalendar({required this.habitId, super.key});

  final String habitId;

  @override
  ConsumerState<HabitMonthCalendar> createState() => _HabitMonthCalendarState();
}

class _HabitMonthCalendarState extends ConsumerState<HabitMonthCalendar> {
  LocalDate? _month;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final snapshot = ref.watch(habitSnapshotProvider(widget.habitId)).value;
    final habit = snapshot?.build;
    if (snapshot == null || habit == null) return const SizedBox(height: 200);
    final month = _month ?? snapshot.today.firstDayOfMonth;
    final prefs = ref.watch(userPreferencesProvider);
    final fmt = AppFormat(context.localeName);
    final gridStart = month.startOfWeek(prefs.weekStart);
    final last = month.lastDayOfMonth;
    final weeks = ((gridStart.daysUntil(last) + 1) / 7).ceil();
    final service = ref.watch(habitPeriodServiceProvider);
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: l.habitsPreviousMonth,
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() => _month = month.plusMonths(-1)),
            ),
            Expanded(child: Text(fmt.monthYear(month), textAlign: TextAlign.center, style: context.text.titleSmall)),
            IconButton(
              tooltip: l.habitsNextMonth,
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() => _month = month.plusMonths(1)),
            ),
          ],
        ),
        Row(
          children: [
            for (final w in Weekday.ordered(prefs.weekStart))
              Expanded(child: Text(fmt.weekdayShort(w), textAlign: TextAlign.center, style: context.text.labelSmall)),
          ],
        ),
        for (var week = 0; week < weeks; week++)
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: () {
                    final d = gridStart.plusDays(week * 7 + i);
                    if (d.month != month.month) return const SizedBox(height: 44);
                    final view = habitDayView(snapshot, d, service);
                    final status = view?.status ?? PeriodStatus.notDue;
                    final style = StatusStyle.of(context, status);
                    final active = view != null;
                    return Semantics(
                      button: active,
                      label: '${fmt.dayLong(d)}, ${l.statusLabel(status)}',
                      excludeSemantics: true,
                      child: InkWell(
                        onTap: active ? () => showDayEditor(context, ref, habit.id, d) : null,
                        borderRadius: BorderRadius.circular(Radii.sm),
                        child: SizedBox(
                          height: 44,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                fmt.number(d.day),
                                style: context.text.labelSmall?.copyWith(
                                  fontWeight: d == snapshot.today ? FontWeight.w800 : null,
                                ),
                              ),
                              Icon(
                                style.icon,
                                size: 16,
                                color: status == PeriodStatus.notDue ? style.color.withValues(alpha: 0.3) : style.color,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }(),
                ),
            ],
          ),
      ],
    );
  }
}
