import 'package:collection/collection.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/presentation/views/view_entries.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Switcher groups (T3.6.01).
enum PlannerViewGroup {
  calendar,
  productivity;

  String label(AppLocalizations l) => switch (this) {
    PlannerViewGroup.calendar => l.pvGroupCalendar,
    PlannerViewGroup.productivity => l.pvGroupProductivity,
  };
}

/// Release tier (arch §9.8): P2 views ship dark unless a flag enables them (dev builds show all).
enum ViewTier { mvp, m2, m3 }

/// What a view builder receives: its key (entry id or `saved:<id>`), type and deep-link date.
@immutable
class PlannerViewArgs {
  const PlannerViewArgs({required this.viewKey, required this.type, this.date});

  final String viewKey;
  final PlannerViewType type;
  final LocalDate? date;
}

typedef PlannerViewBuilder = Widget Function(PlannerViewArgs args);

/// One registry entry (T3.6.01): builder, icon, localized name, capability flags and availability.
@immutable
class PlannerViewEntry {
  const PlannerViewEntry({
    required this.id,
    required this.type,
    required this.icon,
    required this.label,
    required this.builder,
    this.group = PlannerViewGroup.calendar,
    this.tier = ViewTier.m2,
    this.timeBased = false,
    this.supportsSlotSize = false,
    this.supportsDrag = false,
  });

  final String id;
  final PlannerViewType type;
  final IconData icon;
  final String Function(AppLocalizations l) label;
  final PlannerViewBuilder builder;
  final PlannerViewGroup group;
  final ViewTier tier;
  final bool timeBased;
  final bool supportsSlotSize;
  final bool supportsDrag;

  /// Visible in the switcher: MVP and M2 views always; M3 (P2) views in dev builds or when the
  /// `planner_views_m3` / `view_<id>` flag is on.
  bool isAvailable(Set<String> flags, {required bool dev}) =>
      tier != ViewTier.m3 || dev || flags.contains('planner_views_m3') || flags.contains('view_$id');
}

/// Maps view types / entry ids to builders (T3.6.01).
class PlannerViewRegistry {
  PlannerViewRegistry(List<PlannerViewEntry> entries) : entries = List.unmodifiable(entries);

  final List<PlannerViewEntry> entries;

  PlannerViewEntry? byId(String id) => entries.firstWhereOrNull((e) => e.id == id);

  /// First entry rendering [type] (saved views of that type use it).
  PlannerViewEntry? forType(PlannerViewType type) => entries.firstWhereOrNull((e) => e.type == type);

  List<PlannerViewEntry> available(Set<String> flags, {required bool dev}) => [
    for (final e in entries)
      if (e.isAvailable(flags, dev: dev)) e,
  ];

  /// True when [savedViewId] is the storage row of a built-in entry (not a user-named view).
  bool isEntryRow(String savedViewId, String userId) => entries.any((e) => entryViewId(userId, e.id) == savedViewId);

  /// Entry id of a built-in storage row, or null.
  String? entryOfRow(String savedViewId, String userId) =>
      entries.firstWhereOrNull((e) => entryViewId(userId, e.id) == savedViewId)?.id;

  /// Resolves a view key to the entry that renders it (saved views → their type's entry).
  PlannerViewEntry? resolve(String key, List<SavedView> saved) {
    final savedId = ViewKeys.savedIdOf(key);
    if (savedId == null) {
      return byId(key) ?? (PlannerViewType.tryParse(key) == null ? null : forType(PlannerViewType.tryParse(key)!));
    }
    final view = saved.firstWhereOrNull((v) => v.id == savedId);
    return view == null ? null : forType(view.type);
  }
}

final plannerViewRegistryProvider = Provider<PlannerViewRegistry>(
  (ref) => PlannerViewRegistry(buildPlannerViewEntries()),
);
