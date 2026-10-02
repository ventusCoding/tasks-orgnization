import 'dart:convert';
import 'dart:io';

import 'package:everslot/core/env/env.dart';
import 'package:home_widget/home_widget.dart';

/// Where widget snapshots go (T8.2.02): the App Group (iOS) / shared preferences (Android).
abstract interface class WidgetBridge {
  Future<void> init();

  /// Registers the Dart entry point widget buttons call (interactive widgets).
  Future<void> registerActions(Future<void> Function(Uri? uri) callback);
  Future<void> save(String snapshotJson);

  /// Asks every installed widget to reload.
  Future<void> reloadAll();

  /// Whether the launcher can add a widget for the user (Android 8+ launchers).
  Future<bool> canPin();

  /// Asks the launcher to add [kind] (`today`, `habits`, `quit`, `checklist`).
  Future<void> pin(String kind);

  /// Widget taps the iOS extension queued for the app, oldest first, then clears the queue.
  Future<List<(String, DateTime)>> takeQueuedActions();
}

/// `home_widget` implementation. Widget kinds / receivers must match the native code
/// (`ios/EverslotWidgets`, `android/app/src/main/kotlin/app/everslot/widgets`).
class HomeWidgetBridge implements WidgetBridge {
  HomeWidgetBridge(this.flavor);

  final Flavor flavor;

  static const snapshotKey = 'everslot_snapshot';
  static const actionsKey = 'everslot_widget_actions';
  static const iosKinds = ['EverslotToday', 'EverslotHabits', 'EverslotQuit', 'EverslotChecklist', 'EverslotAccessory'];
  static const androidReceivers = [
    'app.everslot.widgets.TodayWidgetReceiver',
    'app.everslot.widgets.HabitsWidgetReceiver',
    'app.everslot.widgets.QuitWidgetReceiver',
    'app.everslot.widgets.ChecklistWidgetReceiver',
  ];

  /// App Group shared by the app and the widget extension (one per flavor bundle id).
  String get appGroup => flavor == Flavor.prod ? 'group.app.everslot' : 'group.app.everslot.dev';

  @override
  Future<void> init() async => HomeWidget.setAppGroupId(appGroup);

  @override
  Future<void> registerActions(Future<void> Function(Uri? uri) callback) async =>
      HomeWidget.registerInteractivityCallback(callback);

  @override
  Future<void> save(String snapshotJson) async => HomeWidget.saveWidgetData<String>(snapshotKey, snapshotJson);

  @override
  Future<List<(String, DateTime)>> takeQueuedActions() async {
    final raw = await HomeWidget.getWidgetData<String>(actionsKey);
    if (raw == null || raw.isEmpty) return const [];
    await HomeWidget.saveWidgetData<String>(actionsKey, null);
    return parseQueuedActions(raw);
  }

  /// `[{"uri": …, "at": ISO-8601}]` → (uri, tap instant); malformed entries are skipped.
  static List<(String, DateTime)> parseQueuedActions(String raw) {
    try {
      return [
        for (final e in jsonDecode(raw) as List<Object?>)
          if (e case {'uri': final String uri, 'at': final String at})
            if (DateTime.tryParse(at) case final instant?) (uri, instant.toUtc()),
      ];
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<bool> canPin() async => Platform.isAndroid && (await HomeWidget.isRequestPinWidgetSupported() ?? false);

  @override
  Future<void> pin(String kind) async {
    final receiver = androidReceivers.where((r) => r.toLowerCase().contains('.${kind}widget')).firstOrNull;
    if (receiver != null) await HomeWidget.requestPinWidget(qualifiedAndroidName: receiver);
  }

  @override
  Future<void> reloadAll() async {
    if (Platform.isIOS) {
      for (final kind in iosKinds) {
        await HomeWidget.updateWidget(iOSName: kind);
      }
      return;
    }
    if (!Platform.isAndroid) return;
    for (final receiver in androidReceivers) {
      try {
        await HomeWidget.updateWidget(qualifiedAndroidName: receiver);
      } on Object {
        // Receiver not present in this build (e.g. tests, older installs).
      }
    }
  }
}
