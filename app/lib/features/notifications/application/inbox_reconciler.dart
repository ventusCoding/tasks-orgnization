import 'package:everslot/core/time/clock.dart';
import 'package:everslot/features/notifications/data/inbox_repository.dart';
import 'package:everslot/features/notifications/data/local_schedule_store.dart';
import 'package:everslot/features/notifications/domain/json_fields.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/scheduler/schedule_plan.dart';

/// Creates inbox rows for every fired instance, even when the app never ran at fire time
/// (iOS runs no code when a local notification fires) — T7.3.02. Idempotent: same dedupe key →
/// same inbox id on every device; the schedule row is marked reconciled.
class InboxReconciler {
  InboxReconciler({required this.store, required this.inbox, required this.clock});

  final LocalScheduleStore store;
  final InboxRepository inbox;
  final Clock clock;

  /// Reconciles fired rows (all, or only [onlyKeys]). Returns the rows written.
  Future<List<ScheduleEntry>> reconcile({Set<String>? onlyKeys}) async {
    final now = clock.nowUtc();
    final done = <ScheduleEntry>[];
    for (final e in await store.dueUnreconciled(now)) {
      if (onlyKeys != null && !onlyKeys.contains(e.dedupeKey)) continue;
      final delivery = deliveryFor(e);
      if (delivery == null) {
        await store.put(e.copyWith(reconciledAt: now));
        continue;
      }
      await inbox.upsertDelivered(delivery);
      final marked = e.copyWith(reconciledAt: now);
      await store.put(marked);
      done.add(marked);
    }
    return done;
  }

  /// Inbox delivery for a schedule row (null when the row carries no content).
  static InboxDelivery? deliveryFor(ScheduleEntry e) {
    final c = e.content;
    final title = asString(c['t']);
    if (title == null || !e.inbox) return null;
    final payload = <String, Object?>{
      'v': 1,
      'dk': e.dedupeKey,
      'bk': ?asString(c['bk']),
      'tk': e.targetKey,
      'tt': ?asString(c['tt']),
      'tid': ?asString(c['tid']),
      'occ': ?asString(c['occ']),
      'rid': ?asString(c['rid']),
      'sec': ?asString(c['sec']),
      'cat': ?asString(c['cat']),
      'link': ?asString(c['link']),
      'acts': ?c['acts'],
      'snz': ?c['snz'],
      'rep': ?c['rep'],
      'uid': ?asString(c['uid']),
      'adj': ?c['adj'],
    };
    return InboxDelivery(
      dedupeKey: e.dedupeKey,
      category: InboxCategory.parse(asString(c['cat'])),
      title: title,
      body: asString(c['b']),
      fireAt: e.fireAt,
      ruleId: asString(c['rid']),
      sourceType: asString(c['tt']),
      sourceId: asString(c['tid']),
      occurrenceKey: asString(c['occ']),
      section: NotificationSection.tryParse(asString(c['sec'])),
      payload: payload,
      // Members of merged / repeating notifications were shown through their group.
      via: e.os || e.kind == ScheduleKind.merged || asBool(c['grp']) == true ? 'local' : 'inbox_only',
    );
  }
}
