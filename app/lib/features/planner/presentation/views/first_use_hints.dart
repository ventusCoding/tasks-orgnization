import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/views/plan_summary_views.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// First-use hints & empty week (T3.4.18): dismissible coach cards shown once each (remembered in
// the view's local state) and an empty-range card with *Plan your first task*.

/// Hint ids in display order.
const plannerHintIds = ['longPress', 'pinch', 'slotSize'];

/// The next hint not dismissed yet for [viewKey], or null.
String? nextPlannerHint(ViewState? state) {
  final seen = (state?.extra['hintsSeen'] as List?)?.whereType<String>().toSet() ?? const <String>{};
  for (final id in plannerHintIds) {
    if (!seen.contains(id)) return id;
  }
  return null;
}

/// One coach card at a time; *Got it* remembers it.
class FirstUseHintCard extends ConsumerWidget {
  const FirstUseHintCard({required this.viewKey, required this.slotLabel, super.key});

  final String viewKey;

  /// Current row size, e.g. "30 min" (the slot-size hint names it).
  final String slotLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(plannerViewStateProvider(viewKey));
    if (state == null) return const SizedBox.shrink();
    final hint = nextPlannerHint(state);
    if (hint == null) return const SizedBox.shrink();
    final l = context.l10n;
    final (icon, text) = switch (hint) {
      'longPress' => (Icons.touch_app_outlined, l.pvHintLongPress),
      'pinch' => (Icons.pinch_outlined, l.pvHintPinch),
      _ => (Icons.height, l.pvHintSlotSize(slotLabel)),
    };
    void dismiss() => ref
        .read(plannerViewStateProvider(viewKey).notifier)
        .update((s) => s.withExtra('hintsSeen', [...?(s.extra['hintsSeen'] as List?)?.whereType<String>(), hint]));
    return Padding(
      padding: const EdgeInsets.all(Space.sm),
      child: Material(
        key: ValueKey('hint-$hint'),
        elevation: 3,
        color: context.colors.inverseSurface,
        borderRadius: BorderRadius.circular(Radii.md),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.md, Space.xs, Space.xs, Space.xs),
          child: Row(
            children: [
              Icon(icon, color: context.colors.onInverseSurface, size: 20),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(text, style: context.text.bodyMedium?.copyWith(color: context.colors.onInverseSurface)),
              ),
              TextButton(
                key: const Key('hint-got-it'),
                onPressed: dismiss,
                child: Text(l.pvGotIt, style: TextStyle(color: context.colors.inversePrimary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty visible range (T3.4.18): a card with *Plan your first task* over the grid, leaving the
/// grid itself interactive around it.
class EmptyRangeCard extends ConsumerWidget {
  const EmptyRangeCard({required this.days, required this.onPlan, super.key});

  final List<LocalDate> days;
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (days.isEmpty) return const SizedBox.shrink();
    final items = ref.watch(viewItemsProvider(rangeOfDays(days))).value;
    if (items == null || items.isNotEmpty) return const SizedBox.shrink();
    final l = context.l10n;
    return Center(
      child: Card(
        key: const Key('empty-week'),
        margin: const EdgeInsets.all(Space.xl),
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_available_outlined, size: 48, color: context.colors.primary),
              const SizedBox(height: Space.sm),
              Text(l.pvEmptyWeekTitle, textAlign: TextAlign.center, style: context.text.titleMedium),
              const SizedBox(height: Space.md),
              FilledButton.icon(
                key: const Key('plan-first-task'),
                onPressed: onPlan,
                icon: const Icon(Icons.add),
                label: Text(l.pvPlanFirstTask),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
