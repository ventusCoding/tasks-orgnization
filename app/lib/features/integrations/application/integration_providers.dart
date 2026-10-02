import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/features/integrations/application/app_shortcuts_service.dart';
import 'package:everslot/features/integrations/application/external_links_service.dart';
import 'package:everslot/features/integrations/application/integration_commands.dart';
import 'package:everslot/features/integrations/application/integration_events.dart';
import 'package:everslot/features/integrations/application/share_intake_service.dart';
import 'package:everslot/features/integrations/data/integration_queries.dart';
import 'package:everslot/features/integrations/data/quick_actions_source.dart';
import 'package:everslot/features/integrations/data/share_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Integrations application providers (manual Riverpod providers, dev_patterns §3).

final integrationQueriesProvider = Provider<IntegrationQueries>(
  (ref) => IntegrationQueries(ref.watch(appDatabaseProvider), () => ref.read(currentUserIdProvider)),
);

/// UI work requested by integrations (navigation, notices, sheets) — consumed by the
/// `IntegrationsOverlay` (presentation); buffered until it listens.
final integrationUiEventsProvider = Provider<BufferedEventBus<IntegrationUiEvent>>((ref) {
  final bus = BufferedEventBus<IntegrationUiEvent>();
  ref.onDispose(() => unawaited(bus.close()));
  return bus;
});

/// Source of external links (override with a fake in tests).
final linkSourceProvider = Provider<LinkSource>((ref) => AppLinksSource());

final linkCommandRegistryProvider = Provider<LinkCommandRegistry>((ref) {
  final registry = LinkCommandRegistry();
  IntegrationCommands.registerAll(ref, registry, ref.watch(integrationUiEventsProvider));
  return registry;
});

/// Platform app shortcuts (override with a fake in tests).
final shortcutPlatformProvider = Provider<ShortcutPlatform>((ref) => QuickActionsShortcutPlatform());

/// App icon shortcuts (T8.2.06).
final appShortcutsServiceProvider = Provider<AppShortcutsService>(
  (ref) => AppShortcutsService(ref.watch(shortcutPlatformProvider), ref.watch(externalLinksServiceProvider)),
);

/// External links (T8.2.01).
final externalLinksServiceProvider = Provider<ExternalLinksService>((ref) {
  final service = ExternalLinksService(
    source: ref.watch(linkSourceProvider),
    queries: ref.watch(integrationQueriesProvider),
    events: ref.watch(integrationUiEventsProvider),
    clock: ref.watch(clockProvider),
    commands: ref.watch(linkCommandRegistryProvider),
  );
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

/// Source of shared content (override with a fake in tests).
final shareSourceProvider = Provider<ShareSource>((ref) => ReceiveSharingIntentSource());

/// Share into Everslot (T8.2.07).
final shareIntakeServiceProvider = Provider<ShareIntakeService>((ref) {
  final service = ShareIntakeService(ref, ref.watch(shareSourceProvider), ref.watch(integrationUiEventsProvider));
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});
