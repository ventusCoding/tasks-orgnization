import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/habits/application/habit_labels.dart';
import 'package:everslot/features/habits/domain/catalogs.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show PeriodStatus;
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

export 'package:everslot/features/habits/application/habit_labels.dart';

/// Formats a goal value (integers without decimals, else one or two decimals).
String formatValue(BuildContext context, num value) {
  final v = value.toDouble();
  final decimals = v == v.roundToDouble() ? 0 : ((v * 10) == (v * 10).roundToDouble() ? 1 : 2);
  return AppFormat(context.localeName).number(v, decimals: decimals);
}

/// "15 reps", "20 min", "5 km" (duration goals are shown as h:mm when ≥ 60).
String formatAmount(BuildContext context, num value, String? unit) {
  final l = context.l10n;
  if (unit == HabitUnits.minutes && value >= 60) {
    return AppFormat(context.localeName, l10n: l).duration(value.round());
  }
  final label = l.unitLabel(unit, value);
  final number = formatValue(context, value);
  return label.isEmpty ? number : '$number $label';
}

/// Visual style of a period status: icon + color (+ the text label — never color alone).
class StatusStyle {
  const StatusStyle(this.icon, this.color);

  final IconData icon;
  final Color color;

  static StatusStyle of(BuildContext context, PeriodStatus s) {
    final c = context.appColors;
    return switch (s) {
      PeriodStatus.done => StatusStyle(Icons.check_circle, c.success),
      PeriodStatus.partial => StatusStyle(Icons.timelapse, c.warning),
      PeriodStatus.failed => StatusStyle(Icons.cancel, c.danger),
      PeriodStatus.missed => StatusStyle(Icons.radio_button_unchecked, c.missed),
      PeriodStatus.skipped => StatusStyle(Icons.redo, c.skipped),
      PeriodStatus.excused => StatusStyle(Icons.event_busy, c.info),
      PeriodStatus.frozen => StatusStyle(Icons.ac_unit, c.info),
      PeriodStatus.paused => StatusStyle(Icons.pause_circle_outline, c.skipped),
      PeriodStatus.pending => StatusStyle(Icons.radio_button_unchecked, context.colors.outline),
      PeriodStatus.notDue => StatusStyle(Icons.remove, context.colors.outlineVariant),
    };
  }
}

/// Status pill with icon + text + color.
class HabitStatusPill extends StatelessWidget {
  const HabitStatusPill(this.status, {super.key, this.dense = true});

  final PeriodStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final style = StatusStyle.of(context, status);
    return StatusPill(label: context.l10n.statusLabel(status), color: style.color, icon: style.icon, dense: dense);
  }
}

/// Colored round icon of a habit.
class HabitAvatar extends StatelessWidget {
  const HabitAvatar({required this.habit, super.key, this.size = 40});

  final Habit habit;
  final double size;

  @override
  Widget build(BuildContext context) {
    final argb = habit.color ?? CategoryPalette.at(habit.name.hashCode.abs() % 16);
    final brightness = Theme.of(context).brightness;
    final bg = CategoryColors.background(argb, brightness);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(
          IconCatalog.iconFor(habit.icon, fallback: habit.isQuit ? Icons.smoke_free : Icons.check),
          size: size * 0.55,
          color: CategoryColors.accent(argb, brightness),
        ),
      ),
    );
  }
}

/// Accent color of a habit (rings, bars).
Color habitAccent(BuildContext context, Habit habit) =>
    CategoryColors.accent(habit.color ?? CategoryPalette.at(habit.name.hashCode.abs() % 16), Theme.of(context).brightness);

/// "🔥 12" streak chip with a spoken label.
class StreakChip extends StatelessWidget {
  const StreakChip(this.days, {super.key});

  final int days;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.habitsStreakSemantics(days),
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.xs + 2, 2, Space.sm, 2),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, size: 14, color: days > 0 ? context.appColors.warning : context.colors.outline),
          const SizedBox(width: 2),
          Text(formatValue(context, days), style: context.text.labelMedium),
        ],
      ),
    ),
  );
}

/// 1–5 mood selector with text labels (T5.2.09).
class MoodSelector extends StatelessWidget {
  const MoodSelector({required this.value, required this.onChanged, super.key});

  final int? value;
  final ValueChanged<int?> onChanged;

  static const emojis = ['😣', '🙁', '😐', '🙂', '😄'];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Wrap(
      spacing: Space.xs,
      runSpacing: Space.xs,
      children: [
        for (var m = 1; m <= 5; m++)
          ChoiceChip(
            label: Text('${emojis[m - 1]} ${l.moodLabel(m)}'),
            selected: value == m,
            onSelected: (sel) => onChanged(sel ? m : null),
          ),
      ],
    );
  }
}

/// Navigation that works with the app router and — in isolated widget tests — plain routes.
abstract final class HabitNav {
  static Future<void> push(BuildContext context, String location, WidgetBuilder fallback) async {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      await router.push<void>(location);
      return;
    }
    await Navigator.of(context).push<void>(MaterialPageRoute(builder: fallback));
  }

  static String habit(String id) => AppLinks.habit(id);
  static String quit(String id) => AppLinks.quit(id);
  static String habitNew({String kind = 'build'}) => AppLinks.habitNew(kind: kind);
  static String habitEdit(String id) => AppLinks.habitEdit(id);
}
