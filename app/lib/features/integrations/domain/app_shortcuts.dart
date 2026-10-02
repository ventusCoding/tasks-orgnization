/// Long-press app icon shortcuts (T8.2.06). Each one routes through the external links pipeline
/// (T8.2.01), so cold and warm starts behave the same.
enum AppShortcut {
  newTask('new_task', 'everslot://do/new-task'),
  logHabit('log_habit', 'everslot://habits'),
  logCraving('log_craving', 'everslot://do/craving'),
  today('today', 'everslot://today');

  AppShortcut(this.type, this.link);

  /// `quick_actions` shortcut type.
  final String type;

  /// External link it opens.
  final String link;

  Uri get uri => Uri.parse(link);

  static AppShortcut? tryParse(String? type) => values.where((s) => s.type == type).firstOrNull;
}
