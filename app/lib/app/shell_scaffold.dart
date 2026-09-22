import 'package:everslot/design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Bottom navigation (phones) / navigation rail (tablets) around the 5 tab branches (T1.3.12).
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({required this.shell, super.key});

  final StatefulNavigationShell shell;

  void _go(int index) => shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final destinations = [
      (Icons.wb_sunny_outlined, Icons.wb_sunny, l.tabToday),
      (Icons.calendar_view_week_outlined, Icons.calendar_view_week, l.tabPlan),
      (Icons.checklist_outlined, Icons.checklist, l.tabLists),
      (Icons.local_fire_department_outlined, Icons.local_fire_department, l.tabHabits),
      (Icons.insights_outlined, Icons.insights, l.tabInsights),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 840;
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _go,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: Text(d.$3)),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: shell),
          ],
        ),
      );
    }
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _go,
        destinations: [
          for (final d in destinations)
            NavigationDestination(icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: d.$3),
        ],
      ),
    );
  }
}
