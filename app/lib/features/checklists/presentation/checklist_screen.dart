import 'package:everslot/design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

/// Placeholder — implemented by its feature section (see docs/tasks_section_*.md).
class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({required this.checklistId, this.focusItemId, this.preview = false, super.key});

  final String checklistId;
  final String? focusItemId;
  final bool preview;

  @override
  Widget build(BuildContext context) => PlaceholderScreen(title: 'Checklist');
}
