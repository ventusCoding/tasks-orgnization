import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/item_time.dart';
import 'package:material_ui/material_ui.dart';

/// Design tokens per status (T4.3.04): icon + color + label, never color alone.
abstract final class StatusStyle {
  static IconData icon(ItemStatus s) => switch (s) {
    ItemStatus.todo => Icons.check_box_outline_blank,
    ItemStatus.ongoing => Icons.play_circle_outline,
    ItemStatus.waiting => Icons.schedule,
    ItemStatus.blocked => Icons.block,
    ItemStatus.completed => Icons.check_box,
    ItemStatus.cancelled => Icons.cancel_outlined,
  };

  static Color color(BuildContext context, ItemStatus s) {
    final c = context.appColors;
    return switch (s) {
      ItemStatus.todo => c.todo,
      ItemStatus.ongoing => c.ongoing,
      ItemStatus.waiting => c.waiting,
      ItemStatus.blocked => c.blocked,
      ItemStatus.completed => c.completed,
      ItemStatus.cancelled => c.cancelled,
    };
  }

  static String label(BuildContext context, ItemStatus s) {
    final l = context.l10n;
    return switch (s) {
      ItemStatus.todo => l.statusTodo,
      ItemStatus.ongoing => l.statusOngoing,
      ItemStatus.waiting => l.statusWaiting,
      ItemStatus.blocked => l.statusBlocked,
      ItemStatus.completed => l.statusCompleted,
      ItemStatus.cancelled => l.statusCancelled,
    };
  }

  /// Escalated color for aged waiting/blocked pills (T4.3.11).
  static Color escalated(BuildContext context, ItemStatus s, AgeLevel level) => switch (level) {
    AgeLevel.normal => color(context, s),
    AgeLevel.warn => context.appColors.warning,
    AgeLevel.alert => context.appColors.danger,
  };

  /// [color] shaded (only as much as needed) so pill text keeps ≥ 4.5:1 on the pill's own tint
  /// after 8-bit rendering (T4.3.04). The design-system pill targets exactly 4.5, which renders as
  /// 4.48 for some statuses, so status pills aim for 4.6.
  static Color pillColor(BuildContext context, Color color) {
    final surface = context.colors.surface;
    bool readable(Color c) =>
        CategoryColors.contrastRatio(c, Color.alphaBlend(c.withValues(alpha: 0.14), surface)) >= 4.6;
    if (readable(color)) return color;
    final towards = surface.computeLuminance() > 0.18 ? Colors.black : Colors.white;
    var lo = 0.0;
    var hi = 1.0;
    for (var i = 0; i < 20; i++) {
      final mid = (lo + hi) / 2;
      if (readable(Color.lerp(color, towards, mid)!)) {
        hi = mid;
      } else {
        lo = mid;
      }
    }
    return Color.lerp(color, towards, hi)!;
  }
}

/// Localized compact age ("4 d", "2 h").
String formatAge(BuildContext context, DateTime since, DateTime now) {
  final (n, unit) = ItemTimeRules.age(since, now);
  final l = context.l10n;
  return switch (unit) {
    'd' => l.statusAgeDays(n),
    'h' => l.statusAgeHours(n),
    _ => l.statusAgeMinutes(n),
  };
}

/// The leading status control of a row: checkbox for todo/completed, icons for the others,
/// a bullet when checkboxes are hidden. 48 dp target (T4.2.08 / T4.3.03).
class StatusControl extends StatelessWidget {
  const StatusControl({
    required this.status,
    super.key,
    this.onTap,
    this.onLongPress,
    this.bullet = false,
    this.size = 22,
    this.semanticsLabel,
  });

  final ItemStatus status;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool bullet;
  final double size;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final color = StatusStyle.color(context, status);
    final Widget glyph = bullet
        ? Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: context.colors.onSurfaceVariant, shape: BoxShape.circle),
          )
        : Icon(
            StatusStyle.icon(status),
            size: size,
            color: status == ItemStatus.todo ? context.colors.onSurfaceVariant : color,
          );
    return Semantics(
      button: true,
      checked: bullet ? null : status == ItemStatus.completed,
      label: semanticsLabel ?? StatusStyle.label(context, status),
      child: InkResponse(
        onTap: onTap,
        onLongPress: onLongPress,
        radius: 24,
        child: SizedBox(width: 48, height: 48, child: Center(child: glyph)),
      ),
    );
  }
}

/// "Waiting · 4 d" pill (T4.3.04 / T4.3.11), escalating with age.
class ItemStatusPill extends StatelessWidget {
  const ItemStatusPill({required this.status, required this.now, super.key, this.since, this.dense = true});

  final ItemStatus status;
  final DateTime? since;
  final DateTime now;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final label = StatusStyle.label(context, status);
    final level = ItemTimeRules.escalationFor(status, since, now);
    final text = since == null ? label : context.l10n.statusWithAge(label, formatAge(context, since!, now));
    // Scales down (never overflows) when a narrow column can't fit it at large text scales.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: StatusPill(
        label: text,
        color: StatusStyle.pillColor(context, StatusStyle.escalated(context, status, level)),
        icon: StatusStyle.icon(status),
        dense: dense,
      ),
    );
  }
}
