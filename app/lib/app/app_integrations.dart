import 'package:everslot/app/quick_add_sheet.dart';
import 'package:everslot/features/integrations/application/integration_events.dart';
import 'package:everslot/features/integrations/presentation/integrations_overlay.dart';

/// App-level UI for integration events that live outside features (the universal quick add).
void registerAppIntegrations() {
  IntegrationsOverlay.handlers[QuickAddUiEvent] = (context, container, event) async {
    final title = (event as QuickAddUiEvent).title;
    await showQuickAdd(context, initial: QuickAddContext(title: title));
  };
}
