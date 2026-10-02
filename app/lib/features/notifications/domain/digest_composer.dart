import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/domain/template_engine.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';

/// Builds synthetic digest targets (one per enabled digest kind × local day) from the targets the
/// registered sources returned (T7.5.18). Content is rendered at plan time and refreshed on every
/// replan, so a task added last night on another device shows up in this morning's agenda.
abstract final class DigestComposer {
  static List<NotificationTarget> compose({
    required List<NotificationRule> rules,
    required List<NotificationTarget> targets,
    required DateTime now,
    required int horizonDays,
    required String zone,
    required ZoneResolver zones,
    required NotificationTexts texts,
    Map<String, int> facts = const {},
  }) {
    final kinds = {
      for (final r in rules)
        if (r.enabled && r.spec.trigger is DigestTrigger) (r.spec.trigger as DigestTrigger).kind,
    };
    if (kinds.isEmpty) return const [];
    final today = zones.toLocal(now, zone).date;
    DateTime startOf(LocalDate d) => zones.resolve(d.atStartOfDay, zone).utc;
    final out = <NotificationTarget>[];
    for (final kind in kinds) {
      for (var i = 0; i <= horizonDays; i++) {
        final day = today.plusDays(i);
        final from = startOf(day);
        final to = startOf(day.plusDays(1));
        final (tasks, habits, items, first) = _counts(kind, targets, from, to, day, zone, zones, texts);
        out.add(
          NotificationTarget(
            type: NotificationTargetType.digest,
            id: kind,
            section: NotificationSection.system,
            title: texts.digestTitle(kind),
            occurrenceKey: day.toIso(),
            periodStart: from,
            periodEnd: to,
            variables: {
              'kind': kind,
              'summary': texts.digestSummary(
                kind,
                tasks: tasks,
                habits: habits,
                items: items,
                first: first,
                backlog: kind == 'plan_tomorrow' ? facts['backlog'] : null,
              ),
              'open_items': items,
            },
          ),
        );
      }
    }
    return out;
  }

  static (int, int, int, String?) _counts(
    String kind,
    List<NotificationTarget> targets,
    DateTime from,
    DateTime to,
    LocalDate day,
    String zone,
    ZoneResolver zones,
    NotificationTexts texts,
  ) {
    bool inDay(DateTime? t) => t != null && !t.isBefore(from) && t.isBefore(to);
    bool beforeEnd(DateTime? t) => t != null && t.isBefore(to);
    // plan_tomorrow looks at the next day.
    final shift = kind == 'plan_tomorrow' ? const Duration(days: 1) : Duration.zero;
    final f = from.add(shift);
    final t2 = to.add(shift);
    bool inWindow(DateTime? t) => t != null && !t.isBefore(f) && t.isBefore(t2);
    final seen = <String>{};
    var tasks = 0;
    var habits = 0;
    var items = 0;
    NotificationTarget? firstTask;
    for (final t in targets) {
      if (!t.isOpen || t.type == NotificationTargetType.digest) continue;
      final key = '${t.targetKey}|${t.occurrenceKey ?? ''}';
      if (!seen.add(key)) continue;
      final bool counts;
      switch (kind) {
        case 'overdue_summary' || 'evening_review':
          counts = beforeEnd(t.end ?? t.due) && !(inDay(t.start) && kind == 'overdue_summary' && t.end == null);
        case 'weekly_review' || 'monthly_report':
          counts = false;
        default:
          counts = inWindow(t.start) || inWindow(t.due) || inWindow(t.slot) || inWindow(t.periodStart);
      }
      if (!counts) continue;
      switch (t.type) {
        case NotificationTargetType.task:
          tasks++;
          if (t.start != null && (firstTask == null || t.start!.isBefore(firstTask.start!))) {
            firstTask = t;
          }
        case NotificationTargetType.habit:
          habits++;
        case NotificationTargetType.checklist || NotificationTargetType.checklistItem:
          items++;
        case NotificationTargetType.digest || NotificationTargetType.custom:
          break;
      }
    }
    final first = firstTask == null ? null : '${firstTask.title} ${texts.time(zones.toLocal(firstTask.start!, zone))}';
    return (tasks, habits, items, first);
  }
}
