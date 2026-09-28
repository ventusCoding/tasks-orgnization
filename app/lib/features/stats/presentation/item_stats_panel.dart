/// Item insights (T6.4.15): the "Insights" section of a checklist item's details sheet — CL-I-01…07
/// (time in status, cycle/lead time, age, staleness, subtree progress and the status timeline with
/// the actual reason notes). `/insights/item/:id` shows it full screen.
library;

import 'package:everslot/features/stats/application/stats_providers.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/stats_scope_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class ItemStatsPanel extends ConsumerWidget {
  const ItemStatsPanel({required this.itemId, super.key, this.showHeader = false});

  final String itemId;

  /// Show the item text header (full-screen use; the details sheet already shows it).
  final bool showHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entity = showHeader ? ref.watch(scopeEntityProvider(('item', itemId))).value : null;
    return StatsScopeView(
      key: ValueKey('item/$itemId'),
      scope: MetricScope.checklistItem,
      scopeId: itemId,
      entity: entity,
      showPeriod: false,
    );
  }
}
