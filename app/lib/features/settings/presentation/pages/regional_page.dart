import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/profile/application/profile_providers.dart';
import 'package:everslot/features/profile/domain/profile.dart';
import 'package:everslot/features/profile/presentation/zone_picker.dart';
import 'package:everslot/features/settings/application/settings_providers.dart';
import 'package:everslot/features/settings/domain/settings_models.dart';
import 'package:everslot/features/settings/presentation/widgets/choice_sheet.dart';
import 'package:everslot/features/settings/presentation/widgets/settings_tiles.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Currencies offered for quit-tracker savings (ISO 4217), most used first.
const commonCurrencies = [
  'EUR',
  'USD',
  'GBP',
  'TND',
  'MAD',
  'DZD',
  'EGP',
  'SAR',
  'AED',
  'QAR',
  'KWD',
  'CAD',
  'CHF',
  'AUD',
  'JPY',
  'CNY',
  'INR',
  'TRY',
  'XOF',
  'XAF',
];

/// Settings › Regional (T8.3.03): home zone (manual or following the device), current zone,
/// week start, 12/24 h with preview, habit day start (future logs only), savings currency.
class RegionalPage extends ConsumerWidget {
  const RegionalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final profile = ref.watch(profileProvider).value;
    final prefs = ref.watch(userPreferencesProvider);
    final regional = ref.watch(regionalSettingsProvider);
    final habits = ref.watch(habitsDefaultsProvider);
    final writer = ref.read(settingsWriterProvider);
    final repo = ref.read(profileRepositoryProvider);
    final deviceZone = ref.watch(deviceZoneProvider);
    final now = ref.watch(clockProvider).nowUtc();
    final tag = Localizations.localeOf(context).toLanguageTag();
    final format = AppFormat(tag, use24h: prefs.use24h, l10n: l);
    final homeZone = profile?.homeTimeZone ?? prefs.homeTimeZone;
    final weekStart = profile?.weekStart ?? prefs.weekStart.iso;

    return SettingsPageScaffold(
      title: l.settingsRegional,
      children: [
        SettingsValueTile(
          key: const ValueKey('regional-home-zone'),
          icon: Icons.home_outlined,
          title: l.settingsHomeZone,
          value: zoneDisplay(homeZone, now),
          subtitle: l.settingsHomeZoneSubtitle,
          onTap: regional.homeZoneAuto
              ? null
              : () async {
                  final zone = await pickTimeZone(
                    context,
                    current: homeZone,
                    detected: deviceZone,
                    title: l.settingsHomeZone,
                  );
                  if (zone != null) await repo.update(homeTimeZone: zone);
                },
        ),
        SettingsSwitchTile(
          key: const ValueKey('regional-home-auto'),
          icon: Icons.my_location,
          title: l.settingsHomeZoneAuto,
          subtitle: l.settingsHomeZoneAutoSubtitle,
          value: regional.homeZoneAuto,
          onChanged: (v) async {
            await writer.update(RegionalSettings.codec, (s) => s.copyWith(homeZoneAuto: v));
            if (v && homeZone != deviceZone) await repo.update(homeTimeZone: deviceZone);
          },
        ),
        ListTile(
          key: const ValueKey('regional-current-zone'),
          leading: const Icon(Icons.public),
          title: Text(l.settingsCurrentZone),
          subtitle: Text(zoneDisplay(deviceZone, now)),
        ),
        const Divider(),
        SettingsValueTile(
          key: const ValueKey('regional-week-start'),
          icon: Icons.date_range,
          title: l.settingsWeekStart,
          value: format.weekdayLong(Weekday.fromIso(weekStart)),
          onTap: () async {
            final day = await pickChoice<int>(
              context,
              title: l.settingsWeekStart,
              selected: weekStart,
              choices: [
                for (final iso in const [1, 6, 7, 2, 3, 4, 5]) Choice(iso, format.weekdayLong(Weekday.fromIso(iso))),
              ],
            );
            if (day != null) await repo.update(weekStart: day);
          },
        ),
        SettingsSegmentTile<bool>(
          key: const ValueKey('regional-clock'),
          icon: Icons.schedule,
          title: l.settingsClock,
          selected: prefs.use24h,
          segments: [
            (false, '${l.settingsClock12} · ${AppFormat(tag, use24h: false).time(LocalTime(13, 30))}'),
            (true, '${l.settingsClock24} · ${AppFormat(tag).time(LocalTime(13, 30))}'),
          ],
          onChanged: (v) => repo.update(timeFormat: v ? TimeFormat.h24 : TimeFormat.h12),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.xl * 2 + Space.lg, 0, Space.lg, Space.md),
          child: Text(
            '${l.settingsPreview}: ${format.dayLong(ref.watch(zoneResolverProvider).toLocal(now, deviceZone).date)} · '
            '${format.time(LocalTime(18, 5))}',
            key: const ValueKey('regional-preview'),
            style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ),
        const Divider(),
        SettingsValueTile(
          key: const ValueKey('regional-day-start'),
          icon: Icons.bedtime_outlined,
          title: l.settingsDayStart,
          value: format.time(LocalTime.fromMinuteOfDay(habits.dayStartMinutes)),
          subtitle: l.settingsDayStartSubtitle,
          onTap: () async {
            final t = await pickTime(
              context,
              initial: LocalTime.fromMinuteOfDay(habits.dayStartMinutes),
              use24h: prefs.use24h,
            );
            if (t != null) {
              await writer.update(HabitsDefaults.codec, (s) => s.copyWith(dayStartMinutes: t.minuteOfDay % 1440));
            }
          },
        ),
        SettingsValueTile(
          key: const ValueKey('regional-currency'),
          icon: Icons.savings_outlined,
          title: l.settingsCurrency,
          value: '${regional.currency} · ${format.currency(12.5, regional.currency)}',
          onTap: () async {
            final code = await pickChoice<String>(
              context,
              title: l.settingsCurrency,
              selected: regional.currency,
              choices: [for (final c in commonCurrencies) Choice(c, '$c · ${format.currency(12.5, c)}')],
            );
            if (code != null) await writer.update(RegionalSettings.codec, (s) => s.copyWith(currency: code));
          },
        ),
      ],
    );
  }
}
