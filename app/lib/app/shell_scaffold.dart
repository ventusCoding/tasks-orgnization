import 'dart:async';

import 'package:everslot/app/command_palette.dart';
import 'package:everslot/app/quick_add_sheet.dart';
import 'package:everslot/core/preferences/last_tab.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/habits/application/habit_day_view.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Tab badge counts (T1.3.12), by branch index. Habits: habits still due today.
final tabBadgesProvider = Provider<List<int>>((ref) {
  final habits = ref.watch(habitDayViewsProvider(ref.watch(habitTodayProvider))).value ?? const [];
  return [0, 0, 0, habits.where((v) => v.group == DayGroup.due).length, 0];
});

/// The 5-tab shell (T1.3.06, T1.3.12): bottom bar on phones, navigation rail from 600 dp, tab
/// badges, a contextual + (long-press = quick add), Android back through the tab history, the
/// last tab remembered, and a bottom bar that hides while scrolling content down.
class ShellScaffold extends ConsumerStatefulWidget {
  const ShellScaffold({required this.shell, super.key});

  final StatefulNavigationShell shell;

  /// Tabs whose + creates a task (the other tabs bring their own action, Insights has none).
  static const taskTabs = {0, 1};

  @override
  ConsumerState<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends ConsumerState<ShellScaffold> {
  /// Previously visited tabs, most recent last (Android back walks it before exiting).
  final _history = <int>[];
  bool _barVisible = true;

  StatefulNavigationShell get _shell => widget.shell;

  void _go(int index) {
    final current = _shell.currentIndex;
    if (index != current) {
      _history
        ..remove(index)
        ..add(current);
      unawaited(LastTab.save(ref.read(appDatabaseProvider), index).catchError((Object _) {}));
    }
    setState(() => _barVisible = true);
    // Re-selecting the current tab returns to its root.
    _shell.goBranch(index, initialLocation: index == current);
  }

  void _back() {
    if (_history.isEmpty) return;
    final previous = _history.removeLast();
    setState(() => _barVisible = true);
    _shell.goBranch(previous);
  }

  bool _onScroll(UserScrollNotification n) {
    // The planner grid scrolls all the time: its bar stays put.
    if (n.metrics.axis != Axis.vertical || _shell.currentIndex == 1) return false;
    final visible = switch (n.direction) {
      ScrollDirection.reverse => false,
      ScrollDirection.forward => true,
      ScrollDirection.idle => _barVisible,
    };
    if (visible != _barVisible) setState(() => _barVisible = visible);
    return false;
  }

  /// Long press on **+**: the universal quick add (T8.1.10).
  Future<void> _quickAdd() async {
    unawaited(HapticFeedback.mediumImpact());
    await showQuickAdd(context);
  }

  Widget? _fab({bool small = false}) {
    if (!ShellScaffold.taskTabs.contains(_shell.currentIndex)) return null;
    final l = context.l10n;
    void open() => unawaited(context.push(AppLinks.taskNew()));
    // No FAB tooltip of its own: its long-press would win over quick add. The manual Tooltip keeps
    // the label for screen readers and `find.byTooltip`.
    final button = small
        ? FloatingActionButton.small(heroTag: null, onPressed: open, child: const Icon(Icons.add))
        : FloatingActionButton(heroTag: null, onPressed: open, child: const Icon(Icons.add));
    return Semantics(
      customSemanticsActions: {CustomSemanticsAction(label: l.shellQuickAdd): _quickAdd},
      child: GestureDetector(
        key: const ValueKey('shell-fab'),
        onLongPress: _quickAdd,
        child: Tooltip(message: l.tasksEditorNewTitle, triggerMode: TooltipTriggerMode.manual, child: button),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final badges = ref.watch(tabBadgesProvider);
    final destinations = [
      (Icons.wb_sunny_outlined, Icons.wb_sunny, l.tabToday),
      (Icons.calendar_view_week_outlined, Icons.calendar_view_week, l.tabPlan),
      (Icons.checklist_outlined, Icons.checklist, l.tabLists),
      (Icons.local_fire_department_outlined, Icons.local_fire_department, l.tabHabits),
      (Icons.insights_outlined, Icons.insights, l.tabInsights),
    ];
    Widget icon(IconData data, int index) {
      final count = badges[index];
      return count > 0
          ? Badge(
              label: Text(CountBadge.format(count)),
              child: Icon(data, semanticLabel: l.shellDueCount(count)),
            )
          : Icon(data);
    }

    final size = context.windowSize;
    final body = PopScope(
      canPop: _history.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      // Ctrl/⌘ + K: command palette (T8.1.18).
      child: PaletteShortcut(
        child: NotificationListener<UserScrollNotification>(onNotification: _onScroll, child: _shell),
      ),
    );

    if (size != WindowSizeClass.compact) {
      final extended = size == WindowSizeClass.expanded;
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              right: false,
              child: NavigationRail(
                selectedIndex: _shell.currentIndex,
                onDestinationSelected: _go,
                extended: extended,
                labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                leading: _fab(small: !extended),
                destinations: [
                  for (final (i, d) in destinations.indexed)
                    NavigationRailDestination(icon: icon(d.$1, i), selectedIcon: icon(d.$2, i), label: Text(d.$3)),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }
    final bar = NavigationBar(
      selectedIndex: _shell.currentIndex,
      onDestinationSelected: _go,
      destinations: [
        for (final (i, d) in destinations.indexed)
          NavigationDestination(icon: icon(d.$1, i), selectedIcon: icon(d.$2, i), label: d.$3),
      ],
    );
    return Scaffold(
      body: body,
      floatingActionButton: _fab(),
      bottomNavigationBar: AnimatedSize(
        duration: context.reduceMotion ? Duration.zero : Motion.normal,
        curve: Motion.curve,
        child: _barVisible ? bar : const SizedBox(width: double.infinity),
      ),
    );
  }
}
