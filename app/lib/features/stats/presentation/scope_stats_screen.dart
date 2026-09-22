import 'package:everslot/design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

/// Placeholder — implemented by its feature section (see docs/tasks_section_*.md).
class ScopeStatsScreen extends StatelessWidget {
  const ScopeStatsScreen({required this.scope, this.scopeId, super.key});

  final String scope;
  final String? scopeId;

  @override
  Widget build(BuildContext context) => PlaceholderScreen(title: 'Insights');
}
