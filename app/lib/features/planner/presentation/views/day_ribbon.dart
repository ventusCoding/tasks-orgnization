import 'dart:math' as math;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/engine/day_slices.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:material_ui/material_ui.dart';

/// One piece of a ribbon: a block (an item) or a free gap between blocks.
@immutable
sealed class RibbonPiece {
  const RibbonPiece(this.start, this.end);

  /// Wall-clock minutes relative to the day start (may exceed 1440 for items crossing midnight).
  final int start;
  final int end;

  int get minutes => end - start;
}

final class RibbonBlock extends RibbonPiece {
  const RibbonBlock(super.start, super.end, this.item, {this.overlaps = false});

  final PlannerItem item;

  /// Starts before the previous block ended (drawn indented).
  final bool overlaps;
}

final class RibbonGap extends RibbonPiece {
  const RibbonGap(super.start, super.end);
}

/// Blocks in start order with the free gaps between them (T3.5.14 / T3.6.13).
List<RibbonPiece> ribbonPieces(DaySlice slice, {int minGap = 1}) {
  final pieces = <RibbonPiece>[];
  var cursor = -1;
  final seen = <String>{};
  for (final s in slice.timed) {
    if (!seen.add(s.item.key)) continue;
    final start = s.wallStart;
    final end = math.max(start, s.continuesAfter ? 1440 : s.wallEnd);
    if (cursor >= 0 && start - cursor >= minGap) pieces.add(RibbonGap(cursor, start));
    pieces.add(RibbonBlock(start, end, s.item, overlaps: cursor > start));
    cursor = math.max(cursor, end);
  }
  return pieces;
}

/// The day as a ribbon of rounded blocks sized by duration with dotted "free 45 m" connectors and a
/// now marker (T3.5.14, Structured / Tiimo style). Same actions as the slot rows.
class DayRibbon extends StatelessWidget {
  const DayRibbon({
    required this.day,
    required this.slice,
    required this.colors,
    required this.format,
    required this.now,
    required this.onOpen,
    required this.onToggle,
    required this.onMenu,
    required this.onCreate,
    this.dimPast = true,
    super.key,
  });

  final LocalDate day;
  final DaySlice slice;
  final ItemColorResolver colors;
  final AppFormat format;
  final LocalDateTime now;
  final bool dimPast;
  final ValueChanged<PlannerItem> onOpen;
  final ValueChanged<PlannerItem> onToggle;
  final ValueChanged<PlannerItem> onMenu;
  final void Function(LocalDateTime start, int minutes) onCreate;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pieces = ribbonPieces(slice);
    if (pieces.isEmpty) {
      return EmptyState(icon: Icons.wb_sunny_outlined, title: l.pvEmptyDay, message: l.pvHintLongPress);
    }
    final nowMinute = now.date == day ? now.time.minuteOfDay : null;
    final children = <Widget>[];
    var nowPlaced = nowMinute == null;
    for (final p in pieces) {
      if (!nowPlaced && nowMinute! < p.start) {
        children.add(_NowMarker(label: format.timeOf(now)));
        nowPlaced = true;
      }
      switch (p) {
        case RibbonGap():
          children.add(
            _Gap(
              label: l.pvFreeGap(format.duration(p.minutes)),
              onTap: () => onCreate(day.atStartOfDay.plusMinutes(p.start), p.minutes),
            ),
          );
        case RibbonBlock(:final item):
          final current = nowMinute != null && nowMinute >= p.start && nowMinute < p.end;
          children.add(
            _Block(
              piece: p,
              colors: colors.of(item),
              timeText: format.timeRange(item.startLocal, item.endLocal),
              durationText: format.duration(item.durationMinutes),
              progress: current ? (nowMinute - p.start) / math.max(1, p.minutes) : null,
              past: dimPast && item.endLocal.isBefore(now),
              onOpen: () => onOpen(item),
              onToggle: () => onToggle(item),
              onMenu: () => onMenu(item),
            ),
          );
          if (current) nowPlaced = true;
      }
    }
    if (!nowPlaced) children.add(_NowMarker(label: format.timeOf(now)));
    return ListView(
      key: const Key('day-ribbon'),
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.md, Space.lg, 96),
      children: children,
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.piece,
    required this.colors,
    required this.timeText,
    required this.durationText,
    required this.onOpen,
    required this.onToggle,
    required this.onMenu,
    this.progress,
    this.past = false,
  });

  final RibbonBlock piece;
  final TileColors colors;
  final String timeText;
  final String durationText;
  final double? progress;
  final bool past;
  final VoidCallback onOpen;
  final VoidCallback onToggle;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final item = piece.item;
    final done = item.isDone;
    final height = (56 + piece.minutes * 0.6).clamp(56.0, 220.0);
    final fg = colors.foreground;
    final l = context.l10n;
    return Padding(
      padding: EdgeInsetsDirectional.only(start: piece.overlaps ? Space.xl : 0, bottom: Space.xs),
      child: Semantics(
        button: true,
        label: '${item.title}, $timeText, ${context.statusLabel(item.status)}',
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.lg),
          onTap: onOpen,
          onLongPress: onMenu,
          child: Opacity(
            opacity: done || item.status == OccurrenceStatus.skipped ? 0.55 : (past ? 0.75 : 1),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(Radii.lg),
                border: Border.all(color: colors.accent, width: progress != null ? 2 : 1),
              ),
              child: Stack(
                children: [
                  if (progress != null)
                    PositionedDirectional(
                      start: 0,
                      top: 0,
                      bottom: 0,
                      width: 4,
                      child: FractionallySizedBox(
                        alignment: AlignmentDirectional.topStart,
                        heightFactor: progress!.clamp(0.0, 1.0),
                        child: ColoredBox(color: context.appColors.nowLine),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(Space.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: colors.accent,
                          child: Icon(
                            IconCatalog.iconFor(item.icon, fallback: Icons.event),
                            size: 18,
                            color: CategoryColors.onBackground(colors.accent),
                          ),
                        ),
                        const SizedBox(width: Space.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.titleSmall?.copyWith(
                                  color: fg,
                                  decoration: done ? TextDecoration.lineThrough : null,
                                  decorationColor: fg,
                                ),
                              ),
                              Text(
                                '$timeText · $durationText',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.labelSmall?.copyWith(color: fg),
                              ),
                            ],
                          ),
                        ),
                        if (item.trackingMode == TrackingMode.check)
                          IconButton(
                            tooltip: done ? l.pvMarkNotDone : l.pvMarkDone,
                            icon: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: fg),
                            onPressed: onToggle,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Gap extends StatelessWidget {
  const _Gap({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$label, ${context.l10n.pvCreateHere}',
    child: ExcludeSemantics(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 36,
          child: Row(
            children: [
              SizedBox(width: 36, child: CustomPaint(painter: _DottedLine(context.colors.outline))),
              Text(
                label,
                style: context.text.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DottedLine extends CustomPainter {
  _DottedLine(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    for (var y = 2.0; y < size.height; y += 6) {
      canvas.drawCircle(Offset(size.width / 2, y), 1.5, p);
    }
  }

  @override
  bool shouldRepaint(_DottedLine old) => old.color != color;
}

class _NowMarker extends StatelessWidget {
  const _NowMarker({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    key: const Key('ribbon-now'),
    padding: const EdgeInsets.symmetric(vertical: Space.xs),
    child: Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: context.appColors.nowLine, borderRadius: BorderRadius.circular(Radii.pill)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 2),
            child: Text(
              label,
              style: context.text.labelSmall?.copyWith(color: CategoryColors.onBackground(context.appColors.nowLine)),
            ),
          ),
        ),
        Expanded(child: Container(height: 2, color: context.appColors.nowLine)),
      ],
    ),
  );
}
