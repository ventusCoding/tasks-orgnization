import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/design_system/formatting.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/today/domain/today_overview.dart';
import 'package:everslot/features/widgets_home/domain/widget_snapshot.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show HabitLogKind;

/// Builds the widget snapshot from the Today overview (T8.2.02): pure — same inputs, same JSON.
abstract final class WidgetSnapshotBuilder {
  static WidgetSnapshot build({
    required TodayOverview overview,
    required AppLocalizations l10n,
    required AppFormat format,
    required DateTime now,
    TodayPinnedChecklist? pinned,
    List<ChecklistItem> pinnedItems = const [],
  }) {
    final l = l10n;
    final agenda = overview.agenda ?? const <PlannerItem>[];
    final timed = agenda.where((i) => !i.allDay).toList();
    final doneTasks = agenda.where((i) => i.status == OccurrenceStatus.done).length;
    final habits = overview.habits ?? const <TodayHabitEntry>[];
    return WidgetSnapshot(
      generatedAt: now.toUtc(),
      locale: l.localeName,
      rtl: l.localeName.startsWith('ar'),
      day: overview.date.toString(),
      dayLabel: format.dayLong(overview.date),
      progressLabel: agenda.isEmpty ? '' : l.todayProgressTasks(doneTasks, agenda.length),
      strings: {
        'today': l.tabToday,
        'habits': l.tabHabits,
        'quit': l.widgetCleanTime,
        'list': l.tabLists,
        'empty': l.widgetNothingLeft,
        'noHabits': l.widgetNoHabits,
        'noQuit': l.widgetNoQuit,
        'listDone': l.widgetListDone,
        'allDone': l.widgetAllDone,
        'stale': l.widgetStale,
        'now': l.widgetNow,
        'allDay': l.todayAllDay,
        'habitsProgress': habits.isEmpty
            ? ''
            : l.todayProgressHabits(habits.where((h) => h.resolved).length, habits.length),
        'noList': l.widgetNoList,
      },
      agenda: [
        for (final i in [...agenda.where((i) => i.allDay), ...timed])
          WidgetAgendaRow(
            key: '${i.taskId}|${i.occurrenceKey}',
            title: WidgetSnapshot.clip(i.title),
            timeLabel: i.allDay
                ? l.todayAllDay
                : format.timeRange(i.startLocal, i.startLocal.plusMinutes(i.durationMinutes)),
            link: _external(AppLinks.task(i.taskId, occurrenceKey: i.occurrenceKey)),
            start: i.allDay ? null : i.startUtc,
            end: i.allDay ? null : i.endUtc,
            allDay: i.allDay,
            color: i.color,
            done: i.status == OccurrenceStatus.done,
          ),
      ],
      habits: [
        for (final h in habits)
          WidgetHabitRow(
            id: h.habit.id,
            name: WidgetSnapshot.clip(h.habit.name, 60),
            progress: h.progress,
            label: h.isMeasurable ? '${_num(h.achieved)}/${_num(h.target)}' : (h.resolved ? '✓' : ''),
            done: h.resolved || h.explicitState == HabitLogKind.done,
            counter: h.isMeasurable,
            link: _external(AppLinks.habit(h.habit.id)),
            action: WidgetActions.habitCheck(h.habit.id),
            color: h.habit.color,
            icon: h.habit.icon,
          ),
      ],
      quits: [
        for (final q in overview.quits ?? const <TodayQuitEntry>[])
          WidgetQuitRow(
            id: q.habit.id,
            name: WidgetSnapshot.clip(q.habit.name, 60),
            since: q.abstinenceStart,
            link: _external(AppLinks.quit(q.habit.id)),
            savedLabel: q.moneySaved == null || q.currency == null
                ? null
                : l.todayQuitSaved(format.currency(q.moneySaved!.toDouble(), q.currency!)),
            nextMilestoneLabel: q.nextMilestone == null
                ? null
                : l.todayQuitNextMilestone(format.duration(q.nextMilestone!.tMin.inMinutes)),
            nextMilestoneAt: q.nextMilestone == null ? null : q.abstinenceStart.add(q.nextMilestone!.tMin),
          ),
      ],
      checklist: pinned == null
          ? null
          : WidgetChecklist(
              id: pinned.id,
              title: WidgetSnapshot.clip(pinned.title, 60),
              done: pinned.done,
              total: pinned.total,
              color: pinned.color,
              link: _external(AppLinks.checklist(pinned.id)),
              items: _openItems(pinned.id, pinnedItems),
            ),
    ).bounded();
  }

  /// Open items in tree order, two levels deep.
  static List<WidgetChecklistItem> _openItems(String checklistId, List<ChecklistItem> items) {
    final byParent = <String?, List<ChecklistItem>>{};
    for (final i in items) {
      (byParent[i.parentId] ??= []).add(i);
    }
    for (final list in byParent.values) {
      list.sort((a, b) => a.sortKey.compareTo(b.sortKey));
    }
    final out = <WidgetChecklistItem>[];
    void walk(String? parent, int depth) {
      for (final i in byParent[parent] ?? const <ChecklistItem>[]) {
        if (!i.status.isOpen) continue;
        out.add(
          WidgetChecklistItem(
            id: i.id,
            text: WidgetSnapshot.clip(i.text, 80),
            depth: depth,
            action: WidgetActions.itemComplete(checklistId, i.id),
          ),
        );
        if (depth < 1) walk(i.id, depth + 1);
      }
    }

    walk(null, 0);
    return out;
  }

  /// Native widgets open `everslot://…` links (handled by the external links service, T8.2.01).
  static String _external(String path) => AppLinks.external(path).toString();

  static String _num(double v) => v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
}
