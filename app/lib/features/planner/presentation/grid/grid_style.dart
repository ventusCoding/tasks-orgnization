import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/view_config/planner_view_config.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Colors and metrics of the time grid, derived from design tokens (T3.3.07 / T3.3.22).
@immutable
class GridStyle {
  const GridStyle({
    required this.major,
    required this.minor,
    required this.faint,
    required this.offHours,
    required this.weekend,
    required this.today,
    required this.nowLine,
    required this.unavailable,
    required this.hiddenBand,
    required this.label,
    required this.labelStrong,
    required this.surface,
    required this.outline,
    required this.primary,
    required this.onPrimary,
    required this.brightness,
    required this.density,
  });

  factory GridStyle.of(BuildContext context, {Density density = Density.comfortable}) {
    final c = context.colors;
    final a = context.appColors;
    return GridStyle(
      major: a.gridMajor,
      minor: a.gridMinor,
      faint: a.gridMinor.withValues(alpha: a.gridMinor.a * 0.6),
      offHours: a.offHours,
      weekend: a.offHours,
      today: a.today,
      nowLine: a.nowLine,
      unavailable: c.onSurface.withValues(alpha: 0.06),
      hiddenBand: c.surfaceContainerHighest,
      label: c.onSurfaceVariant,
      labelStrong: c.onSurface,
      surface: c.surface,
      outline: c.outlineVariant,
      primary: c.primary,
      onPrimary: c.onPrimary,
      brightness: Theme.of(context).brightness,
      density: density,
    );
  }

  final Color major;
  final Color minor;
  final Color faint;
  final Color offHours;
  final Color weekend;
  final Color today;
  final Color nowLine;
  final Color unavailable;
  final Color hiddenBand;
  final Color label;
  final Color labelStrong;
  final Color surface;
  final Color outline;
  final Color primary;
  final Color onPrimary;
  final Brightness brightness;
  final Density density;

  bool get compact => density == Density.compact;
  double get tilePadding => compact ? 2 : 4;
  double get tileFont => compact ? 11 : 12;
  double get chipExtent => compact ? 18 : 22;
  double get minTileHeight => 18;
  double get laneRowExtent => compact ? 18 : 22;

  @override
  bool operator ==(Object other) =>
      other is GridStyle &&
      other.major == major &&
      other.minor == minor &&
      other.today == today &&
      other.nowLine == nowLine &&
      other.label == label &&
      other.surface == surface &&
      other.brightness == brightness &&
      other.density == density;

  @override
  int get hashCode => Object.hash(major, minor, today, nowLine, label, surface, brightness, density);
}

/// Resolved tile colors.
@immutable
class TileColors {
  const TileColors(this.background, this.accent, this.foreground);

  final Color background;
  final Color accent;
  final Color foreground;
}

/// Picks tile colors by the view's `colorBy` (category / priority / status / task).
class ItemColorResolver {
  ItemColorResolver({
    required this.colorBy,
    required this.brightness,
    required this.categoryColor,
    required this.statusColor,
  });

  final ColorBy colorBy;
  final Brightness brightness;
  final int? Function(String? categoryId) categoryColor;
  final Color Function(OccurrenceStatus status) statusColor;
  final Map<String, TileColors> _cache = {};

  static int _fallback(PlannerItem item) => CategoryPalette.at(item.seriesId.hashCode.abs());

  int _base(PlannerItem item) => switch (colorBy) {
    ColorBy.category => categoryColor(item.categoryId) ?? item.color ?? CategoryPalette.at(12),
    ColorBy.priority => PriorityStyle.color(item.priority).toARGB32(),
    ColorBy.status => statusColor(item.status).toARGB32(),
    ColorBy.task => item.color ?? _fallback(item),
  };

  TileColors of(PlannerItem item) {
    final base = _base(item);
    final key = '$base';
    return _cache.putIfAbsent(key, () {
      final bg = CategoryColors.background(base, brightness);
      return TileColors(bg, CategoryColors.accent(base, brightness), CategoryColors.onBackground(bg));
    });
  }
}

/// Resolver provider inputs: category colors from the organization feature (application API).
final categoryColorLookupProvider = Provider<int? Function(String?)>((ref) {
  final categories = ref.watch(allCategoriesProvider).value ?? const [];
  final map = {for (final c in categories) c.id: c.color};
  return (id) => id == null ? null : map[id];
});

extension PlannerStatusX on BuildContext {
  String statusLabel(OccurrenceStatus s) {
    final l = l10n;
    return switch (s) {
      OccurrenceStatus.scheduled => l.pvStatusScheduled,
      OccurrenceStatus.inProgress => l.pvStatusInProgress,
      OccurrenceStatus.done => l.pvStatusDone,
      OccurrenceStatus.skipped => l.pvStatusSkipped,
      OccurrenceStatus.missed => l.pvStatusMissed,
      OccurrenceStatus.cancelled => l.pvStatusCancelled,
    };
  }

  Color statusColor(OccurrenceStatus s) {
    final a = appColors;
    return switch (s) {
      OccurrenceStatus.scheduled => a.todo,
      OccurrenceStatus.inProgress => a.ongoing,
      OccurrenceStatus.done => a.completed,
      OccurrenceStatus.skipped => a.skipped,
      OccurrenceStatus.missed => a.missed,
      OccurrenceStatus.cancelled => a.cancelled,
    };
  }

  String trackingLabel(TrackingMode m) => switch (m) {
    TrackingMode.check => l10n.pvTrackingCheck,
    TrackingMode.event => l10n.pvTrackingEvent,
    TrackingMode.timer => l10n.pvTrackingTimer,
  };

  /// Locale-aware formatter honouring the user's 12/24 h preference.
  AppFormat plannerFormat({bool use24h = true}) => AppFormat(localeName, use24h: use24h, l10n: l10n);
}

/// Human label of a slot size: "30 min", "1 h 30 min", "24 h".
String slotLabel(AppFormat f, int minutes) =>
    minutes == 1440 ? (f.l10n?.durationHoursShort(24) ?? '24h') : f.duration(minutes);

/// "Mon 22" style day label.
String dayLabel(AppFormat f, LocalDate d) => f.dayShort(d);
