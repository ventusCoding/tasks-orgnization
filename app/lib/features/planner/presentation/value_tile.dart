import 'package:material_ui/material_ui.dart';

/// A field row of the planner editors and sheets: an icon, the field [label] and its [value]
/// underneath it. The value never sits beside the label, so long values (Arabic, zone names,
/// category names) and text scale 2.0 wrap instead of overflowing the tile. [action] is a
/// compact trailing button (clear, open, unlink…); [note] an extra line under the value.
class ValueTile extends StatelessWidget {
  const ValueTile({
    required this.label,
    super.key,
    this.value,
    this.icon,
    this.leading,
    this.note,
    this.action,
    this.onTap,
    this.dense,
  });

  final String label;

  /// The field's current value (null = no second line).
  final String? value;
  final IconData? icon;

  /// Replaces [icon] (color dots, category icons).
  final Widget? leading;
  final Widget? note;
  final Widget? action;
  final VoidCallback? onTap;
  final bool? dense;

  @override
  Widget build(BuildContext context) {
    final v = value;
    final n = note;
    Widget? subtitle;
    if (v != null && n != null) {
      subtitle = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [Text(v), n],
      );
    } else if (v != null) {
      subtitle = Text(v);
    } else {
      subtitle = n;
    }
    return ListTile(
      dense: dense,
      leading: leading ?? (icon == null ? null : Icon(icon)),
      title: Text(label),
      subtitle: subtitle,
      trailing: action,
      onTap: onTap,
    );
  }
}
