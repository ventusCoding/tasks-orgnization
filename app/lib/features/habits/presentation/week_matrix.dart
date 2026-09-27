import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/habits/application/habit_day_view.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/check_in.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/presentation/check_in_sheets.dart';
import 'package:everslot/features/habits/presentation/habit_routes.dart';
import 'package:everslot/features/habits/presentation/habit_ui.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show PeriodStatus;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Habits-tab settings read by the check-in views (`user_settings.habits`, arch §8.5).
class HabitViewSettings {
  const HabitViewSettings({
    this.tapCycle = TapCycle.doneNotDoneClear,
    this.toggleWithShortPress = true,
    this.showStreakChips = true,
    this.compact = false,
    this.hideNotDue = false,
  });

  factory HabitViewSettings.fromMap(Map<String, dynamic> m) => HabitViewSettings(
    tapCycle: TapCycle.parse(m['matrixTapCycle']),
    toggleWithShortPress: m.get<bool>('toggleWithShortPress', true),
    showStreakChips: m.get<bool>('showStreakChips', true),
    compact: m['density'] == 'compact',
    hideNotDue: m.get<bool>('hideNotDue', false),
  );

  final TapCycle tapCycle;
  final bool toggleWithShortPress;
  final bool showStreakChips;
  final bool compact;
  final bool hideNotDue;
}

final habitViewSettingsProvider = Provider<HabitViewSettings>(
  (ref) => HabitViewSettings.fromMap(ref.watch(settingsProvider(SettingsNs.habits)).value ?? const {}),
);

/// Loop-style week matrix (T5.2.06): habits as rows, the [days] days ending at [endDate] as columns
/// (today at the trailing edge), sticky habit column, tap cycles the state, long-press opens the
/// day editor; dragging horizontally goes back in time. Column order mirrors in RTL.
class WeekMatrix extends ConsumerStatefulWidget {
  const WeekMatrix({required this.endDate, super.key});

  final LocalDate endDate;

  @override
  ConsumerState<WeekMatrix> createState() => _WeekMatrixState();
}

class _WeekMatrixState extends ConsumerState<WeekMatrix> {
  int _offsetDays = 0;
  double _drag = 0;

  static int columnsFor(double width) => ((width - 140) / 44).floor().clamp(5, 14);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final habitsAsync = ref.watch(habitsProvider);
    final settings = ref.watch(habitViewSettingsProvider);
    final today = ref.watch(habitTodayProvider);
    return AsyncValueView<List<Habit>>(
      value: habitsAsync,
      data: (all) {
        final habits = [for (final h in all) if (h is BuildHabit) h];
        if (habits.isEmpty) return EmptyState(icon: Icons.grid_on, title: l.habitsEmptyTitle, message: l.habitsEmptyBody);
        return LayoutBuilder(
          builder: (context, constraints) {
            final n = columnsFor(constraints.maxWidth);
            final end = widget.endDate.minusDays(_offsetDays);
            final dates = [for (var i = n - 1; i >= 0; i--) end.minusDays(i)];
            final fmt = AppFormat(context.localeName);
            return GestureDetector(
              onHorizontalDragUpdate: (d) => _drag += d.delta.dx * (context.isRtl ? -1 : 1),
              onHorizontalDragEnd: (_) {
                if (_drag.abs() > 40) {
                  setState(() => _offsetDays = (_offsetDays + (_drag > 0 ? n : -n)).clamp(0, 36500));
                }
                _drag = 0;
              },
              child: ListView(
                padding: const EdgeInsetsDirectional.only(bottom: 96),
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 140,
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: l.habitsOlder,
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () => setState(() => _offsetDays += n),
                            ),
                            IconButton(
                              tooltip: l.habitsNewer,
                              icon: const Icon(Icons.chevron_right),
                              onPressed: _offsetDays == 0 ? null : () => setState(() => _offsetDays = (_offsetDays - n).clamp(0, 36500)),
                            ),
                          ],
                        ),
                      ),
                      for (final d in dates)
                        Expanded(
                          child: Semantics(
                            label: fmt.dayLong(d),
                            excludeSemantics: true,
                            child: Column(
                              children: [
                                Text(fmt.weekdayShort(d.weekday), style: context.text.labelSmall),
                                Text(
                                  fmt.number(d.day),
                                  style: context.text.labelMedium?.copyWith(
                                    fontWeight: d == today ? FontWeight.w800 : FontWeight.w400,
                                    color: d == today ? context.colors.primary : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: Space.sm),
                  for (final habit in habits) _MatrixRow(habit: habit, dates: dates, settings: settings),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MatrixRow extends ConsumerWidget {
  const _MatrixRow({required this.habit, required this.dates, required this.settings});

  final BuildHabit habit;
  final List<LocalDate> dates;
  final HabitViewSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final snapshot = ref.watch(habitSnapshotProvider(habit.id)).value;
    if (snapshot == null) return const SizedBox(height: 48);
    final periodService = ref.watch(habitPeriodServiceProvider);
    final views = [for (final d in dates) habitDayView(snapshot, d, periodService)];
    final quotaView = views.lastWhere((v) => v?.quota != null, orElse: () => null);
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: InkWell(
              onTap: () => HabitRoutes.detail(context, habit.id),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: Space.lg, end: Space.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(habit.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodyMedium),
                    if (quotaView != null)
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              quotaView.quota!.key.startsWith('month:')
                                  ? l.habitsQuotaMonth(quotaView.quota!.flags.activeDays ?? 0, quotaView.quota!.flags.requiredDays ?? 0)
                                  : l.habitsQuotaWeek(quotaView.quota!.flags.activeDays ?? 0, quotaView.quota!.flags.requiredDays ?? 0),
                              style: context.text.labelSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (quotaView.atRisk)
                            Tooltip(
                              message: l.habitsAtRisk,
                              child: Icon(Icons.warning_amber, size: 14, color: context.appColors.warning),
                            ),
                        ],
                      )
                    else if (settings.showStreakChips && (snapshot.summary?.currentStreak ?? 0) > 0)
                      Text(l.habitsStreakSemantics(snapshot.summary!.currentStreak), style: context.text.labelSmall),
                  ],
                ),
              ),
            ),
          ),
          for (final v in views) Expanded(child: _Cell(habit: habit, view: v, settings: settings)),
        ],
      ),
    );
  }
}

class _Cell extends ConsumerWidget {
  const _Cell({required this.habit, required this.view, required this.settings});

  final BuildHabit habit;
  final HabitDayView? view;
  final HabitViewSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final v = view;
    if (v == null) return const SizedBox.shrink();
    final status = v.status;
    final style = StatusStyle.of(context, status);
    final fmt = AppFormat(context.localeName);
    final semantics = l.habitsCellSemantics(habit.name, fmt.dayLong(v.date), l.statusLabel(status));
    final accent = habitAccent(context, habit);
    final faded = status == PeriodStatus.notDue;

    Future<void> tap() async {
      if (v.isSlot) return showDayEditor(context, ref, habit.id, v.date);
      if (habit.goal.isMeasurable && !v.isQuota) {
        final value = await showValueSheet(context, habit);
        if (value != null && context.mounted) await CheckInActions(context, ref).addProgress(habit, v.key, value);
        return;
      }
      await CheckInActions(context, ref).setState(habit, v.key, settings.tapCycle.next(v.explicit?.kind));
    }

    Widget content;
    if (v.isSlot && v.slots.isNotEmpty) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in v.slots.take(6))
            Container(
              width: 4,
              height: 18,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              color: StatusStyle.of(context, s.status).color.withValues(alpha: s.status == PeriodStatus.done ? 1 : 0.35),
            ),
        ],
      );
    } else if (habit.goal.isMeasurable && !v.isQuota && status != PeriodStatus.notDue) {
      content = Container(
        width: 36,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12 + 0.6 * v.progress),
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child: Text(
          formatValue(context, v.achieved),
          style: context.text.labelSmall,
          maxLines: 1,
        ),
      );
    } else {
      content = Icon(style.icon, color: faded ? style.color.withValues(alpha: 0.4) : style.color, size: 22);
    }
    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: InkWell(
        onTap: settings.toggleWithShortPress ? tap : () => showDayEditor(context, ref, habit.id, v.date),
        onLongPress: settings.toggleWithShortPress ? () => showDayEditor(context, ref, habit.id, v.date) : () => unawaited(tap()),
        child: SizedBox(height: 56, child: Center(child: content)),
      ),
    );
  }
}
