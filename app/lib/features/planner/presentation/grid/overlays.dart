import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/habits/application/check_in_service.dart';
import 'package:everslot/features/habits/application/habit_day_view.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/engine/free_slots.dart';
import 'package:everslot/features/planner/presentation/grid/engine/occupancy.dart';
import 'package:everslot/features/planner/presentation/grid/timeline_page.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show PeriodStatus;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// Overlays framework (T3.3.23): layers toggled by the view config `overlays` map —
// `habits` (timed habit slots, tap to check in), `checklistDue` (checklist items due in the range),
// `freeSlots` (openings inside work hours, T3.7.04), `heat` (weekday × hour occupancy of the last
// four weeks) and `deviceCalendars` (reserved for [8.2]: no data source yet, the toggle is inert).

/// Point overlays drawn over the grid at a wall-clock time.
enum OverlayMarkerKind { habit, checklistDue }

@immutable
class OverlayMarker {
  const OverlayMarker({
    required this.kind,
    required this.id,
    required this.targetId,
    required this.day,
    required this.minute,
    required this.label,
    this.periodKey,
    this.itemId,
    this.color,
    this.done = false,
  });

  final OverlayMarkerKind kind;

  /// Unique within a range.
  final String id;

  /// Habit id or checklist id.
  final String targetId;

  /// Habit slot key (`YYYY-MM-DDTHH:mm`).
  final String? periodKey;

  /// Checklist item id.
  final String? itemId;
  final LocalDate day;

  /// Wall-clock minute of [day].
  final int minute;
  final String label;
  final int? color;
  final bool done;

  @override
  bool operator ==(Object other) =>
      other is OverlayMarker &&
      other.kind == kind &&
      other.id == id &&
      other.day == day &&
      other.minute == minute &&
      other.label == label &&
      other.color == color &&
      other.done == done;

  @override
  int get hashCode => Object.hash(kind, id, day, minute, label, color, done);
}

/// Which point overlays to load for a range.
@immutable
class OverlayQuery {
  const OverlayQuery(this.range, {this.habits = false, this.checklistDue = false});

  final DayRange range;
  final bool habits;
  final bool checklistDue;

  bool get isEmpty => !habits && !checklistDue;

  @override
  bool operator ==(Object other) =>
      other is OverlayQuery && other.range == range && other.habits == habits && other.checklistDue == checklistDue;

  @override
  int get hashCode => Object.hash(range, habits, checklistDue);
}

/// Markers of a range from the habits and checklists application APIs (overridable in tests).
final plannerOverlayMarkersProvider = Provider.autoDispose.family<List<OverlayMarker>, OverlayQuery>((ref, q) {
  final out = <OverlayMarker>[];
  if (q.habits) {
    for (var i = 0; i < q.range.days; i++) {
      final day = q.range.start.plusDays(i);
      final views = ref.watch(habitDayViewsProvider(day)).value ?? const <HabitDayView>[];
      for (final v in views) {
        if (!v.isSlot) continue;
        for (final s in v.slots) {
          final at = LocalDateTime.tryParse(s.key);
          if (at == null || at.date != day) continue;
          out.add(
            OverlayMarker(
              kind: OverlayMarkerKind.habit,
              id: 'habit|${v.habit.id}|${s.key}',
              targetId: v.habit.id,
              periodKey: s.key,
              day: day,
              minute: at.time.minuteOfDay,
              label: v.habit.name,
              color: v.habit.color,
              done: s.status == PeriodStatus.done,
            ),
          );
        }
      }
    }
  }
  if (q.checklistDue) {
    for (final s in ref.watch(allItemsProvider).value ?? const []) {
      final due = s.item.dueLocal;
      if (due == null || !s.item.status.isOpen || !q.range.contains(due.date)) continue;
      out.add(
        OverlayMarker(
          kind: OverlayMarkerKind.checklistDue,
          id: 'item|${s.item.id}',
          targetId: s.item.checklistId,
          itemId: s.item.id,
          day: due.date,
          minute: due.time.minuteOfDay,
          label: s.item.text,
          color: s.checklistColor,
        ),
      );
    }
  }
  out.sort((a, b) => a.day == b.day ? a.minute.compareTo(b.minute) : a.day.compareTo(b.day));
  return out;
});

/// Tap on a marker: a habit slot toggles its check-in; a checklist item opens its list.
Future<void> openOverlayMarker(BuildContext context, WidgetRef ref, OverlayMarker m) async {
  switch (m.kind) {
    case OverlayMarkerKind.habit:
      final habit = (ref.read(habitsProvider).value ?? const <Habit>[]).firstWhereOrNull((h) => h.id == m.targetId);
      if (habit is! BuildHabit || m.periodKey == null) {
        ref.read(plannerNavProvider).openHabit(context, m.targetId);
        return;
      }
      final service = ref.read(checkInServiceProvider);
      if (m.done) {
        await service.markNotDone(habit, m.periodKey!);
      } else {
        await service.markDone(habit, m.periodKey!);
      }
    case OverlayMarkerKind.checklistDue:
      ref.read(plannerNavProvider).openChecklist(context, m.targetId, itemId: m.itemId);
  }
}

/// A small marker positioned by the grid at its time (≥ 48 dp hit area through padding).
class OverlayMarkerChip extends StatelessWidget {
  const OverlayMarkerChip({required this.marker, required this.onTap, this.timeText, super.key});

  final OverlayMarker marker;
  final String? timeText;
  final VoidCallback onTap;

  static const extent = 18.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = marker.color == null ? colors.tertiary : Color(marker.color!);
    final habit = marker.kind == OverlayMarkerKind.habit;
    final l = context.l10n;
    final label = [
      if (habit) l.pvOverlayHabits else l.pvOverlayChecklistDue,
      marker.label,
      ?timeText,
      if (marker.done) l.pvStatusDone,
    ].join(', ');
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('overlay-${marker.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: extent,
          padding: const EdgeInsetsDirectional.only(start: 2, end: Space.xs),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(color: accent, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                habit ? (marker.done ? Icons.check_circle : Icons.radio_button_unchecked) : Icons.flag_outlined,
                size: 12,
                color: accent,
              ),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  marker.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, height: 1.1, color: colors.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Positions [markers] of a page body (timeline renderer) in content coordinates.
List<Widget> positionedMarkers({
  required List<OverlayMarker> markers,
  required List<LocalDate> days,
  required PageOverlayContext page,
  required double width,
  required Widget Function(OverlayMarker m) builder,
}) {
  if (markers.isEmpty || days.isEmpty) return const [];
  final col = width / days.length;
  final out = <Widget>[];
  final usedRows = <String, int>{};
  for (final m in markers) {
    final i = days.indexOf(m.day);
    if (i < 0) continue;
    final y = page.axis.yOf(m.minute, ppm: page.ppm);
    // Markers at the same time of the same day stack downwards.
    final slot = '${m.day}|${(y / OverlayMarkerChip.extent).floor()}';
    final stack = usedRows[slot] = (usedRows[slot] ?? -1) + 1;
    final x = page.rtl ? width - (i + 1) * col : i * col;
    out.add(
      Positioned(
        left: x + 2,
        top: y + stack * (OverlayMarkerChip.extent + 1),
        width: math.max(0.0, col - 4),
        height: OverlayMarkerChip.extent,
        child: builder(m),
      ),
    );
  }
  return out;
}

/// Free-slot shading (T3.7.04 overlay): openings inside work hours of each work day.
class FreeSlotsPainter extends CustomPainter {
  FreeSlotsPainter({required this.page, required this.openings, required this.color});

  final PageOverlayContext page;
  final List<FreeInterval> openings;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (page.days.isEmpty) return;
    final col = size.width / page.days.length;
    final fill = Paint()..color = color.withValues(alpha: 0.10);
    final edge = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 2;
    for (final o in openings) {
      final i = page.days.indexOf(o.day);
      if (i < 0) continue;
      final startMinute = o.start.date == o.day ? o.start.time.minuteOfDay : 0;
      final endMinute = o.end.date == o.day ? o.end.time.minuteOfDay : 1440;
      final top = page.axis.yOf(startMinute, ppm: page.ppm);
      final bottom = page.axis.yOf(endMinute, ppm: page.ppm, end: true);
      final x = page.rtl ? size.width - (i + 1) * col : i * col;
      final rect = Rect.fromLTRB(x + 1, top, x + col - 1, bottom);
      canvas.drawRect(rect, fill);
      final edgeX = page.rtl ? rect.right - 1 : rect.left + 1;
      canvas.drawLine(Offset(edgeX, rect.top), Offset(edgeX, rect.bottom), edge);
    }
  }

  @override
  bool shouldRepaint(FreeSlotsPainter old) =>
      old.color != color || !const ListEquality<FreeInterval>().equals(old.openings, openings) || old.page.ppm != page.ppm;
}

/// Occupancy heat tint (T3.3.23): each hour cell tinted by its average load over past weeks.
class HeatTintPainter extends CustomPainter {
  HeatTintPainter({required this.page, required this.grid, required this.color});

  final PageOverlayContext page;
  final OccupancyGrid grid;
  final Color color;

  static const _alphas = [0.0, 0.05, 0.09, 0.14, 0.2];

  @override
  void paint(Canvas canvas, Size size) {
    if (page.days.isEmpty) return;
    final col = size.width / page.days.length;
    final paint = Paint();
    for (final (i, day) in page.days.indexed) {
      final x = page.rtl ? size.width - (i + 1) * col : i * col;
      for (var h = 0; h < 24; h++) {
        final bin = heatBin(grid.load(day.weekday.iso, h));
        if (bin == 0) continue;
        paint.color = color.withValues(alpha: _alphas[bin]);
        final top = page.axis.yOf(h * 60, ppm: page.ppm);
        final bottom = page.axis.yOf(h * 60 + 60, ppm: page.ppm, end: true);
        canvas.drawRect(Rect.fromLTRB(x, top, x + col, bottom), paint);
      }
    }
  }

  @override
  bool shouldRepaint(HeatTintPainter old) => old.grid != grid || old.color != color || old.page.ppm != page.ppm;
}

/// Items of the page days that block time (timed segments of the slices), for the finder.
List<PlannerItem> pageItems(PageOverlayContext page) => [
  for (final d in page.days)
    if (page.slices[d] case final s?) ...[for (final seg in s.timed) seg.item],
];
