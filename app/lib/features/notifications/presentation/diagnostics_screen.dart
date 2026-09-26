import 'dart:async';
import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/notifications/application/capabilities_service.dart';
import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/application/notification_pipeline.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/scheduler/schedule_plan.dart';
import 'package:everslot/features/notifications/presentation/notification_labels.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Snapshot shown by the diagnostics screen (no titles/bodies — safe to copy for support).
@immutable
class NotificationDiagnostics {
  const NotificationDiagnostics({
    required this.capabilities,
    required this.osPending,
    required this.scheduledOs,
    required this.tracked,
    required this.snoozes,
    required this.mismatches,
    required this.budget,
    required this.report,
    required this.pushAvailable,
  });

  final NotificationCapabilities capabilities;
  final int osPending;
  final int scheduledOs;
  final int tracked;
  final int snoozes;
  final int mismatches;
  final ScheduleBudget budget;
  final ReplanReport? report;
  final bool pushAvailable;

  /// JSON for "Copy diagnostics" — ids/counts only, never content (T7.2.21 test).
  Map<String, Object?> toJson() => {
    'capabilities': {...capabilities.toJson(), 'platform': capabilities.platform},
    'osPending': osPending,
    'scheduledOs': scheduledOs,
    'tracked': tracked,
    'snoozes': snoozes,
    'mismatches': mismatches,
    'budget': budget.total,
    'coverageUntil': report?.scheduler.coverageUntil?.toIso8601String(),
    'lastReplan': report == null
        ? null
        : {
            'at': report!.at.toIso8601String(),
            'ms': report!.duration.inMilliseconds,
            'reason': report!.reason,
            'planned': report!.planned,
            'skipped': report!.skipped,
            'targets': report!.targets,
            'error': report!.error == null ? null : 'error',
          },
    'next': [
      for (final p in report?.next ?? const []) {'at': p.fireAt.toIso8601String(), 'section': p.section.wire, 'channel': p.channelId},
    ],
    'push': pushAvailable,
  };
}

final notificationDiagnosticsProvider = FutureProvider.autoDispose<NotificationDiagnostics>((ref) async {
  final port = ref.watch(localNotificationsPortProvider);
  final store = ref.watch(localScheduleStoreProvider);
  final now = ref.watch(clockProvider).nowUtc();
  final report = ref.watch(lastReplanReportProvider).value;
  final entries = await store.all();
  final pending = await port.pending();
  final osFuture = [for (final e in entries) if (e.os && e.fireAt.isAfter(now)) e];
  final pendingIds = {for (final p in pending) p.id};
  final osIds = {for (final e in osFuture) e.platformId};
  return NotificationDiagnostics(
    capabilities: ref.watch(notificationCapabilitiesProvider),
    osPending: pending.length,
    scheduledOs: osFuture.length,
    tracked: entries.where((e) => !e.os && e.fireAt.isAfter(now)).length,
    snoozes: entries.where((e) => e.kind == ScheduleKind.snooze && e.fireAt.isAfter(now)).length,
    mismatches: port is InMemoryLocalNotificationsPort ? 0 : osIds.difference(pendingIds).length + pendingIds.difference(osIds).length,
    budget: ref.watch(localSchedulerProvider).budget,
    report: report,
    pushAvailable: ref.watch(pushAvailableProvider),
  );
});

class NotificationDiagnosticsScreen extends ConsumerWidget {
  const NotificationDiagnosticsScreen({super.key});

  Future<void> _battery(BuildContext context) async {
    var maker = 'android';
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        maker = (await DeviceInfoPlugin().androidInfo).manufacturer.toLowerCase();
      }
    } on Object {
      // keep generic page
    }
    await launchUrl(Uri.parse('https://dontkillmyapp.com/$maker'), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final labels = NotificationLabels.of(context);
    final zone = ref.watch(deviceZoneProvider);
    final zones = ref.watch(zoneResolverProvider);
    final diagnostics = ref.watch(notificationDiagnosticsProvider);
    String yes(bool v) => v ? l.notifYes : l.notifNo;
    String when(DateTime? t) => t == null ? l.notifNever : labels.format.dateTime(zones.toLocal(t, zone));
    return Scaffold(
      appBar: AppBar(
        title: Text(l.notifDiagTitle),
        actions: [
          IconButton(
            tooltip: l.notifDiagReplanNow,
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await ref.read(notificationReplanServiceProvider).flush();
              ref.invalidate(notificationDiagnosticsProvider);
            },
          ),
        ],
      ),
      body: AsyncValueView<NotificationDiagnostics>(
        value: diagnostics,
        data: (d) => ListView(
          padding: const EdgeInsets.only(bottom: Space.xxxl),
          children: [
            SectionHeader(l.notifDiagCapabilities),
            ListTile(title: Text(l.notifDiagPermission), trailing: Text(yes(d.capabilities.notifications))),
            if (d.capabilities.isIos) ListTile(title: Text(l.notifDiagProvisional), trailing: Text(yes(d.capabilities.provisional))),
            if (d.capabilities.isAndroid) ListTile(title: Text(l.notifDiagExact), trailing: Text(yes(d.capabilities.exactAlarm))),
            ListTile(title: Text(l.notifDiagTimeSensitive), trailing: Text(yes(d.capabilities.timeSensitive))),
            ListTile(title: Text(l.notifDiagBadge), trailing: Text(yes(d.capabilities.badge))),
            if (d.capabilities.blockedChannels.isNotEmpty)
              ListTile(title: Text(l.notifDiagBlocked), subtitle: Text(d.capabilities.blockedChannels.join(', '))),
            ListTile(title: Text(l.notifDiagPush), subtitle: Text(d.pushAvailable ? l.notifDiagPushOn : l.notifDiagPushOff)),
            SectionHeader(l.notifDiagSchedule),
            ListTile(title: Text(l.notifDiagPendingOs), trailing: Text('${d.osPending}')),
            ListTile(title: Text(l.notifDiagBudget(d.scheduledOs, d.budget.total))),
            ListTile(title: Text(l.notifDiagTracked), trailing: Text('${d.tracked}')),
            if (d.mismatches > 0)
              ListTile(
                leading: Icon(Icons.warning_amber, color: context.appColors.warning),
                title: Text(l.notifDiagMismatch(d.mismatches)),
              ),
            ListTile(title: Text(l.notifDiagCoverage), trailing: Text(when(d.report?.scheduler.coverageUntil))),
            ListTile(
              title: Text(l.notifDiagLastReplan),
              subtitle: Text(
                d.report == null
                    ? l.notifNever
                    : l.notifDiagReplanInfo(when(d.report!.at), d.report!.duration.inMilliseconds, d.report!.reason),
              ),
            ),
            SectionHeader(l.notifDiagNext),
            for (final p in d.report?.next ?? const [])
              ListTile(
                dense: true,
                leading: Icon(p.deliverSystem ? Icons.notifications_active_outlined : Icons.inbox_outlined, size: 20),
                title: Text(p.inboxTitle),
                subtitle: Text('${when(p.fireAt)} · ${labels.section(p.section)}'),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.send_outlined),
              title: Text(l.notifSendTest),
              onTap: () async {
                await ref.read(localSchedulerProvider).showTest(
                  title: l.notifBodyTest,
                  body: l.notifBodyTest,
                  channelId: 'dl.system.v1',
                  actions: const ['open'],
                  sound: 'default',
                  importance: NotificationImportance.normal,
                  interruptionLevel: InterruptionLevel.active,
                );
                if (context.mounted) showInfoSnackBar(context, l.notifTestSent);
              },
            ),
            if (d.capabilities.isAndroid)
              ListTile(
                leading: const Icon(Icons.battery_alert_outlined),
                title: Text(l.notifDiagBattery),
                subtitle: Text(l.notifDiagBatteryBody),
                onTap: () => unawaited(_battery(context)),
              ),
            ListTile(
              leading: const Icon(Icons.copy_all_outlined),
              title: Text(l.notifDiagCopy),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: const JsonEncoder.withIndent('  ').convert(d.toJson())));
                if (context.mounted) showInfoSnackBar(context, l.notifDiagCopied);
              },
            ),
          ],
        ),
      ),
    );
  }
}
