import 'package:everslot/core/providers.dart';
import 'package:everslot/features/integrations/application/integration_providers.dart';
import 'package:everslot/features/integrations/domain/ics.dart';
import 'package:everslot/features/integrations/domain/ics_mapping.dart';
import 'package:everslot/features/notifications/application/notification_host_api.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

/// ICS export (T8.2.11) and import (T8.2.12) for tasks.
class IcsService {
  IcsService(this._read);

  final T Function<T>(ProviderListenable<T> provider) _read;

  /// Expanded instances of non-representable rules cover this window when none is given.
  static const defaultWindow = Duration(days: 180);

  // ---------------------------------------------------------------------------
  // Export

  Future<String> exportTask(String taskId) async {
    final task = await _read(plannerQueriesProvider).task(taskId);
    return _calendar(task == null ? const [] : [task], name: task?.title ?? 'Everslot');
  }

  /// Tasks with an occurrence in [from, to] (optionally of one category).
  Future<String> exportRange(LocalDate from, LocalDate to, {String? categoryId, String name = 'Everslot'}) async {
    final tasks = await _read(plannerQueriesProvider).tasksForRange(from.atStartOfDay, to.plusDays(1).atStartOfDay);
    final picked = [
      for (final t in tasks)
        if (!t.isTemplate && (categoryId == null || t.categoryId == categoryId)) t,
    ];
    return _calendar(picked, from: from.atStartOfDay, to: to.plusDays(1).atStartOfDay, name: name);
  }

  Future<String> _calendar(List<Task> tasks, {LocalDateTime? from, LocalDateTime? to, required String name}) async {
    final clock = _read(clockProvider);
    final now = clock.nowUtc();
    final zone = _read(deviceZoneProvider);
    final zones = _read(zoneResolverProvider);
    final today = zones.toLocal(now, zone).date;
    final windowFrom = from ?? today.atStartOfDay;
    final windowTo = to ?? today.plusDays(defaultWindow.inDays).atStartOfDay;
    final records = await _read(plannerQueriesProvider).records(tasks.map((t) => t.id));
    final resolver = _read(occurrenceResolverProvider);
    final settings = _read(plannerSettingsProvider).resolver;
    final events = <IcsEvent>[
      for (final task in tasks)
        ...IcsMapping.eventsForTask(
          task,
          records: [
            for (final r in records)
              if (r.taskId == task.id) r,
          ],
          encode: (rule, anchor) => RRuleCodec.encode(rule, anchor, resolver: zones),
          expand: () => [
            for (final o in resolver.resolveTask(
              task,
              [
                for (final r in records)
                  if (r.taskId == task.id) r,
              ],
              from: windowFrom,
              to: windowTo,
              viewerZone: zone,
              now: now,
              settings: settings,
            ))
              if (!(o.record?.isCancelled ?? false))
                (
                  key: o.occurrenceKey,
                  start: o.effectiveStartLocal,
                  minutes: o.endInstant.difference(o.startInstant).inMinutes,
                  title: o.record?.overrideTitle ?? task.title,
                ),
          ],
        ),
    ];
    return IcsWriter.calendar(events, stamp: now, name: name);
  }

  // ---------------------------------------------------------------------------
  // Import

  /// What [content] would import, duplicates flagged.
  Future<List<IcsImportCandidate>> preview(String content) async {
    final result = IcsParser.parse(content);
    final existing = await _read(integrationQueriesProvider).taskExternalUids();
    return IcsImport.candidates(result, existingUids: existing, resolver: _read(zoneResolverProvider));
  }

  /// Creates the tasks of [candidates] (with their reminders and occurrence overrides); returns how
  /// many tasks were created.
  Future<int> import(List<IcsImportCandidate> candidates) async {
    final planner = _read(plannerServiceProvider);
    var created = 0;
    for (final c in candidates) {
      final alarms = c.event.alarmsMinutesBefore.toSet().toList()..sort();
      final reminders = alarms.isEmpty
          ? null
          : NotificationRulesDraft(
              rules: [
                for (final m in alarms)
                  RuleDraft(
                    targetType: RuleTargetType.task,
                    section: NotificationSection.planner,
                    spec: NotificationRuleSpec(
                      trigger: RelativeTrigger(anchor: TriggerAnchor.start, offsetMinutes: -m),
                    ),
                  ),
              ],
            );
      final result = await planner.createTask(c.task, source: 'ics', reminders: reminders);
      created++;
      for (final o in c.overrides) {
        final rid = o.recurrenceId;
        if (rid == null) continue;
        final key = IcsMapping.keyOf(rid, allDay: c.task.isAllDay);
        if (o.cancelled) {
          await _read(occurrencesRepositoryProvider).cancel(result.taskId, key);
        } else {
          await _read(tasksRepositoryProvider).editOccurrence(
            result.taskId,
            key,
            start: o.start == rid ? null : o.start,
            duration: o.durationMinutes == c.task.durationMinutes ? null : o.durationMinutes,
            title: o.summary == c.task.title || o.summary.isEmpty ? null : o.summary,
            source: 'ics',
          );
        }
      }
    }
    return created;
  }
}

final icsServiceProvider = Provider<IcsService>((ref) {
  ref.watch(currentUserIdProvider);
  return IcsService(ref.read);
});
