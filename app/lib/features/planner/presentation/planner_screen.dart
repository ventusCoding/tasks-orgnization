import 'package:collection/collection.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The Plan tab (T3.4.01 / T3.6.01): hosts the view selected by the route — `view` is a registry
/// entry id (`week_table`, `day_list`, `month`…), a view type of arch §8.3, or `saved:<id>`; `date`
/// is an ISO date to show first. The bare tab opens the user's default view.
class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({this.view = 'week_table', this.date, super.key});

  final String view;
  final String? date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(plannerViewRegistryProvider);
    final saved = ref.watch(plannerSavedViewsProvider).value ?? const <SavedView>[];
    final key = _effectiveKey(ref, registry, saved);
    final entry = registry.resolve(key, saved) ?? registry.byId('week_table')!;
    final viewKey = registry.resolve(key, saved) == null ? entry.id : key;
    final type = ViewKeys.savedIdOf(viewKey) == null
        ? entry.type
        : (saved.firstWhereOrNull((v) => v.id == ViewKeys.savedIdOf(viewKey))?.type ?? entry.type);
    final initial = date == null ? null : LocalDate.tryParse(date!);
    return KeyedSubtree(
      key: ValueKey('planner-view-$viewKey'),
      child: entry.builder(PlannerViewArgs(viewKey: viewKey, type: type, date: initial)),
    );
  }

  /// The bare Plan tab (`/plan`, no date) opens the saved default view when one is set.
  String _effectiveKey(WidgetRef ref, PlannerViewRegistry registry, List<SavedView> saved) {
    if (view != 'week_table' || date != null) return view;
    final def = saved.firstWhereOrNull((v) => v.isDefault);
    if (def == null) return view;
    final userId = ref.watch(currentUserIdProvider);
    return registry.entryOfRow(def.id, userId) ?? ViewKeys.saved(def.id);
  }
}
