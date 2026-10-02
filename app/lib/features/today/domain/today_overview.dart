import 'package:collection/collection.dart';
import 'package:decimal/decimal.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/notifications/domain/inbox_item.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/today/domain/day_window.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show HabitLogKind, PeriodResult, QuitMilestone;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

const _listEq = ListEquality<Object?>();

/// Data sources of the Today overview; each loads (and may fail) independently.
enum TodaySection { planner, overdue, habits, checklists, inbox }

/// A build habit due today with everything the habits block shows (T8.1.06).
@immutable
class TodayHabitEntry {
  const TodayHabitEntry({
    required this.habit,
    required this.checkInKey,
    required this.progress,
    required this.resolved,
    this.day,
    this.quota,
    this.slots = const [],
    this.currentSlot,
    this.nextSlot,
    this.explicitState,
    this.currentStreak = 0,
  });

  final BuildHabit habit;

  /// Today's day result (slot roll-up for slot habits, the day view for quota habits).
  final PeriodResult? day;

  /// The quota period containing today (quota habits).
  final PeriodResult? quota;

  /// Today's slots in order (intraday habits).
  final List<PeriodResult> slots;

  /// The slot "check now" targets (its early window has opened), or null.
  final PeriodResult? currentSlot;

  /// The next slot still ahead today (shown when no slot is open yet).
  final PeriodResult? nextSlot;

  /// Key a one-tap check-in writes: today's day key, or the current slot key. Null when nothing
  /// can be checked yet (before the first slot).
  final String? checkInKey;

  /// Explicit state logged for [checkInKey] (done / fail / skip / excuse), if any.
  final HabitLogKind? explicitState;

  /// 0…1 for the progress ring (achieved ÷ target; done slots ÷ slots; quota progress).
  final double progress;

  /// Nothing left to do today (done, skipped or excused; limits unless exceeded).
  final bool resolved;
  final int currentStreak;

  bool get isSlotHabit => slots.isNotEmpty;
  bool get isQuota => quota != null;
  bool get isMeasurable => habit.goal.isMeasurable;
  bool get isLimit => habit.goal.isLimit;

  /// Amount achieved for the check-in period (count, minutes or value).
  double get achieved => (currentSlot ?? day)?.achieved ?? 0;

  /// Target of the check-in period (1 for yes/no habits).
  double get target => (currentSlot ?? day)?.target ?? habit.goal.effectiveTarget;

  @override
  bool operator ==(Object other) =>
      other is TodayHabitEntry &&
      other.habit == habit &&
      other.day == day &&
      other.quota == quota &&
      _listEq.equals(other.slots, slots) &&
      other.currentSlot == currentSlot &&
      other.nextSlot == nextSlot &&
      other.checkInKey == checkInKey &&
      other.explicitState == explicitState &&
      other.progress == progress &&
      other.resolved == resolved &&
      other.currentStreak == currentStreak;

  @override
  int get hashCode => Object.hash(
    habit,
    day,
    quota,
    Object.hashAll(slots),
    currentSlot,
    nextSlot,
    checkInKey,
    explicitState,
    progress,
    resolved,
    currentStreak,
  );
}

/// An active quit tracker (T8.1.07). The live counter is computed from [abstinenceStart] on every
/// tick — nothing is written per tick.
@immutable
class TodayQuitEntry {
  const TodayQuitEntry({
    required this.habit,
    required this.abstinenceStart,
    this.moneySaved,
    this.currency,
    this.nextMilestone,
    this.dayStreak = 0,
    this.usedToday,
  });

  final QuitHabit habit;

  /// Start of the current clean streak: the quit date, or the last relapse / restart.
  final DateTime abstinenceStart;

  /// Money saved since the quit date (null when no unit cost is set).
  final Decimal? moneySaved;
  final String? currency;

  /// Next day milestone of the current streak (1, 3, 7, 14, 30… days), null after the last one.
  final QuitMilestone? nextMilestone;
  final int dayStreak;

  /// Reduce mode: units used today.
  final double? usedToday;

  bool get isReduce => habit.isReduce;

  @override
  bool operator ==(Object other) =>
      other is TodayQuitEntry &&
      other.habit == habit &&
      other.abstinenceStart == abstinenceStart &&
      other.moneySaved == moneySaved &&
      other.currency == currency &&
      other.nextMilestone?.id == nextMilestone?.id &&
      other.dayStreak == dayStreak &&
      other.usedToday == usedToday;

  @override
  int get hashCode =>
      Object.hash(habit, abstinenceStart, moneySaved, currency, nextMilestone?.id, dayStreak, usedToday);
}

/// A pinned checklist with its progress (T8.1.08).
@immutable
class TodayPinnedChecklist {
  const TodayPinnedChecklist({
    required this.id,
    required this.title,
    required this.done,
    required this.total,
    this.color,
    this.blocked = 0,
    this.waiting = 0,
  });

  final String id;
  final String title;
  final int? color;
  final int done;
  final int total;
  final int blocked;
  final int waiting;

  double get progress => total == 0 ? 0 : done / total;

  @override
  bool operator ==(Object other) =>
      other is TodayPinnedChecklist &&
      other.id == id &&
      other.title == title &&
      other.color == color &&
      other.done == done &&
      other.total == total &&
      other.blocked == blocked &&
      other.waiting == waiting;

  @override
  int get hashCode => Object.hash(id, title, color, done, total, blocked, waiting);
}

/// A checklist item surfaced on Today: due today (or overdue), or a waiting/blocked item whose
/// follow-up date has come (T8.1.08).
@immutable
class TodayChecklistItem {
  const TodayChecklistItem({
    required this.id,
    required this.checklistId,
    required this.text,
    required this.status,
    required this.checklistTitle,
    this.checklistColor,
    this.parentText,
    this.statusNote,
    this.dueLocal,
    this.timeZone,
    this.followUpAt,
    this.priority = 0,
  });

  final String id;
  final String checklistId;
  final String text;
  final ItemStatus status;
  final String checklistTitle;
  final int? checklistColor;

  /// Text of the parent item (breadcrumb), if any.
  final String? parentText;
  final String? statusNote;

  /// Due wall-clock value (00:00 = date only) in [timeZone], or floating.
  final LocalDateTime? dueLocal;
  final String? timeZone;
  final DateTime? followUpAt;
  final int priority;

  @override
  bool operator ==(Object other) =>
      other is TodayChecklistItem &&
      other.id == id &&
      other.checklistId == checklistId &&
      other.text == text &&
      other.status == status &&
      other.checklistTitle == checklistTitle &&
      other.checklistColor == checklistColor &&
      other.parentText == parentText &&
      other.statusNote == statusNote &&
      other.dueLocal == dueLocal &&
      other.timeZone == timeZone &&
      other.followUpAt == followUpAt &&
      other.priority == priority;

  @override
  int get hashCode => Object.hash(
    id,
    checklistId,
    text,
    status,
    checklistTitle,
    checklistColor,
    parentText,
    statusNote,
    dueLocal,
    timeZone,
    followUpAt,
    priority,
  );
}

/// Everything Today needs for the current logical day (T8.1.01). A null section is still loading.
@immutable
class TodayOverview {
  const TodayOverview({
    required this.window,
    required this.now,
    this.agenda,
    this.upcoming,
    this.overdue,
    this.habits,
    this.quits,
    this.pinned,
    this.dueItems,
    this.followUps,
    this.unreadInbox,
    this.inboxHighlights,
    this.errors = const {},
  });

  final DayWindow window;

  /// Instant the overview was assembled.
  final DateTime now;

  /// Occurrences of the logical day, sorted (all-day first, then by start).
  final List<PlannerItem>? agenda;

  /// Occurrences starting after the day window (the Now/Next card looks ahead to tomorrow).
  final List<PlannerItem>? upcoming;

  /// Unresolved past occurrences within the look-back (T8.1.05).
  final List<PlannerItem>? overdue;
  final List<TodayHabitEntry>? habits;
  final List<TodayQuitEntry>? quits;
  final List<TodayPinnedChecklist>? pinned;

  /// Open checklist items due today or overdue.
  final List<TodayChecklistItem>? dueItems;

  /// Waiting / blocked items whose follow-up is today or past.
  final List<TodayChecklistItem>? followUps;
  final int? unreadInbox;
  final List<InboxItem>? inboxHighlights;

  /// Sections whose source failed.
  final Map<TodaySection, Object> errors;

  LocalDate get date => window.date;

  bool isLoading(TodaySection section) => switch (section) {
    TodaySection.planner => agenda == null,
    TodaySection.overdue => overdue == null,
    TodaySection.habits => habits == null || quits == null,
    TodaySection.checklists => pinned == null || dueItems == null || followUps == null,
    TodaySection.inbox => unreadInbox == null,
  };

  @override
  bool operator ==(Object other) =>
      other is TodayOverview &&
      other.window == window &&
      other.now == now &&
      _same(other.agenda, agenda) &&
      _same(other.upcoming, upcoming) &&
      _same(other.overdue, overdue) &&
      _same(other.habits, habits) &&
      _same(other.quits, quits) &&
      _same(other.pinned, pinned) &&
      _same(other.dueItems, dueItems) &&
      _same(other.followUps, followUps) &&
      other.unreadInbox == unreadInbox &&
      _same(other.inboxHighlights, inboxHighlights) &&
      const MapEquality<TodaySection, Object>().equals(other.errors, errors);

  static bool _same(List<Object?>? a, List<Object?>? b) => a == null ? b == null : b != null && _listEq.equals(a, b);

  @override
  int get hashCode => Object.hash(
    window,
    now,
    agenda?.length,
    overdue?.length,
    habits?.length,
    quits?.length,
    pinned?.length,
    dueItems?.length,
    followUps?.length,
    unreadInbox,
  );
}
