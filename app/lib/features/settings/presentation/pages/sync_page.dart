import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/core/sync/sync_api.dart';
import 'package:everslot/core/sync/sync_status.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/auth/application/auth_providers.dart';
import 'package:everslot/features/settings/application/sync_settings_providers.dart';
import 'package:everslot/features/settings/domain/device_info.dart';
import 'package:everslot/features/settings/presentation/widgets/settings_tiles.dart';
import 'package:everslot/features/settings/presentation/widgets/sync_indicator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Settings › Sync & data (T8.3.04): status (state, last success, live pending count, rejected
/// changes, last error), Sync now, Force full resync, devices with Remove, links to data pages.
class SyncPage extends ConsumerWidget {
  const SyncPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final session = ref.watch(sessionProvider);
    final cloud = session?.isCloud ?? false;
    return SettingsPageScaffold(
      title: l.settingsSyncTitle,
      children: [
        if (cloud) const _StatusCard() else const _SyncOffCard(),
        if (cloud) ...[SectionHeader(l.settingsDevices), const _DevicesList()],
        SectionHeader(l.settingsSyncData),
        SettingsNavTile(
          icon: Icons.import_export,
          title: l.settingsDataTitle,
          subtitle: l.settingsDataSubtitle,
          location: AppLinks.settings('data'),
        ),
        SettingsNavTile(icon: Icons.delete_outline, title: l.settingsTrash, location: AppLinks.trash()),
        if (ref.watch(envProvider).isDev && cloud)
          SettingsNavTile(
            icon: Icons.bug_report_outlined,
            title: l.settingsSyncDiagnostics,
            location: '${AppLinks.debug()}?page=sync',
          ),
      ],
    );
  }
}

class _SyncOffCard extends ConsumerWidget {
  const _SyncOffCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final canSignIn = ref.watch(cloudAuthAvailableProvider);
    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.cloud_off, color: context.colors.onSurfaceVariant),
                  const SizedBox(width: Space.md),
                  Expanded(child: Text(l.settingsSyncOffTitle, style: context.text.titleMedium)),
                ],
              ),
              const SizedBox(height: Space.sm),
              Text(canSignIn ? l.settingsSyncOffBody : l.localOnlyBanner),
              if (canSignIn) ...[
                const SizedBox(height: Space.md),
                FilledButton.tonal(
                  key: const ValueKey('sync-sign-in'),
                  onPressed: () => GoRouter.maybeOf(context)?.push(AppLinks.signIn()),
                  child: Text(l.authSignInToSync),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends ConsumerWidget {
  const _StatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final status = ref.watch(syncStatusProvider);
    final counts = ref.watch(outboxCountsProvider).value ?? (pending: status.pendingChanges, failed: status.failedChanges);
    final state = ref.watch(syncStateProvider).value;
    final now = ref.watch(clockProvider).nowUtc();
    final format = AppFormat(Localizations.localeOf(context).toLanguageTag(), l10n: l);
    final last = status.lastSuccessAt ?? state?.lastSuccessAt?.toUtc();
    final service = ref.watch(syncServiceProvider);
    final progress = status.initialSyncProgress;
    final errorText = status.lastError;

    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _PhaseIcon(status),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Text(
                      syncStatusMessage(context, status),
                      key: const ValueKey('sync-phase'),
                      style: context.text.titleMedium,
                    ),
                  ),
                ],
              ),
              if (progress != null && status.isBusy) ...[
                const SizedBox(height: Space.md),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: Space.xs),
                Text(l.settingsSyncInitialProgress((progress * 100).round()), style: context.text.bodySmall),
              ],
              const SizedBox(height: Space.sm),
              Text(
                last == null ? l.settingsSyncNever : l.settingsSyncLastSuccess(format.relative(last, now)),
                key: const ValueKey('sync-last-success'),
              ),
              Text(l.syncPending(counts.pending), key: const ValueKey('sync-pending')),
              if (counts.failed > 0) ...[
                const SizedBox(height: Space.sm),
                Text(
                  l.settingsSyncFailed(counts.failed),
                  key: const ValueKey('sync-failed'),
                  style: context.text.bodyMedium?.copyWith(color: context.appColors.danger),
                ),
                Wrap(
                  spacing: Space.sm,
                  children: [
                    TextButton(
                      onPressed: service == null ? null : () => unawaited(service.retryFailed()),
                      child: Text(l.settingsSyncRetryFailed),
                    ),
                    TextButton(
                      onPressed: service == null
                          ? null
                          : () async {
                              final ok = await confirmDialog(
                                context,
                                title: l.settingsSyncDiscardTitle,
                                body: l.settingsSyncDiscardBody,
                                destructive: true,
                              );
                              if (ok) await service.discardFailed();
                            },
                      child: Text(l.settingsSyncDiscardFailed),
                    ),
                  ],
                ),
              ],
              if (errorText != null && status.phase == SyncPhase.error) ...[
                const SizedBox(height: Space.sm),
                ExpansionTile(
                  key: const ValueKey('sync-last-error'),
                  tilePadding: EdgeInsets.zero,
                  title: Text(l.settingsSyncLastError),
                  children: [
                    SelectableText(errorText, style: context.text.bodySmall),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: IconButton(
                        tooltip: MaterialLocalizations.of(context).copyButtonLabel,
                        icon: const Icon(Icons.copy),
                        onPressed: () => Clipboard.setData(ClipboardData(text: errorText)),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: Space.md),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  FilledButton.icon(
                    key: const ValueKey('sync-now'),
                    onPressed: status.isBusy ? null : () => unawaited(refreshSync(context, ref)),
                    icon: const Icon(Icons.sync),
                    label: Text(l.settingsSyncNow),
                  ),
                  OutlinedButton(
                    key: const ValueKey('sync-resync'),
                    onPressed: service == null || status.isBusy
                        ? null
                        : () async {
                            final ok = await confirmDialog(
                              context,
                              title: l.settingsSyncResyncTitle,
                              body: l.settingsSyncResyncBody,
                            );
                            if (ok) await service.resync();
                          },
                    child: Text(l.settingsSyncResync),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhaseIcon extends StatelessWidget {
  const _PhaseIcon(this.status);

  final SyncStatus status;

  @override
  Widget build(BuildContext context) => switch (status.phase) {
    SyncPhase.idle || SyncPhase.localOnly => Icon(Icons.cloud_done_outlined, color: context.appColors.success),
    SyncPhase.pushing || SyncPhase.pulling => const SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(strokeWidth: 3),
    ),
    SyncPhase.offline => Icon(Icons.cloud_off, color: context.colors.onSurfaceVariant),
    SyncPhase.error => Icon(Icons.sync_problem, color: context.appColors.danger),
  };
}

class _DevicesList extends ConsumerWidget {
  const _DevicesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final devices = ref.watch(devicesProvider);
    final thisDevice = ref.watch(activeDeviceIdProvider);
    final now = ref.watch(clockProvider).nowUtc();
    final format = AppFormat(Localizations.localeOf(context).toLanguageTag(), l10n: l);
    return devices.when(
      loading: () => const Padding(padding: EdgeInsets.all(Space.lg), child: LinearProgressIndicator()),
      error: (e, _) => ListTile(
        key: const ValueKey('devices-offline'),
        leading: const Icon(Icons.cloud_off),
        title: Text(e is SyncApiException ? l.syncError : l.settingsDevicesOffline),
        trailing: IconButton(
          tooltip: l.actionRetry,
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(devicesProvider),
        ),
      ),
      data: (list) {
        if (list.isEmpty) return ListTile(title: Text(l.settingsDevicesEmpty));
        return Column(
          children: [
            for (final d in list)
              ListTile(
                key: ValueKey('device-${d.id}'),
                leading: Icon(_platformIcon(d.platform)),
                title: Text(d.id == thisDevice ? '${d.label ?? l.settingsDeviceUnknown} · ${l.settingsDeviceThis}' : d.label ?? l.settingsDeviceUnknown),
                subtitle: Text([
                  if (d.lastSeenAt != null) l.settingsDeviceLastSeen(format.relative(d.lastSeenAt!, now)),
                  if (d.receivesPush) l.settingsDevicePushOn else l.settingsDevicePushOff,
                ].join('\n')),
                isThreeLine: d.lastSeenAt != null,
                trailing: d.id == thisDevice
                    ? null
                    : IconButton(
                        tooltip: l.settingsDeviceRevoke,
                        icon: const Icon(Icons.phonelink_erase),
                        onPressed: () => _revoke(context, ref, d),
                      ),
              ),
          ],
        );
      },
    );
  }

  static IconData _platformIcon(String platform) => switch (platform) {
    'ios' => Icons.phone_iphone,
    'android' => Icons.phone_android,
    'web' => Icons.web,
    _ => Icons.computer,
  };

  Future<void> _revoke(BuildContext context, WidgetRef ref, DeviceInfo d) async {
    final l = context.l10n;
    final ok = await confirmDialog(
      context,
      title: l.settingsDeviceRevokeTitle(d.label ?? l.settingsDeviceUnknown),
      body: l.settingsDeviceRevokeBody,
      confirmLabel: l.settingsDeviceRevoke,
      destructive: true,
    );
    if (!ok) return;
    final repo = ref.read(devicesRepositoryProvider);
    if (repo == null) return;
    try {
      await repo.revoke(d.id);
      if (context.mounted) showInfoSnackBar(context, l.settingsDeviceRevoked);
    } on Object {
      if (context.mounted) showInfoSnackBar(context, l.settingsDevicesOffline);
    }
    ref.invalidate(devicesProvider);
  }
}
