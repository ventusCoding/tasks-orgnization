import 'dart:io' show Platform;

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/application/local_scheduler.dart';
import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/application/notification_texts_l10n.dart';
import 'package:everslot/features/notifications/application/plugin_local_notifications_port.dart';
import 'package:everslot/features/notifications/data/inbox_repository.dart';
import 'package:everslot/features/notifications/data/local_schedule_store.dart';
import 'package:everslot/features/notifications/data/notification_rules_repository.dart';
import 'package:everslot/features/notifications/data/notify_mode_store.dart';
import 'package:everslot/features/notifications/domain/inbox_item.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_settings.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ------------------------------------------------------------------------------ repositories --

final notificationRulesRepositoryProvider = Provider<NotificationRulesRepository>(
  (ref) => NotificationRulesRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncWriterProvider),
    () => ref.read(currentUserIdProvider),
  ),
);

final notificationProfilesRepositoryProvider = Provider<NotificationProfilesRepository>(
  (ref) => NotificationProfilesRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncWriterProvider),
    () => ref.read(currentUserIdProvider),
  ),
);

final notificationMutesRepositoryProvider = Provider<NotificationMutesRepository>(
  (ref) => NotificationMutesRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncWriterProvider),
    () => ref.read(currentUserIdProvider),
  ),
);

final inboxRepositoryProvider = Provider<InboxRepository>(
  (ref) => InboxRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncWriterProvider),
    () => ref.read(currentUserIdProvider),
    ref.watch(clockProvider),
  ),
);

final localScheduleStoreProvider = Provider<LocalScheduleStore>((ref) => LocalScheduleStore(ref.watch(appDatabaseProvider)));

final notifyModeStoreProvider = Provider<NotifyModeStore>(
  (ref) => NotifyModeStore(ref.watch(appDatabaseProvider), ref.watch(syncWriterProvider)),
);

// ----------------------------------------------------------------------------------- streams --

final notificationRulesProvider = StreamProvider<List<NotificationRule>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(notificationRulesRepositoryProvider).watchAll();
});

final notificationProfilesProvider = StreamProvider<List<NotificationProfile>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(notificationProfilesRepositoryProvider).watchAll();
});

final notificationMutesProvider = StreamProvider<List<NotificationMute>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(notificationMutesRepositoryProvider).watchAll();
});

/// Own rules of one target (`(ruleTargetType, id)`).
final targetRulesProvider = StreamProvider.autoDispose.family<List<NotificationRule>, (RuleTargetType, String)>((ref, key) {
  ref.watch(currentUserIdProvider);
  return ref.watch(notificationRulesRepositoryProvider).watchForTarget(key.$1, key.$2);
});

/// `notify_mode` of a host item (null when the row doesn't exist yet).
final targetNotifyModeProvider = StreamProvider.autoDispose.family<NotifyMode?, (RuleTargetType, String)>(
  (ref, key) => ref.watch(notifyModeStoreProvider).watch(key.$1, key.$2),
);

/// Typed notification settings (+ privacy "hide content"), live.
final notificationSettingsProvider = Provider<NotificationSettings>((ref) {
  final notifications = ref.watch(settingsProvider(SettingsNs.notifications)).value ?? const {};
  final privacy = ref.watch(settingsProvider(SettingsNs.privacy)).value ?? const {};
  return NotificationSettings.fromMaps(notifications, privacy);
});

/// Writes keys of the `notifications` settings namespace (merged, versioned).
final notificationSettingsWriterProvider = Provider<Future<void> Function(Map<String, Object?> patch)>(
  (ref) => (patch) => ref.read(settingsRepositoryProvider).update(SettingsNs.notifications, patch),
);

/// Localized planner texts following the user's language and 12/24 h preference.
final notificationTextsProvider = Provider<L10nNotificationTexts>((ref) {
  final prefs = ref.watch(userPreferencesProvider);
  return L10nNotificationTexts.forLocale(prefs.localeCode, use24h: prefs.use24h);
});

// ------------------------------------------------------------------------------------ inbox --

final inboxFilterProvider = NotifierProvider<InboxFilterController, InboxFilter>(InboxFilterController.new);

class InboxFilterController extends Notifier<InboxFilter> {
  @override
  InboxFilter build() => InboxFilter.all;

  // ignore: use_setters_to_change_properties
  void set(InboxFilter filter) => state = filter;
}

final inboxItemsProvider = StreamProvider.autoDispose<List<InboxItem>>((ref) {
  ref.watch(currentUserIdProvider);
  final filter = ref.watch(inboxFilterProvider);
  return ref.watch(inboxRepositoryProvider).watchInbox(filter: filter);
});

final snoozedInboxProvider = StreamProvider.autoDispose<List<InboxItem>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(inboxRepositoryProvider).watchSnoozed();
});

final inboxHistoryProvider = StreamProvider.autoDispose.family<List<InboxItem>, (String, String)>((ref, key) {
  ref.watch(currentUserIdProvider);
  return ref.watch(inboxRepositoryProvider).watchForSource(key.$1, key.$2);
});

// ----------------------------------------------------------------------------- OS & scheduler --

/// True under `flutter test` (plugins unavailable → in-memory port).
bool get _isFlutterTest {
  try {
    return Platform.environment.containsKey('FLUTTER_TEST');
  } on Object {
    return false;
  }
}

/// The OS notification port. Mobile builds use the plugin; tests/desktop use the in-memory fake.
final localNotificationsPortProvider = Provider<LocalNotificationsPort>((ref) {
  final platform = kIsWeb
      ? 'other'
      : switch (defaultTargetPlatform) {
          TargetPlatform.android => 'android',
          TargetPlatform.iOS => 'ios',
          _ => 'other',
        };
  if (platform == 'other' || _isFlutterTest) return InMemoryLocalNotificationsPort(platform: platform);
  return PluginLocalNotificationsPort();
});

final localSchedulerProvider = Provider<LocalNotificationScheduler>(
  (ref) => LocalNotificationScheduler(
    port: ref.watch(localNotificationsPortProvider),
    store: ref.watch(localScheduleStoreProvider),
    clock: ref.watch(clockProvider),
    l10n: () => ref.read(notificationTextsProvider).l10n,
    handlers: () => ref.read(notificationActionHandlersProvider),
  ),
);
