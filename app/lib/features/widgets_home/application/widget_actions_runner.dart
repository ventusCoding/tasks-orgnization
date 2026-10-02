import 'dart:async';

import 'package:everslot/core/logging/log.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/habits/application/check_in_service.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart' show LogSource;
import 'package:everslot/features/notifications/application/background_entry.dart' show NotificationBackground;
import 'package:everslot/features/widgets_home/application/widget_providers.dart';
import 'package:everslot/features/widgets_home/domain/widget_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Applies a widget button press (T8.2.04 / T8.2.08) with the same application services the UI
/// uses: one SyncWriter transaction + outbox, `source = widget`.
class WidgetActionRunner {
  WidgetActionRunner(this._container);

  final ProviderContainer _container;
  static final _log = AppLog.get('widgets');

  /// True when something was written. [at] is when the user tapped (iOS queues taps for the app).
  Future<bool> run(WidgetAction action, {DateTime? at}) async {
    try {
      switch (action.kind) {
        case WidgetActionKind.habitCheck:
          final habit = await _container.read(habitsRepositoryProvider).byId(action.id!);
          if (habit is! BuildHabit || habit.isArchived) return false;
          final checkIn = _container.read(checkInServiceProvider);
          if (habit.goal.isMeasurable) {
            final target = await checkIn.currentTarget(habit, at: at);
            if (target == null) return false;
            await checkIn.addProgress(habit, target.key, habit.settings.incrementStep, source: LogSource.widget);
          } else {
            await checkIn.checkNow(habit, source: LogSource.widget, at: at);
          }
          return true;
        case WidgetActionKind.itemComplete:
          final record = await _container.read(checklistServiceProvider).changeStatus(action.checklistId!, [
            action.id!,
          ], ItemStatus.completed);
          return record != null;
        case WidgetActionKind.refresh:
          return false;
      }
    } on Object catch (e, st) {
      _log.warning('widget action failed: ${action.kind.name}', e, st);
      return false;
    }
  }
}

/// Applies taps queued by the iOS widget extension (in tap order, at their tap time) and writes a
/// fresh snapshot when something changed. Returns how many actions were applied.
Future<int> drainQueuedWidgetActions(ProviderContainer container) async {
  final queued = await container.read(widgetBridgeProvider).takeQueuedActions();
  if (queued.isEmpty) return 0;
  final runner = WidgetActionRunner(container);
  var applied = 0;
  for (final (uri, at) in queued) {
    final action = WidgetActions.parse(Uri.tryParse(uri));
    if (action != null && await runner.run(action, at: at)) applied++;
  }
  await refreshWidgetSnapshot(container);
  return applied;
}

/// Waits (≤ [timeout]) for a complete snapshot and writes it immediately.
Future<void> refreshWidgetSnapshot(ProviderContainer container, {Duration timeout = const Duration(seconds: 3)}) async {
  final ready = Completer<WidgetSnapshot?>();
  final sub = container.listen<WidgetSnapshot?>(widgetSnapshotProvider, (_, next) {
    if (next != null && !ready.isCompleted) ready.complete(next);
  }, fireImmediately: true);
  try {
    final snapshot = await ready.future.timeout(timeout, onTimeout: () => null);
    if (snapshot == null) return;
    final writer = container.read(widgetSnapshotWriterProvider)..schedule(snapshot);
    await writer.flush();
  } finally {
    sub.close();
  }
}

/// `home_widget` interactivity entry point: runs in a background isolate even when the app was
/// killed; the widget already updated optimistically, the fresh snapshot confirms it.
@pragma('vm:entry-point')
Future<void> widgetInteractivityCallback(Uri? uri) async {
  final action = WidgetActions.parse(uri);
  if (action == null) return;
  await NotificationBackground.run((container) async {
    // No MaterialApp here: date symbols for the pre-rendered labels are loaded by hand.
    await initializeDateFormatting();
    await container.read(widgetBridgeProvider).init();
    await WidgetActionRunner(container).run(action);
    await refreshWidgetSnapshot(container);
  });
}
