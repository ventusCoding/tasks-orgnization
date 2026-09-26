import 'dart:async';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/notifications/application/capabilities_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Primer shown before the OS notification prompt (T7.2.05). Never shown twice per session;
/// returns true when notifications end up allowed.
Future<bool> showNotificationPrimer(
  BuildContext context,
  WidgetRef ref, {
  bool provisional = false,
}) async {
  final controller = ref.read(notificationCapabilitiesProvider.notifier);
  final caps = ref.read(notificationCapabilitiesProvider);
  if (caps.notifications) return true;
  if (!controller.primersShown.add('notifications')) return false;
  final l = context.l10n;
  final allow = await showAppSheet<bool>(
    context,
    title: l.notifPrimerTitle,
    builder: (ctx) => _PrimerBody(
      icon: Icons.notifications_active_outlined,
      body: l.notifPrimerBody,
      allowLabel: l.notifPrimerAllow,
      laterLabel: l.notifPrimerLater,
    ),
  );
  if (allow != true) return false;
  return controller.requestNotifications(provisional: provisional);
}

/// Android "precise reminders" primer before the exact-alarm settings page (T7.2.04/05).
Future<bool> showExactAlarmPrimer(BuildContext context, WidgetRef ref) async {
  final controller = ref.read(notificationCapabilitiesProvider.notifier);
  if (ref.read(notificationCapabilitiesProvider).exactAlarm) return true;
  if (!controller.primersShown.add('exact')) return false;
  final l = context.l10n;
  final allow = await showAppSheet<bool>(
    context,
    title: l.notifPrimerExactTitle,
    builder: (ctx) => _PrimerBody(
      icon: Icons.alarm_on_outlined,
      body: l.notifPrimerExactBody,
      allowLabel: l.notifAllowPrecise,
      laterLabel: l.notifPrimerLater,
    ),
  );
  if (allow != true) return false;
  return controller.requestExactAlarms();
}

/// iOS time-sensitive explanation (shown when a rule uses high/urgent importance).
Future<void> showTimeSensitivePrimer(
  BuildContext context,
  WidgetRef ref,
) async {
  final controller = ref.read(notificationCapabilitiesProvider.notifier);
  if (!controller.primersShown.add('timeSensitive')) return;
  final l = context.l10n;
  await showAppSheet<bool>(
    context,
    title: l.notifPrimerTimeSensitiveTitle,
    builder: (ctx) => _PrimerBody(
      icon: Icons.priority_high,
      body: l.notifPrimerTimeSensitiveBody,
      allowLabel: l.actionContinue,
    ),
  );
}

class _PrimerBody extends StatelessWidget {
  const _PrimerBody({
    required this.icon,
    required this.body,
    required this.allowLabel,
    this.laterLabel,
  });

  final IconData icon;
  final String body;
  final String allowLabel;
  final String? laterLabel;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsetsDirectional.fromSTEB(
      Space.xl,
      0,
      Space.xl,
      Space.xl,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(icon, size: 48, color: context.colors.primary),
        const SizedBox(height: Space.lg),
        Text(body, style: context.text.bodyLarge),
        const SizedBox(height: Space.xl),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(allowLabel),
        ),
        if (laterLabel != null)
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(laterLabel!),
          ),
      ],
    ),
  );
}

/// Inline recovery banner (rule editors, settings): notifications off, channels blocked, or
/// exact alarms unavailable — each with a one-tap fix (T7.2.05).
class NotificationPermissionBanner extends ConsumerWidget {
  const NotificationPermissionBanner({super.key, this.showExact = true});

  final bool showExact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caps = ref.watch(notificationCapabilitiesProvider);
    final l = context.l10n;
    if (!caps.determined) return const SizedBox.shrink();
    final controller = ref.read(notificationCapabilitiesProvider.notifier);
    if (!caps.notifications) {
      return _Banner(
        icon: Icons.notifications_off_outlined,
        title: l.notifPermissionOff,
        body: l.notifPermissionOffBody,
        actionLabel: l.notifEnable,
        onAction: () async {
          final granted = await showNotificationPrimer(context, ref);
          if (!granted) await controller.openSettings();
        },
      );
    }
    if (caps.blockedChannels.isNotEmpty) {
      return _Banner(
        icon: Icons.block,
        title: l.notifChannelBlocked,
        actionLabel: l.notifOpenSettings,
        onAction: () async {
          await controller.openSettings();
        },
      );
    }
    if (showExact && caps.isAndroid && !caps.exactAlarm) {
      return _Banner(
        icon: Icons.alarm_off,
        title: l.notifExactOff,
        body: l.notifExactOffBody,
        actionLabel: l.notifAllowPrecise,
        onAction: () async {
          await showExactAlarmPrimer(context, ref);
        },
      );
    }
    return const SizedBox.shrink();
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.body,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsetsDirectional.fromSTEB(
      Space.lg,
      Space.sm,
      Space.lg,
      Space.sm,
    ),
    color: context.colors.tertiaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(Space.md),
      child: Row(
        children: [
          Icon(icon, color: context.colors.onTertiaryContainer),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.text.titleSmall?.copyWith(
                    color: context.colors.onTertiaryContainer,
                  ),
                ),
                if (body != null)
                  Text(
                    body!,
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.onTertiaryContainer,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => unawaited(onAction()),
            child: Text(actionLabel),
          ),
        ],
      ),
    ),
  );
}
