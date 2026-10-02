/// TARGET CONTRACT between feature sections (planner, checklists, habits, quit…) and the
/// notification system (arch §6.13, T7.2.06 "NotifiableTarget").
///
/// A feature makes its items notifiable by implementing [NotificationTargetSource] and
/// registering it (see `features/notifications/README.md`). Pure Dart — no Flutter imports.
library;

import 'dart:async';

import 'package:everslot/features/notifications/domain/json_fields.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:meta/meta.dart';

export 'package:everslot/features/notifications/domain/notification_types.dart';

/// Guard descriptor re-checked before delivery (device) and at dispatch (server SQL,
/// `private.notification_guards_ok`). Shared vocabulary — ids and statuses only (T7.4.05).
@immutable
class NotificationGuard {
  const NotificationGuard(this.kind, [this.params = const {}]);

  factory NotificationGuard.fromJson(Map<String, Object?> json) =>
      NotificationGuard(asString(json['kind']) ?? 'always', asJsonMap(json['params']) ?? const {});

  static const always = NotificationGuard('always');

  static NotificationGuard taskOccurrenceOpen(String taskId, String? occurrenceKey) =>
      NotificationGuard('task_occurrence_open', {'taskId': taskId, 'occurrenceKey': ?occurrenceKey});

  static NotificationGuard habitPeriodOpen(
    String habitId,
    String occurrenceKey, {
    String? goalType,
    num? target,
    String? op,
  }) => NotificationGuard('habit_period_open', {
    'habitId': habitId,
    'occurrenceKey': occurrenceKey,
    'goalType': ?goalType,
    'target': ?target,
    'op': ?op,
  });

  static NotificationGuard checklistItemStatusIn(String itemId, List<String> statuses) =>
      NotificationGuard('checklist_item_status_in', {'itemId': itemId, 'statuses': statuses});

  static NotificationGuard itemNotCompleted(String itemId) =>
      NotificationGuard('item_not_completed', {'itemId': itemId});

  static NotificationGuard quitNoRelapseSince(String habitId, DateTime since) =>
      NotificationGuard('quit_no_relapse_since', {'habitId': habitId, 'since': since.toUtc().toIso8601String()});

  static NotificationGuard inboxNotActed(String dedupeKey) =>
      NotificationGuard('inbox_not_acted', {'dedupeKey': dedupeKey});

  /// task_occurrence_open | habit_period_open | checklist_item_status_in | item_not_completed |
  /// quit_no_relapse_since | inbox_not_acted | always
  final String kind;
  final Map<String, Object?> params;

  Map<String, Object?> toJson() => {'kind': kind, if (params.isNotEmpty) 'params': params};

  /// Server format (`private.notification_guards_ok`, supabase/README.md): flat objects
  /// `{"kind": …, "<param>": …}`; an array means "all must pass". Nag chains carry the
  /// `inboxNotActed` marker → `[targetGuard, {"kind": "inbox_not_acted", "dedupeKey": …}]`.
  Object toServerJson() {
    final ack = params['inboxNotActed'];
    final flat = <String, Object?>{
      'kind': kind,
      for (final e in params.entries)
        if (e.key != 'inboxNotActed') e.key: e.value,
    };
    if (ack is! String) return flat;
    return [
      if (kind != 'always') flat,
      {'kind': 'inbox_not_acted', 'dedupeKey': ack},
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationGuard && other.kind == kind && jsonEquals(other.params, params);

  @override
  int get hashCode => Object.hash(kind, jsonHash(params));

  @override
  String toString() => 'Guard($kind)';
}

/// A projected milestone instant (quit clean time, money saved, streak/total thresholds…).
/// Sources project them because only they know the economics; the planner can also project
/// `clean_days` itself from [NotificationTarget.milestoneBaseline].
@immutable
class NotificationMilestone {
  const NotificationMilestone({
    required this.metric,
    required this.threshold,
    required this.at,
    this.label,
    this.runKey,
  });

  /// clean_days | streak | total_value | money_saved | units_avoided | health | custom
  final String metric;
  final num threshold;

  /// Instant the threshold is (or will be) crossed.
  final DateTime at;

  /// Optional localized label ("24 hours smoke-free").
  final String? label;

  /// Distinguishes repeated crossings of the same threshold (a new streak reaching 7 days again):
  /// part of the occurrence key; null for one-time thresholds.
  final String? runKey;

  @override
  bool operator ==(Object other) =>
      other is NotificationMilestone &&
      other.metric == metric &&
      other.threshold == threshold &&
      other.at == at &&
      other.label == label &&
      other.runKey == runKey;

  @override
  int get hashCode => Object.hash(metric, threshold, at, label, runKey);
}

/// An observed event for event-driven triggers (status_change, children_complete, child_overdue).
@immutable
class NotificationEvent {
  const NotificationEvent({required this.kind, required this.at, this.data = const {}});

  /// status_change (data: from, to) | children_complete | child_overdue (data: childId) | reset
  final String kind;
  final DateTime at;
  final Map<String, Object?> data;

  @override
  bool operator ==(Object other) =>
      other is NotificationEvent && other.kind == kind && other.at == at && jsonEquals(other.data, data);

  @override
  int get hashCode => Object.hash(kind, at, jsonHash(data));
}

/// Quota habit progress in the current period (quota_behind).
@immutable
class QuotaProgress {
  const QuotaProgress({required this.done, required this.target, required this.eligibleDaysLeft});

  final int done;
  final int target;

  /// Eligible days left in the period including today.
  final int eligibleDaysLeft;

  int get remaining => (target - done).clamp(0, target);
  bool get behind => remaining > 0 && remaining >= eligibleDaysLeft;

  @override
  bool operator ==(Object other) =>
      other is QuotaProgress &&
      other.done == done &&
      other.target == target &&
      other.eligibleDaysLeft == eligibleDaysLeft;

  @override
  int get hashCode => Object.hash(done, target, eligibleDaysLeft);
}

/// One notifiable thing **for one occurrence** (or the item itself when it doesn't recur,
/// [occurrenceKey] == null). A recurring task yields one target per occurrence (same [id]).
///
/// Anchors are UTC instants of *this occurrence*; the planner applies rules to them:
/// `start/end` (tasks), `due` (items, checklists), `followUp` (waiting/blocked items),
/// `slot` (habit intraday slot), `periodStart/periodEnd` (habit period).
@immutable
class NotificationTarget {
  const NotificationTarget({
    required this.type,
    required this.id,
    required this.section,
    required this.title,
    this.occurrenceKey,
    this.categoryId,
    this.checklistId,
    this.parentItemId,
    this.ancestorItemIds = const [],
    this.notifyMode = NotifyMode.inherit,
    this.itemKind = ItemKind.timed,
    this.timeZone,
    this.start,
    this.end,
    this.due,
    this.followUp,
    this.slot,
    this.periodStart,
    this.periodEnd,
    this.status,
    this.statusChangedAt,
    this.lastActivityAt,
    this.isOpen = true,
    this.guard,
    this.variables = const {},
    this.deepLink,
    this.defaultActions,
    this.streak,
    this.quota,
    this.milestoneBaseline,
    this.milestones = const [],
    this.events = const [],
  });

  final NotificationTargetType type;

  /// Entity id (task id, item id, habit id…). For digests: the digest kind.
  final String id;
  final NotificationSection section;

  /// Display title (task title, item text, habit name…).
  final String title;

  /// Occurrence identity (`YYYY-MM-DDTHH:mm` for tasks, period key for habits), null for
  /// non-recurring items.
  final String? occurrenceKey;
  final String? categoryId;

  /// Checklist containing an item (checklist-level rules with `scope.appliesTo = items`).
  final String? checklistId;

  /// Direct parent item (nested checklist items).
  final String? parentItemId;

  /// All ancestor items, nearest first (defaults inherit down nested lists). When empty and
  /// [parentItemId] is set, the resolver uses `[parentItemId]`.
  final List<String> ancestorItemIds;
  final NotifyMode notifyMode;
  final ItemKind itemKind;

  /// IANA zone of the item, or null = floating (device zone).
  final String? timeZone;

  final DateTime? start;
  final DateTime? end;
  final DateTime? due;
  final DateTime? followUp;
  final DateTime? slot;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  /// Current status (`scheduled`, `in_progress`, `waiting`, `blocked`, …) for
  /// `conditions.onlyIfStatusIn` and `status_age`.
  final String? status;
  final DateTime? statusChangedAt;
  final DateTime? lastActivityAt;

  /// Guard currently satisfied (occurrence still open, habit period not done…). Closed targets
  /// produce nothing (they may still be returned so replans cancel their reminders).
  final bool isOpen;

  /// Guard re-checked at delivery / dispatch (default: `always`).
  final NotificationGuard? guard;

  /// Extra template variables (`category`, `notes_excerpt`, `checklist_title`, `progress`,
  /// `streak`, `money_saved`, …). Values: String, num, DateTime (UTC).
  final Map<String, Object?> variables;

  /// Router path opened on tap (AppLinks); default derived from the type.
  final String? deepLink;

  /// Actions used when neither rule nor profile sets any (e.g. `['done','snooze','skip']`).
  final List<String>? defaultActions;

  /// Current streak (streak_risk).
  final int? streak;
  final QuotaProgress? quota;

  /// Clean-time baseline (quit trackers): milestones are projected from it.
  final DateTime? milestoneBaseline;
  final List<NotificationMilestone> milestones;
  final List<NotificationEvent> events;

  /// Replacement unit for server jobs and dirty tracking: `task:<id>`.
  String get targetKey => '${type.wire}:$id';

  /// Nearest-first ancestors used for inheritance.
  List<String> get ancestors =>
      ancestorItemIds.isNotEmpty ? ancestorItemIds : (parentItemId == null ? const [] : [parentItemId!]);

  NotificationTarget copyWith({
    String? title,
    String? occurrenceKey,
    NotifyMode? notifyMode,
    DateTime? start,
    DateTime? end,
    DateTime? due,
    DateTime? followUp,
    String? status,
    bool? isOpen,
    Map<String, Object?>? variables,
    List<NotificationEvent>? events,
  }) => NotificationTarget(
    type: type,
    id: id,
    section: section,
    title: title ?? this.title,
    occurrenceKey: occurrenceKey ?? this.occurrenceKey,
    categoryId: categoryId,
    checklistId: checklistId,
    parentItemId: parentItemId,
    ancestorItemIds: ancestorItemIds,
    notifyMode: notifyMode ?? this.notifyMode,
    itemKind: itemKind,
    timeZone: timeZone,
    start: start ?? this.start,
    end: end ?? this.end,
    due: due ?? this.due,
    followUp: followUp ?? this.followUp,
    slot: slot,
    periodStart: periodStart,
    periodEnd: periodEnd,
    status: status ?? this.status,
    statusChangedAt: statusChangedAt,
    lastActivityAt: lastActivityAt,
    isOpen: isOpen ?? this.isOpen,
    guard: guard,
    variables: variables ?? this.variables,
    deepLink: deepLink,
    defaultActions: defaultActions,
    streak: streak,
    quota: quota,
    milestoneBaseline: milestoneBaseline,
    milestones: milestones,
    events: events ?? this.events,
  );

  @override
  bool operator ==(Object other) =>
      other is NotificationTarget &&
      other.type == type &&
      other.id == id &&
      other.occurrenceKey == occurrenceKey &&
      other.section == section &&
      other.title == title &&
      other.notifyMode == notifyMode &&
      other.start == start &&
      other.end == end &&
      other.due == due &&
      other.followUp == followUp &&
      other.slot == slot &&
      other.periodStart == periodStart &&
      other.periodEnd == periodEnd &&
      other.status == status &&
      other.isOpen == isOpen &&
      jsonEquals(other.variables, variables);

  @override
  int get hashCode => Object.hash(type, id, occurrenceKey, section, title, notifyMode, start, end, due, status, isOpen);

  @override
  String toString() => 'NotificationTarget($targetKey${occurrenceKey == null ? '' : '@$occurrenceKey'})';
}

/// Implemented by each feature section and registered with the notification system.
abstract interface class NotificationTargetSource {
  /// Section wire value this source feeds (`planner`, `checklists`, `habits`, `quit`, …).
  String get section;

  /// Every target that may fire in `[fromUtc, toUtc]`: occurrences whose anchors fall in the
  /// range **plus** open non-recurring targets (their absolute/schedule/status triggers are
  /// evaluated by the planner). Closed targets may be omitted.
  Future<List<NotificationTarget>> targetsBetween(DateTime fromUtc, DateTime toUtc);

  /// Emits when this source's data changed (the replan orchestrator debounces it).
  Stream<void> get changes;

  /// Re-checks the guard of [t] right before delivery (foreground ticker, action handler,
  /// push handler). Return false when the reminder is obsolete (done, deleted, paused…).
  Future<bool> guardOpen(NotificationTarget t);
}

/// Optional extra of a [NotificationTargetSource]: counts that digests show but no target carries
/// (T7.5.18), e.g. `backlog` = unscheduled tasks in *Plan tomorrow*.
abstract interface class DigestFactsSource {
  Future<Map<String, int>> digestFacts();
}

/// Optional extra of a [NotificationTargetSource]: when the user actually did things (habit
/// check-ins, task starts / completions) per target key (`habit:id`, `task:id`) — reminder
/// effectiveness (T7.5.17) and smart suggestions (T7.5.19).
abstract interface class TargetActivitySource {
  Future<Map<String, List<DateTime>>> activityBetween(DateTime fromUtc, DateTime toUtc);
}

/// In-memory source (tests, demos, debug menu): set [targets] and call [notifyChanged].
class InMemoryNotificationTargetSource implements NotificationTargetSource {
  InMemoryNotificationTargetSource({required this.section, List<NotificationTarget>? targets})
    : _targets = [...?targets];

  @override
  final String section;

  List<NotificationTarget> _targets;
  final _changes = StreamController<void>.broadcast();

  /// Targets closed by [close] (guard now false).
  final Set<String> closed = {};

  List<NotificationTarget> get targets => List.unmodifiable(_targets);

  set targets(List<NotificationTarget> value) {
    _targets = [...value];
    notifyChanged();
  }

  void add(NotificationTarget target) {
    _targets = [..._targets, target];
    notifyChanged();
  }

  /// Marks a target (by key and optional occurrence) as done.
  void close(String targetKey, [String? occurrenceKey]) {
    closed.add('$targetKey|${occurrenceKey ?? ''}');
    notifyChanged();
  }

  void notifyChanged() => _changes.add(null);

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<List<NotificationTarget>> targetsBetween(DateTime fromUtc, DateTime toUtc) async => [
    for (final t in _targets)
      if (_relevant(t, fromUtc, toUtc))
        closed.contains('${t.targetKey}|${t.occurrenceKey ?? ''}') ? t.copyWith(isOpen: false) : t,
  ];

  bool _relevant(NotificationTarget t, DateTime from, DateTime to) {
    final anchors = [t.start, t.end, t.due, t.followUp, t.slot, t.periodStart, t.periodEnd].whereType<DateTime>();
    if (anchors.isEmpty || t.occurrenceKey == null) return true;
    return anchors.any((a) => !a.isBefore(from) && !a.isAfter(to));
  }

  @override
  Future<bool> guardOpen(NotificationTarget t) async =>
      !closed.contains('${t.targetKey}|${t.occurrenceKey ?? ''}') && t.isOpen;

  Future<void> dispose() => _changes.close();
}
