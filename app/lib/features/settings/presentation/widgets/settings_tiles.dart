import 'package:everslot/design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Navigation row of the settings screens.
class SettingsNavTile extends StatelessWidget {
  const SettingsNavTile({
    required this.icon,
    required this.title,
    required this.location,
    super.key,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String location;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => GoRouter.maybeOf(context)?.push(location),
  );
}

/// A row showing the current value; tapping opens [onTap] (a picker).
class SettingsValueTile extends StatelessWidget {
  const SettingsValueTile({
    required this.title,
    required this.value,
    required this.onTap,
    super.key,
    this.icon,
    this.subtitle,
  });

  final IconData? icon;
  final String title;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: icon == null ? null : Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle == null ? value : '$value\n$subtitle'),
    isThreeLine: subtitle != null,
    trailing: onTap == null ? null : const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}

/// A labelled switch (the whole row toggles; the switch carries the semantics).
class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
    super.key,
    this.icon,
    this.subtitle,
  });

  final IconData? icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    secondary: icon == null ? null : Icon(icon),
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    value: value,
    onChanged: onChanged,
  );
}

/// Segmented single choice with a title row (theme, density, clock…).
class SettingsSegmentTile<T> extends StatelessWidget {
  const SettingsSegmentTile({
    required this.title,
    required this.segments,
    required this.selected,
    required this.onChanged,
    super.key,
    this.icon,
  });

  final IconData? icon;
  final String title;
  final List<(T value, String label)> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.md, Space.lg, Space.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: context.colors.onSurfaceVariant),
              const SizedBox(width: Space.xl),
            ],
            Expanded(child: Text(title, style: context.text.bodyLarge)),
          ],
        ),
        const SizedBox(height: Space.sm),
        SegmentedButton<T>(
          segments: [for (final s in segments) ButtonSegment<T>(value: s.$1, label: Text(s.$2))],
          selected: {selected},
          showSelectedIcon: false,
          onSelectionChanged: (v) => onChanged(v.first),
        ),
      ],
    ),
  );
}

/// Scaffold of a settings page.
class SettingsPageScaffold extends StatelessWidget {
  const SettingsPageScaffold({required this.title, required this.children, super.key, this.actions});

  final String title;
  final List<Widget> children;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), actions: actions),
    body: ListView(padding: const EdgeInsetsDirectional.only(bottom: Space.xxl), children: children),
  );
}
