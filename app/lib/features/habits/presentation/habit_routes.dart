import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/features/habits/presentation/habit_detail_screen.dart';
import 'package:everslot/features/habits/presentation/habit_editor_screen.dart';
import 'package:everslot/features/habits/presentation/habit_ui.dart';
import 'package:everslot/features/habits/presentation/quit_dashboard_screen.dart';
import 'package:material_ui/material_ui.dart';

/// Deep-link aware navigation to habit screens (`AppLinks.habit/quit/habitNew/habitEdit`).
abstract final class HabitRoutes {
  static Future<void> detail(BuildContext context, String id) =>
      HabitNav.push(context, AppLinks.habit(id), (_) => HabitDetailScreen(habitId: id));

  static Future<void> quit(BuildContext context, String id) =>
      HabitNav.push(context, AppLinks.quit(id), (_) => QuitDashboardScreen(habitId: id));

  static Future<void> create(BuildContext context, {String kind = 'build', String? template}) {
    if (template != null) {
      // Templates are an in-app flow (the route has no template parameter).
      return Navigator.of(context).push<void>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => HabitEditorScreen(kind: kind, template: template),
        ),
      );
    }
    return HabitNav.push(context, AppLinks.habitNew(kind: kind), (_) => HabitEditorScreen(kind: kind));
  }

  static Future<void> edit(BuildContext context, String id) =>
      HabitNav.push(context, AppLinks.habitEdit(id), (_) => HabitEditorScreen(habitId: id));
}
