import 'package:drift/drift.dart';
import 'package:everslot/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Unread in-app notifications (bell badge, T7.3.06).
final inboxUnreadCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final count = db.notifications.id.count();
  final query = db.selectOnly(db.notifications)
    ..addColumns([count])
    ..where(db.notifications.readAt.isNull() & db.notifications.deletedAt.isNull() &
        db.notifications.dismissedAt.isNull());
  return query.watchSingle().map((row) => row.read(count) ?? 0);
});
