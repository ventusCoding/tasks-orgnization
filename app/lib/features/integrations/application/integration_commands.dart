import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/quit_service.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/integrations/application/external_links_service.dart';
import 'package:everslot/features/integrations/application/integration_events.dart';
import 'package:everslot/features/integrations/domain/external_link.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `everslot://do/…` command handlers shared by shortcuts, widgets and voice actions (8.2).
abstract final class IntegrationCommands {
  static void registerAll(Ref ref, LinkCommandRegistry registry, BufferedEventBus<IntegrationUiEvent> events) {
    // New task → the universal quick add (T8.2.06).
    registry.register('new-task', (command) async => events.add(QuickAddUiEvent(title: command.params['title'])));

    // Log craving (T8.2.06): one active quit tracker → logged at once; several → choose in Habits;
    // none → create one.
    registry.register('craving', (command) async {
      final quits = [
        for (final h in await ref.read(habitsRepositoryProvider).all(includeArchived: false))
          if (h case final QuitHabit q) q,
      ];
      if (quits.isEmpty) {
        events.add(OpenPathUiEvent(AppLinks.habitNew(kind: 'quit')));
      } else if (quits.length > 1) {
        events.add(OpenPathUiEvent(AppLinks.habits(), asRoot: true));
      } else {
        await ref.read(quitServiceProvider).logCraving(quits.single);
        events.add(NoticeUiEvent(IntegrationNotice.cravingLogged, detail: quits.single.name));
      }
    });
  }

  /// For tests and diagnostics.
  static LinkCommand command(String name, [Map<String, String> params = const {}]) => LinkCommand(name, params);
}
