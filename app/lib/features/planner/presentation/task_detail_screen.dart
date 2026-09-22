import 'package:everslot/design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

/// Placeholder — implemented by its feature section (see docs/tasks_section_*.md).
class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({required this.taskId, this.occurrenceKey, super.key});

  final String taskId;
  final String? occurrenceKey;

  @override
  Widget build(BuildContext context) => PlaceholderScreen(title: 'Task');
}
