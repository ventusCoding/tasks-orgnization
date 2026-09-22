import 'package:everslot/app/widgets/app_bar_actions.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

/// Placeholder — implemented by its feature section (see docs/tasks_section_*.md).
class PlannerScreen extends StatelessWidget {
  const PlannerScreen({this.view = 'week_table', this.date, super.key});

  final String view;
  final String? date;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.tabPlan), actions: const [AppBarActions()]),
    body: EmptyState(icon: Icons.construction, title: context.l10n.tabPlan, message: context.l10n.placeholderScreen),
  );
}
