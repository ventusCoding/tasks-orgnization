import 'package:quick_actions/quick_actions.dart';

/// Platform shortcuts (`quick_actions`); faked in tests.
abstract interface class ShortcutPlatform {
  Future<void> initialize(void Function(String type) onSelected);
  Future<void> setShortcuts(List<(String type, String title)> shortcuts);
}

class QuickActionsShortcutPlatform implements ShortcutPlatform {
  final _plugin = const QuickActions();

  @override
  Future<void> initialize(void Function(String type) onSelected) => _plugin.initialize(onSelected);

  @override
  Future<void> setShortcuts(List<(String, String)> shortcuts) => _plugin.setShortcutItems([
    for (final (type, title) in shortcuts) ShortcutItem(type: type, localizedTitle: title),
  ]);
}
