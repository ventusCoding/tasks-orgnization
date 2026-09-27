import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/notifications/application/inbox_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Icon of the app-bar inbox button: unread badge capped at "99+" (T7.3.06) and a "paused" bell
/// while *Pause all* is active (T7.5.15). The host button provides the tap and the tooltip.
class NotificationBellIcon extends ConsumerWidget {
  const NotificationBellIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(inboxUnreadCountProvider).value ?? 0;
    final paused = ref.watch(notificationsPausedProvider);
    return Badge(
      isLabelVisible: unread > 0,
      label: Text(unread > 99 ? '99+' : '$unread'),
      child: Icon(
        paused ? Icons.notifications_paused_outlined : Icons.notifications_none,
        semanticLabel: paused ? context.l10n.notifPausedShort : null,
      ),
    );
  }
}
