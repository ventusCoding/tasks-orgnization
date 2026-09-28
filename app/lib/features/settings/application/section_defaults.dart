import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A planner view the Plan tab can open by default (T8.3.05).
typedef PlannerViewChoice = ({String id, String name, bool isDefault});

/// Saved planner views (the planner owns them; one is the default of the bare Plan tab).
final plannerViewChoicesProvider = Provider<List<PlannerViewChoice>>((ref) {
  final views = ref.watch(plannerSavedViewsProvider).value ?? const [];
  return [for (final v in views) (id: v.id, name: v.name, isDefault: v.isDefault)];
});

/// Makes [savedViewId] the view the Plan tab opens.
Future<void> setDefaultPlannerView(WidgetRef ref, String savedViewId) async {
  await ref.read(savedViewsRepositoryProvider).setDefault(savedViewId);
}
