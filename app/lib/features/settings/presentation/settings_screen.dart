import 'package:everslot/core/env/env.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/profile/application/profile_providers.dart';
import 'package:everslot/features/settings/presentation/widgets/settings_tiles.dart';
import 'package:everslot/features/settings/presentation/widgets/sync_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Settings root (T8.3.01): Account · General · Sections · Data & privacy · Help.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final session = ref.watch(sessionProvider);
    final profile = ref.watch(profileProvider).value;
    final accountSubtitle = switch (session) {
      null => null,
      final s when s.isLocalOnly => l.settingsAccountLocalOnly,
      final s when s.isAnonymous => l.authGuestAccount,
      final s => s.email,
    };
    // Hidden gesture to the dev debug menu (T1.3.16): long-press the title, dev builds only.
    final devTools = Env.devToolsCompiled && ref.watch(envProvider).isDev;
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          key: const ValueKey('settings-title'),
          onLongPress: devTools ? () => GoRouter.maybeOf(context)?.push(AppLinks.debug()) : null,
          child: Text(l.settingsTitle),
        ),
        actions: const [SyncIndicator()],
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.only(bottom: Space.xxl),
        children: [
          ListTile(
            key: const ValueKey('settings-account'),
            leading: CircleAvatar(
              child: Text(_initials(profile?.displayName ?? session?.email), style: context.text.titleMedium),
            ),
            title: Text(profile?.displayName ?? l.settingsAccount),
            subtitle: accountSubtitle == null ? null : Text(accountSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => GoRouter.maybeOf(context)?.push(AppLinks.settings('account')),
          ),
          SectionHeader(l.settingsGroupGeneral),
          SettingsNavTile(
            icon: Icons.palette_outlined,
            title: l.settingsAppearance,
            subtitle: l.settingsAppearanceSubtitle,
            location: AppLinks.settings('appearance'),
          ),
          SettingsNavTile(
            icon: Icons.public,
            title: l.settingsRegional,
            subtitle: l.settingsRegionalSubtitle,
            location: AppLinks.settings('regional'),
          ),
          SettingsNavTile(
            icon: Icons.accessibility_new,
            title: l.settingsAccessibility,
            subtitle: l.settingsAccessibilitySubtitle,
            location: AppLinks.settings('accessibility'),
          ),
          SectionHeader(l.settingsGroupSections),
          SettingsNavTile(
            icon: Icons.calendar_view_week_outlined,
            title: l.settingsPlan,
            subtitle: l.settingsPlanSubtitle,
            location: AppLinks.settings('plan'),
          ),
          SettingsNavTile(
            icon: Icons.checklist,
            title: l.settingsLists,
            subtitle: l.settingsListsSubtitle,
            location: AppLinks.settings('lists'),
          ),
          SettingsNavTile(
            icon: Icons.local_fire_department_outlined,
            title: l.settingsHabits,
            subtitle: l.settingsHabitsSubtitle,
            location: AppLinks.settings('habits'),
          ),
          SettingsNavTile(
            icon: Icons.insights_outlined,
            title: l.settingsInsights,
            subtitle: l.settingsInsightsSubtitle,
            location: AppLinks.settings('insights'),
          ),
          SettingsNavTile(
            icon: Icons.notifications_none,
            title: l.notifSettingsTitle,
            subtitle: l.settingsNotificationsSubtitle,
            location: AppLinks.settings('notifications'),
          ),
          SettingsNavTile(
            icon: Icons.label_outline,
            title: l.categoriesTitle,
            subtitle: l.settingsOrganizationSubtitle,
            location: AppLinks.categories(),
          ),
          SettingsNavTile(icon: Icons.sell_outlined, title: l.tagsTitle, location: AppLinks.tags()),
          SettingsNavTile(
            icon: Icons.widgets_outlined,
            title: l.settingsIntegrations,
            subtitle: l.settingsIntegrationsSubtitle,
            location: AppLinks.settings('integrations'),
          ),
          SectionHeader(l.settingsGroupData),
          SettingsNavTile(
            icon: Icons.sync,
            title: l.settingsSyncData,
            subtitle: l.settingsSyncDataSubtitle,
            location: AppLinks.settings('sync'),
          ),
          SettingsNavTile(
            icon: Icons.lock_outline,
            title: l.settingsPrivacy,
            subtitle: l.settingsPrivacySubtitle,
            location: AppLinks.settings('privacy'),
          ),
          SettingsNavTile(icon: Icons.delete_outline, title: l.settingsTrash, location: AppLinks.trash()),
          SectionHeader(l.settingsGroupHelp),
          SettingsNavTile(
            icon: Icons.info_outline,
            title: l.settingsAbout,
            subtitle: l.settingsAboutSubtitle,
            location: AppLinks.settings('about'),
          ),
        ],
      ),
    );
  }

  static String _initials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'[\s@._-]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = String.fromCharCodes(parts.first.runes.take(1));
    final second = parts.length > 1 ? String.fromCharCodes(parts[1].runes.take(1)) : '';
    return (first + second).toUpperCase();
  }
}
