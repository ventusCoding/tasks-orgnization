import 'dart:async';

import 'package:everslot/app/quick_add_sheet.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/habits/presentation/habit_routes.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/quick_parse.dart';
import 'package:everslot/features/search/domain/command_matching.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

enum CommandGroup { create, navigate, action }

/// One palette entry (T8.1.18). [run] receives the context that opened the palette (the palette
/// itself is closed first).
class PaletteCommand {
  const PaletteCommand({
    required this.id,
    required this.title,
    required this.group,
    required this.icon,
    required this.run,
    this.keywords = const [],
  });

  final String id;
  final String title;
  final CommandGroup group;
  final IconData icon;
  final List<String> keywords;
  final Future<void> Function(BuildContext context) run;
}

/// Opens the command palette (T8.1.18): from search (`>` or the palette button) and with
/// Ctrl/⌘ + K on hardware keyboards.
Future<void> showCommandPalette(BuildContext context, {String initialQuery = ''}) => showAppSheet<void>(
  context,
  title: context.l10n.paletteTitle,
  builder: (_) => CommandPalette(host: context, initialQuery: initialQuery),
);

class CommandPalette extends ConsumerStatefulWidget {
  const CommandPalette({required this.host, this.initialQuery = '', super.key});

  /// Context the commands run in (outlives the sheet).
  final BuildContext host;
  final String initialQuery;

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  late final _query = TextEditingController(text: widget.initialQuery);

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _run(PaletteCommand c) async {
    Navigator.pop(context);
    final host = widget.host;
    if (host.mounted) await c.run(host);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // Subscribed so the pause / resume entry reflects the current state.
    ref.watch(notificationSettingsProvider);
    final commands = paletteCommands(context, ref, _query.text);
    final matches = CommandMatching.rank(_query.text, commands, title: (c) => c.title, keywords: (c) => c.keywords);
    String group(CommandGroup g) => switch (g) {
      CommandGroup.create => l.paletteGroupCreate,
      CommandGroup.navigate => l.paletteGroupGo,
      CommandGroup.action => l.paletteGroupActions,
    };
    // Keep the groups together, in ranked order of their best entry.
    final ordered = <PaletteCommand>[
      for (final g in {for (final c in matches) c.group}) ...matches.where((c) => c.group == g),
    ];
    // showAppSheet already lifts the sheet above the keyboard.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
          child: TextField(
            key: const ValueKey('palette-field'),
            controller: _query,
            autofocus: true,
            textInputAction: TextInputAction.go,
            decoration: InputDecoration(prefixIcon: const Icon(Icons.keyboard_command_key), hintText: l.paletteHint),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (ordered.isNotEmpty) unawaited(_run(ordered.first));
            },
          ),
        ),
        const SizedBox(height: Space.sm),
        if (ordered.isEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.all(Space.lg),
            child: Text(l.paletteNoMatch, textAlign: TextAlign.center),
          )
        else
          Flexible(
            child: ListView(
              key: const ValueKey('palette-list'),
              shrinkWrap: true,
              children: [
                for (final (i, c) in ordered.indexed) ...[
                  if (i == 0 || ordered[i - 1].group != c.group) SectionHeader(group(c.group)),
                  ListTile(
                    key: ValueKey('palette-cmd-${c.id}'),
                    leading: Icon(c.icon),
                    title: Text(c.title),
                    onTap: () => unawaited(_run(c)),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Every palette command for [query] (the *New task “…” at …* entry appears when the query reads
/// as a dated task).
List<PaletteCommand> paletteCommands(BuildContext context, WidgetRef ref, String query) {
  final l = context.l10n;
  final prefs = ref.read(userPreferencesProvider);
  final zones = ref.read(zoneResolverProvider);
  final zone = ref.read(deviceZoneProvider);
  final nowUtc = ref.read(clockProvider).nowUtc();
  final now = zones.toLocal(nowUtc, zone);
  final today = now.date;
  final fmt = AppFormat(context.localeName, use24h: prefs.use24h, l10n: l);

  Future<void> go(BuildContext c, String link) async => GoRouter.of(c).go(link);
  Future<void> push(BuildContext c, String link) async => unawaited(GoRouter.of(c).push(link));
  Future<void> pause(BuildContext c, DateTime? until) async {
    await ref.read(notificationSettingsWriterProvider)({'pausedUntil': until?.toIso8601String()});
    if (c.mounted) showInfoSnackBar(c, until == null ? l.paletteResumed : l.palettePaused);
  }

  PaletteCommand nav(String id, String title, IconData icon, String link, {List<String> keywords = const []}) =>
      PaletteCommand(
        id: id,
        title: title,
        group: CommandGroup.navigate,
        icon: icon,
        keywords: keywords,
        run: (c) => go(c, link),
      );

  final parsed = query.trim().isEmpty ? null : QuickParser.parse(query, now: now, weekStart: prefs.weekStart);
  final datedTask = parsed != null && parsed.date != null && parsed.title.isNotEmpty;
  final paused = ref.read(notificationSettingsProvider).pausedUntil?.isAfter(nowUtc) ?? false;

  return [
    if (datedTask)
      PaletteCommand(
        id: 'new_task_at',
        title: l.paletteNewTaskAt(
          parsed.title,
          parsed.time == null || parsed.allDay
              ? fmt.dateMedium(parsed.date!)
              : '${fmt.dateMedium(parsed.date!)} ${fmt.timeOf(LocalDateTime(parsed.date!, parsed.time!))}',
        ),
        group: CommandGroup.create,
        icon: Icons.add_task,
        // Always matches: it is built from the query itself.
        keywords: [query],
        run: (c) async {
          await ref
              .read(plannerServiceProvider)
              .createAt(
                LocalDateTime(parsed.date!, parsed.time ?? LocalTime(9, 0)),
                parsed.durationMinutes ?? ref.read(plannerSettingsProvider).defaultTaskDurationMinutes,
                title: parsed.title,
                allDay: parsed.allDay,
                recurrence: parsed.rule,
                priority: parsed.priority?.index ?? 0,
              );
          if (c.mounted) showInfoSnackBar(c, l.quickAddAdded(parsed.title));
        },
      ),
    PaletteCommand(
      id: 'new_task',
      title: l.paletteNewTask,
      group: CommandGroup.create,
      icon: Icons.add_task,
      keywords: const ['add', 'create', 'todo', 'ajouter', 'creer', 'tache'],
      run: showQuickAdd,
    ),
    PaletteCommand(
      id: 'new_list',
      title: l.paletteNewList,
      group: CommandGroup.create,
      icon: Icons.playlist_add,
      keywords: const ['checklist', 'liste'],
      run: (c) => showQuickAdd(c, initial: const QuickAddContext(type: QuickAddType.list)),
    ),
    PaletteCommand(
      id: 'new_habit',
      title: l.paletteNewHabit,
      group: CommandGroup.create,
      icon: Icons.repeat,
      keywords: const ['routine', 'habitude'],
      run: HabitRoutes.create,
    ),
    PaletteCommand(
      id: 'new_quit',
      title: l.paletteNewQuit,
      group: CommandGroup.create,
      icon: Icons.smoke_free,
      keywords: const ['stop', 'arreter', 'addiction'],
      run: (c) => HabitRoutes.create(c, kind: 'quit'),
    ),
    nav('today', l.paletteGoToday, Icons.wb_sunny_outlined, AppLinks.today(), keywords: const ['home', 'accueil']),
    nav(
      'week',
      l.paletteGoThisWeek,
      Icons.calendar_view_week,
      AppLinks.planWeek(date: today.toString()),
      keywords: const ['plan', 'calendar', 'agenda', 'semaine'],
    ),
    nav(
      'next_week',
      l.paletteGoNextWeek,
      Icons.arrow_forward,
      AppLinks.planWeek(date: today.plusDays(7).toString()),
      keywords: const ['plan', 'calendar', 'semaine prochaine'],
    ),
    nav(
      'previous_week',
      l.paletteGoPreviousWeek,
      Icons.arrow_back,
      AppLinks.planWeek(date: today.plusDays(-7).toString()),
      keywords: const ['plan', 'last week', 'semaine derniere'],
    ),
    nav(
      'day',
      l.paletteGoDay,
      Icons.view_day_outlined,
      AppLinks.planDay(date: today.toString()),
      keywords: const ['jour'],
    ),
    nav('lists', l.paletteGoLists, Icons.checklist, AppLinks.lists(), keywords: const ['checklists', 'listes']),
    nav(
      'habits',
      l.paletteGoHabits,
      Icons.local_fire_department_outlined,
      AppLinks.habits(),
      keywords: const ['habitudes'],
    ),
    nav(
      'insights',
      l.paletteGoInsights,
      Icons.insights,
      AppLinks.insights(),
      keywords: const ['stats', 'statistiques'],
    ),
    for (final (scope, label) in [('planner', l.tabPlan), ('checklists', l.tabLists), ('habits', l.tabHabits)])
      PaletteCommand(
        id: 'insights_$scope',
        title: l.paletteGoInsightsScope(label),
        group: CommandGroup.navigate,
        icon: Icons.insights,
        keywords: const ['stats', 'statistiques'],
        run: (c) => push(c, AppLinks.insightsScope(scope)),
      ),
    PaletteCommand(
      id: 'inbox',
      title: l.paletteGoInbox,
      group: CommandGroup.navigate,
      icon: Icons.notifications_none,
      keywords: const ['notifications', 'boite'],
      run: (c) => push(c, AppLinks.inbox()),
    ),
    PaletteCommand(
      id: 'search',
      title: l.paletteGoSearch,
      group: CommandGroup.navigate,
      icon: Icons.search,
      keywords: const ['find', 'chercher', 'rechercher'],
      run: (c) => push(c, AppLinks.search()),
    ),
    PaletteCommand(
      id: 'settings',
      title: l.paletteGoSettings,
      group: CommandGroup.navigate,
      icon: Icons.settings_outlined,
      keywords: const ['preferences', 'parametres', 'reglages'],
      run: (c) => push(c, AppLinks.settings()),
    ),
    PaletteCommand(
      id: 'settings_notifications',
      title: l.paletteGoNotificationSettings,
      group: CommandGroup.navigate,
      icon: Icons.notifications_active_outlined,
      keywords: const ['reminders', 'rappels'],
      run: (c) => push(c, AppLinks.settings('notifications')),
    ),
    PaletteCommand(
      id: 'trash',
      title: l.paletteGoTrash,
      group: CommandGroup.navigate,
      icon: Icons.delete_outline,
      keywords: const ['deleted', 'restore', 'corbeille', 'restaurer'],
      run: (c) => push(c, AppLinks.trash()),
    ),
    PaletteCommand(
      id: 'categories',
      title: l.paletteGoCategories,
      group: CommandGroup.navigate,
      icon: Icons.label_outline,
      keywords: const ['categories'],
      run: (c) => push(c, AppLinks.categories()),
    ),
    PaletteCommand(
      id: 'tags',
      title: l.paletteGoTags,
      group: CommandGroup.navigate,
      icon: Icons.sell_outlined,
      keywords: const ['etiquettes'],
      run: (c) => push(c, AppLinks.tags()),
    ),
    if (paused)
      PaletteCommand(
        id: 'resume',
        title: l.paletteResume,
        group: CommandGroup.action,
        icon: Icons.notifications_active_outlined,
        keywords: const ['unmute', 'notifications', 'reprendre'],
        run: (c) => pause(c, null),
      )
    else ...[
      PaletteCommand(
        id: 'pause_1h',
        title: l.palettePause1h,
        group: CommandGroup.action,
        icon: Icons.notifications_paused_outlined,
        keywords: const ['mute', 'silence', 'dnd', 'snooze', 'notifications'],
        run: (c) => pause(c, nowUtc.add(const Duration(hours: 1))),
      ),
      PaletteCommand(
        id: 'pause_tomorrow',
        title: l.palettePauseTomorrow,
        group: CommandGroup.action,
        icon: Icons.bedtime_outlined,
        keywords: const ['mute', 'silence', 'dnd', 'notifications', 'demain'],
        run: (c) => pause(c, zones.resolve(LocalDateTime(today.plusDays(1), LocalTime(8, 0)), zone).utc),
      ),
    ],
    if (ref.read(syncServiceProvider) case final sync?)
      PaletteCommand(
        id: 'sync',
        title: l.paletteSyncNow,
        group: CommandGroup.action,
        icon: Icons.sync,
        keywords: const ['refresh', 'synchroniser', 'actualiser'],
        run: (c) => sync.syncNow(manual: true),
      ),
    PaletteCommand(
      id: 'undo',
      title: l.actionUndo,
      group: CommandGroup.action,
      icon: Icons.undo,
      keywords: const ['annuler', 'revert'],
      run: (c) async => ref.read(undoStackProvider).undo(),
    ),
  ];
}

/// Ctrl/⌘ + K opens the palette (tablets and desktops with a keyboard).
class PaletteShortcut extends StatelessWidget {
  const PaletteShortcut({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    void open() => unawaited(showCommandPalette(context));
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): open,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): open,
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}
