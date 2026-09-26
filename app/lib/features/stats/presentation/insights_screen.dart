import 'package:everslot/app/widgets/app_bar_actions.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

/// Placeholder — implemented by its feature section (see docs/tasks_section_*.md).
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.tabInsights), actions: const [AppBarActions()]),
    body: EmptyState(
      icon: Icons.construction,
      title: context.l10n.tabInsights,
      message: context.l10n.placeholderScreen,
    ),
  );
}
