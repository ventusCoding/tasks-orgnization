import 'dart:async';

import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/session/local_account.dart';
import 'package:everslot/core/session/local_data_wiper.dart';
import 'package:everslot/core/session/local_only_choice.dart';
import 'package:everslot/core/session/session.dart';
import 'package:everslot/core/sync/sync_service.dart';
import 'package:everslot/features/auth/application/auth_binding.dart';
import 'package:everslot/features/auth/application/sign_out_service.dart';
import 'package:everslot/features/dev/data/dev_inspector.dart';
import 'package:everslot/features/dev/domain/dev_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final devInspectorProvider = Provider<DevInspector>((ref) => DevInspector(ref.watch(appDatabaseProvider)));

/// Live outbox grouped by operation (sync diagnostics, T1.4.18).
final devOutboxProvider = StreamProvider.autoDispose<List<OutboxGroupView>>(
  (ref) => ref.watch(devInspectorProvider).watchOutbox().map(groupOutbox),
);

/// Live sync cursor of the current user.
final devSyncStateProvider = StreamProvider.autoDispose<SyncStateView?>(
  (ref) => ref.watch(devInspectorProvider).watchSyncState(ref.watch(currentUserIdProvider)),
);

/// Local table sizes (DB inspector). Refresh with `ref.invalidate`.
final devTableCountsProvider = FutureProvider.autoDispose<List<TableCount>>(
  (ref) => ref.watch(devInspectorProvider).tableCounts(),
);

/// First rows of one table (DB inspector).
final devTableRowsProvider = FutureProvider.autoDispose.family<List<Map<String, Object?>>, String>(
  (ref, table) => ref.watch(devInspectorProvider).sampleRows(table),
);

/// Conflict log (stale fields the server rejected), newest first; empty without a sync engine.
final devConflictLogProvider = FutureProvider.autoDispose<List<ConflictLogEntry>>((ref) async {
  final service = ref.watch(syncServiceProvider);
  return service == null ? const <ConflictLogEntry>[] : service.conflictLog();
});

/// Recent log records (ring buffer of [AppLog]).
final devLogsProvider = Provider.autoDispose((ref) => AppLog.recent);

final devToolsProvider = Provider<DevTools>(DevTools.new);

/// Actions of the dev debug menu (T1.3.16) and sync diagnostics (T1.4.18).
class DevTools {
  DevTools(this._ref);

  final Ref _ref;
  static final _log = AppLog.get('dev');

  /// Moves the app clock so that it reads [target] now (time travel).
  void travelTo(DateTime target) =>
      _ref.read(timeTravelProvider.notifier).travel(TimeTravelSteps.offsetFor(target, DateTime.now()));

  /// Adds [step] to the current time-travel offset.
  void travelBy(Duration step) {
    final travel = _ref.read(timeTravelProvider.notifier);
    travel.travel(_ref.read(timeTravelProvider) + step);
  }

  void resetTime() => _ref.read(timeTravelProvider.notifier).travel(Duration.zero);

  void overrideZone(String zone) => _ref.read(deviceZoneProvider.notifier).debugSet(zone);

  Future<void> resetZone() => _ref.read(deviceZoneProvider.notifier).debugClear();

  void toggleFlag(String flag) => _ref.read(featureFlagsProvider.notifier).toggle(flag);

  /// Debug switch: every sync run fails as if offline.
  void simulateOffline(bool on) {
    final service = _ref.read(syncServiceProvider);
    if (service == null) return;
    service.simulateOffline = on;
    if (!on) unawaited(service.syncNow(manual: true));
  }

  bool get simulatingOffline => _ref.read(syncServiceProvider)?.simulateOffline ?? false;

  Future<void> clearConflictLog() async {
    await _ref.read(syncServiceProvider)?.clearConflictLog();
    _ref.invalidate(devConflictLogProvider);
  }

  /// Deletes every local row and file. Cloud sessions end (the data stays on the server, the next
  /// sign-in pulls it back); local-only devices restart with a fresh local account (onboarding).
  Future<void> resetLocalData() async {
    final session = _ref.read(sessionProvider);
    _log.warning('debug: reset local data (${session?.mode.name ?? 'signed out'})');
    if (session != null && session.isCloud) {
      await _ref.read(signOutServiceProvider).endSession();
      return;
    }
    final db = _ref.read(appDatabaseProvider);
    final sessions = _ref.read(sessionProvider.notifier);
    final startup = _ref.read(accountStartupProvider);
    final roots = _ref.read(wipeFileRootsProvider);
    final container = _ref.container;
    final chosenLocalOnly = await LocalOnlyChoice.isChosen(db);
    sessions.set(null);
    await LocalDataWiper.wipeAll(db, fileRoots: roots);
    if (chosenLocalOnly) await LocalOnlyChoice.choose(db);
    final id = await LocalAccount.ensureUserId(db);
    sessions.set(AppSession(userId: id, mode: SessionMode.localOnly));
    unawaited(startup(container));
  }
}
