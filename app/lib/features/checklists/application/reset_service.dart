import 'dart:async';

import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/sync/sync_status.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:everslot/core/time/recurrence_service.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/data/checklist_items_repository.dart';
import 'package:everslot/features/checklists/data/checklists_repository.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/reset.dart';
import 'package:everslot/features/checklists/domain/tree_change.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resettable / recurring checklists (T4.5.06).
///
/// A reset is idempotent across devices: the run row id is `uuidv5(checklist_id | key)`, and its
/// writes use the occurrence instant as their clock so later user edits win under LWW.
class ChecklistResetService {
  ChecklistResetService({
    required this._lists,
    required this._items,
    required this._engine,
    required this._clock,
    required this._zone,
  });

  final ChecklistsRepository _lists;
  final ChecklistItemsRepository _items;
  final RecurrenceEngine _engine;
  final Clock _clock;
  final String Function() _zone;
  final _log = AppLog.get('checklists.reset');
  Future<int>? _running;

  /// Applies every due reset (only the latest after missed periods). Returns the number applied.
  Future<int> runDue({String? onlyChecklistId}) {
    final existing = _running;
    if (existing != null && onlyChecklistId == null) return existing;
    final future = _runDue(onlyChecklistId).whenComplete(() {
      if (onlyChecklistId == null) _running = null;
    });
    if (onlyChecklistId == null) _running = future;
    return future;
  }

  Future<int> _runDue(String? onlyChecklistId) async {
    var applied = 0;
    final lists = await _lists.recurring();
    for (final c in lists) {
      if (onlyChecklistId != null && c.id != onlyChecklistId) continue;
      try {
        if (await _resetIfDue(c)) applied++;
      } on Object catch (e, st) {
        _log.warning('reset of ${c.id} failed', e, st);
      }
    }
    return applied;
  }

  Future<bool> _resetIfDue(Checklist c) async {
    final schedule = ResetSchedule.fromJson(c.resetRule);
    if (schedule == null) return false;
    final plan = ResetPlanner.due(
      _engine,
      schedule,
      lastResetKey: c.lastResetKey,
      now: _clock.nowUtc(),
      evalZone: _zone(),
    );
    if (plan == null) return false;
    final runId = Ids.checklistRun(c.id, plan.key);
    if (await _lists.runExists(runId)) {
      // Another device already reset this period; just catch up the key (automatic write).
      if (c.lastResetKey != plan.key) {
        await _lists.applyChange(
          TreeChange(
            writes: [
              RowWrite.update('checklists', c.id, {'last_reset_key': plan.key}),
            ],
            cause: 'reset',
            scheduledAt: plan.at,
          ),
        );
      }
      return false;
    }
    final tree = ChecklistTree.build(await _items.items(c.id));
    final change = ResetPlanner.apply(
      tree,
      c,
      runId: runId,
      key: plan.key,
      at: plan.at,
      startedAt: plan.previousAt ?? c.createdAt ?? plan.at,
      mode: c.resetMode ?? ResetMode.completedToTodo,
    );
    await _lists.applyChange(change);
    return true;
  }

  /// "Reset now" (key `manual:<uuidv7>`): a run is recorded; `last_reset_key` is untouched.
  Future<OpRecord?> resetNow(String checklistId) async {
    final c = await _lists.byId(checklistId);
    if (c == null) return null;
    final key = 'manual:${Ids.v7()}';
    final now = _clock.nowUtc();
    final tree = ChecklistTree.build(await _items.items(checklistId));
    final change = ResetPlanner.apply(
      tree,
      c,
      runId: Ids.checklistRun(checklistId, key),
      key: key,
      at: now,
      startedAt: c.updatedAt ?? c.createdAt ?? now,
      mode: c.resetMode ?? ResetMode.allToTodo,
      updateLastKey: false,
    );
    return _lists.applyChange(change);
  }

  /// Sets (or clears) the schedule; past occurrences are marked as done.
  Future<OpRecord> configure(
    String checklistId,
    ResetSchedule? schedule, {
    ResetMode mode = ResetMode.completedToTodo,
  }) {
    final lastKey = schedule == null
        ? null
        : ResetPlanner.initialKey(_engine, schedule, now: _clock.nowUtc(), evalZone: _zone());
    return _lists.setResetRule(checklistId, rule: schedule?.toJson(), mode: mode, lastResetKey: lastKey);
  }

  DateTime? nextReset(ResetSchedule schedule) =>
      ResetPlanner.next(_engine, schedule, now: _clock.nowUtc(), evalZone: _zone());
}

final checklistResetServiceProvider = Provider<ChecklistResetService>(
  (ref) => ChecklistResetService(
    lists: ref.watch(checklistsRepositoryProvider),
    items: ref.watch(checklistItemsRepositoryProvider),
    // The shared facade's engine (T2.1.14): one resolver and zone handling app-wide.
    engine: ref.watch(recurrenceServiceProvider).engine,
    clock: ref.watch(clockProvider),
    zone: () => ref.read(deviceZoneProvider),
  ),
);

/// Startup hook (T4.5.06): resets at app start, on resume and after each pull.
Future<void> runChecklistResets(ProviderContainer container) async {
  final service = container.read(checklistResetServiceProvider);
  unawaited(service.runDue());
  // Both subscriptions live as long as the app.
  _keepAlive.add(container.read(lifecycleProvider).onResume.listen((_) => unawaited(service.runDue())));
  container.listen<SyncStatus>(syncStatusProvider, (prev, next) {
    if (prev?.phase == SyncPhase.pulling && next.phase != SyncPhase.pulling) unawaited(service.runDue());
  });
}

final List<StreamSubscription<void>> _keepAlive = [];
