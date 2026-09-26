import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:everslot/features/notifications/domain/json_fields.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/planner/planned_notification.dart';
import 'package:meta/meta.dart';

/// Kinds of rows in `local_notification_schedule` (stored in the payload JSON because the
/// Drift table only has the core columns).
abstract final class ScheduleKind {
  static const oneShot = 'one_shot';
  static const nag = 'nag';
  static const merged = 'merged';
  static const sentinel = 'sentinel';
  static const snooze = 'snooze';

  /// Tracked for inbox reconciliation / in-app banner only (no OS request): inbox-only rules,
  /// members of a merged notification, instances beyond the OS budget.
  static const tracked = 'tracked';

  static const test = 'test';
}

/// OS budget (arch §9.7): iOS 56 regular + 8 reserved (nags/snoozes) with a saturation sentinel;
/// Android ≤ 250.
@immutable
class ScheduleBudget {
  const ScheduleBudget({required this.regular, this.reserve = 0, this.sentinel = false});

  static const ios = ScheduleBudget(regular: 56, reserve: 8, sentinel: true);
  static const android = ScheduleBudget(regular: 250);

  final int regular;
  final int reserve;
  final bool sentinel;

  int get total => regular + reserve;
}

/// Stable 31-bit platform ids (FNV-1a) with collision probing (T7.2.09).
abstract final class PlatformIds {
  static const _mask = 0x7fffffff;

  static int hash(String key) {
    var h = 0x811c9dc5;
    for (final b in utf8.encode(key)) {
      h ^= b;
      h = (h * 0x01000193) & 0xffffffff;
    }
    final id = h & _mask;
    return id == 0 ? 1 : id;
  }

  /// Returns the id for [key], probing linearly past ids already [used] by other keys.
  static int assign(String key, Set<int> used) {
    var id = hash(key);
    while (used.contains(id)) {
      id = (id + 1) & _mask;
      if (id == 0) id = 1;
    }
    return id;
  }
}

/// One row of the local schedule (`local_notification_schedule` + payload metadata).
@immutable
class ScheduleEntry {
  const ScheduleEntry({
    required this.dedupeKey,
    required this.platformId,
    required this.fireAt,
    required this.targetKey,
    required this.kind,
    required this.os,
    required this.hash,
    required this.scheduledAt,
    this.expiresAt,
    this.channelId,
    this.repeating = false,
    this.members = const [],
    this.reconciledAt,
    this.inbox = true,
    this.banner = true,
    this.content = const {},
  });

  /// Decodes a row's payload JSON.
  factory ScheduleEntry.fromRow({
    required String dedupeKey,
    required int platformId,
    required DateTime fireAt,
    required String targetKey,
    required String payload,
    required bool repeating,
    required DateTime scheduledAt,
  }) {
    Map<String, Object?> meta;
    try {
      meta = asJsonMap(jsonDecode(payload)) ?? const {};
    } on FormatException {
      meta = const {};
    }
    final exp = asString(meta['exp']);
    final rec = asString(meta['rec']);
    return ScheduleEntry(
      dedupeKey: dedupeKey,
      platformId: platformId,
      fireAt: fireAt.toUtc(),
      targetKey: targetKey,
      kind: asString(meta['k']) ?? ScheduleKind.oneShot,
      os: asBool(meta['os']) ?? true,
      hash: asString(meta['h']) ?? '',
      scheduledAt: scheduledAt.toUtc(),
      expiresAt: exp == null ? null : DateTime.tryParse(exp)?.toUtc(),
      channelId: asString(meta['ch']),
      repeating: repeating,
      members: asStringList(meta['mem']) ?? const [],
      reconciledAt: rec == null ? null : DateTime.tryParse(rec)?.toUtc(),
      inbox: asBool(meta['ib']) ?? true,
      banner: asBool(meta['bn']) ?? true,
      content: asJsonMap(meta['c']) ?? const {},
    );
  }

  final String dedupeKey;
  final int platformId;
  final DateTime fireAt;
  final String targetKey;
  final String kind;

  /// True when an OS request exists (scheduled or delivered).
  final bool os;
  final String hash;
  final DateTime scheduledAt;
  final DateTime? expiresAt;
  final String? channelId;
  final bool repeating;

  /// Member keys of a merged notification.
  final List<String> members;

  /// When the inbox row for this firing was created on this device.
  final DateTime? reconciledAt;
  final bool inbox;
  final bool banner;

  /// Inbox content & identity: `t`, `b`, `cat`, `sec`, `rid`, `tt`, `tid`, `occ`, `link`, `acts`,
  /// `snz`, `bk`, `rep`, `uid`.
  final Map<String, Object?> content;

  bool get createsInboxRow =>
      inbox && kind != ScheduleKind.merged && kind != ScheduleKind.sentinel && kind != ScheduleKind.test;

  String encodePayload() => jsonEncode({
    'k': kind,
    'os': os,
    'h': hash,
    if (expiresAt != null) 'exp': expiresAt!.toUtc().toIso8601String(),
    'ch': ?channelId,
    if (members.isNotEmpty) 'mem': members,
    if (reconciledAt != null) 'rec': reconciledAt!.toUtc().toIso8601String(),
    'ib': inbox,
    'bn': banner,
    if (content.isNotEmpty) 'c': content,
  });

  ScheduleEntry copyWith({
    DateTime? reconciledAt,
    bool? os,
    int? platformId,
    String? channelId,
    String? hash,
    Map<String, Object?>? content,
  }) => ScheduleEntry(
    dedupeKey: dedupeKey,
    platformId: platformId ?? this.platformId,
    fireAt: fireAt,
    targetKey: targetKey,
    kind: kind,
    os: os ?? this.os,
    hash: hash ?? this.hash,
    scheduledAt: scheduledAt,
    expiresAt: expiresAt,
    channelId: channelId ?? this.channelId,
    repeating: repeating,
    members: members,
    reconciledAt: reconciledAt ?? this.reconciledAt,
    inbox: inbox,
    banner: banner,
    content: content ?? this.content,
  );

  @override
  bool operator ==(Object other) =>
      other is ScheduleEntry &&
      other.dedupeKey == dedupeKey &&
      other.platformId == platformId &&
      other.fireAt == fireAt &&
      other.kind == kind &&
      other.os == os &&
      other.hash == hash &&
      other.reconciledAt == reconciledAt;

  @override
  int get hashCode => Object.hash(dedupeKey, platformId, fireAt, kind, os, hash);
}

/// A desired schedule item computed from the plan.
@immutable
class DesiredItem {
  const DesiredItem({
    required this.key,
    required this.fireAt,
    required this.kind,
    required this.os,
    required this.targetKey,
    required this.hash,
    this.planned,
    this.members = const [],
  });

  final String key;
  final DateTime fireAt;
  final String kind;
  final bool os;
  final String targetKey;
  final String hash;

  /// The single planned notification (null for merged / sentinel).
  final PlannedNotification? planned;
  final List<PlannedNotification> members;

  /// Inbox content map stored in the schedule row.
  Map<String, Object?> get content {
    final p = planned;
    if (p == null) return {if (members.isNotEmpty) 'mem': [for (final m in members) m.inboxTitle]};
    return {
      't': p.inboxTitle,
      'b': ?p.inboxBody,
      'cat': p.category.wire,
      'sec': p.section.wire,
      'rid': p.ruleId,
      'tt': p.targetType.wire,
      'tid': p.targetId,
      if (p.occurrenceKey.isNotEmpty) 'occ': p.occurrenceKey,
      'link': p.deepLink,
      if (p.actions.isNotEmpty) 'acts': p.actions,
      if (p.snoozeOptions.isNotEmpty) 'snz': p.snoozeOptions,
      if (p.baseKey != p.dedupeKey) 'bk': p.baseKey,
      if (p.repeatIdx > 0) 'rep': p.repeatIdx,
      'uid': p.userId,
      'imp': p.importance.wire,
    };
  }
}

/// Changes needed to make the OS match the plan (T7.2.09).
@immutable
class ScheduleDiff {
  const ScheduleDiff({required this.cancel, required this.upsert, required this.remove, required this.unchanged});

  /// Rows whose OS request must be cancelled (removed or changed).
  final List<ScheduleEntry> cancel;

  /// Items to (re)schedule with the OS (os = true) or to track (os = false).
  final List<DesiredItem> upsert;

  /// Rows to delete from the table without an OS call.
  final List<ScheduleEntry> remove;
  final int unchanged;

  bool get isEmpty => cancel.isEmpty && upsert.isEmpty && remove.isEmpty;

  /// Number of platform calls this diff needs.
  int get platformCalls => cancel.where((e) => e.os).length + upsert.where((u) => u.os).length;
}

abstract final class ScheduleComputation {
  /// Desired items for this device: soonest first within the [budget], same-minute merge,
  /// iOS saturation sentinel (T7.2.09).
  static List<DesiredItem> desired(
    List<PlannedNotification> planned, {
    required ScheduleBudget budget,
    required String sentinelTitle,
    required String Function(int count) mergedTitle,
    bool merge = true,
  }) {
    final local = [for (final p in planned) if (p.scheduleLocally) p];
    final result = <DesiredItem>[];
    final osCandidates = <PlannedNotification>[];
    for (final p in local) {
      if (p.deliverSystem) {
        osCandidates.add(p);
      } else if (p.deliverInbox || p.deliverBanner) {
        result.add(_single(p, os: false, kind: ScheduleKind.tracked));
      }
    }
    osCandidates.sort(_order);

    // Same-minute merge (Android plays one sound per second; one banner on iOS).
    final groups = <List<PlannedNotification>>[];
    for (final p in osCandidates) {
      final minute = p.fireAt.millisecondsSinceEpoch ~/ 60000;
      if (merge &&
          groups.isNotEmpty &&
          groups.last.first.fireAt.millisecondsSinceEpoch ~/ 60000 == minute &&
          !groups.last.first.isNag &&
          !p.isNag) {
        groups.last.add(p);
      } else {
        groups.add([p]);
      }
    }
    final osItems = <DesiredItem>[];
    for (final g in groups) {
      if (g.length == 1) {
        osItems.add(_single(g.single, os: true, kind: g.single.isNag ? ScheduleKind.nag : ScheduleKind.oneShot));
        continue;
      }
      final keys = [for (final p in g) p.dedupeKey]..sort();
      final key = 'merged:${sha1.convert(utf8.encode(keys.join('|'))).toString().substring(0, 32)}';
      osItems.add(
        DesiredItem(
          key: key,
          fireAt: g.first.fireAt,
          kind: ScheduleKind.merged,
          os: true,
          targetKey: '*',
          hash: _hash([for (final p in g) p.contentHash]),
          members: g,
        ),
      );
      for (final p in g) {
        result.add(_single(p, os: false, kind: ScheduleKind.tracked));
      }
    }

    // Budget: nags use the reserve first, everything else the regular pool; soonest first.
    var reserveLeft = budget.reserve;
    final regular = <DesiredItem>[];
    for (final item in osItems) {
      if (item.kind == ScheduleKind.nag && reserveLeft > 0) {
        reserveLeft--;
        result.add(item);
      } else {
        regular.add(item);
      }
    }
    if (regular.length <= budget.regular) {
      result.addAll(regular);
    } else {
      final keep = budget.sentinel ? budget.regular - 1 : budget.regular;
      result.addAll(regular.take(keep));
      for (final overflow in regular.skip(keep)) {
        _demote(overflow, result);
      }
      if (budget.sentinel) {
        final at = regular[keep].fireAt;
        result.add(
          DesiredItem(
            key: 'sentinel',
            fireAt: at,
            kind: ScheduleKind.sentinel,
            os: true,
            targetKey: '*',
            hash: _hash([at.toIso8601String(), sentinelTitle]),
          ),
        );
      }
    }
    result.sort((a, b) => a.fireAt.compareTo(b.fireAt));
    return result;
  }

  static void _demote(DesiredItem item, List<DesiredItem> out) {
    if (item.planned != null) {
      out.add(_single(item.planned!, os: false, kind: ScheduleKind.tracked));
    }
    // Members of merged groups are already tracked individually.
  }

  static DesiredItem _single(PlannedNotification p, {required bool os, required String kind}) => DesiredItem(
    key: p.dedupeKey,
    fireAt: p.fireAt,
    kind: kind,
    os: os,
    targetKey: p.targetKey,
    hash: os ? p.contentHash : _hash([p.contentHash, 'tracked']),
    planned: p,
  );

  static int _order(PlannedNotification a, PlannedNotification b) {
    final c = a.fireAt.compareTo(b.fireAt);
    if (c != 0) return c;
    final i = b.importance.rank.compareTo(a.importance.rank);
    return i != 0 ? i : a.dedupeKey.compareTo(b.dedupeKey);
  }

  static String _hash(List<String> parts) => sha1.convert(utf8.encode(parts.join('|'))).toString().substring(0, 16);

  /// Diff between the stored schedule and the desired items. Past rows are kept (they await
  /// inbox reconciliation); snooze and test rows are never touched by replans.
  static ScheduleDiff diff(List<ScheduleEntry> current, List<DesiredItem> desired, DateTime now) {
    final managed = {
      for (final e in current)
        if (e.kind != ScheduleKind.snooze && e.kind != ScheduleKind.test) e.dedupeKey: e,
    };
    final desiredKeys = <String>{};
    final cancel = <ScheduleEntry>[];
    final upsert = <DesiredItem>[];
    final remove = <ScheduleEntry>[];
    var unchanged = 0;
    for (final d in desired) {
      desiredKeys.add(d.key);
      final existing = managed[d.key];
      if (existing == null) {
        upsert.add(d);
        continue;
      }
      if (!existing.fireAt.isAfter(now) && !d.fireAt.isAfter(now)) {
        // Already fired (or catch-up already shown): leave it for reconciliation.
        unchanged++;
        continue;
      }
      if (existing.hash == d.hash && existing.os == d.os) {
        unchanged++;
        continue;
      }
      if (existing.os) cancel.add(existing);
      upsert.add(d);
    }
    for (final e in managed.values) {
      if (desiredKeys.contains(e.dedupeKey)) continue;
      if (!e.fireAt.isAfter(now)) continue; // fired → keep for reconciliation / cleanup
      if (e.os) {
        cancel.add(e);
      } else {
        remove.add(e);
      }
    }
    return ScheduleDiff(cancel: cancel, upsert: upsert, remove: remove, unchanged: unchanged);
  }

  /// `devices.local_coverage_until`: fire time of the last OS-scheduled one-shot, or the horizon
  /// end when everything fit (T7.2.11).
  static DateTime? coverageUntil(List<DesiredItem> desired, {required DateTime horizonEnd}) {
    final saturated = desired.any((d) => d.kind == ScheduleKind.sentinel) ||
        desired.any((d) => !d.os && d.kind == ScheduleKind.tracked && d.planned?.deliverSystem == true && _isOverflow(d, desired));
    final osTimes = [for (final d in desired) if (d.os && d.kind != ScheduleKind.sentinel) d.fireAt];
    if (!saturated) return horizonEnd;
    if (osTimes.isEmpty) return null;
    osTimes.sort();
    final sentinel = desired.where((d) => d.kind == ScheduleKind.sentinel).map((d) => d.fireAt);
    return sentinel.isNotEmpty ? sentinel.first : osTimes.last;
  }

  static bool _isOverflow(DesiredItem tracked, List<DesiredItem> all) {
    // A tracked system notification that is not part of a merged group = over budget.
    final key = tracked.key;
    return !all.any((d) => d.kind == ScheduleKind.merged && d.members.any((m) => m.dedupeKey == key));
  }

  /// Importance helper for sorting in UIs.
  static int importanceRank(String? wire) => (NotificationImportance.tryParse(wire) ?? NotificationImportance.normal).rank;
}
