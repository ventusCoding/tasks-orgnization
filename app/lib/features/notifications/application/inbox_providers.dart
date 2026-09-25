import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Unread in-app notifications (bell badge, T7.3.06): not read, not dismissed, not currently
/// snoozed. Re-evaluated every minute so expiring snoozes count again without a DB change.
final inboxUnreadCountProvider = StreamProvider<int>((ref) {
  ref.watch(currentUserIdProvider);
  final timer = Timer(const Duration(minutes: 1), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return ref.watch(inboxRepositoryProvider).watchUnreadCount();
});
