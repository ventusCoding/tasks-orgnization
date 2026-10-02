/// Isolate-sendable inputs of a stats batch (T6.1.12, T6.1.13). Pure Dart.
///
/// The data layer maps Drift rows into these compact records (never Drift row classes); the stats
/// isolate turns them into the `everslot_metrics` facts (resolution, period evaluation) and runs the
/// metric catalog. Wall-clock values stay wall clock (`LocalDateTime`, `LocalDate`) and are resolved
/// in the isolate with the zone snapshot of [StatsEnvironment].
library;

import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_settings.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show HabitPause, PlannerOccurrenceStatus, TrackingMode;
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate, LocalDateTime, Weekday;
import 'package:meta/meta.dart';
import 'package:timezone/timezone.dart' as tz;

// ---------------------------------------------------------------------------------------------
// Environment
// ---------------------------------------------------------------------------------------------

/// Everything a batch needs besides the rows: the clock, the user's zone and preferences.
@immutable
final class StatsEnvironment {
  const StatsEnvironment({
    required this.now,
    required this.zoneId,
    required this.zones,
    this.weekStart = Weekday.monday,
    this.dayStartMinutes = 0,
    this.settings = const StatsSettings(),
    this.currency = 'EUR',
  });

  /// Current instant (UTC), from the injected clock.
  final DateTime now;

  /// The user's current zone (floating values and day boundaries).
  final String zoneId;

  /// Snapshot of every zone the batch may resolve (sendable, no tz database in the isolate).
  final Map<String, tz.Location> zones;
  final Weekday weekStart;

  /// Habit "day starts at" in minutes after midnight (arch §9.1).
  final int dayStartMinutes;
  final StatsSettings settings;
  final String currency;
}

// ---------------------------------------------------------------------------------------------
// Shared organization records
// ---------------------------------------------------------------------------------------------

/// A `categories` row.
@immutable
final class CategoryInfo {
  const CategoryInfo(this.id, this.name, {required this.color, this.unavailable = false, this.archived = false});

  final String id;
  final String name;
  final int color;

  /// `counts_as_unavailable` (Sleep/Time off): excluded from capacity.
  final bool unavailable;
  final bool archived;
}

/// A `tags` row.
@immutable
final class TagInfo {
  const TagInfo(this.id, this.name, {this.color});

  final String id;
  final String name;
  final int? color;
}

/// An `entity_tags` row.
@immutable
final class TagLink {
  const TagLink(this.tagId, this.entityType, this.entityId);

  final String tagId;
  final String entityType;
  final String entityId;
}

/// An `activity_events` row with its decoded payload.
@immutable
final class ActivityRecord {
  const ActivityRecord({
    required this.entityType,
    required this.entityId,
    required this.eventType,
    required this.occurredAt,
    this.parentId,
    this.payload = const {},
    this.rev = 0,
  });

  final String entityType;
  final String entityId;
  final String? parentId;
  final String eventType;
  final Map<String, Object?> payload;
  final DateTime occurredAt;
  final int rev;

  String? payloadString(String key) {
    final v = payload[key];
    return v is String ? v : null;
  }

  int? payloadInt(String key) {
    final v = payload[key];
    return v is num ? v.toInt() : null;
  }
}

/// A `goals` row ([5.4]).
@immutable
final class GoalRecord {
  const GoalRecord({
    required this.id,
    required this.scopeType,
    required this.metric,
    required this.target,
    required this.period,
    this.scopeId,
    this.startDate,
    this.endDate,
    this.title,
    this.achievedAt,
    this.createdAt,
  });

  final String id;
  final String scopeType;
  final String? scopeId;
  final String metric;
  final double target;
  final String period;
  final LocalDate? startDate;
  final LocalDate? endDate;
  final String? title;
  final DateTime? achievedAt;
  final DateTime? createdAt;
}

// ---------------------------------------------------------------------------------------------
// Planner
// ---------------------------------------------------------------------------------------------

/// A `tasks` row (the columns stats need).
@immutable
final class TaskRecord {
  const TaskRecord({
    required this.id,
    required this.seriesId,
    required this.title,
    required this.createdAt,
    this.categoryId,
    this.color,
    this.priority = 0,
    this.trackingMode = TrackingMode.check,
    this.isAllDay = false,
    this.startLocal,
    this.durationMinutes,
    this.timeZone,
    this.recurrence,
    this.status = 'active',
    this.linkedChecklistId,
    this.icon,
  });

  final String id;
  final String seriesId;
  final String title;
  final DateTime createdAt;
  final String? categoryId;
  final int? color;
  final int priority;
  final TrackingMode trackingMode;
  final bool isAllDay;

  /// Null = unscheduled (backlog).
  final LocalDateTime? startLocal;
  final int? durationMinutes;

  /// IANA zone, or null = floating.
  final String? timeZone;

  /// Recurrence JSON (arch §8.1); null = one-off.
  final String? recurrence;

  /// active | paused | archived
  final String status;
  final String? linkedChecklistId;
  final String? icon;

  bool get isRecurring => recurrence != null;

  bool get isUnscheduled => startLocal == null;

  /// Key of a one-off task's single occurrence (`YYYY-MM-DDTHH:mm`, all-day `YYYY-MM-DD`).
  String? get oneOffKey {
    final s = startLocal;
    if (s == null) return null;
    return isAllDay ? s.date.toIso() : s.toIso();
  }
}

/// A `task_occurrences` row (touched occurrences only).
@immutable
final class OccurrenceRecord {
  const OccurrenceRecord({
    required this.taskId,
    required this.key,
    this.overrideStartLocal,
    this.overrideDurationMinutes,
    this.overrideTitle,
    this.isCancelled = false,
    this.status = PlannerOccurrenceStatus.scheduled,
    this.statusChangedAt,
    this.completedAt,
    this.actualStartAt,
    this.actualEndAt,
    this.trackedSeconds,
    this.completionPercent,
    this.skipReason,
    this.rating,
    this.outcomeNote,
  });

  final String taskId;
  final String key;
  final LocalDateTime? overrideStartLocal;
  final int? overrideDurationMinutes;
  final String? overrideTitle;
  final bool isCancelled;
  final PlannerOccurrenceStatus status;
  final DateTime? statusChangedAt;
  final DateTime? completedAt;
  final DateTime? actualStartAt;
  final DateTime? actualEndAt;
  final int? trackedSeconds;
  final int? completionPercent;
  final String? skipReason;
  final int? rating;
  final String? outcomeNote;

  bool get cancelled => isCancelled || status == PlannerOccurrenceStatus.cancelled;
}

/// A `time_entries` row (open entries are clipped at "now" by the resolver).
@immutable
final class TimeEntryRecord {
  const TimeEntryRecord({required this.taskId, required this.startedAt, this.occurrenceKey, this.endedAt});

  final String taskId;
  final String? occurrenceKey;
  final DateTime startedAt;
  final DateTime? endedAt;
}

/// Planner rows of a batch.
@immutable
final class PlannerInput {
  const PlannerInput({
    this.tasks = const [],
    this.occurrences = const [],
    this.timeEntries = const [],
    this.events = const [],
    this.categories = const [],
    this.tags = const [],
    this.tagLinks = const [],
    this.goals = const [],
    this.from,
    this.to,
  });

  final List<TaskRecord> tasks;
  final List<OccurrenceRecord> occurrences;
  final List<TimeEntryRecord> timeEntries;

  /// Task activity events (`rescheduled`, `created`, `completed`, `reopened`…).
  final List<ActivityRecord> events;
  final List<CategoryInfo> categories;
  final List<TagInfo> tags;
  final List<TagLink> tagLinks;
  final List<GoalRecord> goals;

  /// Local date window the resolver should cover (inclusive); null = the batch decides.
  final LocalDate? from;
  final LocalDate? to;
}

// ---------------------------------------------------------------------------------------------
// Checklists
// ---------------------------------------------------------------------------------------------

/// A `checklists` row.
@immutable
final class ChecklistRecord {
  const ChecklistRecord({
    required this.id,
    required this.title,
    required this.createdAt,
    this.color,
    this.categoryId,
    this.archivedAt,
    this.deletedAt,
    this.isTemplate = false,
    this.dueLocal,
    this.timeZone,
    this.isResettable = false,
    this.requireReasonFor = const {},
    this.staleAfterDays,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final int? color;
  final String? categoryId;
  final DateTime? archivedAt;
  final DateTime? deletedAt;
  final bool isTemplate;
  final LocalDateTime? dueLocal;
  final String? timeZone;

  /// Has a reset rule (recurring routine, T6.4.11).
  final bool isResettable;

  /// `settings.requireReasonFor` statuses (integrity flags, CL-L-17).
  final Set<String> requireReasonFor;

  /// `settings.staleAfterDays` override.
  final int? staleAfterDays;
}

/// A `checklist_items` row.
@immutable
final class ItemRecord {
  const ItemRecord({
    required this.id,
    required this.checklistId,
    required this.status,
    required this.createdAt,
    this.parentId,
    this.text = '',
    this.statusNote,
    this.completedAt,
    this.deletedAt,
    this.dueLocal,
    this.timeZone,
    this.followUpAt,
    this.waitingOn,
    this.updatedAt,
  });

  final String id;
  final String checklistId;
  final String? parentId;
  final String text;
  final String status;
  final String? statusNote;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? deletedAt;
  final LocalDateTime? dueLocal;
  final String? timeZone;
  final DateTime? followUpAt;
  final String? waitingOn;

  /// Last edit instant (edit activity for staleness).
  final DateTime? updatedAt;
}

/// A `checklist_runs` row.
@immutable
final class RunRecord {
  const RunRecord({
    required this.checklistId,
    required this.key,
    required this.startedAt,
    this.endedAt,
    this.totalItems,
    this.completedItems,
    this.snapshot = const [],
  });

  final String checklistId;
  final String key;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? totalItems;
  final int? completedItems;

  /// `[{itemId, status, completedAt}]` decoded.
  final List<({String itemId, String status, DateTime? completedAt})> snapshot;
}

/// An `attachments` aggregate row.
@immutable
final class AttachmentRecord {
  const AttachmentRecord({
    required this.ownerType,
    required this.ownerId,
    required this.mimeType,
    required this.byteSize,
  });

  final String ownerType;
  final String ownerId;
  final String mimeType;
  final int byteSize;
}

/// Checklist rows of a batch.
@immutable
final class ChecklistInput {
  const ChecklistInput({
    this.checklists = const [],
    this.items = const [],
    this.events = const [],
    this.runs = const [],
    this.attachments = const [],
    this.categories = const [],
    this.tagLinks = const [],
  });

  final List<ChecklistRecord> checklists;
  final List<ItemRecord> items;

  /// `checklist_item` activity events.
  final List<ActivityRecord> events;
  final List<RunRecord> runs;
  final List<AttachmentRecord> attachments;
  final List<CategoryInfo> categories;
  final List<TagLink> tagLinks;
}

// ---------------------------------------------------------------------------------------------
// Habits & quit
// ---------------------------------------------------------------------------------------------

/// A `habits` row (build habits and quit trackers).
@immutable
final class HabitRecord {
  const HabitRecord({
    required this.id,
    required this.kind,
    required this.name,
    required this.startDate,
    required this.createdAt,
    this.icon,
    this.color,
    this.categoryId,
    this.goalType = 'check',
    this.targetValue,
    this.targetOp = 'gte',
    this.unit,
    this.schedule,
    this.endDate,
    this.timeZone,
    this.skipPolicy = 'neutral',
    this.freezesPerMonth = 0,
    this.quitMode,
    this.quitSubstance,
    this.quitStartedAt,
    this.dailyLimit,
    this.baselinePerDay,
    this.unitCost,
    this.currency,
    this.timePerUnitMinutes,
    this.lifeMinutesPerUnit,
    this.autoSuccess = true,
    this.requireExplicitLog = false,
    this.slotMinDone,
    this.earlyToleranceMinutes = 30,
    this.archivedAt,
  });

  final String id;

  /// build | quit
  final String kind;
  final String name;
  final String? icon;
  final int? color;
  final String? categoryId;
  final String goalType;
  final double? targetValue;
  final String targetOp;
  final String? unit;

  /// Schedule JSON (arch §8.1); null for quit trackers.
  final String? schedule;
  final LocalDate startDate;
  final LocalDate? endDate;
  final String? timeZone;
  final String skipPolicy;
  final int freezesPerMonth;
  final String? quitMode;
  final String? quitSubstance;
  final DateTime? quitStartedAt;
  final double? dailyLimit;
  final double? baselinePerDay;
  final double? unitCost;
  final String? currency;
  final double? timePerUnitMinutes;
  final double? lifeMinutesPerUnit;
  final bool autoSuccess;

  /// `settings.requireExplicitLog`.
  final bool requireExplicitLog;

  /// `settings.slotRollup.minSlots` (null = all slots).
  final int? slotMinDone;

  /// `settings.earlyToleranceMinutes` (keyless slot logs).
  final int earlyToleranceMinutes;
  final DateTime createdAt;
  final DateTime? archivedAt;

  bool get isQuit => kind == 'quit';
}

/// A `habit_logs` row.
@immutable
final class HabitLogRecord {
  const HabitLogRecord({
    required this.id,
    required this.habitId,
    required this.kind,
    required this.loggedAt,
    required this.localDate,
    this.occurrenceKey,
    this.value,
    this.mood,
    this.intensity,
    this.resisted,
    this.trigger,
    this.place,
    this.coping,
    this.durationSeconds,
    this.note,
    this.source = 'manual',
    this.createdAt,
  });

  final String id;
  final String habitId;
  final String? occurrenceKey;

  /// `habit_logs.kind` (done | fail | progress | skip | excuse | clean | relapse | craving | …).
  final String kind;
  final double? value;
  final DateTime loggedAt;
  final LocalDate localDate;
  final int? mood;
  final int? intensity;
  final bool? resisted;
  final String? trigger;
  final String? place;
  final String? coping;
  final int? durationSeconds;
  final String? note;
  final String source;
  final DateTime? createdAt;
}

/// A `habit_revisions` row.
@immutable
final class RevisionRecord {
  const RevisionRecord({
    required this.id,
    required this.habitId,
    required this.effectiveFrom,
    this.schedule,
    this.goalType,
    this.targetValue,
    this.targetOp,
    this.unit,
    this.baselinePerDay,
    this.unitCost,
    this.dailyLimit,
  });

  final String id;
  final String habitId;
  final LocalDate effectiveFrom;
  final String? schedule;
  final String? goalType;
  final double? targetValue;
  final String? targetOp;
  final String? unit;
  final double? baselinePerDay;
  final double? unitCost;
  final double? dailyLimit;
}

/// A `notifications` row (P2 consumers: reminder effectiveness).
@immutable
final class NotificationRecord {
  const NotificationRecord({
    required this.fireAt,
    this.sourceType,
    this.sourceId,
    this.category,
    this.actedAt,
    this.action,
  });

  final String? sourceType;
  final String? sourceId;
  final String? category;
  final DateTime fireAt;
  final DateTime? actedAt;
  final String? action;
}

/// Habit rows of a batch.
@immutable
final class HabitInput {
  const HabitInput({
    this.habits = const [],
    this.logs = const [],
    this.pauses = const [],
    this.revisions = const [],
    this.goals = const [],
    this.notifications = const [],
    this.categories = const [],
  });

  final List<HabitRecord> habits;
  final List<HabitLogRecord> logs;
  final List<HabitPause> pauses;
  final List<RevisionRecord> revisions;
  final List<GoalRecord> goals;
  final List<NotificationRecord> notifications;
  final List<CategoryInfo> categories;
}

// ---------------------------------------------------------------------------------------------
// Batch
// ---------------------------------------------------------------------------------------------

/// One isolate job: a request, its environment and the rows of the domains it reads.
@immutable
final class StatsJob {
  const StatsJob({
    required this.request,
    required this.env,
    required this.metricIds,
    this.planner,
    this.checklists,
    this.habits,
    this.pendingOutbox = 0,
    this.firstDataDate,
    this.reviewedWeeks = const [],
  });

  final StatsRequest request;
  final StatsEnvironment env;

  /// The metrics to compute (already resolved from the request and the registry).
  final List<String> metricIds;
  final PlannerInput? planner;
  final ChecklistInput? checklists;
  final HabitInput? habits;

  /// Pending sync outbox rows (data-quality caveat, T6.1.20).
  final int pendingOutbox;

  /// First data date of the scope (all-time periods).
  final LocalDate? firstDataDate;

  /// Week starts with a completed guided weekly review (global scope, GL-04).
  final List<LocalDate> reviewedWeeks;
}
