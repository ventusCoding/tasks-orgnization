import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:everslot/features/notifications/domain/json_fields.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/planner/planned_notification.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
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

  /// One OS calendar trigger (daily or weekly) standing for a regular sequence of instances,
  /// which stay `tracked` for the inbox (T7.2.10).
  static const repeating = 'repeating';
}

/// OS calendar-trigger repetition (T7.2.10): `DateTimeComponents.time` /
/// `DateTimeComponents.dayOfWeekAndTime`.
enum RepeatMatch {
  daily('time', 1),
  weekly('day_of_week_and_time', 7);

  const RepeatMatch(this.wire, this.stepDays);

  final String wire;
  final int stepDays;

  static RepeatMatch? tryParse(String? wire) {
    for (final m in values) {
      if (m.wire == wire) return m;
    }
    return null;
  }
}

/// Inputs of the repeating-trigger optimization (T7.2.10).
@immutable
class RepeatingOptions {
  const RepeatingOptions({
    required this.zones,
    required this.zone,
    required this.now,
    required this.horizonEnd,
    required this.honorsStartDate,
  });

  final ZoneResolver zones;

  /// Device zone: the zone of the OS calendar trigger.
  final String zone;
  final DateTime now;
  final DateTime horizonEnd;

  /// Android arms the first alarm at the given date; an iOS calendar trigger fires at the next
  /// matching time, so there a sequence must start at the first match after now.
  final bool honorsStartDate;
}

/// OS budget (arch §9.7): iOS 56 regular + 8 reserved (nags/snoozes) with a saturation sentinel;
/// Android ≤ 250.
@immutable
class ScheduleBudget {
  const ScheduleBudget({
    required this.regular,
    this.reserve = 0,
    this.sentinel = false,
  });

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
      inbox &&
      kind != ScheduleKind.merged &&
      kind != ScheduleKind.repeating &&
      kind != ScheduleKind.sentinel &&
      kind != ScheduleKind.test;

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
  int get hashCode =>
      Object.hash(dedupeKey, platformId, fireAt, kind, os, hash);
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
    this.repeat,
  });

  final String key;
  final DateTime fireAt;
  final String kind;
  final bool os;
  final String targetKey;
  final String hash;

  /// The single planned notification (null for merged / sentinel; the first member of a
  /// repeating sequence).
  final PlannedNotification? planned;
  final List<PlannedNotification> members;

  /// Repetition of a `repeating` item.
  final RepeatMatch? repeat;

  /// Inbox content map stored in the schedule row.
  Map<String, Object?> get content {
    final p = planned;
    if (p == null)
      return {
        if (members.isNotEmpty) 'mem': [for (final m in members) m.inboxTitle],
      };
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
  const ScheduleDiff({
    required this.cancel,
    required this.upsert,
    required this.remove,
    required this.unchanged,
  });

  /// Rows whose OS request must be cancelled (removed or changed).
  final List<ScheduleEntry> cancel;

  /// Items to (re)schedule with the OS (os = true) or to track (os = false).
  final List<DesiredItem> upsert;

  /// Rows to delete from the table without an OS call.
  final List<ScheduleEntry> remove;
  final int unchanged;

  bool get isEmpty => cancel.isEmpty && upsert.isEmpty && remove.isEmpty;

  /// Number of platform calls this diff needs.
  int get platformCalls =>
      cancel.where((e) => e.os).length + upsert.where((u) => u.os).length;
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
    RepeatingOptions? repeating,
  }) {
    final local = [
      for (final p in planned)
        if (p.scheduleLocally) p,
    ];
    final result = <DesiredItem>[];
    var osCandidates = <PlannedNotification>[];
    for (final p in local) {
      if (p.deliverSystem) {
        osCandidates.add(p);
      } else if (p.deliverInbox || p.deliverBanner) {
        result.add(_single(p, os: false, kind: ScheduleKind.tracked));
      }
    }

    // Regular daily/weekly sequences → one repeating OS trigger each; members stay tracked.
    final osItems = <DesiredItem>[];
    if (repeating != null) {
      final sequences = repeatingSequences(osCandidates, repeating);
      final covered = <String>{};
      for (final item in sequences) {
        osItems.add(item);
        for (final m in item.members) {
          covered.add(m.dedupeKey);
          result.add(_single(m, os: false, kind: ScheduleKind.tracked));
        }
      }
      if (covered.isNotEmpty) {
        osCandidates = [
          for (final p in osCandidates)
            if (!covered.contains(p.dedupeKey)) p,
        ];
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
    for (final g in groups) {
      if (g.length == 1) {
        osItems.add(
          _single(
            g.single,
            os: true,
            kind: g.single.isNag ? ScheduleKind.nag : ScheduleKind.oneShot,
          ),
        );
        continue;
      }
      final keys = [for (final p in g) p.dedupeKey]..sort();
      final key =
          'merged:${sha1.convert(utf8.encode(keys.join('|'))).toString().substring(0, 32)}';
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
    osItems.sort(_itemOrder);
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
    // Members of merged groups and repeating sequences are already tracked individually.
    if (item.kind == ScheduleKind.repeating) return;
    if (item.planned != null) {
      out.add(_single(item.planned!, os: false, kind: ScheduleKind.tracked));
    }
    // Members of merged groups are already tracked individually.
  }

  static DesiredItem _single(
    PlannedNotification p, {
    required bool os,
    required String kind,
  }) => DesiredItem(
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

  static int _itemOrder(DesiredItem a, DesiredItem b) {
    final c = a.fireAt.compareTo(b.fireAt);
    if (c != 0) return c;
    int rank(DesiredItem d) => [
      if (d.planned != null) d.planned!,
      ...d.members,
    ].fold(0, (r, p) => p.importance.rank > r ? p.importance.rank : r);
    final i = rank(b).compareTo(rank(a));
    return i != 0 ? i : a.key.compareTo(b.key);
  }

  /// Everything the OS shows for an instance except its time and identity (sequence grouping).
  static String _shape(PlannedNotification p) => _hash([
    p.channelId,
    p.title,
    p.body ?? '',
    p.actions.join(','),
    p.snoozeOptions.join(','),
    p.sound,
    p.vibration,
    p.importance.wire,
    p.interruptionLevel.wire,
    p.threadId,
    p.deepLink,
    p.expiresAt.difference(p.fireAt).inMinutes.toString(),
  ]);

  /// Regular daily / weekly sequences among [candidates] (T7.2.10): same rule, target and
  /// shown content, same local time in the device zone, every day (or every week on the same
  /// weekday) without a gap from the first match after now (iOS) to beyond the horizon end.
  static List<DesiredItem> repeatingSequences(
    List<PlannedNotification> candidates,
    RepeatingOptions o,
  ) {
    final groups = <String, List<PlannedNotification>>{};
    for (final p in candidates) {
      if (!p.repeatable || p.isNag || !p.fireAt.isAfter(o.now)) continue;
      groups
          .putIfAbsent('${p.ruleId}|${p.targetKey}|${_shape(p)}', () => [])
          .add(p);
    }
    final items = <DesiredItem>[];
    for (final group in groups.values) {
      if (group.length < 2) continue;
      final byTime = <LocalTime, List<(PlannedNotification, LocalDateTime)>>{};
      for (final p in group) {
        final local = o.zones.toLocal(p.fireAt, o.zone);
        // A fire time that doesn't resolve back (DST gap / fold) can't be a calendar match.
        if (o.zones.resolve(local, o.zone).utc != p.fireAt) continue;
        byTime.putIfAbsent(local.time, () => []).add((p, local));
      }
      for (final sequence in byTime.values) {
        sequence.sort((a, b) => a.$1.fireAt.compareTo(b.$1.fireAt));
        if (_regular(sequence, RepeatMatch.daily, o)) {
          items.add(_sequenceItem(sequence, RepeatMatch.daily, o));
          continue;
        }
        final byWeekday =
            <Weekday, List<(PlannedNotification, LocalDateTime)>>{};
        for (final e in sequence) {
          byWeekday.putIfAbsent(e.$2.date.weekday, () => []).add(e);
        }
        for (final weekly in byWeekday.values) {
          if (_regular(weekly, RepeatMatch.weekly, o)) {
            items.add(_sequenceItem(weekly, RepeatMatch.weekly, o));
          }
        }
      }
    }
    items.sort(_itemOrder);
    return items;
  }

  static bool _regular(
    List<(PlannedNotification, LocalDateTime)> sequence,
    RepeatMatch match,
    RepeatingOptions o,
  ) {
    if (sequence.length < 2) return false;
    for (var i = 1; i < sequence.length; i++) {
      final expected = sequence[i - 1].$2.date.plusDays(match.stepDays);
      if (sequence[i].$2.date != expected) return false;
    }
    final time = sequence.first.$2.time;
    DateTime at(LocalDate date) =>
        o.zones.resolve(LocalDateTime(date, time), o.zone).utc;
    // Nothing missing after the last instance up to the horizon end…
    final next = at(sequence.last.$2.date.plusDays(match.stepDays));
    if (!next.isAfter(o.horizonEnd)) return false;
    // …and on iOS nothing missing before the first one either.
    if (o.honorsStartDate) return true;
    final previous = at(sequence.first.$2.date.minusDays(match.stepDays));
    return !previous.isAfter(o.now);
  }

  static DesiredItem _sequenceItem(
    List<(PlannedNotification, LocalDateTime)> sequence,
    RepeatMatch match,
    RepeatingOptions o,
  ) {
    final first = sequence.first.$1;
    final local = sequence.first.$2;
    final identity = [
      first.ruleId,
      first.targetKey,
      match.wire,
      local.time.toString(),
      if (match == RepeatMatch.weekly) local.date.weekday.name,
    ].join('|');
    // Starting later than the next match (Android only) must re-arm the trigger.
    final previous = o.zones
        .resolve(
          LocalDateTime(local.date.minusDays(match.stepDays), local.time),
          o.zone,
        )
        .utc;
    final start = previous.isAfter(o.now)
        ? first.fireAt.toIso8601String()
        : 'next';
    return DesiredItem(
      key:
          'rpt:${sha1.convert(utf8.encode(identity)).toString().substring(0, 32)}',
      fireAt: first.fireAt,
      kind: ScheduleKind.repeating,
      os: true,
      targetKey: first.targetKey,
      hash: _hash([identity, _shape(first), o.zone, start]),
      planned: first,
      members: [for (final e in sequence) e.$1],
      repeat: match,
    );
  }

  static String _hash(List<String> parts) =>
      sha1.convert(utf8.encode(parts.join('|'))).toString().substring(0, 16);

  /// Diff between the stored schedule and the desired items. Past rows are kept (they await
  /// inbox reconciliation); snooze and test rows are never touched by replans.
  static ScheduleDiff diff(
    List<ScheduleEntry> current,
    List<DesiredItem> desired,
    DateTime now,
  ) {
    final managed = {
      for (final e in current)
        if (e.kind != ScheduleKind.snooze && e.kind != ScheduleKind.test)
          e.dedupeKey: e,
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
      // Fired one-shots stay for reconciliation / cleanup; a repeating trigger keeps firing
      // until cancelled.
      if (!e.fireAt.isAfter(now) && e.kind != ScheduleKind.repeating) continue;
      if (e.os) {
        cancel.add(e);
      } else {
        remove.add(e);
      }
    }
    return ScheduleDiff(
      cancel: cancel,
      upsert: upsert,
      remove: remove,
      unchanged: unchanged,
    );
  }

  /// `devices.local_coverage_until`: fire time of the last OS-scheduled one-shot, or the horizon
  /// end when everything fit (T7.2.11).
  static DateTime? coverageUntil(
    List<DesiredItem> desired, {
    required DateTime horizonEnd,
  }) {
    final saturated =
        desired.any((d) => d.kind == ScheduleKind.sentinel) ||
        desired.any(
          (d) =>
              !d.os &&
              d.kind == ScheduleKind.tracked &&
              d.planned?.deliverSystem == true &&
              _isOverflow(d, desired),
        );
    final osTimes = [
      for (final d in desired)
        if (d.os && d.kind != ScheduleKind.sentinel) d.fireAt,
    ];
    if (!saturated) return horizonEnd;
    if (osTimes.isEmpty) return null;
    osTimes.sort();
    final sentinel = desired
        .where((d) => d.kind == ScheduleKind.sentinel)
        .map((d) => d.fireAt);
    return sentinel.isNotEmpty ? sentinel.first : osTimes.last;
  }

  static bool _isOverflow(DesiredItem tracked, List<DesiredItem> all) {
    // A tracked system notification that is not part of a merged group = over budget.
    final key = tracked.key;
    return !all.any(
      (d) =>
          (d.kind == ScheduleKind.merged || d.kind == ScheduleKind.repeating) &&
          d.members.any((m) => m.dedupeKey == key),
    );
  }

  /// Importance helper for sorting in UIs.
  static int importanceRank(String? wire) =>
      (NotificationImportance.tryParse(wire) ?? NotificationImportance.normal)
          .rank;
}
