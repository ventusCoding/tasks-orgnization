import 'package:everslot/design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

/// Placeholder — implemented by its feature section (see docs/tasks_section_*.md).
class HabitEditorScreen extends StatelessWidget {
  const HabitEditorScreen({this.habitId, this.kind = 'build', super.key});

  final String? habitId;
  final String kind;

  @override
  Widget build(BuildContext context) => PlaceholderScreen(title: 'Habit');
}
