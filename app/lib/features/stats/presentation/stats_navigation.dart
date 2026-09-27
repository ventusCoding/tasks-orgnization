/// Navigation from Insights to entities and scopes (drill-down, T6.1.16 / T6.2.10).
library;

import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Router path of a drill reference (null when it has no screen).
String? drillPath(DrillRef ref) => switch (ref.kind) {
  DrillKind.task => AppLinks.task(ref.id),
  DrillKind.occurrence => AppLinks.task(ref.id, occurrenceKey: ref.extra),
  DrillKind.checklist => AppLinks.checklist(ref.id),
  DrillKind.item => AppLinks.checklist(ref.id, itemId: ref.extra),
  DrillKind.habit => AppLinks.habit(ref.id),
  DrillKind.quit => AppLinks.quit(ref.id),
  DrillKind.day => AppLinks.habit(ref.id),
  DrillKind.category => null,
};

/// Opens the screen of [ref].
void openDrillRef(BuildContext context, DrillRef ref) {
  final path = drillPath(ref);
  if (path != null) context.push(path);
}

/// Opens an Insights scope (`/insights/<scope>[/<id>]`).
void openInsights(BuildContext context, String scope, [String? id]) => context.push(AppLinks.insightsScope(scope, id));
