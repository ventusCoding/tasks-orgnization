import 'dart:async';

import 'package:everslot/app/router.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/integrations/application/integration_events.dart';
import 'package:everslot/features/integrations/application/integration_providers.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Localized text of an integration notice.
String integrationNoticeText(AppLocalizations l, IntegrationNotice notice, String? detail) => switch (notice) {
  IntegrationNotice.linkNotFound => l.integrationsLinkNotFound,
  IntegrationNotice.inTrash => l.integrationsLinkInTrash,
  IntegrationNotice.actionFailed => l.integrationsActionFailed,
  IntegrationNotice.habitLogged => l.integrationsHabitLogged(detail ?? ''),
  IntegrationNotice.habitNotFound => l.integrationsHabitNotFound(detail ?? ''),
  IntegrationNotice.nothingNext => l.integrationsNothingNext,
  IntegrationNotice.cravingLogged => l.integrationsCravingLogged(detail ?? ''),
};

/// Performs the UI side of integrations (navigation, notices, share/ICS sheets) for the whole app.
/// Installed once by the integrations startup task; waits for the root navigator (links can
/// arrive before the first frame — they are buffered by the event bus meanwhile).
abstract final class IntegrationsOverlay {
  static StreamSubscription<IntegrationUiEvent>? _sub;
  static ProviderContainer? _container;

  /// Extra handlers registered by later integration screens (share sheet, ICS preview).
  static final Map<
    Type,
    Future<void> Function(BuildContext context, ProviderContainer container, IntegrationUiEvent event)
  >
  handlers = {};

  static void install(ProviderContainer container, {int attempts = 60}) {
    if (identical(_container, container) && _sub != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (rootNavigatorKey.currentState == null) {
        if (attempts > 0) install(container, attempts: attempts - 1);
        return;
      }
      unawaited(_sub?.cancel());
      _container = container;
      _sub = container.read(integrationUiEventsProvider).stream.listen((e) => unawaited(_handle(container, e)));
    });
  }

  static Future<void> _handle(ProviderContainer container, IntegrationUiEvent event) async {
    switch (event) {
      case OpenPathUiEvent(:final path, :final asRoot):
        final router = container.read(routerProvider);
        if (asRoot) {
          router.go(path);
        } else {
          unawaited(router.push<void>(path));
        }
      case NoticeUiEvent(:final notice, :final detail):
        final context = rootNavigatorKey.currentContext;
        if (context == null || !context.mounted) return;
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(SnackBar(content: Text(integrationNoticeText(context.l10n, notice, detail))));
      default:
        final handler = handlers[event.runtimeType];
        final context = rootNavigatorKey.currentContext;
        if (handler == null || context == null || !context.mounted) return;
        await handler(context, container, event);
    }
  }
}
