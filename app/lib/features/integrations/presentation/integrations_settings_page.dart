import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/integrations/presentation/ics_ui.dart';
import 'package:everslot/features/widgets_home/presentation/widgets_settings_section.dart';
import 'package:material_ui/material_ui.dart';

/// Settings › Widgets & integrations (8.2): one section per integration.
class IntegrationsSettingsPage extends StatelessWidget {
  const IntegrationsSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.settingsIntegrations)),
    body: ListView(children: const [WidgetsSettingsSection(), IcsSettingsSection()]),
  );
}
