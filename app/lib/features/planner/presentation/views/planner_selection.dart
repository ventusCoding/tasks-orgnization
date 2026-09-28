import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/bulk_actions_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// Selection mode of the planner views (T3.1.18 wiring): long-press → *Select* (tile menu), then taps
// toggle items; the toolbar turns into a selection bar whose *Actions* open planner-core's bulk
// sheet (one operation, one undo). Also the copy / paste clipboard of T3.1.19 (Ctrl/Cmd + C / V).

/// Selected items of one view (by item key), in selection order.
final plannerSelectionProvider = NotifierProvider.family<PlannerSelection, Map<String, PlannerItem>, String>(
  PlannerSelection.new,
);

class PlannerSelection extends Notifier<Map<String, PlannerItem>> {
  PlannerSelection(this.viewKey);

  final String viewKey;

  @override
  Map<String, PlannerItem> build() => const {};

  bool get active => state.isNotEmpty;

  bool contains(PlannerItem item) => state.containsKey(item.key);

  void select(PlannerItem item) {
    if (!state.containsKey(item.key)) state = {...state, item.key: item};
  }

  void toggle(PlannerItem item) {
    if (state.containsKey(item.key)) {
      state = {...state}..remove(item.key);
    } else {
      state = {...state, item.key: item};
    }
  }

  void clear() {
    if (state.isNotEmpty) state = const {};
  }
}

/// The copied item (Ctrl/Cmd + C, tile menu *Copy*), shared by every view.
final plannerClipboardProvider = NotifierProvider<PlannerClipboard, PlannerItem?>(PlannerClipboard.new);

class PlannerClipboard extends Notifier<PlannerItem?> {
  @override
  PlannerItem? build() => null;

  // ignore: use_setters_to_change_properties
  void copy(PlannerItem item) => state = item;
}

/// The toolbar of a view in selection mode: clear, "N selected", *Actions* (bulk sheet).
class SelectionToolbar extends ConsumerWidget {
  const SelectionToolbar({required this.viewKey, super.key});

  final String viewKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final selection = ref.watch(plannerSelectionProvider(viewKey));
    final notifier = ref.read(plannerSelectionProvider(viewKey).notifier);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.4,
      child: SizedBox(
        key: const Key('selection-toolbar'),
        height: 48,
        child: Row(
          children: [
            IconButton(
              key: const Key('selection-clear'),
              tooltip: l.pvClearSelection,
              icon: const Icon(Icons.close),
              onPressed: notifier.clear,
            ),
            Expanded(
              child: Text(
                l.pvSelected(selection.length),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: Space.sm),
              child: FilledButton.tonalIcon(
                key: const Key('selection-actions'),
                onPressed: selection.isEmpty
                    ? null
                    : () async {
                        final done = await showBulkActionsSheet(context, selection.values.toList());
                        if (done) notifier.clear();
                      },
                icon: const Icon(Icons.checklist_rtl),
                label: Text(l.pvSelectionActions),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Handles taps on an item in a view that supports selection: toggles it while selecting,
/// otherwise runs [otherwise] (open / tick).
void tapOrToggle(WidgetRef ref, String viewKey, PlannerItem item, VoidCallback otherwise) {
  final selection = ref.read(plannerSelectionProvider(viewKey).notifier);
  if (selection.active) {
    selection.toggle(item);
  } else {
    otherwise();
  }
}
