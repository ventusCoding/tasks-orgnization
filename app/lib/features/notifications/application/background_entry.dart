import 'dart:async';
import 'dart:ui';

import 'package:drift/drift.dart' show Variable;
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/env/env.dart';
import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/session/device_identity.dart';
import 'package:everslot/core/session/session.dart';
import 'package:everslot/features/notifications/application/action_dispatcher.dart';
import 'package:everslot/features/notifications/application/inbox_reconciler.dart';
import 'package:everslot/features/notifications/application/notification_pipeline.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/plugin_local_notifications_port.dart';
import 'package:everslot/features/notifications/domain/notification_actions.dart';
import 'package:everslot/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:workmanager/workmanager.dart';

/// Background work of the notification system (T7.2.12 / T7.2.14 / T7.4.10).
abstract final class NotificationBackground {
  static const replanTask = 'everslot.notifications.replan';
  static const userKey = 'notif_user_id';
  static const pendingPullKey = 'notif_pending_pull';
  static final _log = AppLog.get('notifications.background');

  /// Opens the database from a background isolate (Drift shares the connection across isolates
  /// when the app is alive, otherwise a direct WAL connection), rebuilds a minimal provider
  /// container for [userId] and runs [body]. Writes go through SyncWriter + outbox; they are pushed
  /// on the next foreground sync.
  static Future<void> run(
    Future<void> Function(ProviderContainer container) body, {
    String? userId,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    tzdata.initializeTimeZones();
    final db = AppDatabase();
    ProviderContainer? container;
    try {
      final deviceId = await DeviceIdentity.load(db);
      final hlc = await db
          .customSelect("SELECT value FROM local_kv WHERE key = 'hlc_state'")
          .getSingleOrNull();
      HlcBootstrap.initialState = hlc?.data['value'] as String?;
      final storedUser = await db
          .customSelect(
            'SELECT value FROM local_kv WHERE key = ?',
            variables: [Variable<String>(userKey)],
          )
          .getSingleOrNull();
      final uid = userId ?? storedUser?.data['value'] as String?;
      if (uid == null || uid.isEmpty) return;
      SessionController.initial = AppSession(
        userId: uid,
        mode: SessionMode.localOnly,
      );
      try {
        DeviceZoneController.initialZone =
            (await FlutterTimezone.getLocalTimezone()).identifier;
      } on Object {
        // keep UTC
      }
      container = ProviderContainer(
        overrides: [
          envProvider.overrideWithValue(Env.fromEnvironment()),
          appDatabaseProvider.overrideWithValue(db),
          deviceIdProvider.overrideWithValue(deviceId),
        ],
      );
      final port = container.read(localNotificationsPortProvider);
      await port.initialize(categories: const [], onResponse: (_) {});
      await body(container);
    } on Object catch (e, st) {
      _log.warning('background notification work failed', e, st);
    } finally {
      container?.dispose();
      await db.close();
    }
  }

  /// Registers the periodic horizon extension (~6 h; Android WorkManager, min 15 min).
  /// iOS BGAppRefresh needs Info.plist identifiers + AppDelegate registration (see README).
  static Future<void> registerPeriodic() async {
    try {
      await Workmanager().initialize(notificationsWorkmanagerDispatcher);
      await Workmanager().registerPeriodicTask(
        replanTask,
        replanTask,
        frequency: const Duration(hours: 6),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } on Object catch (e) {
      _log.info('periodic notification work unavailable: $e');
    }
  }
}

/// Notification action tapped while the app was killed / in the background (T7.2.14).
@pragma('vm:entry-point')
void notificationBackgroundResponse(NotificationResponse response) {
  final payload = NotificationPayload.tryDecode(response.payload);
  unawaited(
    NotificationBackground.run((c) async {
      final dispatcher = NotificationActionDispatcher(c.read);
      await dispatcher.handleResponse(
        PluginLocalNotificationsPort.mapResponse(response, background: true),
      );
      // Re-plan so the rest of the occurrence's reminders and nag chain disappear.
      await NotificationPipeline(c.read)
          .run('background-action', foreground: false);
    }, userId: payload?.userId),
  );
}

/// WorkManager dispatcher: extends the local horizon when the app isn't opened for days.
@pragma('vm:entry-point')
void notificationsWorkmanagerDispatcher() {
  Workmanager().executeTask((task, input) async {
    if (task != NotificationBackground.replanTask) return true;
    await NotificationBackground.run((c) async {
      await InboxReconciler(
        store: c.read(localScheduleStoreProvider),
        inbox: c.read(inboxRepositoryProvider),
        clock: c.read(clockProvider),
      ).reconcile();
      await NotificationPipeline(c.read)
          .run('periodic-background', foreground: false);
    });
    return true;
  });
}

/// FCM background handler (Android data messages, iOS background pushes). Visible reminder
/// pushes are displayed by the OS (notification messages); `sync` marks a pull for the next
/// start/resume (a full pull needs the Supabase client, which lives in the main isolate).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!DefaultFirebaseOptions.isConfigured) return;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on Object {
    // already initialized
  }
  final type = message.data['type']?.toString();
  if (type == 'sync') {
    await NotificationBackground.run((c) async {
      await c.read(appDatabaseProvider).customStatement(
        'INSERT INTO local_kv(key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value',
        [
          NotificationBackground.pendingPullKey,
          message.data['head']?.toString() ?? '1',
        ],
      );
    });
  }
}
