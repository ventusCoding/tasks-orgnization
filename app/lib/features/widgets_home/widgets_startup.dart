import 'dart:async';
import 'dart:io';

import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/widgets_home/application/widget_actions_runner.dart';
import 'package:everslot/features/widgets_home/application/widget_providers.dart';
import 'package:everslot/features/widgets_home/domain/widget_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _wired = Expando<ProviderSubscription<WidgetSnapshot?>>('home-widgets');

/// Startup task: keeps the widget snapshot written while the app runs (T8.2.02) and registers
/// the background entry point of interactive widgets.
Future<void> startHomeWidgets(ProviderContainer container) async {
  if (!(Platform.isIOS || Platform.isAndroid) || _wired[container] != null) return;
  final bridge = container.read(widgetBridgeProvider);
  try {
    await bridge.init();
    await bridge.registerActions(widgetInteractivityCallback);
  } on Object catch (e) {
    AppLog.get('widgets').info('home widgets unavailable: $e');
    return;
  }
  final writer = container.read(widgetSnapshotWriterProvider);
  _wired[container] = container.listen(
    widgetSnapshotProvider,
    (_, next) => writer.schedule(next),
    fireImmediately: true,
  );
  if (Platform.isIOS) {
    // iOS widget taps wait in the App Group until the app runs (T8.2.04).
    unawaited(drainQueuedWidgetActions(container));
    container.read(lifecycleProvider).onResume.listen((_) => unawaited(drainQueuedWidgetActions(container)));
  }
}
