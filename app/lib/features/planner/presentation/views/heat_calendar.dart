import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/presentation/grid/engine/calendar_metrics.dart';
import 'package:everslot/features/planner/presentation/views/month_view.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

// Shared pieces of the calendar heat views: year heatmap (T3.6.10), quarter (T3.6.12) and the load
// heatmap (T3.6.16).

/// Fill color of heat level 0–4 (0 = nothing planned), derived from the theme's primary color.
Color heatFill(BuildContext context, int level) {
  final c = context.colors;
  if (level <= 0) return c.surfaceContainerHighest.withValues(alpha: 0.55);
  const alphas = [0.0, 0.28, 0.5, 0.75, 1.0];
  return Color.alphaBlend(c.primary.withValues(alpha: alphas[level.clamp(1, 4)]), c.surface);
}

/// Text color readable on [heatFill] of [level].
Color heatOnFill(BuildContext context, int level) => level >= 3 ? context.colors.onPrimary : context.colors.onSurface;

/// "2026" in the locale's digits.
String yearLabel(String locale, int year) => DateFormat.y(locale).format(DateTime.utc(year));

/// "Less ▢▢▢▢▢ More" legend of the heat scale.
class HeatLegend extends StatelessWidget {
  const HeatLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final style = context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant);
    return Semantics(
      excludeSemantics: true,
      label: '${l.pvLess} – ${l.pvMoreLegend}',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l.pvLess, style: style),
          const SizedBox(width: Space.xs),
          for (var i = 0; i <= 4; i++)
            Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(color: heatFill(context, i), borderRadius: BorderRadius.circular(3)),
            ),
          const SizedBox(width: Space.xs),
          Text(l.pvMoreLegend, style: style),
        ],
      ),
    );
  }
}

/// A month laid out as week rows of equally sized cells (blank outside the month), with an
/// optional weekday-initials row. [cell] builds the content of one day.
class MonthCellGrid extends StatelessWidget {
  const MonthCellGrid({
    required this.month,
    required this.weekStart,
    required this.cell,
    this.showWeekdays = true,
    this.aspectRatio = 1,
    super.key,
  });

  final LocalDate month;
  final Weekday weekStart;
  final Widget Function(BuildContext context, LocalDate day) cell;
  final bool showWeekdays;

  /// Width ÷ height of one cell.
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final narrow = DateFormat('EEEEE', locale);
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showWeekdays)
          Row(
            children: [
              for (final w in Weekday.ordered(weekStart))
                Expanded(
                  child: Center(
                    child: Text(
                      narrow.format(DateTime.utc(2024, 1, w.iso)),
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(fontSize: 9, color: w.isWeekend ? c.outline : c.onSurfaceVariant),
                    ),
                  ),
                ),
            ],
          ),
        for (final week in monthWeeks(month, weekStart))
          Row(
            children: [
              for (final d in week)
                Expanded(
                  child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: d.month == month.month ? cell(context, d) : const SizedBox.shrink(),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// One heat cell: level fill, optional day number, today ring, tap / long-press.
class HeatCell extends StatelessWidget {
  const HeatCell({
    required this.day,
    required this.level,
    required this.label,
    required this.isToday,
    this.showNumber = true,
    this.onTap,
    this.onLongPress,
    this.numberText,
    super.key,
  });

  final LocalDate day;
  final int level;
  final String label;
  final bool isToday;
  final bool showNumber;
  final String? numberText;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      onLongPress: onLongPress,
      child: ExcludeSemantics(
        child: GestureDetector(
          key: ValueKey('heat-${day.toIso()}'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: heatFill(context, level),
                borderRadius: BorderRadius.circular(3),
                border: isToday ? Border.all(color: c.primary, width: 1.5) : null,
              ),
              child: showNumber
                  ? Center(
                      child: Text(
                        numberText ?? '${day.day}',
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                          color: heatOnFill(context, level),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Localized value text of a day metric for semantics: "3 h 30 min planned", "75 %", "4 items".
String heatValueLabel(BuildContext context, AppFormat f, HeatMetric metric, double? value) {
  final l = context.l10n;
  if (value == null || (metric != HeatMetric.completion && value <= 0)) {
    return l.pvNoTasks;
  }
  return switch (metric) {
    HeatMetric.planned => '${l.pvPlanned}: ${f.duration(value.round())}',
    HeatMetric.completion => '${l.pvCompletion}: ${f.percent(value)}',
    HeatMetric.count => l.pvItemsCount(value.round()),
  };
}
