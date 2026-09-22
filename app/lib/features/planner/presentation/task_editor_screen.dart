import 'package:everslot/design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

/// Placeholder — implemented by its feature section (see docs/tasks_section_*.md).
class TaskEditorScreen extends StatelessWidget {
  const TaskEditorScreen({this.taskId, this.initialStart, this.initialDurationMinutes, this.allDay = false, super.key});

  final String? taskId;
  final String? initialStart;
  final int? initialDurationMinutes;
  final bool allDay;

  @override
  Widget build(BuildContext context) => PlaceholderScreen(title: 'Task');
}
