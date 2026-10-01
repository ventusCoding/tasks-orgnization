import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/core/sync/sync_status.dart';
import 'package:everslot/features/notifications/application/capabilities_service.dart';
import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/application/notification_pipeline.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/data/inbox_repository.dart';
import 'package:everslot/features/notifications/domain/notification_actions.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// System notices in the inbox (T7.3.07): one `system` row per condition the user must know
/// about, with a fix link. Each notice has a deterministic dedupe key (`system:<code>` → the same
/// inbox id on every device, never duplicated), is dismissed automatically once the condition is
/// fixed and re-opened (unread again) when it comes back.
class SystemNotices {
  SystemNotices(this.read);

  final ProviderReader read;

  static const notificationsOff = 'notifications_off';
  static const channelBlocked = 'channel_blocked';
  static const exactAlarmsOff = 'exact_alarms_off';
  static const budgetSaturated = 'budget_saturated';
  static const syncFailing = 'sync_failing';
  static const deviceRevoked = 'device_revoked';
  static const updateRequired = 'update_required';

  static const codes = [
    notificationsOff,
    channelBlocked,
    exactAlarmsOff,
    budgetSaturated,
    syncFailing,
    deviceRevoked,
    updateRequired,
  ];

  /// Sync errors this long without a successful sync raise [syncFailing].
  static const syncGrace = Duration(hours: 24);

  static String dedupeKey(String code) => 'system:$code';

  /// Conditions active right now.
  static Set<String> activeCodes({
    required NotificationCapabilities capabilities,
    required bool saturated,
    required SyncStatus sync,
    required DateTime now,
  }) {
    final caps = capabilities;
    final known = caps.determined;
    return {
      if (known && !caps.notifications) notificationsOff,
      if (known && caps.notifications && caps.blockedChannels.isNotEmpty) channelBlocked,
      if (known && caps.notifications && caps.isAndroid && !caps.exactAlarm) exactAlarmsOff,
      if (saturated) budgetSaturated,
      if (sync.errorCode == SyncErrorCodes.deviceRevoked) deviceRevoked,
      if (sync.errorCode == SyncErrorCodes.unsupportedClient) updateRequired,
      if (_syncFailing(sync, now)) syncFailing,
    };
  }

  static bool _syncFailing(SyncStatus s, DateTime now) {
    if (s.phase != SyncPhase.error) return false;
    if (s.errorCode == SyncErrorCodes.deviceRevoked || s.errorCode == SyncErrorCodes.unsupportedClient) {
      return false; // their own notices
    }
    final since = s.lastSuccessAt;
    return since != null && now.difference(since) > syncGrace;
  }

  /// Opens the notices of [active] codes and resolves the others.
  Future<void> apply(Set<String> active) async {
    final inbox = read(inboxRepositoryProvider);
    final l = read(notificationTextsProvider).l10n;
    final now = read(clockProvider).nowUtc();
    for (final code in codes) {
      final key = dedupeKey(code);
      if (!active.contains(code)) {
        await inbox.resolveNotice(key, now);
        continue;
      }
      final (title, body, link) = content(code, l);
      await inbox.openNotice(
        InboxDelivery(
          dedupeKey: key,
          category: InboxCategory.system,
          title: title,
          body: body,
          fireAt: now,
          section: NotificationSection.system,
          sourceType: 'system',
          sourceId: code,
          payload: {'v': 1, 'dk': key, 'link': link, 'kind': 'notice'},
          via: 'inbox_only',
        ),
      );
    }
  }

  /// Evaluates the current conditions and applies them.
  Future<Set<String>> refresh({required bool saturated}) async {
    final active = activeCodes(
      capabilities: read(notificationCapabilitiesProvider),
      saturated: saturated,
      sync: read(syncStatusProvider),
      now: read(clockProvider).nowUtc(),
    );
    await apply(active);
    return active;
  }

  /// Title, body and fix link of a notice.
  static (String, String, String) content(String code, AppLocalizations l) => switch (code) {
    notificationsOff => (l.notifPermissionOff, l.notifPermissionOffBody, NotificationLinks.settings),
    channelBlocked => (l.notifChannelBlocked, l.notifNoticeChannelBody, NotificationLinks.settings),
    exactAlarmsOff => (l.notifExactOff, l.notifExactOffBody, NotificationLinks.settings),
    budgetSaturated => (l.notifNoticeSaturatedTitle, l.notifNoticeSaturatedBody, NotificationLinks.diagnostics),
    syncFailing => (l.notifNoticeSyncTitle, l.notifNoticeSyncBody, AppLinks.settings()),
    deviceRevoked => (l.notifNoticeRevokedTitle, l.notifNoticeRevokedBody, AppLinks.settings()),
    _ => (l.notifNoticeUpdateTitle, l.notifNoticeUpdateBody, AppLinks.settings()),
  };
}

final systemNoticesProvider = Provider<SystemNotices>((ref) => SystemNotices(ref.read));
