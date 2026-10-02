import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/settings/application/settings_providers.dart';
import 'package:everslot/features/settings/domain/settings_models.dart';
import 'package:everslot/features/settings/presentation/widgets/settings_tiles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Settings › Accessibility (T8.3.12). The options travel through the theme
/// ([AccessibilityPrefs]) and `ReduceMotionScope` / `Haptics`.
class AccessibilityPage extends ConsumerWidget {
  const AccessibilityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(appearanceSettingsProvider);
    Future<void> set(AppearanceSettings Function(AppearanceSettings s) change) =>
        ref.read(settingsWriterProvider).update(AppearanceSettings.codec, change);
    return SettingsPageScaffold(
      title: l.settingsAccessibility,
      children: [
        SettingsSwitchTile(
          key: const ValueKey('a11y-reduce-motion'),
          icon: Icons.motion_photos_off_outlined,
          title: l.a11yReduceMotion,
          subtitle: l.a11yReduceMotionHint,
          value: s.reduceMotion,
          onChanged: (v) => set((s) => s.copyWith(reduceMotion: v)),
        ),
        SettingsSwitchTile(
          key: const ValueKey('a11y-haptics'),
          icon: Icons.vibration,
          title: l.a11yHaptics,
          subtitle: l.a11yHapticsHint,
          value: s.haptics,
          onChanged: (v) => set((s) => s.copyWith(haptics: v)),
        ),
        SettingsSwitchTile(
          key: const ValueKey('a11y-high-contrast'),
          icon: Icons.contrast,
          title: l.a11yHighContrast,
          subtitle: l.a11yHighContrastHint,
          value: s.highContrastCategories,
          onChanged: (v) => set((s) => s.copyWith(highContrastCategories: v)),
        ),
        SettingsSwitchTile(
          key: const ValueKey('a11y-large-table'),
          icon: Icons.format_size,
          title: l.a11yLargeTable,
          subtitle: l.a11yLargeTableHint,
          value: s.largeWeekTableText,
          onChanged: (v) => set((s) => s.copyWith(largeWeekTableText: v)),
        ),
        SettingsSwitchTile(
          key: const ValueKey('a11y-status-labels'),
          icon: Icons.label_outline,
          title: l.a11yStatusLabels,
          subtitle: l.a11yStatusLabelsHint,
          value: s.statusPillLabels,
          onChanged: (v) => set((s) => s.copyWith(statusPillLabels: v)),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.md, Space.lg, Space.lg),
          child: Text(l.a11ySystemHint, style: context.text.bodySmall),
        ),
        SectionHeader(l.settingsPreview),
        const _CategoryPreview(),
      ],
    );
  }
}

/// A few category tiles in the current palette, so the contrast option is visible at once.
class _CategoryPreview extends StatelessWidget {
  const _CategoryPreview();

  @override
  Widget build(BuildContext context) {
    final brightness = context.theme.brightness;
    final hc = context.a11y.highContrastCategories;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.xl),
      child: Wrap(
        spacing: Space.sm,
        runSpacing: Space.sm,
        children: [
          for (final argb in CategoryPalette.colors.take(6))
            Builder(
              builder: (context) {
                final bg = CategoryColors.background(argb, brightness, highContrast: hc);
                return Container(
                  key: ValueKey('a11y-preview-$argb'),
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.md, vertical: Space.sm),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(Radii.sm),
                    border: BorderDirectional(
                      start: BorderSide(color: CategoryColors.accent(argb, brightness, highContrast: hc), width: 3),
                    ),
                  ),
                  child: Text(
                    '09:00',
                    style: TextStyle(
                      color: CategoryColors.onBackground(bg),
                      fontSize: 12 + context.a11y.tileTextBoost,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
