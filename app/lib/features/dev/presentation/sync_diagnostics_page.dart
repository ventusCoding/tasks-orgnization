import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/sync/sync_service.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/dev/application/dev_providers.dart';
import 'package:everslot/features/dev/domain/dev_models.dart';
import 'package:everslot/features/settings/presentation/widgets/sync_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Dev sync diagnostics (T1.4.18): engine state and cursor, "simulate offline", force sync /
/// full pull, the outbox grouped by operation (failed entries with error, retry, discard), the
/// last pulled pages and the local conflict log.
class SyncDiagnosticsPage extends ConsumerStatefulWidget {
  const SyncDiagnosticsPage({super.key});

  @override
  ConsumerState<SyncDiagnosticsPage> createState() => _SyncDiagnosticsPageState();
}

class _SyncDiagnosticsPageState extends ConsumerState<SyncDiagnosticsPage> {
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final service = ref.watch(syncServiceProvider);
    final status = ref.watch(syncStatusProvider);
    final state = ref.watch(devSyncStateProvider).value;
    final outbox = ref.watch(devOutboxProvider);
    final now = ref.watch(clockProvider).nowUtc();
    final format = AppFormat(Localizations.localeOf(context).toLanguageTag(), l10n: l);
    final tools = ref.read(devToolsProvider);
    String when(DateTime? t) => t == null ? l.devSyncNever : format.relative(t, now);

    return Scaffold(
      appBar: AppBar(title: Text(l.devSyncDiagnostics), actions: const [SyncIndicator()]),
      body: ListView(
        padding: const EdgeInsetsDirectional.only(bottom: Space.xxl),
        children: [
          ListTile(
            key: const ValueKey('diag-phase'),
            leading: const Icon(Icons.sync_alt),
            title: Text(syncStatusMessage(context, status)),
            subtitle: Text(
              [
                if (state != null) l.devSyncCursor(state.cursor, state.purgeWatermarkSeen),
                l.devSyncLastPull(when(state?.lastPullAt)),
                l.devSyncLastPush(when(state?.lastPushAt)),
                if (service != null) l.devSyncBatch(service.currentBatchSize),
                if (status.lastError != null) status.lastError!,
              ].join('\n'),
            ),
            isThreeLine: true,
          ),
          if (service == null)
            Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Text(l.devSyncOff, key: const ValueKey('diag-off')),
            )
          else ...[
            SwitchListTile(
              key: const ValueKey('diag-offline'),
              secondary: const Icon(Icons.cloud_off),
              title: Text(l.devSyncSimulateOffline),
              subtitle: Text(l.devSyncSimulateOfflineHint),
              value: service.simulateOffline,
              onChanged: (v) => setState(() => tools.simulateOffline(v)),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
              child: Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  FilledButton.tonalIcon(
                    key: const ValueKey('diag-sync-now'),
                    onPressed: status.isBusy ? null : () => unawaited(service.syncNow(manual: true)),
                    icon: const Icon(Icons.sync),
                    label: Text(l.settingsSyncNow),
                  ),
                  OutlinedButton(
                    key: const ValueKey('diag-resync'),
                    onPressed: status.isBusy ? null : () => unawaited(service.resync()),
                    child: Text(l.settingsSyncResync),
                  ),
                ],
              ),
            ),
          ],
          SectionHeader(l.devSyncOutbox),
          ...outbox.when(
            loading: () => const [LinearProgressIndicator()],
            error: (e, _) => [ListTile(title: Text('$e'))],
            data: (groups) => groups.isEmpty
                ? [ListTile(key: const ValueKey('diag-outbox-empty'), title: Text(l.devSyncOutboxEmpty))]
                : [
                    if (service != null && groups.any((g) => g.hasFailures))
                      Padding(
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
                        child: Wrap(
                          spacing: Space.sm,
                          children: [
                            TextButton(
                              key: const ValueKey('diag-retry-failed'),
                              onPressed: () => unawaited(service.retryFailed()),
                              child: Text(l.settingsSyncRetryFailed),
                            ),
                            TextButton(
                              key: const ValueKey('diag-discard-failed'),
                              onPressed: () => unawaited(service.discardFailed()),
                              child: Text(l.settingsSyncDiscardFailed),
                            ),
                          ],
                        ),
                      ),
                    for (final g in groups) _GroupTile(group: g, when: when(g.enqueuedAt), service: service),
                  ],
          ),
          SectionHeader(l.devSyncPulls),
          if (service == null || service.recentPulls.isEmpty)
            ListTile(title: Text(l.devSyncNoPulls))
          else
            for (final p in service.recentPulls)
              ListTile(
                dense: true,
                leading: Icon(p.more ? Icons.more_horiz : Icons.download_done_outlined),
                title: Text(l.devSyncPullPage(p.since, p.next, p.changes)),
                trailing: Text(when(p.at), style: context.text.bodySmall),
              ),
          const _ConflictLog(),
        ],
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group, required this.when, required this.service});

  final OutboxGroupView group;
  final String when;
  final SyncService? service;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.appColors;
    return ExpansionTile(
      key: ValueKey('diag-group-${group.opId}'),
      leading: Icon(
        group.hasFailures ? Icons.error_outline : Icons.schedule_send_outlined,
        color: group.hasFailures ? colors.danger : null,
      ),
      title: Text({for (final e in group.entries) e.table}.join(', ')),
      subtitle: Text(l.devSyncGroup(group.entries.length, when)),
      children: [
        for (final e in group.entries)
          ListTile(
            dense: true,
            title: Text('${e.op} ${e.table}/${e.rowId}'),
            subtitle: Text(
              [
                e.fields.join(', '),
                '${e.state} · ${l.devSyncAttempts(e.attempts)}',
                if (e.lastError != null) e.lastError!,
              ].join('\n'),
              style: e.failed ? context.text.bodySmall?.copyWith(color: colors.danger) : context.text.bodySmall,
            ),
            trailing: e.failed && service != null
                ? IconButton(
                    tooltip: l.settingsSyncDiscardFailed,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => unawaited(service!.discardFailed(changeIds: [e.changeId])),
                  )
                : null,
          ),
      ],
    );
  }
}

class _ConflictLog extends ConsumerWidget {
  const _ConflictLog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final log = ref.watch(devConflictLogProvider).value ?? const <ConflictLogEntry>[];
    final now = ref.watch(clockProvider).nowUtc();
    final format = AppFormat(Localizations.localeOf(context).toLanguageTag(), l10n: l);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: SectionHeader(l.devSyncConflicts)),
            if (log.isNotEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: Space.sm),
                child: TextButton(
                  key: const ValueKey('diag-clear-conflicts'),
                  onPressed: () => unawaited(ref.read(devToolsProvider).clearConflictLog()),
                  child: Text(l.devSyncClear),
                ),
              ),
          ],
        ),
        if (log.isEmpty)
          ListTile(key: const ValueKey('diag-conflicts-empty'), title: Text(l.devSyncConflictsEmpty))
        else
          for (final c in log)
            ListTile(
              dense: true,
              leading: const Icon(Icons.call_split),
              title: Text('${c.table}/${c.rowId}'),
              subtitle: Text('${c.fields.join(', ')} · ${c.status}'),
              trailing: Text(format.relative(c.at, now), style: context.text.bodySmall),
            ),
      ],
    );
  }
}
