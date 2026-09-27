import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/auth/application/auth_providers.dart';
import 'package:everslot/features/auth/domain/auth_models.dart';
import 'package:everslot/features/profile/application/profile_providers.dart';
import 'package:everslot/features/profile/application/zone_tracker.dart';
import 'package:everslot/features/profile/domain/zone_labels.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// App-wide, non-blocking banners above every screen (installed in `MaterialApp.builder`):
/// device revoked, update required, session expired (T1.5.14) and the new-time-zone question
/// (T1.5.06). [onOpen] navigates (the host sits above the router).
class SessionBannerHost extends ConsumerWidget {
  const SessionBannerHost({required this.child, required this.onOpen, super.key});

  final Widget child;
  final void Function(String location) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banner = _banner(context, ref);
    if (banner == null) return child;
    return Column(
      children: [
        SafeArea(bottom: false, child: banner),
        Expanded(child: MediaQuery.removePadding(context: context, removeTop: true, child: child)),
      ],
    );
  }

  Widget? _banner(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final issues = ref.watch(sessionIssuesProvider);
    if (ref.watch(sessionProvider) == null) return null;
    if (issues.contains(SessionIssue.deviceRevoked)) {
      return _Banner(
        key: const ValueKey('banner-device-revoked'),
        icon: Icons.phonelink_erase,
        title: l.authDeviceRevokedTitle,
        message: l.authDeviceRevokedBody,
        actions: [
          (l.authExportFirst, () => onOpen('/settings/data')),
          (l.authSignOut, () => onOpen('/settings/account')),
        ],
      );
    }
    if (issues.contains(SessionIssue.updateRequired)) {
      return _Banner(
        key: const ValueKey('banner-update'),
        icon: Icons.system_update,
        message: l.authUpdateRequired,
        actions: [
          (l.actionRetry, () => unawaited(ref.read(syncServiceProvider)?.syncNow(manual: true))),
        ],
      );
    }
    if (issues.contains(SessionIssue.reauthRequired)) {
      return _Banner(
        key: const ValueKey('banner-reauth'),
        icon: Icons.lock_clock,
        message: l.authSessionExpiredBanner,
        actions: [(l.authSignInAgain, () => onOpen('/auth/sign-in?mode=reauth'))],
      );
    }
    final zone = ref.watch(zonePromptProvider);
    if (zone != null) {
      final home = ref.watch(profileProvider).value?.homeTimeZone ?? 'UTC';
      final tracker = ref.read(zoneTrackerProvider);
      return _Banner(
        key: const ValueKey('banner-zone'),
        icon: Icons.flight_land,
        title: l.authZoneChangedTitle,
        message: l.authZoneChangedBody(ZoneLabels.city(zone)),
        actions: [
          (l.authZoneKeepHome(ZoneLabels.city(home)), () => unawaited(tracker.answerPrompt(makeHome: false))),
          (l.authZoneMakeHome, () => unawaited(tracker.answerPrompt(makeHome: true))),
        ],
      );
    }
    return null;
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.message, required this.actions, super.key, this.title});

  final IconData icon;
  final String? title;
  final String message;
  final List<(String, VoidCallback)> actions;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    container: true,
    child: MaterialBanner(
      leading: Icon(icon, color: context.colors.primary),
      backgroundColor: context.colors.surfaceContainerHigh,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) Text(title!, style: context.text.titleSmall),
          Text(message),
        ],
      ),
      actions: [for (final a in actions) TextButton(onPressed: a.$2, child: Text(a.$1))],
    ),
  );
}
