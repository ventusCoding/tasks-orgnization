import 'dart:async';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/habits/application/habit_view_settings.dart';
import 'package:everslot/features/habits/domain/check_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// "View options" of the Habits tab (T5.2.06, T5.2.12): grouping, density, streak chips, hiding
/// not-due habits, the week-matrix tap cycle and toggle gesture. Changes apply (and sync) at once.
Future<void> showHabitViewOptions(BuildContext context) => showAppSheet<void>(
  context,
  title: context.l10n.habitsViewOptions,
  builder: (_) => const _ViewOptions(),
);

class _ViewOptions extends ConsumerWidget {
  const _ViewOptions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(habitViewSettingsProvider);
    final service = ref.read(habitViewSettingsServiceProvider);
    void save(Future<void> write) => unawaited(write);
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.habitsGroupByTitle, style: context.text.labelLarge),
          const SizedBox(height: Space.xs),
          SegmentedButton<HabitGroupBy>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: HabitGroupBy.section, label: Text(l.habitsGroupBySection)),
              ButtonSegment(value: HabitGroupBy.category, label: Text(l.habitsGroupByCategory)),
              ButtonSegment(value: HabitGroupBy.none, label: Text(l.habitsGroupByNone)),
            ],
            selected: {s.groupBy},
            onSelectionChanged: (v) => save(service.update(groupBy: v.first)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.habitsCompactRows),
            value: s.compact,
            onChanged: (v) => save(service.update(compact: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.habitsShowStreaks),
            value: s.showStreakChips,
            onChanged: (v) => save(service.update(showStreakChips: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.habitsHideNotDue),
            value: s.hideNotDue,
            onChanged: (v) => save(service.update(hideNotDue: v)),
          ),
          const Divider(),
          Text(l.habitsMatrixTapTitle, style: context.text.labelLarge),
          RadioGroup<TapCycle>(
            groupValue: s.tapCycle,
            onChanged: (v) {
              if (v != null) save(service.update(tapCycle: v));
            },
            child: Column(
              children: [
                RadioListTile(value: TapCycle.doneNotDoneClear, title: Text(l.habitsTapCycleDoneFail)),
                RadioListTile(value: TapCycle.doneSkipClear, title: Text(l.habitsTapCycleDoneSkip)),
                RadioListTile(value: TapCycle.doneClear, title: Text(l.habitsTapCycleDoneOnly)),
              ],
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.habitsToggleShortPress),
            subtitle: Text(l.habitsToggleShortPressHint),
            value: s.toggleWithShortPress,
            onChanged: (v) => save(service.update(toggleWithShortPress: v)),
          ),
        ],
      ),
    );
  }
}
