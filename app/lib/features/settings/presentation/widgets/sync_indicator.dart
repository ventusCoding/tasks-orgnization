import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/sync/sync_status.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Localized explanation of a sync problem.
String syncStatusMessage(BuildContext context, SyncStatus status) {
  final l = context.l10n;
  return switch (status.phase) {
    SyncPhase.localOnly => l.syncLocalOnly,
    SyncPhase.idle => l.syncIdle,
    SyncPhase.pushing => l.syncPushing,
    SyncPhase.pulling => l.syncPulling,
    SyncPhase.offline => l.syncOffline,
    SyncPhase.error => switch (status.errorCode) {
      SyncErrorCodes.unsupportedClient => l.errorUnsupportedVersion,
      SyncErrorCodes.deviceRevoked => l.authDeviceRevokedTitle,
      SyncErrorCodes.notAuthenticated => l.authErrorSessionExpired,
      _ => l.syncError,
    },
  };
}

/// Subtle sync state for app bars (T8.1.09): hidden when synced or on a local-only device; a
/// spinner while syncing (determinate during an initial sync, T1.4.14); cloud-off when offline;
/// a warning when something needs attention. Tap → Settings › Sync.
class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    final colors = context.appColors;
    final Widget icon;
    switch (status.phase) {
      case SyncPhase.localOnly || SyncPhase.idle:
        if (status.failedChanges == 0) return const SizedBox.shrink();
        icon = Icon(Icons.sync_problem, color: colors.warning);
      case SyncPhase.pushing || SyncPhase.pulling:
        final progress = status.initialSyncProgress;
        icon = SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, value: progress));
      case SyncPhase.offline:
        icon = Icon(Icons.cloud_off, color: context.colors.onSurfaceVariant);
      case SyncPhase.error:
        icon = Icon(Icons.sync_problem, color: colors.danger);
    }
    final label = status.initialSyncProgress != null && status.isBusy
        ? context.l10n.settingsSyncInitialProgress((status.initialSyncProgress! * 100).round())
        : syncStatusMessage(context, status);
    return IconButton(
      key: const ValueKey('sync-indicator'),
      tooltip: label,
      icon: Semantics(label: label, child: icon),
      onPressed: () => GoRouter.maybeOf(context)?.push('/settings/sync'),
    );
  }
}

/// Pull-to-refresh that pushes then pulls (T8.1.09). Wrap a tab root's scrollable with it. It
/// always completes (30 s cap) and explains offline / error outcomes in a snackbar.
class SyncRefresh extends ConsumerWidget {
  const SyncRefresh({required this.child, super.key, this.edgeOffset = 0});

  final Widget child;
  final double edgeOffset;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      RefreshIndicator(edgeOffset: edgeOffset, onRefresh: () => refreshSync(context, ref), child: child);
}

/// Runs a manual sync and reports the outcome (used by [SyncRefresh] and "Sync now").
Future<void> refreshSync(BuildContext context, WidgetRef ref, {Duration timeout = const Duration(seconds: 30)}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l = context.l10n;
  final service = ref.read(syncServiceProvider);
  if (service == null) {
    messenger?.showSnackBar(SnackBar(content: Text(l.settingsSyncRefreshLocalOnly)));
    return;
  }
  try {
    await service.syncNow(manual: true).timeout(timeout);
  } on TimeoutException {
    // Keeps running in the background; the indicator shows the state.
  }
  if (!context.mounted) return;
  final status = ref.read(syncStatusProvider);
  if (status.phase == SyncPhase.offline || status.phase == SyncPhase.error) {
    messenger?.showSnackBar(SnackBar(content: Text(syncStatusMessage(context, status))));
  }
}
