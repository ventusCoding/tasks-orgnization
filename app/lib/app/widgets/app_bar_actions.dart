import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/notifications/application/inbox_providers.dart';
import 'package:everslot/features/planner/presentation/running_timer_chip.dart';
import 'package:everslot/features/settings/presentation/widgets/sync_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Running timer (T3.2.19) · Search · Inbox (with unread badge) · Settings — shown on every tab
/// root (T1.3.12).
class AppBarActions extends ConsumerWidget {
  const AppBarActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(inboxUnreadCountProvider).value ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hidden while no timer runs.
        const RunningTimerChip(),
        // Offline / syncing / error indicator, hidden when synced (T8.1.09).
        const SyncIndicator(),
        IconButton(
          tooltip: context.l10n.actionSearch,
          icon: const Icon(Icons.search),
          onPressed: () => context.push(AppLinks.search()),
        ),
        IconButton(
          tooltip: context.l10n.actionInbox,
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text(unread > 99 ? '99+' : '$unread'),
            child: const Icon(Icons.notifications_none),
          ),
          onPressed: () => context.push(AppLinks.inbox()),
        ),
        IconButton(
          tooltip: context.l10n.actionSettings,
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push(AppLinks.settings()),
        ),
      ],
    );
  }
}
