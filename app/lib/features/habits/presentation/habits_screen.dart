import 'dart:async';

import 'package:everslot/app/widgets/app_bar_actions.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/presentation/calendar_views.dart';
import 'package:everslot/features/habits/presentation/habit_routes.dart';
import 'package:everslot/features/habits/presentation/manage_habits_screen.dart';
import 'package:everslot/features/habits/presentation/notes_journal_screen.dart';
import 'package:everslot/features/habits/presentation/pause_sheet.dart';
import 'package:everslot/features/habits/presentation/quit/live_counter.dart';
import 'package:everslot/features/habits/presentation/templates_sheet.dart';
import 'package:everslot/features/habits/presentation/today_view.dart';
import 'package:everslot/features/habits/presentation/week_matrix.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Views of the Habits tab.
enum HabitsView { today, week, month, year }

/// The Habits tab (T5.2.02): view switcher (Today · Week · Month · Year), quit-counter strip,
/// vacation banner, date navigator and filter for the Today list, and the **+** menu.
class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> with WidgetsBindingObserver {
  HabitsView _view = HabitsView.today;
  LocalDate? _date;

  /// `all`, `due` or a section id.
  String _filter = 'all';
  Timer? _minute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Time-based statuses (slots closing, the day ending) re-evaluate every minute while visible.
    _minute = Timer.periodic(const Duration(minutes: 1), (_) => ref.read(habitTickProvider.notifier).bump());
    unawaited(_restore());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _minute?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.read(habitTickProvider.notifier).bump();
  }

  Future<void> _restore() async {
    final store = ref.read(habitUiStoreProvider);
    final view = await store.read('view');
    final filter = await store.read('filter');
    if (!mounted) return;
    setState(() {
      _view = HabitsView.values.where((v) => v.name == view).firstOrNull ?? _view;
      _filter = filter ?? _filter;
    });
  }

  void _setView(HabitsView v) {
    setState(() => _view = v);
    unawaited(ref.read(habitUiStoreProvider).write('view', v.name));
  }

  void _setFilter(String f) {
    setState(() => _filter = f);
    unawaited(ref.read(habitUiStoreProvider).write('filter', f));
  }

  Future<void> _add() async {
    final l = context.l10n;
    final choice = await showAppSheet<String>(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.add_task),
            title: Text(l.habitsNewHabit),
            onTap: () => Navigator.pop(ctx, 'build'),
          ),
          ListTile(
            leading: const Icon(Icons.smoke_free),
            title: Text(l.habitsNewQuit),
            onTap: () => Navigator.pop(ctx, 'quit'),
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome_outlined),
            title: Text(l.habitsFromTemplate),
            onTap: () => Navigator.pop(ctx, 'template'),
          ),
        ],
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'template') {
      await showTemplatesSheet(context);
      return;
    }
    await HabitRoutes.create(context, kind: choice);
  }

  Future<void> _menu(String value) async {
    switch (value) {
      case 'manage':
        await Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => const ManageHabitsScreen()));
      case 'journal':
        await Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => const NotesJournalScreen()));
      case 'vacation':
        await showPauseSheet(context, ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final today = ref.watch(habitTodayProvider);
    final date = _date ?? today;
    final habits = ref.watch(habitsProvider).value;
    final vacation = ref.watch(vacationProvider);
    final sections = ref.watch(habitSectionsProvider).value ?? const <HabitSection>[];
    final fmt = AppFormat(context.localeName);
    final hasBuild = habits?.any((h) => h is BuildHabit) ?? false;
    final hasAny = habits?.isNotEmpty ?? false;

    Widget body;
    if (habits != null && !hasAny) {
      body = EmptyState(
        icon: Icons.self_improvement,
        title: l.habitsEmptyTitle,
        message: l.habitsEmptyBody,
        actionLabel: l.habitsEmptyAction,
        onAction: () => unawaited(HabitRoutes.create(context)),
      );
    } else {
      body = switch (_view) {
        HabitsView.today => Column(
          children: [
            _DateNavigator(
              date: date,
              today: today,
              onChanged: (d) => setState(() => _date = d),
              label: date == today ? l.habitsToday : fmt.dayLong(date),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
                children: [
                  for (final f in [('all', l.habitsFilterAll), ('due', l.habitsFilterDue)])
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: Space.sm),
                      child: ChoiceChip(label: Text(f.$2), selected: _filter == f.$1, onSelected: (_) => _setFilter(f.$1)),
                    ),
                  for (final s in sections)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: Space.sm),
                      child: ChoiceChip(
                        label: Text(s.name),
                        selected: _filter == s.id,
                        onSelected: (_) => _setFilter(s.id),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: hasBuild
                  ? TodayList(
                      date: date,
                      dueOnly: _filter == 'due',
                      sectionFilter: _filter == 'all' || _filter == 'due' ? null : _filter,
                    )
                  : EmptyState(icon: Icons.add_task, title: l.habitsNoBuildHabits, message: l.habitsEmptyBody),
            ),
          ],
        ),
        HabitsView.week => WeekMatrix(endDate: today),
        HabitsView.month => MonthOverview(initialMonth: date),
        HabitsView.year => const HabitsYearView(),
      };
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.tabHabits),
        actions: [
          const AppBarActions(),
          PopupMenuButton<String>(
            tooltip: l.actionMore,
            onSelected: (v) => unawaited(_menu(v)),
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'manage', child: Text(l.habitsManage)),
              PopupMenuItem(value: 'journal', child: Text(l.habitsJournal)),
              PopupMenuItem(value: 'vacation', child: Text(l.habitsVacationTitle)),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.sm),
            child: SegmentedButton<HabitsView>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: HabitsView.today, label: Text(l.habitsViewToday)),
                ButtonSegment(value: HabitsView.week, label: Text(l.habitsViewWeek)),
                ButtonSegment(value: HabitsView.month, label: Text(l.habitsViewMonth)),
                ButtonSegment(value: HabitsView.year, label: Text(l.habitsViewYear)),
              ],
              selected: {_view},
              onSelectionChanged: (s) => _setView(s.first),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l.habitsAdd,
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (vacation != null && !vacation.start.isAfter(today)) PauseBanner(pause: vacation),
          const QuitStrip(),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({required this.date, required this.today, required this.onChanged, required this.label});

  final LocalDate date;
  final LocalDate today;
  final ValueChanged<LocalDate> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Row(
      children: [
        IconButton(
          tooltip: l.habitsPrevDay,
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onChanged(date.minusDays(1)),
        ),
        Expanded(
          child: TextButton(
            onPressed: () async {
              final picked = await pickDate(context, initial: date);
              if (picked != null) onChanged(picked);
            },
            child: Text(label, style: context.text.titleSmall),
          ),
        ),
        if (date != today)
          TextButton(onPressed: () => onChanged(today), child: Text(l.habitsToday)),
        IconButton(
          tooltip: l.habitsNextDay,
          icon: const Icon(Icons.chevron_right),
          onPressed: () => onChanged(date.plusDays(1)),
        ),
      ],
    );
  }
}
