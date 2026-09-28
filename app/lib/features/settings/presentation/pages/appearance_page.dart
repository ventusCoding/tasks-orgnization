import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/profile/application/profile_providers.dart';
import 'package:everslot/features/settings/application/settings_providers.dart';
import 'package:everslot/features/settings/domain/settings_models.dart';
import 'package:everslot/features/settings/presentation/widgets/choice_sheet.dart';
import 'package:everslot/features/settings/presentation/widgets/settings_tiles.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Settings › Appearance (T8.3.02): theme, density, language (instant switch + RTL flip),
/// Arabic-Indic digits, live preview.
class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(appearanceSettingsProvider);
    final writer = ref.read(settingsWriterProvider);
    final locale = ref.watch(profileProvider).value?.locale;
    Future<void> set(AppearanceSettings Function(AppearanceSettings s) change) =>
        writer.update(AppearanceSettings.codec, change);

    return SettingsPageScaffold(
      title: l.settingsAppearance,
      children: [
        SettingsSegmentTile<ThemePreference>(
          key: const ValueKey('appearance-theme'),
          icon: Icons.brightness_6_outlined,
          title: l.settingsTheme,
          selected: s.theme,
          segments: [
            (ThemePreference.system, l.settingsThemeSystem),
            (ThemePreference.light, l.settingsThemeLight),
            (ThemePreference.dark, l.settingsThemeDark),
          ],
          onChanged: (v) => set((s) => s.copyWith(theme: v)),
        ),
        SettingsSegmentTile<DensityPreference>(
          key: const ValueKey('appearance-density'),
          icon: Icons.density_medium,
          title: l.settingsDensity,
          selected: s.density,
          segments: [
            (DensityPreference.comfortable, l.settingsDensityComfortable),
            (DensityPreference.compact, l.settingsDensityCompact),
          ],
          onChanged: (v) => set((s) => s.copyWith(density: v)),
        ),
        SettingsValueTile(
          key: const ValueKey('appearance-language'),
          icon: Icons.translate,
          title: l.settingsLanguage,
          value: languageLabel(context, locale),
          onTap: () async {
            final code = await pickChoice<String>(
              context,
              title: l.settingsLanguage,
              choices: languageChoices(context),
              selected: locale ?? '',
            );
            if (code != null) await ref.read(profileRepositoryProvider).update(locale: code.isEmpty ? null : code);
          },
        ),
        SettingsSwitchTile(
          key: const ValueKey('appearance-arabic-digits'),
          icon: Icons.pin_outlined,
          title: l.settingsArabicDigits,
          subtitle: l.settingsArabicDigitsSubtitle,
          value: s.arabicDigits,
          onChanged: (v) => set((s) => s.copyWith(arabicDigits: v)),
        ),
        SectionHeader(l.settingsPreview),
        const _Preview(),
      ],
    );
  }
}

class _Preview extends ConsumerWidget {
  const _Preview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userPreferencesProvider);
    final l = context.l10n;
    final tag = Localizations.localeOf(context).toLanguageTag();
    final format = AppFormat(
      tag,
      use24h: prefs.use24h,
      l10n: l,
      arabicDigits: prefs.useArabicDigits && tag.startsWith('ar'),
    );
    final now = ref.watch(clockProvider).nowUtc();
    final today = ref.watch(zoneResolverProvider).toLocal(now, prefs.currentTimeZone).date;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(format.dayLong(today), style: context.text.titleMedium),
              const SizedBox(height: Space.xs),
              Text(
                '${format.time(LocalTime(9, 30))} – ${format.time(LocalTime(10, 45))} · ${format.duration(75)}',
                style: context.text.bodyMedium,
              ),
              const SizedBox(height: Space.md),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  StatusPill(label: l.syncIdle, color: context.appColors.success, icon: Icons.check),
                  StatusPill(label: l.priorityHigh, color: context.appColors.warning, icon: Icons.flag_outlined),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
