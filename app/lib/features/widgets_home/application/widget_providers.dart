import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/formatting.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/planner/application/planner_service.dart' show plannerL10nProvider;
import 'package:everslot/features/today/application/today_overview_provider.dart';
import 'package:everslot/features/widgets_home/application/widget_snapshot_builder.dart';
import 'package:everslot/features/widgets_home/application/widget_snapshot_writer.dart';
import 'package:everslot/features/widgets_home/data/home_widget_bridge.dart';
import 'package:everslot/features/widgets_home/domain/widget_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Home / lock-screen widgets (T8.2.02–09): snapshot, bridge and writer.

final widgetBridgeProvider = Provider<WidgetBridge>((ref) => HomeWidgetBridge(ref.watch(envProvider).flavor));

final widgetSnapshotWriterProvider = Provider<WidgetSnapshotWriter>((ref) {
  final writer = WidgetSnapshotWriter(ref.watch(widgetBridgeProvider));
  ref.onDispose(writer.dispose);
  return writer;
});

final _widgetChecklistItemsProvider = StreamProvider.autoDispose.family<List<ChecklistItem>, String>(
  (ref, id) => ref.watch(checklistItemsRepositoryProvider).watchItems(id),
);

/// The current snapshot — null while Today's sources load. Follows every change the Today
/// overview follows (Drift streams, day rollover, zone changes).
final widgetSnapshotProvider = Provider.autoDispose<WidgetSnapshot?>((ref) {
  final overview = ref.watch(todayOverviewProvider);
  if (overview.agenda == null || overview.habits == null || overview.quits == null || overview.pinned == null) {
    return null;
  }
  final pinned = overview.pinned!.firstOrNull;
  final items = pinned == null ? const <ChecklistItem>[] : ref.watch(_widgetChecklistItemsProvider(pinned.id)).value;
  if (items == null) return null;
  final l10n = ref.watch(plannerL10nProvider);
  final prefs = ref.watch(userPreferencesProvider);
  return WidgetSnapshotBuilder.build(
    overview: overview,
    l10n: l10n,
    format: AppFormat(l10n.localeName, use24h: prefs.use24h, l10n: l10n, arabicDigits: prefs.useArabicDigits),
    now: ref.read(clockProvider).nowUtc(),
    pinned: pinned,
    pinnedItems: items,
  );
});
