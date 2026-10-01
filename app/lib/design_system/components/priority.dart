import 'package:everslot/design_system/l10n_x.dart';
import 'package:everslot/design_system/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// Priority 0–4 (T2.3.03): None, Low, Medium, High, Urgent — icon + color + label.
abstract final class PriorityStyle {
  static String label(BuildContext context, int priority) {
    final l = context.l10n;
    return switch (priority) {
      1 => l.priorityLow,
      2 => l.priorityMedium,
      3 => l.priorityHigh,
      4 => l.priorityUrgent,
      _ => l.priorityNone,
    };
  }

  static Color color(int priority) => switch (priority) {
    1 => const Color(0xFF3B82F6),
    2 => const Color(0xFFF59E0B),
    3 => const Color(0xFFF97316),
    4 => const Color(0xFFDC2626),
    _ => const Color(0xFF9CA3AF),
  };

  /// Readable text/icon color of a priority on [surface] (≥ 4.5:1 in both themes).
  static Color foreground(int priority, Color surface) => CategoryColors.readableOn(color(priority), surface);

  /// [foreground] on the current theme surface.
  static Color foregroundOf(BuildContext context, int priority) =>
      foreground(priority, Theme.of(context).colorScheme.surface);

  static IconData icon(int priority) => switch (priority) {
    0 => Icons.outlined_flag,
    4 => Icons.priority_high,
    _ => Icons.flag,
  };
}

class PriorityBadge extends StatelessWidget {
  const PriorityBadge(this.priority, {super.key, this.showLabel = false});

  final int priority;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    if (priority == 0 && !showLabel) return const SizedBox.shrink();
    final color = PriorityStyle.foregroundOf(context, priority);
    final label = PriorityStyle.label(context, priority);
    return Semantics(
      label: label,
      excludeSemantics: true, // announced once, not "High, High"
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PriorityStyle.icon(priority), size: 16, color: color),
          if (showLabel) ...[const SizedBox(width: 4), Text(label, style: TextStyle(color: color))],
        ],
      ),
    );
  }
}

/// Picker for priority 0–4.
class PrioritySelector extends StatelessWidget {
  const PrioritySelector({required this.value, required this.onChanged, super.key});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    children: [
      for (var p = 0; p <= 4; p++)
        ChoiceChip(
          selected: value == p,
          avatar: Icon(PriorityStyle.icon(p), size: 16, color: PriorityStyle.foregroundOf(context, p)),
          label: Text(PriorityStyle.label(context, p)),
          onSelected: (_) => onChanged(p),
        ),
    ],
  );
}
