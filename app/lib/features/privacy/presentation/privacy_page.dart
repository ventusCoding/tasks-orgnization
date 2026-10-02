import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart' show SettingsNs;
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/privacy/application/app_lock_controller.dart';
import 'package:everslot/features/settings/application/settings_providers.dart';
import 'package:everslot/features/settings/domain/settings_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Settings › Privacy & security (T8.3.09 / T8.3.10, crash-reporting opt-out).
class PrivacyPage extends ConsumerWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(privacySettingsProvider);
    final hideContent = ref.watch(notificationSettingsProvider.select((n) => n.hideContent));
    Future<void> update(PrivacySettings Function(PrivacySettings) change) =>
        ref.read(settingsWriterProvider).update(PrivacySettings.codec, change);
    String timeout(int seconds) => seconds == 0 ? l.appLockImmediately : l.appLockAfterMinutes(seconds ~/ 60);
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsPrivacy)),
      body: ListView(
        children: [
          SectionHeader(l.appLockSection),
          SwitchListTile(
            key: const ValueKey('privacy-app-lock'),
            secondary: const Icon(Icons.lock_outline),
            title: Text(l.appLockEnable),
            subtitle: Text(l.appLockEnableHint),
            value: s.appLockEnabled,
            onChanged: (on) async {
              if (on) {
                final auth = ref.read(authenticatorProvider);
                if (!await auth.isSupported()) {
                  if (context.mounted) showInfoSnackBar(context, l.appLockUnsupported);
                  return;
                }
                // Turning the lock on proves the user can unlock.
                if (!context.mounted || !await auth.authenticate(l.appLockReason)) return;
              }
              await update((p) => p.copyWith(appLockEnabled: on));
            },
          ),
          if (s.appLockEnabled)
            ListTile(
              key: const ValueKey('privacy-lock-timeout'),
              leading: const Icon(Icons.timer_outlined),
              title: Text(l.appLockTimeout),
              trailing: DropdownButton<int>(
                value: PrivacySettings.lockTimeouts.contains(s.appLockTimeoutSeconds) ? s.appLockTimeoutSeconds : 0,
                items: [
                  for (final t in PrivacySettings.lockTimeouts) DropdownMenuItem(value: t, child: Text(timeout(t))),
                ],
                onChanged: (t) => unawaited(update((p) => p.copyWith(appLockTimeoutSeconds: t))),
              ),
            ),
          SwitchListTile(
            key: const ValueKey('privacy-switcher'),
            secondary: const Icon(Icons.visibility_off_outlined),
            title: Text(l.privacyAppSwitcher),
            subtitle: Text(l.privacyAppSwitcherHint),
            value: s.appSwitcherPrivacy || s.appLockEnabled,
            onChanged: s.appLockEnabled ? null : (v) => unawaited(update((p) => p.copyWith(appSwitcherPrivacy: v))),
          ),
          SwitchListTile(
            key: const ValueKey('privacy-hide-notifications'),
            secondary: const Icon(Icons.notifications_off_outlined),
            title: Text(l.notifHideContent),
            subtitle: Text(l.privacyHideContentHint),
            value: hideContent,
            // Written under the arch §8.5 key and its alias so both readers agree.
            onChanged: (v) => unawaited(
              ref.read(settingsRepositoryProvider).update(SettingsNs.privacy, {
                'hideContentInNotifications': v,
                'hideNotificationContent': v,
              }),
            ),
          ),
          SectionHeader(l.privacyDiagnostics),
          SwitchListTile(
            key: const ValueKey('privacy-crash-reports'),
            secondary: const Icon(Icons.bug_report_outlined),
            title: Text(l.privacyCrashReports),
            subtitle: Text(l.privacyCrashReportsHint),
            value: s.crashReporting,
            onChanged: (v) => unawaited(update((p) => p.copyWith(crashReporting: v))),
          ),
        ],
      ),
    );
  }
}
