/// Status-interval & event-log primitives (T6.1.11).
///
/// Turns an ordered status-event log into per-entity status intervals, time-in-status totals,
/// snapshots (`stateAt`) and day-end boundary counts: A(d) = items in scope (created and not
/// deleted by d), S(d) = items that first left `todo` by d, F(d) = items in `completed` at d.
///
/// - Events are sorted by `occurredAt`, with `rev` as the tie-breaker (out-of-order input is fine).
/// - An entity without a `created` event uses its row `created_at` ([EntitySeed]) as an implicit
///   first event; failing that, its first event.
/// - Deleted entities stop counting at `deleted_at` (and resume on `restored`); deletions are
///   exposed as "removed from scope" for burn-up.
/// - `moved` events (payload `fromChecklistId`/`toChecklistId`) split container membership: an item
///   counts in the source container until the move and in the target afterwards.
/// - Durations are measured between instants; day-end sampling instants come from
///   `DayBoundaries.endOf` in the user's zone.
library;

import 'package:meta/meta.dart';

/// Kinds of event consumed here.
enum StatusEventType { created, statusChanged, moved, deleted, restored }

/// One event: `(entityId, occurredAt, from, to, payload)`.
@immutable
final class const StatusEvent(
  final String entityId,
  final StatusEventType type, {
  required final DateTime occurredAt,
  final int rev = 0,
  final String? from,
  final String? to,
  final String? note,
  final String? fromContainerId,
  final String? toContainerId,
  final String? fromParentId,
  final String? toParentId,
  final String? cause,
});

/// Row facts used when the log is incomplete (row `created_at`, current container, deletion).
@immutable
final class const EntitySeed(
  final String entityId, {
  required final DateTime createdAt,
  final String? containerId,
  final DateTime? deletedAt,
  final String initialStatus = 'todo',
});

/// A status interval `[start, end)`; [end] null = still open.
@immutable
final class const StatusInterval(
  final String status,
  final DateTime start, {
  final DateTime? end,
  final String? note,
}) {
  Duration lengthUntil(DateTime now) => (end ?? now).difference(start);

  /// Overlap with `[from, to)`, open intervals ending at [now].
  Duration overlap(DateTime from, DateTime to, DateTime now) {
    final e0 = end ?? now;
    final s = start.isAfter(from) ? start : from;
    final e = e0.isBefore(to) ? e0 : to;
    return e.isAfter(s) ? e.difference(s) : Duration.zero;
  }
}

/// Membership of an entity in a container `[start, end)`.
@immutable
final class const MembershipInterval(
  final String containerId,
  final DateTime start, {
  final DateTime? end,
}) {
  bool containsInstant(DateTime t) =>
      !t.isBefore(start) && (end == null || t.isBefore(end!));
}

/// Existence interval `[start, end)` (between creation/restoration and deletion).
@immutable
final class const AliveInterval(final DateTime start, {final DateTime? end}) {
  bool containsInstant(DateTime t) =>
      !t.isBefore(start) && (end == null || t.isBefore(end!));
}

/// The reconstructed history of one entity.
@immutable
final class EntityTimeline {
  const new(
    this.entityId, {
    required this.createdAt,
    required this.intervals,
    required this.memberships,
    required this.alive,
    required this.statusEvents,
    required this.initialStatus,
    required this.lastEventAt,
  });

  final String entityId;
  final DateTime createdAt;

  /// Contiguous status intervals from creation; the status keeps running while deleted (use
  /// [alive] to clip).
  final List<StatusInterval> intervals;
  final List<MembershipInterval> memberships;
  final List<AliveInterval> alive;

  /// `statusChanged` events in order.
  final List<StatusEvent> statusEvents;
  final String initialStatus;
  final DateTime lastEventAt;

  /// Deletion instant (null when the entity is alive now).
  DateTime? get deletedAt => alive.isEmpty ? null : alive.last.end;

  /// The latest deletion strictly before [t] when the entity is not alive at [t].
  DateTime? deletedBefore(DateTime t) {
    DateTime? latest;
    for (final a in alive) {
      final end = a.end;
      if (end != null &&
          !end.isAfter(t) &&
          (latest == null || end.isAfter(latest))) {
        latest = end;
      }
    }
    return latest;
  }

  bool isAliveAt(DateTime t) => alive.any((a) => a.containsInstant(t));

  /// Current status (of the last interval).
  String get currentStatus => intervals.last.status;

  /// Status at [t] (events at exactly [t] are included when [inclusive]); null before creation.
  String? stateAt(DateTime t, {bool inclusive = true}) {
    if (t.isBefore(createdAt)) return null;
    String? status;
    for (final i in intervals) {
      final starts = inclusive ? !i.start.isAfter(t) : i.start.isBefore(t);
      if (starts) {
        status = i.status;
      } else {
        break;
      }
    }
    return status ?? initialStatus;
  }

  /// Container at [t] (null when unknown or before creation).
  String? containerAt(DateTime t) {
    for (final m in memberships) {
      if (m.containsInstant(t)) return m.containerId;
    }
    return null;
  }

  /// Σ time per status within the clip window `[from, to)` (defaults: creation … [now]), counting
  /// only while the entity is alive.
  Map<String, Duration> timeInStatus({
    required DateTime now,
    DateTime? from,
    DateTime? to,
  }) {
    final result = <String, Duration>{};
    final clipFrom = from ?? createdAt;
    final clipTo = to ?? now;
    for (final i in intervals) {
      for (final a in alive) {
        final s = _later(_later(i.start, a.start), clipFrom);
        final e = _earlier(_earlier(i.end ?? now, a.end ?? now), clipTo);
        if (e.isAfter(s)) {
          result[i.status] =
              (result[i.status] ?? Duration.zero) + e.difference(s);
        }
      }
    }
    return result;
  }

  /// First time the entity entered [status] (null if never).
  DateTime? firstEntry(String status) {
    for (final i in intervals) {
      if (i.status == status) return i.start;
    }
    return null;
  }

  /// Last time the entity left [status] (null if never left).
  DateTime? lastExit(String status) {
    DateTime? last;
    for (final i in intervals) {
      if (i.status == status && i.end != null) last = i.end;
    }
    return last;
  }

  /// First time the entity left [status] for any other status.
  DateTime? firstExit(String status) {
    for (final i in intervals) {
      if (i.status == status && i.end != null) return i.end;
    }
    return null;
  }

  /// Number of transitions from [doneStatus] to anything else (reopens).
  int reopenCount({String doneStatus = 'completed'}) => statusEvents
      .where((e) => e.from == doneStatus && e.to != doneStatus)
      .length;

  /// Number of status changes.
  int get statusChangeCount => statusEvents.length;

  /// Intervals spent in [status] (episodes), e.g. blocked/waiting episodes.
  List<StatusInterval> episodes(String status) => [
    for (final i in intervals)
      if (i.status == status) i,
  ];
}

DateTime _later(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
DateTime _earlier(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

int _compareEvents(StatusEvent a, StatusEvent b) {
  final c = a.occurredAt.compareTo(b.occurredAt);
  if (c != 0) return c;
  final r = a.rev.compareTo(b.rev);
  if (r != 0) return r;
  // Created first, then moves/status changes, deletions last within one instant and revision.
  return a.type.index.compareTo(b.type.index);
}

/// Builds one timeline per entity from [events] (any order) and optional [seeds].
Map<String, EntityTimeline> buildTimelines(
  Iterable<StatusEvent> events, {
  Iterable<EntitySeed> seeds = const [],
  String defaultInitialStatus = 'todo',
}) {
  final byEntity = <String, List<StatusEvent>>{};
  for (final e in events) {
    byEntity.putIfAbsent(e.entityId, () => []).add(e);
  }
  final seedById = {for (final s in seeds) s.entityId: s};
  for (final id in seedById.keys) {
    byEntity.putIfAbsent(id, () => []);
  }
  final result = <String, EntityTimeline>{};
  for (final entry in byEntity.entries) {
    final seed = seedById[entry.key];
    final list = [...entry.value]..sort(_compareEvents);
    final createdEvent = list
        .where((e) => e.type == StatusEventType.created)
        .firstOrNull;
    final createdAt =
        createdEvent?.occurredAt ?? seed?.createdAt ?? list.first.occurredAt;
    final initialStatus =
        createdEvent?.to ?? seed?.initialStatus ?? defaultInitialStatus;
    var status = initialStatus;
    var statusStart = createdAt;
    var statusNote = createdEvent?.note;
    final intervals = <StatusInterval>[];
    final statusEvents = <StatusEvent>[];
    final memberships = <MembershipInterval>[];
    final alive = <AliveInterval>[];
    // Initial container: created payload, else the first move's source, else the seed.
    final firstMove = list
        .where((e) => e.type == StatusEventType.moved)
        .firstOrNull;
    var container =
        createdEvent?.toContainerId ??
        firstMove?.fromContainerId ??
        seed?.containerId;
    var containerStart = createdAt;
    DateTime? aliveStart = createdAt;
    var lastEventAt = createdAt;
    for (final e in list) {
      if (e.occurredAt.isAfter(lastEventAt)) lastEventAt = e.occurredAt;
      switch (e.type) {
        case StatusEventType.created:
          break;
        case StatusEventType.statusChanged:
          final to = e.to;
          if (to == null) break;
          statusEvents.add(e);
          final at = _later(e.occurredAt, createdAt);
          // Zero-length statuses (several changes at one instant) leave no interval.
          if (at.isAfter(statusStart)) {
            intervals.add(
              StatusInterval(status, statusStart, end: at, note: statusNote),
            );
          }
          status = to;
          statusStart = at;
          statusNote = e.note;
        case StatusEventType.moved:
          final to = e.toContainerId;
          if (container != null && e.occurredAt.isAfter(containerStart)) {
            memberships.add(
              MembershipInterval(container, containerStart, end: e.occurredAt),
            );
          }
          container = to;
          containerStart = e.occurredAt;
        case StatusEventType.deleted:
          if (aliveStart != null) {
            alive.add(AliveInterval(aliveStart, end: e.occurredAt));
            aliveStart = null;
          }
        case StatusEventType.restored:
          aliveStart ??= e.occurredAt;
      }
    }
    intervals.add(StatusInterval(status, statusStart, note: statusNote));
    if (container != null) {
      memberships.add(MembershipInterval(container, containerStart));
    }
    if (aliveStart != null) {
      final seedDeleted = seed?.deletedAt;
      alive.add(
        AliveInterval(
          aliveStart,
          end: seedDeleted != null && !seedDeleted.isBefore(aliveStart)
              ? seedDeleted
              : null,
        ),
      );
    }
    result[entry.key] = EntityTimeline(
      entry.key,
      createdAt: createdAt,
      intervals: intervals,
      memberships: memberships,
      alive: alive,
      statusEvents: statusEvents,
      initialStatus: initialStatus,
      lastEventAt: lastEventAt,
    );
  }
  return result;
}

/// Day-end boundary counts for one sampling instant.
@immutable
final class const BoundaryCounts(
  final DateTime at, {
  required final int arrived,
  required final int started,
  required final int finished,
  required final int cancelled,
  required final int removed,
  required final Map<String, int> byStatus,
}) {
  /// In progress = arrived − todo − finished − cancelled (WIP).
  int wip({
    Set<String> wipStatuses = const {'ongoing', 'waiting', 'blocked'},
  }) => byStatus.entries
      .where((e) => wipStatuses.contains(e.key))
      .fold(0, (acc, e) => acc + e.value);
}

/// Samples boundary counts at each instant of [sampleAt] (typically local day ends). Events at
/// exactly the sampling instant belong to the next day (they are excluded).
///
/// When [containerId] is given only items that are members of that container at the sampling
/// instant count (moved-in items arrive on the move day).
List<BoundaryCounts> boundaryCounts(
  Iterable<EntityTimeline> timelines,
  List<DateTime> sampleAt, {
  String? containerId,
  String todoStatus = 'todo',
  String doneStatus = 'completed',
  String cancelledStatus = 'cancelled',
}) {
  final list = timelines.toList();
  return [
    for (final t in sampleAt)
      () {
        var arrived = 0;
        var started = 0;
        var finished = 0;
        var cancelled = 0;
        var removed = 0;
        final byStatus = <String, int>{};
        final probe = t.subtract(const Duration(microseconds: 1));
        for (final e in list) {
          if (!e.createdAt.isBefore(t)) continue;
          if (!e.isAliveAt(probe)) {
            final deleted = e.deletedBefore(probe);
            if (deleted != null) {
              final before = deleted.subtract(const Duration(microseconds: 1));
              if (containerId == null || e.containerAt(before) == containerId) {
                removed++;
              }
            }
            continue;
          }
          if (containerId != null && e.containerAt(probe) != containerId)
            continue;
          arrived++;
          final state = e.stateAt(probe) ?? e.initialStatus;
          byStatus[state] = (byStatus[state] ?? 0) + 1;
          final left = e.firstExit(todoStatus);
          if (e.initialStatus != todoStatus ||
              (left != null && left.isBefore(t))) {
            started++;
          }
          if (state == doneStatus) finished++;
          if (state == cancelledStatus) cancelled++;
        }
        return BoundaryCounts(
          t,
          arrived: arrived,
          started: started,
          finished: finished,
          cancelled: cancelled,
          removed: removed,
          byStatus: byStatus,
        );
      }(),
  ];
}
