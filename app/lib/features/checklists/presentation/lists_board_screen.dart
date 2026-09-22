import 'package:everslot/app/widgets/app_bar_actions.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

/// Placeholder — implemented by its feature section (see docs/tasks_section_*.md).
class ListsBoardScreen extends StatelessWidget {
  const ListsBoardScreen({super.key});


  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.tabLists), actions: const [AppBarActions()]),
    body: EmptyState(icon: Icons.construction, title: context.l10n.tabLists, message: context.l10n.placeholderScreen),
  );
}
