import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/work_settings.dart';
import 'package:everslot/features/planner/presentation/grid/engine/day_slices.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Per-day header stats (T3.4.11): done/total of `check` items, planned minutes and load.
@immutable
class DayStats {
  const DayStats({required this.done, required this.total, required this.plannedMinutes, required this.load});

  factory DayStats.of(DaySlice slice, WorkSettings work) {
    var done = 0;
    var total = 0;
    final seen = <String>{};
    for (final s in slice.timed) {
      if (!seen.add(s.item.key)) continue;
      if (s.item.trackingMode == TrackingMode.check && s.item.status != OccurrenceStatus.cancelled) {
        total++;
        if (s.item.status == OccurrenceStatus.done) done++;
      }
    }
    final planned = slice.timed
        .where((s) => s.item.status != OccurrenceStatus.cancelled && s.item.status != OccurrenceStatus.skipped)
        .fold(0, (a, s) => a + s.minutes);
    final capacity = work.days.contains(slice.date.weekday.iso) ? work.minutesPerDay : 0;
    return DayStats(
      done: done,
      total: total,
      plannedMinutes: planned,
      load: capacity == 0 ? (planned > 0 ? double.infinity : 0) : planned / capacity,
    );
  }

  final int done;
  final int total;
  final int plannedMinutes;

  /// planned ÷ work-hours minutes.
  final double load;

  @override
  bool operator ==(Object other) =>
      other is DayStats &&
      other.done == done &&
      other.total == total &&
      other.plannedMinutes == plannedMinutes &&
      other.load == load;

  @override
  int get hashCode => Object.hash(done, total, plannedMinutes, load);
}

/// Load tint with thresholds at 80 % and 100 % (T3.4.11).
Color? loadTint(BuildContext context, double load, {double warn = 0.8, double over = 1.0}) {
  if (load >= over && load.isFinite) return context.appColors.danger.withValues(alpha: 0.14);
  if (load.isInfinite) return context.appColors.danger.withValues(alpha: 0.10);
  if (load >= warn) return context.appColors.warning.withValues(alpha: 0.14);
  return null;
}

/// One pinned header cell (T3.3.09): weekday + date, today highlight, month-change marker, optional
/// ISO week number, stats slot and load tint. Gestures are handled by the grid; semantics expose them.
class DayHeaderCell extends StatelessWidget {
  const DayHeaderCell({
    required this.date,
    required this.isToday,
    required this.format,
    this.showMonth = false,
    this.weekNumber,
    this.stats,
    this.statsText,
    this.semanticsLabel,
    this.onTap,
    this.onLongPress,
    this.compact = false,
    this.loadWarn = 0.8,
    this.loadOver = 1.0,
    super.key,
  });

  /// Load thresholds of the tint (view config options `loadWarn` / `loadOver`).
  final double loadWarn;
  final double loadOver;
  final LocalDate date;
  final bool isToday;
  final AppFormat format;
  final bool showMonth;
  final String? weekNumber;
  final DayStats? stats;
  final String? statsText;
  final String? semanticsLabel;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tint = stats == null ? null : loadTint(context, stats!.load, warn: loadWarn, over: loadOver);
    final dayNumber = format.number(date.day);
    return Semantics(
      button: true,
      header: true,
      selected: isToday,
      label: semanticsLabel,
      onTap: onTap,
      onLongPress: onLongPress,
      child: ExcludeSemantics(
        child: Container(
          color: tint,
          padding: const EdgeInsets.symmetric(vertical: Space.xxs),
          // Laid out at the column width, then scaled down if taller than the header (text scale).
          child: LayoutBuilder(
            builder: (context, constraints) => FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: constraints.maxWidth.isFinite ? constraints.maxWidth : 56,
                child: _content(context, c, dayNumber),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, ColorScheme c, String dayNumber) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      FittedBox(
        child: Text(
          showMonth
              ? '${format.weekdayShort(date.weekday)} · ${DateFormat.MMM(format.locale).format(date.toDateTimeUtc())}'
              : format.weekdayShort(date.weekday),
          style: context.text.labelSmall?.copyWith(color: isToday ? c.primary : c.onSurfaceVariant),
          maxLines: 1,
        ),
      ),
      const SizedBox(height: 2),
      Container(
        width: compact ? 24 : 28,
        height: compact ? 24 : 28,
        alignment: Alignment.center,
        decoration: isToday ? BoxDecoration(color: c.primary, shape: BoxShape.circle) : null,
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Text(
              dayNumber,
              style: context.text.titleSmall?.copyWith(
                color: isToday ? c.onPrimary : c.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      if (weekNumber != null)
        FittedBox(
          child: Text(weekNumber!, style: context.text.labelSmall?.copyWith(color: c.outline)),
        ),
      if (statsText != null)
        FittedBox(
          child: Text(statsText!, style: context.text.labelSmall?.copyWith(fontSize: 10, color: c.onSurfaceVariant)),
        ),
    ],
  );
}
