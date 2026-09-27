import 'dart:async';

import 'package:everslot/features/integrations/application/integration_providers.dart';
import 'package:everslot/features/integrations/presentation/integrations_overlay.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _wired = Expando<bool>('integrations-startup');

/// Startup task (registered in `startup/startup_tasks.dart`, re-run after account switches):
/// external links, the UI overlay for integration events and — as later tasks land — widgets,
/// shortcuts, share intake, timers and health sync. Fast: everything starts unawaited.
Future<void> startIntegrations(ProviderContainer container) async {
  if (_wired[container] != true) {
    _wired[container] = true;
    IntegrationsOverlay.install(container);
  }
  unawaited(container.read(externalLinksServiceProvider).start());
}
