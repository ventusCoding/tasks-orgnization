import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/features/checklists/domain/collation.dart';
import 'package:everslot/features/habits/application/check_in_service.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/quit_service.dart';
import 'package:everslot/features/habits/domain/check_in.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart' show LogSource;
import 'package:everslot/features/integrations/application/external_links_service.dart';
import 'package:everslot/features/integrations/application/integration_events.dart';
import 'package:everslot/features/integrations/domain/external_link.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/domain/occurrence_resolver.dart';
import 'package:everslot/features/planner/domain/planner_item.dart' show OccurrenceStatus;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `everslot://do/…` command handlers shared by shortcuts, widgets and voice actions (8.2).
abstract final class IntegrationCommands {
  static void registerAll(Ref ref, LinkCommandRegistry registry, BufferedEventBus<IntegrationUiEvent> events) {
    _timerStop(ref, registry, events);
    _voice(ref, registry, events);
    // New task → the universal quick add (T8.2.06).
    registry.register('new-task', (command) async => events.add(QuickAddUiEvent(title: command.params['title'])));

    // Log craving (T8.2.06): one active quit tracker → logged at once; several → choose in Habits;
    // none → create one.
    registry.register('craving', (command) async {
      final quits = [
        for (final h in await ref.read(habitsRepositoryProvider).all(includeArchived: false))
          if (h case final QuitHabit q) q,
      ];
      if (quits.isEmpty) {
        events.add(OpenPathUiEvent(AppLinks.habitNew(kind: 'quit')));
      } else if (quits.length > 1) {
        events.add(OpenPathUiEvent(AppLinks.habits(), asRoot: true));
      } else {
        await ref.read(quitServiceProvider).logCraving(quits.single);
        events.add(NoticeUiEvent(IntegrationNotice.cravingLogged, detail: quits.single.name));
      }
    });
  }

  /// Stop + complete a running timer (iOS Live Activity *Stop*, T8.2.10): the app opens, the
  /// time entry closes now and the occurrence opens.
  static void _timerStop(Ref ref, LinkCommandRegistry registry, BufferedEventBus<IntegrationUiEvent> events) {
    registry.register('timer-stop', (command) async {
      final task = command.params['task']!;
      final occ = command.params['occ']!;
      await ref.read(occurrencesRepositoryProvider).stop(task, occ, cause: 'live_activity');
      events.add(OpenPathUiEvent(AppLinks.task(task, occurrenceKey: occ)));
    });
  }

  /// Siri / App Intents and Android App Actions (T8.2.15): *Log push-ups 15*, *What's next?*,
  /// *Start focus*. Each arrives as an `everslot://do/…` link.
  static void _voice(Ref ref, LinkCommandRegistry registry, BufferedEventBus<IntegrationUiEvent> events) {
    registry.register('habit-log', (command) async {
      final habit = await findHabit(ref, id: command.params['habit'], name: command.params['name']);
      if (habit == null) {
        events.add(NoticeUiEvent(IntegrationNotice.habitNotFound, detail: command.params['name'] ?? ''));
        return;
      }
      final value = double.tryParse((command.params['value'] ?? '').replaceAll(',', '.'));
      final checkIn = ref.read(checkInServiceProvider);
      try {
        if (habit.goal.isMeasurable) {
          final target = await checkIn.currentTarget(habit);
          if (target == null) throw const CheckInException(CheckInRefusal.future);
          await checkIn.addProgress(habit, target.key, value ?? habit.settings.incrementStep, source: LogSource.voice);
        } else {
          await checkIn.checkNow(habit, source: LogSource.voice);
        }
        events.add(NoticeUiEvent(IntegrationNotice.habitLogged, detail: habit.name));
      } on CheckInException {
        events.add(const NoticeUiEvent(IntegrationNotice.actionFailed));
      }
    });
    registry.register('next', (command) async {
      final o = await nextOccurrence(ref);
      if (o == null) {
        events.add(const NoticeUiEvent(IntegrationNotice.nothingNext));
        return;
      }
      events.add(OpenPathUiEvent(AppLinks.task(o.task.id, occurrenceKey: o.occurrenceKey)));
    });
    registry.register('focus', (command) async {
      final o = await nextOccurrence(ref);
      if (o == null) {
        events.add(const NoticeUiEvent(IntegrationNotice.nothingNext));
        return;
      }
      await ref
          .read(occurrencesRepositoryProvider)
          .start(o.task.id, o.occurrenceKey, policy: ref.read(plannerSettingsProvider).timerPolicy, source: 'voice');
      events.add(OpenPathUiEvent(AppLinks.task(o.task.id, occurrenceKey: o.occurrenceKey)));
    });
  }

  /// A build habit by id, else by name (case, accents and Arabic variants ignored; exact match
  /// first, then the shortest name that starts with / contains the spoken words).
  static Future<BuildHabit?> findHabit(Ref ref, {String? id, String? name}) async {
    final habits = [
      for (final h in await ref.read(habitsRepositoryProvider).all(includeArchived: false))
        if (h case final BuildHabit b) b,
    ];
    if (id != null) return habits.where((h) => h.id == id).firstOrNull;
    if (name == null || name.trim().isEmpty) return null;
    final wanted = Collation.key(name);
    final exact = habits.where((h) => Collation.key(h.name) == wanted).firstOrNull;
    if (exact != null) return exact;
    final partial = [
      for (final h in habits)
        if (Collation.key(h.name).contains(wanted) || wanted.contains(Collation.key(h.name))) h,
    ]..sort((a, b) => a.name.length.compareTo(b.name.length));
    return partial.firstOrNull;
  }

  /// The running occurrence, else the next one starting within 24 hours.
  static Future<ResolvedOccurrence?> nextOccurrence(Ref ref) async {
    final zone = ref.read(deviceZoneProvider);
    final zones = ref.read(zoneResolverProvider);
    final nowUtc = ref.read(clockProvider).nowUtc();
    final now = zones.toLocal(nowUtc, zone);
    final from = now.date.atStartOfDay;
    final to = now.plusMinutes(24 * 60);
    final queries = ref.read(plannerQueriesProvider);
    final tasks = await queries.tasksForRange(from, to);
    final records = await queries.recordsForRange(tasks, from, to);
    final occurrences = ref
        .read(occurrenceResolverProvider)
        .resolve(
          tasks: tasks,
          records: records,
          from: from,
          to: to,
          viewerZone: zone,
          now: nowUtc,
          settings: ref.read(plannerSettingsProvider).resolver,
        )
        .occurrences;
    final open = [
      for (final o in occurrences)
        if (!o.isAllDay &&
            o.endInstant.isAfter(nowUtc) &&
            const {OccurrenceStatus.scheduled, OccurrenceStatus.inProgress, OccurrenceStatus.missed}.contains(o.status))
          o,
    ]..sort((a, b) => a.startInstant.compareTo(b.startInstant));
    return open.where((o) => !o.startInstant.isAfter(nowUtc)).firstOrNull ?? open.firstOrNull;
  }

  /// For tests and diagnostics.
  static LinkCommand command(String name, [Map<String, String> params = const {}]) => LinkCommand(name, params);
}
