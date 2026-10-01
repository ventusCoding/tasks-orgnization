import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/features/checklists/presentation/checklist_screen.dart';
import 'package:everslot/features/checklists/presentation/smart_list_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// A card created from the board but not written yet (T4.1.09: an empty new card writes nothing).
@immutable
class PendingCard {
  const PendingCard({required this.id, this.note = false});

  final String id;

  /// New note: focus the body instead of the title.
  final bool note;
}

class PendingCardController extends Notifier<PendingCard?> {
  @override
  PendingCard? build() => null;

  // ignore: use_setters_to_change_properties
  void set(PendingCard? card) => state = card;
}

final pendingCardProvider = NotifierProvider<PendingCardController, PendingCard?>(PendingCardController.new);

/// Opens a checklist through the router (deep-linkable), or a plain route when no router exists.
Future<void> openChecklist(BuildContext context, String id, {String? itemId, bool preview = false}) async {
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    await router.push<void>(AppLinks.checklist(id, itemId: itemId, preview: preview));
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ChecklistScreen(checklistId: id, focusItemId: itemId, preview: preview),
    ),
  );
}

Future<void> openSmartList(BuildContext context, String kind) async {
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    await router.push<void>(AppLinks.smartList(kind));
    return;
  }
  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SmartListScreen(kind: kind)));
}

void openTrash(BuildContext context) => GoRouter.maybeOf(context)?.push<void>(AppLinks.trash());

void openRoute(BuildContext context, String location) => GoRouter.maybeOf(context)?.push<void>(location);
