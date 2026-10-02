import 'dart:async';

import 'package:everslot/core/logging/log.dart';
import 'package:everslot/features/integrations/application/external_links_service.dart';
import 'package:everslot/features/integrations/data/quick_actions_source.dart';
import 'package:everslot/features/integrations/domain/app_shortcuts.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';

/// App icon shortcuts (T8.2.06): localized titles, and a selected shortcut becomes an external
/// link handled like any other (`everslot://do/new-task`, `everslot://today`…).
class AppShortcutsService {
  AppShortcutsService(this._platform, this._links);

  final ShortcutPlatform _platform;
  final ExternalLinksService _links;
  static final _log = AppLog.get('integrations.shortcuts');

  Future<void> start(AppLocalizations l10n) async {
    try {
      await _platform.initialize(select);
      await setTitles(l10n);
    } on Object catch (e) {
      _log.info('app shortcuts unavailable: $e');
    }
  }

  Future<void> setTitles(AppLocalizations l) =>
      _platform.setShortcuts([for (final s in AppShortcut.values) (s.type, title(l, s))]);

  static String title(AppLocalizations l, AppShortcut s) => switch (s) {
    AppShortcut.newTask => l.shortcutNewTask,
    AppShortcut.logHabit => l.shortcutLogHabit,
    AppShortcut.logCraving => l.shortcutLogCraving,
    AppShortcut.today => l.shortcutToday,
  };

  /// Called by the platform when a shortcut is chosen.
  void select(String type) {
    final shortcut = AppShortcut.tryParse(type);
    if (shortcut != null) unawaited(_links.handle(shortcut.uri));
  }
}
