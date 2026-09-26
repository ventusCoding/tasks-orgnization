import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/recurrence_ui/application/recurrence_preview.dart';
import 'package:everslot/features/recurrence_ui/presentation/recurrence_labels.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Live description of the rule with the anchor note, errors and warnings (T2.1.15/16).
class RecurrenceSummary extends StatelessWidget {
  const RecurrenceSummary({
    required this.description,
    required this.preview,
    required this.format,
    super.key,
    this.nextCount = 0,
  });

  /// Localized description (`RecurrenceService.describe`), or null for "Does not repeat".
  final String? description;
  final RecurrencePreview? preview;
  final AppFormat format;

  /// Upcoming occurrences listed compactly under the description (presets sheet).
  final int nextCount;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = preview;
    final errors = p?.validation.errors ?? const <RuleIssue>[];
    final warnings = p?.warnings ?? const <RecurrenceWarning>[];
    final colors = context.appColors;
    Widget line(IconData icon, Color color, String text, {Key? key}) => Padding(
      key: key,
      padding: const EdgeInsetsDirectional.only(top: Space.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: Space.xs),
          Expanded(
            child: Text(text, style: context.text.bodySmall?.copyWith(color: color)),
          ),
        ],
      ),
    );
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.repeat, color: context.colors.primary),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      description ?? l.recurPresetNone,
                      key: const ValueKey('recur-description'),
                      style: context.text.titleMedium,
                    ),
                  ),
                ),
              ],
            ),
            if (p != null && p.isValid && nextCount > 0 && p.next.isNotEmpty)
              line(
                Icons.event_repeat_outlined,
                context.colors.onSurfaceVariant,
                '${l.recurPreview}: ${[for (final o in p.next.take(nextCount)) _occurrenceLabel(format, o.startLocal, o.isAllDay)].join(' · ')}',
                key: const ValueKey('recur-next-inline'),
              ),
            if (p != null && p.isValid && p.anchorMoved)
              line(
                Icons.info_outline,
                context.colors.primary,
                l.recurAnchorMoved(_occurrenceLabel(format, p.alignedAnchor.start, p.alignedAnchor.allDay)),
                key: const ValueKey('recur-anchor-moved'),
              ),
            for (final e in errors) line(Icons.error_outline, colors.danger, l.recurIssueText(e)),
            for (final w in warnings) line(Icons.warning_amber_outlined, colors.warning, l.recurWarningText(w)),
          ],
        ),
      ),
    );
  }
}

/// "Tue, Sep 22 09:00" (or the date only for all-day series).
String _occurrenceLabel(AppFormat format, LocalDateTime start, bool allDay) {
  final date = DateFormat.MMMEd(format.locale).format(start.date.toDateTimeUtc());
  return allDay ? date : '$date ${format.time(start.time)}';
}

/// The next occurrences (local times + zone), or quota periods (T2.1.16).
class RecurrenceNextList extends StatelessWidget {
  const RecurrenceNextList({required this.preview, required this.format, super.key});

  final RecurrencePreview preview;
  final AppFormat format;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final rule = preview.rule;
    final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
    if (rule.type == RuleType.quota) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final period in preview.periods)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.date_range_outlined),
              title: Text(_periodLabel(context, period)),
              trailing: Text(l.recurEndsCount(period.requiredCount)),
            ),
          if (preview.periods.isEmpty) Text(l.recurPreviewEmpty, style: muted),
        ],
      );
    }
    final zone = preview.alignedAnchor.zoneId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (preview.next.isEmpty) Text(l.recurPreviewEmpty, key: const ValueKey('recur-preview-empty'), style: muted),
        for (final (i, o) in preview.next.indexed)
          ListTile(
            key: ValueKey('recur-preview-$i'),
            dense: true,
            visualDensity: VisualDensity.compact,
            contentPadding: EdgeInsets.zero,
            leading: Text('${i + 1}', style: muted),
            title: Text(_occurrenceLabel(format, o.startLocal, o.isAllDay)),
            trailing: o.resolutionKind == ResolutionKind.shiftedForward
                ? Tooltip(
                    message: l.recurWarnDst,
                    child: Icon(Icons.schedule, size: 18, color: context.appColors.warning),
                  )
                : null,
          ),
        if (rule.type == RuleType.afterCompletion) Text(l.recurAfterPreview, style: muted),
        if (!preview.alignedAnchor.allDay && preview.next.isNotEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: Space.xs),
            child: Text(zone == null ? l.recurFloatingNote : l.recurZoneNote(zone), style: muted),
          ),
      ],
    );
  }

  String _periodLabel(BuildContext context, Period period) {
    final l = context.l10n;
    return switch (period.unit) {
      PeriodUnit.day => format.dateMedium(period.startDate),
      PeriodUnit.week => l.recurPeriodWeek(format.dateMedium(period.startDate)),
      PeriodUnit.month => format.monthYear(period.startDate),
      PeriodUnit.year => '${period.startDate.year}',
    };
  }
}

/// Mini calendar of the next 60 days highlighting days with occurrences (T2.1.16).
class RecurrenceMiniCalendar extends StatelessWidget {
  const RecurrenceMiniCalendar({required this.preview, required this.weekStart, required this.format, super.key});

  final RecurrencePreview preview;
  final Weekday weekStart;
  final AppFormat format;

  @override
  Widget build(BuildContext context) {
    final start = preview.calendarStart;
    if (start == null || preview.calendarLength == 0) return const SizedBox.shrink();
    final l = context.l10n;
    final last = start.plusDays(preview.calendarLength - 1);
    final gridStart = start.startOfWeek(weekStart);
    final weeks = (gridStart.daysUntil(last) ~/ 7) + 1;
    final narrow = DateFormat.EEEEE(format.locale);
    final hit = context.colors.primary;
    final onHit = context.colors.onPrimary;
    final muted = context.colors.onSurfaceVariant.withValues(alpha: 0.5);
    Widget cell(Widget child) => SizedBox(height: 30, child: Center(child: child));
    return Semantics(
      container: true,
      label: '${l.recurPreviewCalendar}: ${l.recurCalendarSummary(preview.occurrenceDays.length)}',
      child: ExcludeSemantics(
        child: Column(
          key: const ValueKey('recur-calendar'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${format.monthYear(start)} – ${format.monthYear(last)}',
              style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant),
            ),
            const SizedBox(height: Space.xs),
            Row(
              children: [
                for (final d in Weekday.ordered(weekStart))
                  Expanded(
                    child: cell(
                      Text(
                        narrow.format(DateTime.utc(2024, 1, d.iso)),
                        style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
                      ),
                    ),
                  ),
              ],
            ),
            for (var w = 0; w < weeks; w++)
              Row(
                children: [
                  for (var d = 0; d < 7; d++)
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final day = gridStart.plusDays(w * 7 + d);
                          final inRange = !day.isBefore(start) && !day.isAfter(last);
                          if (!inRange) return cell(const SizedBox.shrink());
                          final on = preview.occurrenceDays.contains(day);
                          return cell(
                            Container(
                              key: on ? ValueKey('recur-calendar-hit-${day.toIso()}') : null,
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: on ? BoxDecoration(color: hit, shape: BoxShape.circle) : null,
                              child: Text(
                                '${day.day}',
                                style: context.text.labelSmall?.copyWith(
                                  color: on ? onHit : (day.day == 1 ? context.colors.onSurface : muted),
                                  fontWeight: day.day == 1 || on ? FontWeight.w700 : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
