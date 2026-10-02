import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/integrations/presentation/integrations_settings_page.dart';
import 'package:everslot/features/notifications/presentation/notifications_settings_page.dart';
import 'package:everslot/features/privacy/presentation/privacy_page.dart';
import 'package:everslot/features/profile/presentation/account_page.dart';
import 'package:everslot/features/settings/presentation/pages/about_page.dart';
import 'package:everslot/features/settings/presentation/pages/accessibility_page.dart';
import 'package:everslot/features/settings/presentation/pages/appearance_page.dart';
import 'package:everslot/features/settings/presentation/pages/data_page.dart';
import 'package:everslot/features/settings/presentation/pages/regional_page.dart';
import 'package:everslot/features/settings/presentation/pages/section_pages.dart';
import 'package:everslot/features/settings/presentation/pages/sync_page.dart';
import 'package:material_ui/material_ui.dart';

/// `/settings/:page` (T8.3.01): dispatches to the settings page of [page].
class SettingsPageScreen extends StatelessWidget {
  const SettingsPageScreen({required this.page, super.key});

  final String page;

  /// Pages reachable from the root screen.
  static const pages = {
    'account',
    'appearance',
    'regional',
    'accessibility',
    'plan',
    'lists',
    'habits',
    'insights',
    'notifications',
    'sync',
    'data',
    'privacy',
    'about',
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return switch (page) {
      'account' => const AccountPage(),
      'appearance' => const AppearancePage(),
      'regional' => const RegionalPage(),
      'sync' => const SyncPage(),
      'notifications' => Scaffold(
        appBar: AppBar(title: Text(l.notifSettingsTitle)),
        body: const NotificationsSettingsPage(embedded: true),
      ),
      'accessibility' => const AccessibilityPage(),
      'plan' => const PlanDefaultsPage(),
      'lists' => const ListsDefaultsPage(),
      'habits' => const HabitsDefaultsPage(),
      'insights' => const InsightsDefaultsPage(),
      'data' => const DataPage(),
      'integrations' => const IntegrationsSettingsPage(),
      'privacy' => const PrivacyPage(),
      'about' => const AboutPage(),
      _ => Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: Icons.settings_suggest_outlined, title: l.settingsUnknownPage),
      ),
    };
  }
}
