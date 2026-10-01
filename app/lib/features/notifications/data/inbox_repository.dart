import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:everslot/features/notifications/domain/inbox_item.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';

/// Delivered firing to record in the inbox (reconciliation, foreground ticker, push).
class InboxDelivery {
  const InboxDelivery({
    required this.dedupeKey,
    required this.category,
    required this.title,
    required this.fireAt,
    this.body,
    this.ruleId,
    this.sourceType,
    this.sourceId,
    this.occurrenceKey,
    this.section,
    this.payload = const {},
    this.via = 'local',
    this.late = false,
    this.deliveredAt,
  });

  final String dedupeKey;
  final InboxCategory category;
  final String title;
  final String? body;
  final DateTime fireAt;
  final String? ruleId;
  final String? sourceType;
  final String? sourceId;
  final String? occurrenceKey;
  final NotificationSection? section;
  final Map<String, Object?> payload;

  /// local | push | inbox_only
  final String via;
  final bool late;
  final DateTime? deliveredAt;
}

/// `notifications` inbox (T7.3.01). Convergence rules (normative, [7.3]): id =
/// `uuidv5(dedupe_key)`; devices write user state; delivery fields merge (earliest
/// `delivered_at`, union of `delivered_via`); automatic inserts are stamped with the scheduled
/// fire instant so later user edits always win.
class InboxRepository {
  InboxRepository(this._db, this._writer, this._userId, this._clock);

  final AppDatabase _db;
  final SyncWriter _writer;
  final String Function() _userId;
  final Clock _clock;

  static InboxItem mapRow(NotificationRow r) => InboxItem(
    id: r.id,
    dedupeKey: r.dedupeKey,
    category: InboxCategory.parse(r.category),
    title: r.title,
    body: r.body,
    fireAt: r.fireAt.toUtc(),
    ruleId: r.ruleId,
    sourceType: r.sourceType,
    sourceId: r.sourceId,
    occurrenceKey: r.occurrenceKey,
    section: NotificationSection.tryParse(r.section),
    payload: InboxItem.decodePayload(r.payload),
    deliveredAt: r.deliveredAt?.toUtc(),
    deliveredVia: InboxItem.decodeVia(r.deliveredVia),
    late: r.late,
    openedAt: r.openedAt?.toUtc(),
    readAt: r.readAt?.toUtc(),
    dismissedAt: r.dismissedAt?.toUtc(),
    actedAt: r.actedAt?.toUtc(),
    action: r.action,
    snoozedUntil: r.snoozedUntil?.toUtc(),
  );

  SimpleSelectStatement<$NotificationsTable, NotificationRow> _query(InboxFilter filter, DateTime now) {
    final q = _db.select(_db.notifications)
      ..where((n) => n.deletedAt.isNull() & n.userId.equals(_userId()))
      ..orderBy([(n) => OrderingTerm.desc(n.fireAt), (n) => OrderingTerm.desc(n.id)]);
    if (filter.unreadOnly) {
      q.where(
        (n) =>
            n.readAt.isNull() &
            n.dismissedAt.isNull() &
            (n.snoozedUntil.isNull() | n.snoozedUntil.isSmallerOrEqualValue(now)),
      );
    } else {
      q.where((n) => n.dismissedAt.isNull());
    }
    if (filter.section != null) {
      q.where((n) => n.section.equals(filter.section!.wire));
    }
    if (filter.category != null) {
      q.where((n) => n.category.equals(filter.category!.wire));
    }
    if (filter.from != null) {
      q.where((n) => n.fireAt.isBiggerOrEqualValue(filter.from!));
    }
    if (filter.to != null) {
      q.where((n) => n.fireAt.isSmallerThanValue(filter.to!));
    }
    final query = filter.query?.trim();
    if (query != null && query.isNotEmpty) {
      q.where((n) => n.title.like('%$query%') | n.body.like('%$query%'));
    }
    return q;
  }

  /// Newest first; 90-day retention (older rows hidden, T7.3.10).
  Stream<List<InboxItem>> watchInbox({InboxFilter filter = InboxFilter.all, int limit = 500}) {
    final now = _clock.nowUtc();
    final retention = now.subtract(const Duration(days: 90));
    return (_query(filter, now)
          ..where((n) => n.fireAt.isBiggerOrEqualValue(retention))
          ..limit(limit))
        .watch()
        .map((rows) => rows.map(mapRow).toList());
  }

  Future<List<InboxItem>> inbox({InboxFilter filter = InboxFilter.all, int limit = 500}) async =>
      (await (_query(filter, _clock.nowUtc())..limit(limit)).get()).map(mapRow).toList();

  /// Rows with `snoozed_until > now` (Snoozed section, T7.3.08).
  Stream<List<InboxItem>> watchSnoozed() {
    final now = _clock.nowUtc();
    return (_db.select(_db.notifications)
          ..where(
            (n) =>
                n.deletedAt.isNull() &
                n.userId.equals(_userId()) &
                n.dismissedAt.isNull() &
                n.snoozedUntil.isBiggerThanValue(now),
          )
          ..orderBy([(n) => OrderingTerm.asc(n.snoozedUntil)]))
        .watch()
        .map((rows) => rows.map(mapRow).toList());
  }

  /// Unread = not read, not dismissed, not currently snoozed (T7.3.01).
  Stream<int> watchUnreadCount() {
    final now = _clock.nowUtc();
    final count = _db.notifications.id.count();
    final n = _db.notifications;
    return (_db.selectOnly(n)
          ..addColumns([count])
          ..where(
            n.deletedAt.isNull() &
                n.userId.equals(_userId()) &
                n.readAt.isNull() &
                n.dismissedAt.isNull() &
                (n.snoozedUntil.isNull() | n.snoozedUntil.isSmallerOrEqualValue(now)),
          ))
        .watchSingle()
        .map((row) => row.read(count) ?? 0);
  }

  /// Past rows of one source (per-item history, T7.3.09).
  Stream<List<InboxItem>> watchForSource(String sourceType, String sourceId) =>
      (_db.select(_db.notifications)
            ..where((n) => n.deletedAt.isNull() & n.sourceType.equals(sourceType) & n.sourceId.equals(sourceId))
            ..orderBy([(n) => OrderingTerm.desc(n.fireAt)])
            ..limit(200))
          .watch()
          .map((rows) => rows.map(mapRow).toList());

  Future<InboxItem?> byDedupeKey(String dedupeKey) async {
    final row = await (_db.select(
      _db.notifications,
    )..where((n) => n.id.equals(Ids.inbox(dedupeKey)))).getSingleOrNull();
    return row == null ? null : mapRow(row);
  }

  Future<InboxItem?> byId(String id) async {
    final row = await (_db.select(_db.notifications)..where((n) => n.id.equals(id))).getSingleOrNull();
    return row == null ? null : mapRow(row);
  }

  /// Base keys acknowledged (acted / opened / dismissed) since [since] — stops nag chains.
  Future<Set<String>> acknowledgedKeys({required DateTime since}) async {
    final rows =
        await (_db.select(_db.notifications)..where(
              (n) =>
                  n.deletedAt.isNull() &
                  n.fireAt.isBiggerOrEqualValue(since) &
                  (n.actedAt.isNotNull() | n.openedAt.isNotNull() | n.dismissedAt.isNotNull()),
            ))
            .get();
    return {for (final r in rows) mapRow(r).baseKey};
  }

  // --------------------------------------------------------------------------- user state --

  Future<OpRecord> markRead(List<String> ids) => _writer.run((tx) async {
    for (final id in ids) {
      if (await tx.exists('notifications', id)) {
        await tx.update('notifications', id, {'read_at': tx.now});
      }
    }
  });

  Future<OpRecord> markUnread(String id) => _writer.run((tx) => tx.update('notifications', id, {'read_at': null}));

  Future<OpRecord> markAllRead({NotificationSection? section}) async {
    final unread = await inbox(filter: InboxFilter(unreadOnly: true, section: section), limit: 5000);
    return markRead([for (final i in unread) i.id]);
  }

  /// Tapped from the OS / banner / inbox: opened + read.
  Future<OpRecord> markOpened(String id) => _writer.run((tx) async {
    if (!await tx.exists('notifications', id)) return;
    final row = await tx.readRaw('notifications', id);
    await tx.update('notifications', id, {'opened_at': tx.now, if (row?['read_at'] == null) 'read_at': tx.now});
  });

  Future<OpRecord> markActed(String id, String action, {WriteTx? inTx}) async {
    Future<void> body(WriteTx tx) async {
      if (!await tx.exists('notifications', id)) return;
      final row = await tx.readRaw('notifications', id);
      await tx.update('notifications', id, {
        'acted_at': tx.now,
        'action': action,
        if (row?['read_at'] == null) 'read_at': tx.now,
      });
    }

    if (inTx != null) {
      await body(inTx);
      return OpRecord(opId: inTx.opId, changes: const [], cause: inTx.cause);
    }
    return _writer.run(body);
  }

  /// Dismiss (undoable via the returned record).
  Future<OpRecord> dismiss(String id) => _writer.run((tx) => tx.update('notifications', id, {'dismissed_at': tx.now}));

  Future<OpRecord> dismissMany(List<String> ids) => _writer.run((tx) async {
    for (final id in ids) {
      await tx.update('notifications', id, {'dismissed_at': tx.now});
    }
  });

  Future<OpRecord> setSnoozedUntil(String id, DateTime? until) =>
      _writer.run((tx) => tx.update('notifications', id, {'snoozed_until': until?.toUtc()}));

  // ------------------------------------------------------------------------- deliveries --

  /// Inserts the row for a delivered firing, or merges delivery fields into an existing row
  /// (earliest `delivered_at`, union of `delivered_via`, `late` sticky). Stamped at the fire
  /// instant (automatic write). Returns true when a new row was created.
  Future<bool> upsertDelivered(InboxDelivery d) async {
    final id = Ids.inbox(d.dedupeKey);
    var created = false;
    await _writer.run(
      (tx) async {
        final existing = await tx.readRaw('notifications', id);
        final deliveredAt = (d.deliveredAt ?? d.fireAt).toUtc();
        if (existing == null) {
          created = true;
          await tx.insert('notifications', id, {
            'dedupe_key': d.dedupeKey,
            'rule_id': d.ruleId,
            'source_type': d.sourceType,
            'source_id': d.sourceId,
            'occurrence_key': d.occurrenceKey,
            'category': d.category.wire,
            'title': d.title,
            'body': d.body,
            'payload': d.payload,
            'section': d.section?.wire,
            'fire_at': d.fireAt.toUtc(),
            'delivered_at': deliveredAt,
            'delivered_via': [d.via],
            'late': d.late,
          });
          return;
        }
        final via = InboxItem.decodeVia(existing['delivered_via'] as String?);
        final currentDelivered = existing['delivered_at'];
        final current = currentDelivered is String ? DateTime.tryParse(currentDelivered) : null;
        await tx.update('notifications', id, {
          if (!via.contains(d.via)) 'delivered_via': [...via, d.via],
          if (current == null || deliveredAt.isBefore(current.toUtc())) 'delivered_at': deliveredAt,
          if (d.late) 'late': true,
          if (existing['deleted_at'] != null) 'deleted_at': null,
        });
      },
      cause: 'auto',
      scheduledAt: d.fireAt,
    );
    return created;
  }

  /// System notice (T7.3.07): creates the row of [d] once; a notice resolved earlier (dismissed)
  /// is re-opened as a new unread row at [d.fireAt] — same deterministic id, never a duplicate.
  /// Returns true when the notice became visible.
  Future<bool> openNotice(InboxDelivery d) async {
    final id = Ids.inbox(d.dedupeKey);
    final existing = await byId(id);
    if (existing == null) return upsertDelivered(d);
    if (existing.dismissedAt == null) return false;
    await _writer.run(
      (tx) => tx.update('notifications', id, {
        'title': d.title,
        'body': d.body,
        'payload': d.payload,
        'fire_at': d.fireAt.toUtc(),
        'delivered_at': d.fireAt.toUtc(),
        'dismissed_at': null,
        'read_at': null,
        'acted_at': null,
        'deleted_at': null,
      }),
      cause: 'auto',
      scheduledAt: d.fireAt,
    );
    return true;
  }

  /// Resolves a system notice: dismissed automatically once its condition is fixed (T7.3.07).
  Future<void> resolveNotice(String dedupeKey, DateTime at) async {
    final id = Ids.inbox(dedupeKey);
    final existing = await byId(id);
    if (existing == null || existing.dismissedAt != null) return;
    await _writer.run(
      (tx) => tx.update('notifications', id, {'dismissed_at': at.toUtc()}),
      cause: 'auto',
      scheduledAt: at,
    );
  }

  /// Local cleanup: soft-deletes rows older than [retention] (the server does the same nightly).
  Future<int> purgeOlderThan(Duration retention) async {
    final cutoff = _clock.nowUtc().subtract(retention);
    final rows =
        await (_db.select(_db.notifications)
              ..where((n) => n.deletedAt.isNull() & n.fireAt.isSmallerThanValue(cutoff))
              ..limit(500))
            .get();
    if (rows.isEmpty) return 0;
    await _writer.run((tx) async {
      for (final r in rows) {
        await tx.softDelete('notifications', r.id);
      }
    }, cause: 'auto');
    return rows.length;
  }
}
