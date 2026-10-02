import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/session/session.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/builtin_templates.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/demo/data/demo_store.dart';
import 'package:everslot/features/demo/domain/demo_generator.dart';
import 'package:everslot/features/habits/application/check_in_service.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/habit_service.dart';
import 'package:everslot/features/habits/application/quit_service.dart';
import 'package:everslot/features/habits/domain/check_in.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart' show DefaultSections, LogSource, VocabKind;
import 'package:everslot/features/habits/domain/quit.dart' show decimalOf;
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final demoServiceProvider = Provider<DemoService>(DemoService.new);

/// Whether sample data is on this device.
final demoPresentProvider = FutureProvider.autoDispose<bool>(
  (ref) async => (await DemoStore(ref.watch(appDatabaseProvider)).read()).isNotEmpty,
);

/// Sample data (T8.3.16): six months of plans, lists, habits and a quit tracker, written through
/// the regular services so every screen and statistic sees ordinary data. Offered only in
/// local-only mode (nothing reaches a cloud account); removed in one tap.
class DemoService {
  DemoService(this._ref);

  final Ref _ref;

  DemoStore get _store => DemoStore(_ref.read(appDatabaseProvider));

  /// Sample data stays on this device: refused for cloud accounts.
  bool get allowed => _ref.read(sessionProvider)?.mode == SessionMode.localOnly;

  DemoTexts texts(AppLocalizations l) {
    List<DemoNode> nodes(List<NodeSpec> specs) => [
      for (final n in specs) DemoNode(n.text, children: nodes(n.children)),
    ];
    final lists = [
      for (final t in [BuiltinTemplates.groceries, BuiltinTemplates.movingHouse, BuiltinTemplates.projectKickoff])
        () {
          final parsed = t.parse(l.localeName);
          return (title: parsed.title ?? t.code, nodes: nodes(parsed.nodes));
        }(),
    ];
    return DemoTexts(
      tasks: {
        'standup': l.demoTaskStandup,
        'deepWork': l.demoTaskDeepWork,
        'gym': l.demoTaskGym,
        'emails': l.demoTaskEmails,
        'planWeek': l.demoTaskPlanWeek,
        'callParents': l.demoTaskCallParents,
        'dentist': l.demoTaskDentist,
        'groceries': l.demoTaskGroceries,
        'laundry': l.demoTaskLaundry,
        'review': l.demoTaskReview,
      },
      lists: lists,
      habits: {
        'water': l.habitsTplWater,
        'meditate': l.habitsTplMeditate,
        'read': l.habitsTplRead,
        'walk': l.habitsTplWalk,
        'pushUps': l.habitsTplPushUps,
      },
      quitName: l.quitNameCigarettes,
      cravingTriggers: const [],
    );
  }

  /// Generates and writes the sample data; returns the dataset written.
  Future<DemoDataset> generate({int seed = 42, void Function(double progress)? onProgress}) async {
    if (!allowed) throw StateError('Sample data is only available in local-only mode');
    final zones = _ref.read(zoneResolverProvider);
    final zone = _ref.read(deviceZoneProvider);
    final today = zones.toLocal(_ref.read(clockProvider).nowUtc(), zone).date;
    final l10n = _ref.read(plannerL10nProvider);
    final vocab = await _ref.read(habitVocabRepositoryProvider).watchAll().first;
    final base = texts(l10n);
    final data = DemoGenerator.generate(
      seed: seed,
      today: today,
      texts: DemoTexts(
        tasks: base.tasks,
        lists: base.lists,
        habits: base.habits,
        quitName: base.quitName,
        cravingTriggers: [
          for (final v in vocab)
            if (v.kind == VocabKind.trigger) v.id,
        ],
      ),
    );
    DateTime utc(LocalDateTime t) => zones.resolve(t, zone).utc;
    final created = <String, List<String>>{'tasks': [], 'checklists': [], 'habits': []};
    final total = data.tasks.length + data.lists.length + data.habits.length + 1;
    var done = 0;
    void step() => onProgress?.call(++done / total);

    final categories = {for (final c in await _ref.read(categoriesRepositoryProvider).all()) c.id};
    final user = _ref.read(currentUserIdProvider);
    final planner = _ref.read(plannerServiceProvider);
    for (final t in data.tasks) {
      final category = t.categoryKey == null ? null : Ids.defaultCategory(user, t.categoryKey!);
      final result = await planner.createTask(
        Task(
          id: '',
          seriesId: '',
          title: t.title,
          startLocal: t.start,
          durationMinutes: t.durationMinutes,
          timeZone: zone,
          recurrence: t.rule,
          priority: t.priority,
          categoryId: categories.contains(category) ? category : null,
        ),
        source: 'demo',
      );
      created['tasks']!.add(result.taskId);
      await _ref.read(occurrencesRepositoryProvider).importHistory(result.taskId, [
        for (final h in t.history)
          (key: h.key, status: h.status, actualStart: utc(h.start), at: utc(h.start.plusMinutes(t.durationMinutes))),
      ], source: 'demo');
      step();
    }

    final lists = _ref.read(checklistsRepositoryProvider);
    for (final l in data.lists) {
      List<NodeSpec> specs(List<DemoNode> nodes) => [
        for (final n in nodes) NodeSpec(text: n.text, status: n.status, children: specs(n.children)),
      ];
      final c = await lists.create(title: l.title, items: specs(l.nodes));
      created['checklists']!.add(c.id);
      step();
    }

    final sections = _ref.read(habitSectionsRepositoryProvider);
    for (final h in data.habits) {
      final habit = BuildHabit(
        id: Ids.v7(),
        name: h.name,
        startDate: h.start ?? today,
        sortKey: '',
        goal: h.preset.adaptGoal(h.goal),
        schedule: h.preset.toRule(weekStart: _ref.read(userPreferencesProvider).weekStart),
        sectionId: sections.defaultId(DefaultSections.anytime),
      );
      await _ref.read(habitServiceProvider).create(habit);
      created['habits']!.add(habit.id);
      await _ref.read(checkInServiceProvider).importHistory(habit, [
        for (final d in h.days) (date: d.date, state: d.value == null ? CheckInState.done : null, value: d.value),
      ]);
      step();
    }

    final q = data.quit;
    final quit = QuitHabit(
      id: Ids.v7(),
      name: q.name,
      startDate: q.quitAt.date,
      sortKey: '',
      mode: QuitMode.abstain,
      quitStartedAt: utc(q.quitAt),
      substance: QuitSubstance.cigarettes,
      baselinePerDay: 12,
      unitCost: decimalOf(0.55),
      timePerUnitMinutes: 5,
      lifeMinutesPerUnit: 20,
      unit: 'cigarettes',
      icon: 'smoke_free',
      sectionId: sections.defaultId(DefaultSections.anytime),
    );
    await _ref.read(habitServiceProvider).create(quit);
    created['habits']!.add(quit.id);
    final quitService = _ref.read(quitServiceProvider);
    for (final at in q.relapses) {
      await quitService.logRelapse(quit, at: utc(at), amount: 2, source: LogSource.import);
    }
    for (final c in q.cravings) {
      await quitService.logCraving(
        quit,
        at: utc(c.at),
        input: CravingInput(intensity: c.intensity, trigger: c.trigger, resisted: c.resisted),
        source: LogSource.import,
      );
    }
    step();
    await _store.write(created);
    return data;
  }

  /// Deletes everything [generate] created (into the trash, like any delete).
  Future<void> remove() async {
    final ids = await _store.read();
    final planner = _ref.read(plannerServiceProvider);
    for (final id in ids['tasks'] ?? const <String>[]) {
      await planner.deleteTask(id);
    }
    final lists = _ref.read(checklistsRepositoryProvider);
    for (final id in ids['checklists'] ?? const <String>[]) {
      await lists.delete(id);
    }
    final habits = _ref.read(habitServiceProvider);
    for (final id in ids['habits'] ?? const <String>[]) {
      await habits.delete(id);
    }
    await _store.clear();
  }
}
