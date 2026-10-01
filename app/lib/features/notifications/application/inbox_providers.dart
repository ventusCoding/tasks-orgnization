import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Unread in-app notifications (bell badge, T7.3.06): not read, not dismissed, not currently
/// snoozed. Re-evaluated when the next snooze ends so the row counts again without a DB change
/// (no timer at all while nothing is snoozed).
final inboxUnreadCountProvider = StreamProvider<int>((ref) {
  ref.watch(currentUserIdProvider);
  final repository = ref.watch(inboxRepositoryProvider);
  final clock = ref.watch(clockProvider);
  Timer? timer;
  final snoozed = repository.watchSnoozed().listen((rows) {
    timer?.cancel();
    DateTime? next;
    for (final r in rows) {
      final until = r.snoozedUntil;
      if (until != null && (next == null || until.isBefore(next))) next = until;
    }
    if (next != null) {
      final wait = next.difference(clock.nowUtc()) + const Duration(seconds: 1);
      timer = Timer(wait.isNegative ? Duration.zero : wait, ref.invalidateSelf);
    }
  });
  ref.onDispose(() {
    timer?.cancel();
    unawaited(snoozed.cancel());
  });
  return repository.watchUnreadCount();
});

/// True while *Pause all* is active (app-bar indicator, T7.5.15); flips back by itself when the
/// pause ends.
final notificationsPausedProvider = Provider<bool>((ref) {
  final until = ref.watch(notificationSettingsProvider.select((s) => s.pausedUntil));
  if (until == null) return false;
  final now = ref.watch(clockProvider).nowUtc();
  if (!now.isBefore(until)) return false;
  final timer = Timer(until.difference(now), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return true;
});
