import 'package:collection/collection.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Views visited in the Plan tab (T3.6.03): Back returns to the previous view type.
final plannerViewHistoryProvider = NotifierProvider<PlannerViewHistory, ({String? current, List<String> back})>(
  PlannerViewHistory.new,
);

class PlannerViewHistory extends Notifier<({String? current, List<String> back})> {
  static const _max = 20;

  @override
  ({String? current, List<String> back}) build() => (current: null, back: const []);

  /// Records that [key] is shown (the previous view goes on the back stack).
  void visit(String key) {
    final s = state;
    if (s.current == key) return;
    final back = s.current == null ? s.back : [...s.back, s.current!];
    state = (current: key, back: back.length > _max ? back.sublist(back.length - _max) : back);
  }

  /// Pops the previous view (null when none); it becomes the current one.
  String? pop() {
    final s = state;
    if (s.back.isEmpty) return null;
    final previous = s.back.last;
    state = (current: previous, back: s.back.sublist(0, s.back.length - 1));
    return previous;
  }
}

/// The Plan tab (T3.4.01 / T3.6.01): hosts the view selected by the route — `view` is a registry
/// entry id (`week_table`, `day_list`, `month`…), a view type of arch §8.3, or `saved:<id>`; `date`
/// is an ISO date to show first. The bare tab opens the user's default view. Switching views keeps
/// the shared anchor date / time (T3.6.03) with a fade-through transition; Back returns to the
/// previous view.
class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({this.view = 'week_table', this.date, super.key});

  final String view;
  final String? date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(plannerDefaultViewsProvider);
    final registry = ref.watch(plannerViewRegistryProvider);
    final saved = ref.watch(plannerSavedViewsProvider).value ?? const <SavedView>[];
    final key = _effectiveKey(ref, registry, saved);
    final entry = registry.resolve(key, saved) ?? registry.byId('week_table')!;
    final viewKey = registry.resolve(key, saved) == null ? entry.id : key;
    final type = ViewKeys.savedIdOf(viewKey) == null
        ? entry.type
        : (saved.firstWhereOrNull((v) => v.id == ViewKeys.savedIdOf(viewKey))?.type ?? entry.type);
    final initial = date == null ? null : LocalDate.tryParse(date!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) ref.read(plannerViewHistoryProvider.notifier).visit(viewKey);
    });
    final hasBack = ref.watch(plannerViewHistoryProvider.select((h) => h.back.isNotEmpty && h.current == viewKey));
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return PopScope(
      canPop: !hasBack,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final previous = ref.read(plannerViewHistoryProvider.notifier).pop();
        if (previous == null) return;
        ref.read(plannerNavProvider).openView(context, previous, date: ref.read(plannerAnchorProvider) ?? ref.read(plannerTodayProvider));
      },
      child: AnimatedSwitcher(
        duration: reduceMotion ? Duration.zero : Motion.normal,
        switchInCurve: Motion.curve,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: Tween(begin: 0.98, end: 1.0).animate(animation), child: child),
        ),
        child: KeyedSubtree(
          key: ValueKey('planner-view-$viewKey'),
          child: entry.builder(PlannerViewArgs(viewKey: viewKey, type: type, date: initial)),
        ),
      ),
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
