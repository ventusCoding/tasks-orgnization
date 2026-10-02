import 'package:everslot/features/integrations/domain/ics.dart';
import 'package:everslot/features/planner/domain/occurrence_record.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// One expanded occurrence (non-representable rules are exported instance by instance).
typedef IcsInstance = ({String key, LocalDateTime start, int minutes, String title});

/// Tasks ↔ calendar events (T8.2.11 / T8.2.12).
abstract final class IcsMapping {
  static const uidDomain = 'everslot.app';

  /// Imported tasks keep their calendar UID so a round trip stays the same event.
  static String uidFor(Task task) => task.externalUid ?? '${task.id}@$uidDomain';

  /// Events of [task]: one VEVENT with RRULE / EXDATE (+ RECURRENCE-ID overrides) when the rule is
  /// representable in RFC 5545 ([encode] returns null otherwise), else one event per [expand]ed
  /// instance. Unscheduled tasks have no events.
  static List<IcsEvent> eventsForTask(
    Task task, {
    List<TaskOccurrenceRecord> records = const [],
    required String? Function(RecurrenceRule rule, RecurrenceAnchor anchor) encode,
    required List<IcsInstance> Function() expand,
  }) {
    final start = task.startLocal;
    if (start == null) return const [];
    final minutes = task.durationMinutes ?? (task.isAllDay ? 1440 : 60);
    final allDay = task.isAllDay;
    final zone = task.timeZone;
    final uid = uidFor(task);
    IcsEvent base({String? recurrence}) => IcsEvent(
      uid: uid,
      summary: task.title,
      start: allDay ? start.date.atStartOfDay : start,
      end: allDay
          ? start.date.plusDays((minutes / 1440).ceil().clamp(1, 366)).atStartOfDay
          : start.plusMinutes(minutes),
      allDay: allDay,
      timeZone: zone,
      description: task.notes,
      location: task.location,
      url: task.url,
      recurrence: recurrence,
    );
    final rule = task.recurrence;
    if (rule == null) return [base()];

    final cancelled = [
      for (final r in records)
        if (r.isCancelled) r.occurrenceKey,
    ];
    final withExdates = cancelled.isEmpty ? rule : rule.copyWith(exdates: {...rule.exdates, ...cancelled}.toList());
    final anchor = RecurrenceAnchor(start, zone, durationMinutes: minutes, allDay: allDay);
    final block = encode(withExdates, anchor);
    if (block != null) {
      return [
        base(recurrence: block),
        for (final r in records)
          if (!r.isCancelled &&
              (r.overrideStartLocal != null || r.overrideTitle != null || r.overrideDurationMinutes != null))
            if (keyStart(r.occurrenceKey) case final original?)
              () {
                final s = r.overrideStartLocal ?? original;
                final m = r.overrideDurationMinutes ?? minutes;
                return IcsEvent(
                  uid: uid,
                  summary: r.overrideTitle ?? task.title,
                  start: s,
                  end: allDay ? s.date.plusDays(1).atStartOfDay : s.plusMinutes(m),
                  allDay: allDay,
                  timeZone: zone,
                  description: r.overrideNotes ?? task.notes,
                  location: task.location,
                  recurrenceId: original,
                );
              }(),
      ];
    }
    return [
      for (final i in expand())
        IcsEvent(
          uid: '${task.id}-${i.key}@$uidDomain',
          summary: i.title,
          start: allDay ? i.start.date.atStartOfDay : i.start,
          end: allDay ? i.start.date.plusDays(1).atStartOfDay : i.start.plusMinutes(i.minutes),
          allDay: allDay,
          timeZone: zone,
          description: task.notes,
          location: task.location,
          url: task.url,
        ),
    ];
  }

  /// Wall-clock start of an occurrence key (`2026-09-22T09:00` / all-day `2026-09-22`).
  static LocalDateTime? keyStart(String key) => LocalDateTime.tryParse(key) ?? LocalDate.tryParse(key)?.atStartOfDay;

  /// Occurrence key of a RECURRENCE-ID.
  static String keyOf(LocalDateTime start, {required bool allDay}) => allDay ? start.date.toIso() : start.toIso();
}

/// A calendar event ready to become a task (T8.2.12).
@immutable
class IcsImportCandidate {
  const IcsImportCandidate({
    required this.event,
    required this.task,
    this.overrides = const [],
    this.alreadyImported = false,
    this.problem,
  });

  final IcsEvent event;

  /// The task to create (id assigned on save).
  final Task task;

  /// RECURRENCE-ID events of this series.
  final List<IcsEvent> overrides;

  /// A task with this UID exists (duplicate detection).
  final bool alreadyImported;

  /// Why the recurrence could not be read (the event is imported as a one-off).
  final String? problem;
}

abstract final class IcsImport {
  /// Candidates of [result] (series / one-off events with their overrides), flagged against
  /// [existingUids].
  static List<IcsImportCandidate> candidates(
    IcsParseResult result, {
    required Set<String> existingUids,
    ZoneResolver? resolver,
  }) {
    final overridesByUid = <String, List<IcsEvent>>{};
    for (final e in result.events.where((e) => e.recurrenceId != null)) {
      (overridesByUid[e.uid] ??= []).add(e);
    }
    final seen = <String>{};
    return [
      for (final e in result.events.where((e) => e.recurrenceId == null))
        if (seen.add(e.uid)) _candidate(e, overridesByUid[e.uid] ?? const [], existingUids.contains(e.uid), resolver),
    ];
  }

  static IcsImportCandidate _candidate(IcsEvent e, List<IcsEvent> overrides, bool exists, ZoneResolver? resolver) {
    RecurrenceRule? rule;
    String? problem;
    var start = e.start;
    if (e.recurrence case final text?) {
      try {
        final parsed = RRuleCodec.parse(text, resolver: resolver);
        rule = parsed.rule;
        if (parsed.anchor case final a?) start = a.start;
      } on FormatException catch (err) {
        problem = err.message;
      }
    }
    final zone = e.timeZone == 'UTC' ? 'UTC' : e.timeZone;
    return IcsImportCandidate(
      event: e,
      overrides: overrides,
      alreadyImported: exists,
      problem: problem,
      task: Task(
        id: '',
        seriesId: '',
        title: e.summary.isEmpty ? '—' : e.summary,
        notes: (e.description?.trim().isEmpty ?? true) ? null : e.description!.trim(),
        location: (e.location?.trim().isEmpty ?? true) ? null : e.location!.trim(),
        url: e.url,
        startLocal: e.allDay ? start.date.atStartOfDay : start,
        durationMinutes: e.allDay ? ((e.durationMinutes / 1440).ceil().clamp(1, 366)) * 1440 : e.durationMinutes,
        isAllDay: e.allDay,
        timeZone: zone,
        recurrence: rule,
        externalUid: e.uid.length > 255 ? e.uid.substring(0, 255) : e.uid,
      ),
    );
  }
}
