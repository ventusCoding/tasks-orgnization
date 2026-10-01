import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/settings/application/section_defaults.dart';
import 'package:everslot/features/settings/application/settings_providers.dart';
import 'package:everslot/features/settings/domain/settings_models.dart';
import 'package:everslot/features/settings/presentation/widgets/choice_sheet.dart';
import 'package:everslot/features/settings/presentation/widgets/settings_tiles.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

AppFormat _format(BuildContext context, WidgetRef ref) => AppFormat(
  Localizations.localeOf(context).toLanguageTag(),
  use24h: ref.watch(userPreferencesProvider).use24h,
  l10n: context.l10n,
);

Widget _hint(BuildContext context) => Padding(
  padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.md, Space.lg, 0),
  child: Text(
    context.l10n.settingsDefaultsHint,
    style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
  ),
);

/// Settings › Plan (T8.3.05): default view, task duration, tracking, missed grace, work hours &
/// days, roll-over and actual-time prompt (`planner` namespace, read by the planner and stats).
class PlanDefaultsPage extends ConsumerWidget {
  const PlanDefaultsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(plannerDefaultsProvider);
    final writer = ref.read(settingsWriterProvider);
    final format = _format(context, ref);
    final views = ref.watch(plannerViewChoicesProvider);
    final current = views.where((v) => v.isDefault).firstOrNull;
    Future<void> set(PlannerDefaults Function(PlannerDefaults s) change) =>
        writer.update(PlannerDefaults.codec, change);

    return SettingsPageScaffold(
      title: l.settingsPlan,
      children: [
        _hint(context),
        SettingsValueTile(
          key: const ValueKey('plan-default-view'),
          icon: Icons.view_week_outlined,
          title: l.settingsPlanDefaultView,
          value: current?.name ?? l.settingsPlanDefaultViewNone,
          onTap: views.isEmpty
              ? null
              : () async {
                  final id = await pickChoice<String>(
                    context,
                    title: l.settingsPlanDefaultView,
                    selected: current?.id ?? '',
                    choices: [for (final v in views) Choice(v.id, v.name)],
                  );
                  if (id != null) await setDefaultPlannerView(ref, id);
                },
        ),
        SettingsValueTile(
          key: const ValueKey('plan-duration'),
          icon: Icons.timelapse,
          title: l.settingsPlanDefaultDuration,
          value: format.duration(s.defaultTaskDurationMinutes),
          onTap: () async {
            final minutes = await pickDuration(context, initialMinutes: s.defaultTaskDurationMinutes, maxMinutes: 1440);
            if (minutes != null && minutes > 0) await set((s) => s.copyWith(defaultTaskDurationMinutes: minutes));
          },
        ),
        SettingsSegmentTile<String>(
          key: const ValueKey('plan-tracking'),
          icon: Icons.task_alt,
          title: l.settingsPlanTracking,
          selected: s.defaultTrackingMode,
          segments: [
            ('check', l.settingsPlanTrackingCheck),
            ('event', l.settingsPlanTrackingEvent),
            ('timer', l.settingsPlanTrackingTimer),
          ],
          onChanged: (v) => set((s) => s.copyWith(defaultTrackingMode: v)),
        ),
        SettingsValueTile(
          key: const ValueKey('plan-grace'),
          icon: Icons.hourglass_bottom,
          title: l.settingsPlanGrace,
          value: l.settingsPlanGraceValue(s.missedGraceMinutes),
          onTap: () async {
            final minutes = await pickChoice<int>(
              context,
              title: l.settingsPlanGrace,
              selected: s.missedGraceMinutes,
              choices: [for (final m in PlannerDefaults.graceChoices) Choice(m, l.settingsPlanGraceValue(m))],
            );
            if (minutes != null) await set((s) => s.copyWith(missedGraceMinutes: minutes));
          },
        ),
        SectionHeader(l.settingsPlanWorkHours),
        Row(
          children: [
            Expanded(
              child: SettingsValueTile(
                key: const ValueKey('plan-work-start'),
                title: l.settingsPlanWorkStart,
                value: format.time(LocalTime.fromMinuteOfDay(s.workStartMinute)),
                onTap: () => _pickWorkTime(context, ref, s, start: true),
              ),
            ),
            Expanded(
              child: SettingsValueTile(
                key: const ValueKey('plan-work-end'),
                title: l.settingsPlanWorkEnd,
                value: format.time(LocalTime.fromMinuteOfDay(s.workEndMinute % 1440)),
                onTap: () => _pickWorkTime(context, ref, s, start: false),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.settingsPlanWorkDays, style: context.text.bodyLarge),
              const SizedBox(height: Space.sm),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  for (final iso in _weekOrder(ref.watch(userPreferencesProvider).weekStart.iso))
                    FilterChip(
                      key: ValueKey('plan-day-$iso'),
                      label: Text(format.weekdayShort(Weekday.fromIso(iso))),
                      selected: s.workDays.contains(iso),
                      onSelected: (on) {
                        final days = {...s.workDays};
                        on ? days.add(iso) : days.remove(iso);
                        if (days.isNotEmpty) unawaited(set((s) => s.copyWith(workDays: days)));
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        const Divider(),
        SettingsSegmentTile<String>(
          key: const ValueKey('plan-rollover'),
          icon: Icons.redo,
          title: l.settingsPlanRollOver,
          selected: s.rollOverIncomplete,
          segments: [
            ('off', l.settingsPlanRollOverOff),
            ('ask', l.settingsPlanRollOverAsk),
            ('auto', l.settingsPlanRollOverAuto),
          ],
          onChanged: (v) => set((s) => s.copyWith(rollOverIncomplete: v)),
        ),
        SettingsSegmentTile<String>(
          key: const ValueKey('plan-actual-time'),
          icon: Icons.more_time,
          title: l.settingsPlanActualTime,
          selected: s.askActualTimeOnDone,
          segments: [
            ('never', l.settingsPlanActualNever),
            ('if_off_schedule', l.settingsPlanActualOffSchedule),
            ('always', l.settingsPlanActualAlways),
          ],
          onChanged: (v) => set((s) => s.copyWith(askActualTimeOnDone: v)),
        ),
      ],
    );
  }

  static List<int> _weekOrder(int start) => [for (var i = 0; i < 7; i++) (start - 1 + i) % 7 + 1];

  Future<void> _pickWorkTime(BuildContext context, WidgetRef ref, PlannerDefaults s, {required bool start}) async {
    final t = await pickTime(
      context,
      initial: LocalTime.fromMinuteOfDay((start ? s.workStartMinute : s.workEndMinute) % 1440),
      use24h: ref.read(userPreferencesProvider).use24h,
    );
    if (t == null) return;
    final m = t.minuteOfDay;
    final startMinute = start ? m : s.workStartMinute;
    // An end at midnight means the end of the day.
    final endMinute = start ? s.workEndMinute : (m == 0 ? 1440 : m);
    if (startMinute >= endMinute) return;
    await ref
        .read(settingsWriterProvider)
        .update(PlannerDefaults.codec, (s) => s.copyWith(workStartMinute: startMinute, workEndMinute: endMinute));
  }
}

/// Settings › Lists (T8.3.05): defaults for new checklists (`checklists` namespace).
class ListsDefaultsPage extends ConsumerWidget {
  const ListsDefaultsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(checklistsDefaultsProvider);
    final writer = ref.read(settingsWriterProvider);
    Future<void> set(ChecklistsDefaults Function(ChecklistsDefaults s) change) =>
        writer.update(ChecklistsDefaults.codec, change);
    final statuses = {
      'ongoing': l.statusOngoing,
      'waiting': l.statusWaiting,
      'blocked': l.statusBlocked,
      'completed': l.statusCompleted,
    };
    return SettingsPageScaffold(
      title: l.settingsLists,
      children: [
        _hint(context),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.md, Space.lg, Space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.settingsListsRequireReason, style: context.text.bodyLarge),
              const SizedBox(height: Space.sm),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  for (final e in statuses.entries)
                    FilterChip(
                      key: ValueKey('lists-reason-${e.key}'),
                      label: Text(e.value),
                      selected: s.requireReasonFor.contains(e.key),
                      onSelected: (on) {
                        final next = {...s.requireReasonFor};
                        on ? next.add(e.key) : next.remove(e.key);
                        unawaited(set((s) => s.copyWith(requireReasonFor: next)));
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        SettingsSwitchTile(
          key: const ValueKey('lists-auto-complete'),
          icon: Icons.account_tree_outlined,
          title: l.settingsListsAutoComplete,
          subtitle: l.settingsListsAutoCompleteHint,
          value: s.autoCompleteParents,
          onChanged: (v) => set((s) => s.copyWith(autoCompleteParents: v)),
        ),
        SettingsSegmentTile<ProgressModePreference>(
          key: const ValueKey('lists-progress'),
          icon: Icons.donut_large,
          title: l.settingsListsProgress,
          selected: s.progressMode,
          segments: [
            (ProgressModePreference.leaves, l.settingsListsProgressLeaves),
            (ProgressModePreference.children, l.settingsListsProgressChildren),
          ],
          onChanged: (v) => set((s) => s.copyWith(progressMode: v)),
        ),
        SettingsSwitchTile(
          key: const ValueKey('lists-show-completed'),
          icon: Icons.visibility_outlined,
          title: l.settingsListsShowCompleted,
          value: s.showCompleted,
          onChanged: (v) => set((s) => s.copyWith(showCompleted: v)),
        ),
        SettingsSwitchTile(
          key: const ValueKey('lists-completed-bottom'),
          icon: Icons.vertical_align_bottom,
          title: l.settingsListsCompletedBottom,
          value: s.sortCompletedToBottom,
          onChanged: (v) => set((s) => s.copyWith(sortCompletedToBottom: v)),
        ),
      ],
    );
  }
}

/// Settings › Habits (T8.3.05): defaults for new habits + the day start (Regional).
class HabitsDefaultsPage extends ConsumerWidget {
  const HabitsDefaultsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(habitsDefaultsProvider);
    final writer = ref.read(settingsWriterProvider);
    final format = _format(context, ref);
    Future<void> set(HabitsDefaults Function(HabitsDefaults s) change) => writer.update(HabitsDefaults.codec, change);
    return SettingsPageScaffold(
      title: l.settingsHabits,
      children: [
        _hint(context),
        SettingsSegmentTile<SkipPolicy>(
          key: const ValueKey('habits-skip'),
          icon: Icons.skip_next_outlined,
          title: l.settingsHabitsSkipPolicy,
          selected: s.defaultSkipPolicy,
          segments: [
            (SkipPolicy.neutral, l.settingsHabitsSkipNeutral),
            (SkipPolicy.breaks, l.settingsHabitsSkipBreaks),
          ],
          onChanged: (v) => set((s) => s.copyWith(defaultSkipPolicy: v)),
        ),
        ListTile(
          key: const ValueKey('habits-freezes'),
          leading: const Icon(Icons.ac_unit),
          title: Text(l.settingsHabitsFreezes),
          subtitle: Text(l.settingsHabitsFreezesHint),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: const ValueKey('habits-freezes-minus'),
                tooltip: l.settingsFewer,
                icon: const Icon(Icons.remove),
                onPressed: s.defaultFreezesPerMonth <= 0
                    ? null
                    : () => set((s) => s.copyWith(defaultFreezesPerMonth: s.defaultFreezesPerMonth - 1)),
              ),
              Text(format.number(s.defaultFreezesPerMonth), key: const ValueKey('habits-freezes-value')),
              IconButton(
                key: const ValueKey('habits-freezes-plus'),
                tooltip: l.settingsMore,
                icon: const Icon(Icons.add),
                onPressed: s.defaultFreezesPerMonth >= 10
                    ? null
                    : () => set((s) => s.copyWith(defaultFreezesPerMonth: s.defaultFreezesPerMonth + 1)),
              ),
            ],
          ),
        ),
        SettingsNavTile(
          key: const ValueKey('habits-day-start'),
          icon: Icons.bedtime_outlined,
          title: l.settingsHabitsDayStartLink(format.time(LocalTime.fromMinuteOfDay(s.dayStartMinutes))),
          subtitle: l.settingsDayStartSubtitle,
          location: AppLinks.settings('regional'),
        ),
      ],
    );
  }
}

/// Settings › Insights (T8.3.05): default period, comparison, week start override (`stats`).
class InsightsDefaultsPage extends ConsumerWidget {
  const InsightsDefaultsPage({super.key});

  static String periodLabel(BuildContext context, String key) {
    final l = context.l10n;
    return switch (key) {
      'thisWeek' || 'week' => l.settingsPeriodThisWeek,
      'lastWeek' => l.settingsPeriodLastWeek,
      'thisMonth' || 'month' => l.settingsPeriodThisMonth,
      'lastMonth' => l.settingsPeriodLastMonth,
      'thisQuarter' || 'quarter' => l.settingsPeriodThisQuarter,
      'thisYear' || 'year' => l.settingsPeriodThisYear,
      _ when key.startsWith('rolling:') => l.settingsPeriodRolling(int.tryParse(key.substring(8)) ?? 30),
      _ => key,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(statsDefaultsProvider);
    final writer = ref.read(settingsWriterProvider);
    final format = _format(context, ref);
    final profileStart = ref.watch(userPreferencesProvider).weekStart;
    Future<void> set(StatsDefaults Function(StatsDefaults s) change) => writer.update(StatsDefaults.codec, change);
    return SettingsPageScaffold(
      title: l.settingsInsights,
      children: [
        SettingsValueTile(
          key: const ValueKey('insights-period'),
          icon: Icons.date_range,
          title: l.settingsInsightsPeriod,
          value: periodLabel(context, s.defaultPeriod),
          onTap: () async {
            final key = await pickChoice<String>(
              context,
              title: l.settingsInsightsPeriod,
              selected: s.defaultPeriod,
              choices: [for (final p in StatsDefaults.periodChoices) Choice(p, periodLabel(context, p))],
            );
            if (key != null) await set((s) => s.copyWith(defaultPeriod: key));
          },
        ),
        SettingsSwitchTile(
          key: const ValueKey('insights-compare'),
          icon: Icons.compare_arrows,
          title: l.settingsInsightsCompare,
          value: s.compareWithPrevious,
          onChanged: (v) => set((s) => s.copyWith(compareWithPrevious: v)),
        ),
        SettingsValueTile(
          key: const ValueKey('insights-week-start'),
          icon: Icons.first_page,
          title: l.settingsInsightsWeekStart,
          value: s.weekStartOverride == null
              ? l.settingsInsightsWeekStartProfile(format.weekdayLong(profileStart))
              : format.weekdayLong(Weekday.fromIso(s.weekStartOverride!)),
          onTap: () async {
            final iso = await pickChoice<int>(
              context,
              title: l.settingsInsightsWeekStart,
              selected: s.weekStartOverride ?? 0,
              choices: [
                Choice(0, l.settingsInsightsWeekStartProfile(format.weekdayLong(profileStart))),
                for (final d in const [1, 6, 7, 2, 3, 4, 5]) Choice(d, format.weekdayLong(Weekday.fromIso(d))),
              ],
            );
            if (iso != null) await set((s) => s.copyWith(weekStartOverride: iso == 0 ? null : iso));
          },
        ),
      ],
    );
  }
}
