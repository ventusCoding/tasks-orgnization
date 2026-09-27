import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/features/integrations/application/external_links_service.dart';
import 'package:everslot/features/integrations/application/integration_events.dart';
import 'package:everslot/features/integrations/data/integration_queries.dart';
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

final linkCommandRegistryProvider = Provider<LinkCommandRegistry>((ref) => LinkCommandRegistry());

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
