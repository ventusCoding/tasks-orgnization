import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:material_ui/material_ui.dart';

import 'planner_harness.dart';

/// A [PlannerNav] that really switches the hosted view (like the router's `context.go`) and
/// records the rest.
class SwitchingNav extends RecordingNav {
  SwitchingNav(String view, {LocalDate? date}) : current = ValueNotifier((view, date));

  final ValueNotifier<(String, LocalDate?)> current;

  @override
  void openView(BuildContext context, String viewKey, {LocalDate? date}) {
    super.openView(context, viewKey, date: date);
    current.value = (viewKey, date);
  }

  @override
  void openTask(BuildContext context, PlannerItem item) => super.openTask(context, item);
}

/// Hosts [PlannerScreen] for the view selected through [nav].
class SwitchingHost extends StatelessWidget {
  const SwitchingHost({required this.nav, super.key});

  final SwitchingNav nav;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<(String, LocalDate?)>(
    valueListenable: nav.current,
    builder: (context, v, _) => PlannerScreen(view: v.$1, date: v.$2?.toIso()),
  );
}
