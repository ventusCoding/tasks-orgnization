import 'dart:async';
import 'dart:io';

import 'package:everslot/features/integrations/application/health_sync_service.dart';
import 'package:everslot/features/integrations/application/integration_events.dart';
import 'package:everslot/features/integrations/application/integration_providers.dart';
import 'package:everslot/features/integrations/presentation/ics_ui.dart';
import 'package:everslot/features/integrations/presentation/integrations_overlay.dart';
import 'package:everslot/features/integrations/presentation/share_intake_sheet.dart';
import 'package:everslot/features/planner/application/planner_service.dart' show plannerL10nProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _wired = Expando<bool>('integrations-startup');

/// Startup task (registered in `startup/startup_tasks.dart`, re-run after account switches):
/// external links, the UI overlay for integration events and — as later tasks land — widgets,
/// shortcuts, share intake, timers and health sync. Fast: everything starts unawaited.
Future<void> startIntegrations(ProviderContainer container) async {
  if (_wired[container] != true) {
    _wired[container] = true;
    IntegrationsOverlay.install(container);
    IntegrationsOverlay.handlers[ShareReceivedUiEvent] = (context, container, _) => showShareIntake(context);
    IntegrationsOverlay.handlers[IcsReceivedUiEvent] = (context, container, event) =>
        showIcsImport(context, (event as IcsReceivedUiEvent).content);
  }
  unawaited(container.read(externalLinksServiceProvider).start());
  if (Platform.isIOS || Platform.isAndroid) {
    unawaited(container.read(shareIntakeServiceProvider).start());
    startHealthSync(container);
    final shortcuts = container.read(appShortcutsServiceProvider);
    unawaited(shortcuts.start(container.read(plannerL10nProvider)));
    // Titles follow the app language.
    container.listen(plannerL10nProvider, (_, l10n) => unawaited(shortcuts.setTitles(l10n)));
  }
}
