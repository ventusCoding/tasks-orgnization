import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show TableUpdateQuery, Variable;
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/core/session/session.dart';
import 'package:everslot/core/sync/sync_status.dart';
import 'package:everslot/features/notifications/application/action_dispatcher.dart';
import 'package:everslot/features/notifications/application/background_entry.dart';
import 'package:everslot/features/notifications/application/capabilities_service.dart';
import 'package:everslot/features/notifications/application/in_app_banners.dart';
import 'package:everslot/features/notifications/application/inbox_reconciler.dart';
import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/application/notification_pipeline.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/application/notification_texts_l10n.dart';
import 'package:everslot/features/notifications/application/system_notices.dart';
import 'package:everslot/features/notifications/application/push/job_uploader.dart';
import 'package:everslot/features/notifications/application/push/push_messaging_port.dart';
import 'package:everslot/features/notifications/application/push/push_service.dart';
import 'package:everslot/features/notifications/data/inbox_repository.dart';
import 'package:everslot/features/notifications/domain/badge_count.dart';
import 'package:everslot/features/notifications/domain/notification_actions.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ------------------------------------------------------------------------------- UI events --

/// Events for the presentation layer (navigation, snackbars) — emitted by taps/actions.
@immutable
sealed class NotificationUiEvent {
  const NotificationUiEvent();
}

class OpenLinkEvent extends NotificationUiEvent {
  const OpenLinkEvent(this.link, {this.alreadyDone = false});

  final String link;
  final bool alreadyDone;
}

class MessageEvent extends NotificationUiEvent {
  const MessageEvent(this.message);

  final String message;
}

// ------------------------------------------------------------------------------- providers --

final notificationPipelineProvider = Provider<NotificationPipeline>(
  (ref) => NotificationPipeline(ref.read),
);

final notificationReplanServiceProvider = Provider<NotificationReplanService>((
  ref,
) {
  final pipeline = ref.watch(notificationPipelineProvider);
  final service = NotificationReplanService(
    runner: (reason) => pipeline.run(
      reason,
      foreground: ref.read(lifecycleProvider).isForeground,
    ),
  );
  ref.onDispose(service.dispose);
  return service;
});

final inboxReconcilerProvider = Provider<InboxReconciler>(
  (ref) => InboxReconciler(
    store: ref.watch(localScheduleStoreProvider),
    inbox: ref.watch(inboxRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

final inAppBannerControllerProvider = Provider<InAppBannerController>((ref) {
  final controller = InAppBannerController();
  ref.onDispose(controller.dispose);
  return controller;
});

final notificationUiEventsProvider =
    Provider<StreamController<NotificationUiEvent>>((ref) {
      final controller = StreamController<NotificationUiEvent>.broadcast();
      ref.onDispose(() => unawaited(controller.close()));
      return controller;
    });

final jobUploaderProvider = Provider<JobUploader>(
  (ref) => JobUploader(
    db: ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
    deviceId: ref.watch(deviceIdProvider),
    onStale: () {
      ref.read(syncServiceProvider)?.schedulePull(Duration.zero);
      ref.read(notificationReplanServiceProvider).request('stale-jobs');
    },
  ),
);

final deviceStateReporterProvider = Provider<DeviceStateReporter>((ref) {
  final reporter = DeviceStateReporter(
    api: () => ref.read(syncServiceProvider)?.api,
    deviceId: ref.watch(deviceIdProvider),
    clock: ref.watch(clockProvider),
  );
  ref.onDispose(reporter.dispose);
  return reporter;
});

final notificationActionDispatcherProvider =
    Provider<NotificationActionDispatcher>(
      (ref) => NotificationActionDispatcher(
        ref.read,
        onReplanNeeded: (reason) =>
            ref.read(notificationReplanServiceProvider).request(reason),
        onTargetsDirty: (keys) =>
            unawaited(ref.read(jobUploaderProvider).markDirty(keys)),
      ),
    );

/// Push (FCM) is active only with `FIREBASE_ENABLED`, real FlutterFire options, an initialized
/// Firebase app, a configured Supabase client and a cloud session (T7.4 configuration checks).
final pushAvailableProvider = Provider<bool>((ref) {
  final env = ref.watch(envProvider);
  if (!env.firebaseEnabled || !DefaultFirebaseOptions.isConfigured)
    return false;
  if (ref.watch(supabaseClientProvider) == null) return false;
  final session = ref.watch(sessionProvider);
  if (session == null || !session.isCloud) return false;
  try {
    return Firebase.apps.isNotEmpty;
  } on Object {
    return false;
  }
});

/// Override in tests with a [FakePushMessagingPort].
final pushMessagingPortProvider = Provider<PushMessagingPort?>(
  (ref) =>
      ref.watch(pushAvailableProvider) ? FirebasePushMessagingPort() : null,
);

final notificationsEngineProvider = Provider<NotificationsEngine>((ref) {
  final engine = NotificationsEngine(ref);
  ref.onDispose(engine.dispose);
  return engine;
});

/// Last replan report (diagnostics).
final lastReplanReportProvider = StreamProvider<ReplanReport?>((ref) async* {
  final service = ref.watch(notificationReplanServiceProvider);
  yield service.last;
  yield* service.reports;
});

// ---------------------------------------------------------------------------------- engine --

/// Tables whose changes may affect planned notifications.
const notificationRelevantTables = {
  'tasks',
  'task_occurrences',
  'time_entries',
  'checklists',
  'checklist_items',
  'checklist_runs',
  'habits',
  'habit_logs',
  'habit_pauses',
  'habit_revisions',
  'categories',
  'notification_rules',
  'notification_profiles',
  'notification_mutes',
  'notifications',
  'user_settings',
  'profiles',
};

/// Wires every replan trigger, cold start, reconciliation, the foreground ticker, job upload and
/// push (T7.2.12, T7.2.13, T7.2.16, T7.3.02, T7.4.04, T7.4.10).
class NotificationsEngine {
  NotificationsEngine(this.ref);

  final Ref ref;
  static final _log = AppLog.get('notifications.engine');

  final List<StreamSubscription<Object?>> _subs = [];
  final Set<NotificationTargetSource> _subscribedSources = Set.identity();
  final List<ProviderSubscription<Object?>> _listens = [];
  Timer? _periodic;
  ForegroundTicker? _ticker;
  PushService? _push;
  bool started = false;
  Map<String, String> _targetHashes = {};
  DateTime? _lastSyncSuccess;

  /// User the engine currently runs for (an account switch restarts it).
  String? _userId;
  String? get userId => _userId;

  NotificationReplanService get _replan =>
      ref.read(notificationReplanServiceProvider);

  /// Starts (or, after an account switch, restarts) every notification trigger for the current
  /// user. Idempotent for the same user; does nothing without a user.
  Future<void> start() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId.isEmpty || userId == _userId) return;
    if (_userId != null) _stop();
    _userId = userId;
    started = true;
    final db = ref.read(appDatabaseProvider);
    await db.customStatement(
      'INSERT INTO local_kv(key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value',
      [NotificationBackground.userKey, userId],
    );
    await seedNotificationDefaults(ref.read);

    final port = ref.read(localNotificationsPortProvider);
    final scheduler = ref.read(localSchedulerProvider);
    try {
      await port.initialize(
        categories: scheduler.initialCategories(),
        onResponse: (r) => unawaited(_onResponse(r)),
      );
    } on Object catch (e, st) {
      _log.warning('notification plugin init failed', e, st);
    }
    unawaited(ref.read(notificationCapabilitiesProvider.notifier).refresh());
    _wireTriggers();

    final banners = ref.read(inAppBannerControllerProvider);
    _ticker = ForegroundTicker(
      store: ref.read(localScheduleStoreProvider),
      reconciler: ref.read(inboxReconcilerProvider),
      banners: banners,
      clock: ref.read(clockProvider),
      bannerEnabled: () => ref.read(notificationSettingsProvider).bannerInApp,
      guardOpen: (p) =>
          ref.read(notificationActionDispatcherProvider).guardOpen(p),
    )..start();

    await ref.read(inboxReconcilerProvider).reconcile();
    _replan.request('start', immediate: true);

    // Cold start from a notification tap.
    try {
      final launch = await port.launchResponse();
      if (launch != null) await _onResponse(launch);
    } on Object catch (e) {
      _log.fine('launch details unavailable', e);
    }
    if (defaultTargetPlatform == TargetPlatform.android &&
        !kIsWeb &&
        port.platform == 'android') {
      unawaited(NotificationBackground.registerPeriodic());
    }
    unawaited(_startPush());
  }

  void _wireTriggers() {
    final writer = ref.read(syncWriterProvider);
    _subs.add(
      writer.committed.listen((record) {
        if (record.changes.any(
          (c) => notificationRelevantTables.contains(c.table),
        ))
          _replan.request('write');
      }),
    );
    final db = ref.read(appDatabaseProvider);
    final infos = [
      for (final t in db.allTables)
        if (notificationRelevantTables.contains(t.actualTableName)) t,
    ];
    _subs.add(
      db
          .tableUpdates(TableUpdateQuery.onAllTables(infos))
          .listen((_) => _replan.request('data')),
    );
    // App-icon badge follows the unread count live between replans (T7.3.06).
    _subs.add(
      ref.read(inboxRepositoryProvider).watchUnreadCount().listen((unread) {
        if (ref.read(notificationSettingsProvider).badgePolicy !=
            BadgePolicy.unread)
          return;
        unawaited(ref.read(localNotificationsPortProvider).setBadge(unread));
      }),
    );

    void subscribeSources() {
      for (final source in ref.read(notificationTargetSourcesProvider)) {
        if (!_subscribedSources.add(source)) continue;
        _subs.add(
          source.changes.listen(
            (_) => _replan.request('source:${source.section}'),
          ),
        );
      }
    }

    subscribeSources();
    _subs.add(
      ref.read(notificationRegistryProvider).changes.listen((_) {
        // After the sources provider recomputed (it listens to the same stream).
        scheduleMicrotask(subscribeSources);
        _replan.request('registry');
      }),
    );

    final lifecycle = ref.read(lifecycleProvider);
    _subs
      ..add(lifecycle.onResume.listen((_) => unawaited(_onResume())))
      ..add(
        lifecycle.onPause.listen((_) {
          _ticker?.stop();
          ref.read(inAppBannerControllerProvider).clear();
          _replan.request('pause', immediate: true);
        }),
      )
      ..add(
        _replan.reports.listen((report) => unawaited(_afterReplan(report))),
      );

    _listens
      ..add(
        ref.listen<String>(deviceZoneProvider, (_, zone) {
          _replan.request('zone', immediate: true);
          ref.read(deviceStateReporterProvider).report({'time_zone': zone});
        }),
      )
      ..add(
        ref.listen<(String?, bool)>(
          userPreferencesProvider.select((p) => (p.localeCode, p.use24h)),
          (_, _) => _replan.request('locale'),
        ),
      )
      ..add(
        ref.listen<NotificationCapabilities>(notificationCapabilitiesProvider, (
          previous,
          caps,
        ) {
          if (previous != null && previous.determined)
            _replan.request('capabilities');
          ref.read(deviceStateReporterProvider).report({
            'capabilities': {
              'notifications': caps.notifications,
              'exactAlarm': caps.exactAlarm,
              'timeSensitive': caps.timeSensitive,
              'alarmKit': false,
              'fullScreenIntent': caps.fullScreenIntent,
              'badge': caps.badge,
            },
            'local_notifications_enabled': caps.notifications,
          });
        }),
      )
      ..add(
        ref.listen<SyncStatus>(
          syncStatusProvider,
          (_, status) => unawaited(_onSyncStatus(status)),
        ),
      )
      ..add(
        ref.listen<AppSession?>(sessionProvider, (previous, next) {
          if (previous != null && next == null) unawaited(_onSignOut());
        }),
      );
    // Day rollover / horizon extension while the app stays open.
    _periodic = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _replan.request('periodic'),
    );
  }

  Future<void> _onResume() async {
    final reporter = ref.read(deviceStateReporterProvider)
      ..report({
        'last_seen_at': ref.read(clockProvider).nowUtc().toIso8601String(),
      });
    unawaited(reporter.flush());
    await ref.read(inboxReconcilerProvider).reconcile();
    _ticker?.start();
    _replan.request('resume', immediate: true);
    final db = ref.read(appDatabaseProvider);
    final pending = await db
        .customSelect(
          'SELECT value FROM local_kv WHERE key = ?',
          variables: [Variable<String>(NotificationBackground.pendingPullKey)],
        )
        .getSingleOrNull();
    if (pending != null) {
      ref.read(syncServiceProvider)?.schedulePull(Duration.zero);
      await db.customStatement('DELETE FROM local_kv WHERE key = ?', [
        NotificationBackground.pendingPullKey,
      ]);
    }
  }

  Future<void> _afterReplan(ReplanReport report) async {
    _ticker?.start();
    final plan = ref.read(notificationPipelineProvider).lastPlan;
    if (plan != null) {
      // Targets whose planned instances changed → dirty for the server job upload.
      final hashes = <String, List<String>>{};
      for (final p in plan.planned) {
        (hashes[p.targetKey] ??= []).add('${p.dedupeKey}:${p.contentHash}');
      }
      final next = {
        for (final e in hashes.entries)
          e.key: sha1
              .convert(utf8.encode((e.value..sort()).join('|')))
              .toString(),
      };
      final changed = <String>{
        for (final e in next.entries)
          if (_targetHashes[e.key] != e.value) e.key,
        for (final k in _targetHashes.keys)
          if (!next.containsKey(k)) k,
      };
      final first = _targetHashes.isEmpty;
      _targetHashes = next;
      if (first) {
        await ref.read(jobUploaderProvider).markDirty({'*'});
      } else if (changed.isNotEmpty) {
        await ref.read(jobUploaderProvider).markDirty(changed);
      }
    }
    final userId = ref.read(currentUserIdProvider);
    final rev = await ref.read(jobUploaderProvider).sourceRev(userId);
    ref.read(deviceStateReporterProvider).report({
      'local_coverage_until': report.scheduler.coverageUntil
          ?.toUtc()
          .toIso8601String(),
      'schedule_rev': rev,
      'local_repeating_rules': report.scheduler.repeatingRules.toList()..sort(),
    });
    _saturated = report.scheduler.saturated;
    await _refreshNotices();
  }

  /// Last scheduler saturation (iOS budget), for the system notices between replans.
  bool _saturated = false;

  /// System notices (T7.3.07) — best effort, never breaks a replan.
  Future<void> _refreshNotices() async {
    try {
      await ref.read(systemNoticesProvider).refresh(saturated: _saturated);
    } on Object catch (e) {
      _log.fine('system notices unavailable', e);
    }
  }

  Future<void> _onSyncStatus(SyncStatus status) async {
    unawaited(_refreshNotices());
    final success = status.lastSuccessAt;
    if (success == null || success == _lastSyncSuccess) return;
    _lastSyncSuccess = success;
    await uploadJobs();
  }

  /// Uploads dirty targets after a successful sync push (only when push is configured).
  Future<bool> uploadJobs() async {
    final client = ref.read(supabaseClientProvider);
    final plan = ref.read(notificationPipelineProvider).lastPlan;
    if (client == null || plan == null || !ref.read(pushAvailableProvider))
      return false;
    final uploader = ref.read(jobUploaderProvider);
    final rev = await uploader.sourceRev(ref.read(currentUserIdProvider));
    return uploader.upload(
      SupabaseNotificationJobsApi(client),
      plan,
      sourceRev: rev,
    );
  }

  Future<void> _startPush() async {
    final port = ref.read(pushMessagingPortProvider);
    if (port == null) return;
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } on Object catch (e) {
      _log.fine('FCM background handler not registered', e);
    }
    final db = ref.read(appDatabaseProvider);
    const registeredKey = 'notifications.fcm_registered_at';
    _push = PushService(
      port: port,
      reporter: ref.read(deviceStateReporterProvider),
      onSync: () => ref.read(syncServiceProvider)?.schedulePull(),
      onForegroundReminder: _onForegroundPush,
      onOpened: _onPushOpened,
      onCancel: (m) async {
        final dk = m.dedupeKey;
        if (dk != null) {
          await ref.read(localSchedulerProvider).cancelDelivered(dk);
        }
      },
      isAndroid: ref.read(localNotificationsPortProvider).platform == 'android',
      now: () => ref.read(clockProvider).nowUtc(),
      readRegisteredAt: () async {
        final row = await (db.select(
          db.localKv,
        )..where((k) => k.key.equals(registeredKey))).getSingleOrNull();
        return row == null ? null : DateTime.tryParse(row.value)?.toUtc();
      },
      writeRegisteredAt: (at) => db.customStatement(
        'INSERT INTO local_kv(key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value',
        [registeredKey, at.toUtc().toIso8601String()],
      ),
    );
    await _push!.start(
      bannerInApp: ref.read(notificationSettingsProvider).bannerInApp,
    );
  }

  Future<void> _onForegroundPush(PushMessage m) async {
    final dk = m.dedupeKey;
    if (dk == null) return;
    final target = (m.data['target'] ?? '').split(':');
    final link = _routerLink(m.data['deepLink']);
    final now = ref.read(clockProvider).nowUtc();
    final actions = (m.data['actions'] ?? '')
        .split(',')
        .where((a) => a.isNotEmpty)
        .toList();
    await ref
        .read(inboxRepositoryProvider)
        .upsertDelivered(
          InboxDelivery(
            dedupeKey: dk,
            category: InboxCategory.parse(m.type),
            title: m.title ?? '',
            body: m.body,
            fireAt: DateTime.tryParse(m.data['fireAt'] ?? '')?.toUtc() ?? now,
            sourceType: target.isNotEmpty ? target.first : null,
            sourceId: target.length > 1 ? target[1] : null,
            occurrenceKey: m.data['occ'],
            payload: {
              'v': 1,
              'dk': dk,
              'tk': m.data['target'],
              'occ': m.data['occ'],
              'link': link,
              'acts': actions,
            },
            via: 'push',
            deliveredAt: now,
          ),
        );
    if (ref.read(notificationSettingsProvider).bannerInApp) {
      ref
          .read(inAppBannerControllerProvider)
          .show(
            BannerItem(
              key: dk,
              title: m.title ?? '',
              body: m.body,
              link: link,
              actions: [
                for (final a in actions)
                  if (a != NotificationActionIds.open) a,
              ].take(2).toList(),
              payload: NotificationPayload.fromJson({
                'dk': dk,
                'tk': m.data['target'],
                'tt': target.isNotEmpty ? target.first : null,
                'tid': target.length > 1 ? target[1] : null,
                'occ': m.data['occ'],
                'link': link,
                'acts': actions,
              }),
            ),
          );
    }
  }

  Future<void> _onPushOpened(PushMessage m) async {
    final dk = m.dedupeKey;
    if (dk != null)
      await ref.read(inboxRepositoryProvider).markOpened(Ids.inbox(dk));
    final link = _routerLink(m.data['deepLink']);
    if (link != null)
      ref.read(notificationUiEventsProvider).add(OpenLinkEvent(link));
  }

  static String? _routerLink(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    return uri == null ? null : DeepLinkParser.parse(uri);
  }

  Future<void> _onResponse(OsResponse response) async {
    try {
      final result = await ref
          .read(notificationActionDispatcherProvider)
          .handleResponse(response);
      emit(result);
    } on Object catch (e, st) {
      _log.warning('notification response failed', e, st);
    }
  }

  /// Forwards a dispatcher result to the UI (navigation / "Already done" / messages).
  void emit(ActionDispatchResult result) {
    final events = ref.read(notificationUiEventsProvider);
    if (result.openLink != null)
      events.add(
        OpenLinkEvent(result.openLink!, alreadyDone: result.alreadyDone),
      );
    if (result.message != null) events.add(MessageEvent(result.message!));
  }

  Future<void> _onSignOut() async {
    await ref.read(localSchedulerProvider).clearAll();
    await _push?.signOut();
  }

  void _stop() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _subs.clear();
    _subscribedSources.clear();
    for (final l in _listens) {
      l.close();
    }
    _listens.clear();
    _periodic?.cancel();
    _periodic = null;
    _ticker?.stop();
    _ticker = null;
    unawaited(_push?.dispose());
    _push = null;
    _targetHashes = {};
    started = false;
  }

  void dispose() => _stop();
}

/// Seeds the built-in profiles and section default rules (idempotent, deterministic ids — T7.1.07).
Future<void> seedNotificationDefaults(ProviderReader read) async {
  final l10n = L10nNotificationTexts.forLocale(
    read(userPreferencesProvider).localeCode,
  ).l10n;
  final profiles = read(notificationProfilesRepositoryProvider);
  await profiles.seedBuiltins({
    for (final code in BuiltinProfiles.codes)
      code: builtinProfileName(l10n, code),
  });
  await read(notificationRulesRepositoryProvider)
      .seedDefaults(profiles.builtinId);
}
