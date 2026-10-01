import 'dart:async';
import 'dart:math' as math;

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/engine/day_timeline.dart';
import 'package:everslot/features/planner/presentation/grid/engine/radial_geometry.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/occurrence_panel.dart';
import 'package:everslot/features/planner/presentation/view_config/view_settings_sheet.dart';
import 'package:everslot/features/planner/presentation/views/item_chip.dart';
import 'package:everslot/features/planner/presentation/views/mini_month.dart';
import 'package:everslot/features/planner/presentation/views/planner_chrome.dart';
import 'package:everslot/features/planner/presentation/views/planner_keys.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Zoom choices around now (hours; 0 = the whole dial).
const radialZoomChoices = [0, 1, 2, 4, 6, 12];

/// One arc to draw: its item, sweep and ring (overlaps go to inner rings).
@immutable
class _Arc {
  const _Arc(this.item, this.start, this.sweep, this.ring);

  final PlannerItem item;
  final double start;
  final double sweep;
  final int ring;
}

/// 24-hour radial clock (T3.7.10, Sectograph style): the day as a 24 h (or 12 h) dial with an arc
/// per occurrence colored by category, the now hand, free gaps visible as bare track; tap an arc to
/// open the occurrence; zoom 1–12 h around now (`options.hours`, `options.zoomHours`).
class RadialView extends ConsumerStatefulWidget {
  const RadialView({required this.args, super.key});

  final PlannerViewArgs args;

  @override
  ConsumerState<RadialView> createState() => _RadialViewState();
}

class _RadialViewState extends ConsumerState<RadialView> {
  late LocalDate _day;

  String get _key => widget.args.viewKey;

  @override
  void initState() {
    super.initState();
    _day = widget.args.date ?? ref.read(plannerAnchorProvider) ?? ref.read<LocalDate>(plannerTodayProvider);
  }

  void _go(LocalDate d) {
    setState(() => _day = d);
    ref.read(plannerAnchorProvider.notifier).set(d);
  }

  Future<void> _pick() async {
    final weekStart = ref.read(userPreferencesProvider).weekStart;
    final picked = await showMiniMonth(context, initial: _day, weekStart: weekStart, highlight: [_day]);
    if (picked != null) _go(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(plannerViewConfigProvider(_key));
    final prefs = ref.watch(userPreferencesProvider);
    final today = ref.watch(plannerTodayProvider);
    ref.watch(plannerNowProvider); // minute tick
    final hours = config.option<int>('hours', 24) == 12 ? 12 : 24;
    final zoom = config.option<int>('zoomHours', 0).clamp(0, 12);
    final f = context.plannerFormat(use24h: prefs.use24h);
    final zone = ref.watch(plannerZoneProvider);
    final timeline = ref.watch(timelineCacheProvider).of(_day, zone);
    final nowUtc = ref.read(clockProvider).nowUtc();
    final nowT = timeline.tOfInstant(nowUtc);
    final isToday = _day == today;
    final window = dialWindow(
      dayLength: timeline.lengthMinutes,
      hours: hours,
      zoomHours: isToday ? zoom : 0,
      nowT: isToday ? nowT.clamp(0, timeline.lengthMinutes - 1) : 0,
    );
    final items = [
      for (final i in filteredItems(ref, DayRange(_day, 1), config).value ?? const <PlannerItem>[])
        if (!i.allDay && i.status != OccurrenceStatus.cancelled) i,
    ]..sort((a, b) => a.startUtc.compareTo(b.startUtc));
    // Greedy rings: overlapping items move inward.
    final ringEnds = <int>[];
    final arcs = <_Arc>[];
    for (final i in items) {
      final ts = timeline.tOfInstant(i.startUtc);
      final te = timeline.tOfInstant(i.endUtc);
      final arc = arcOf(ts, te, window);
      if (arc == null) continue;
      var ring = ringEnds.indexWhere((e) => e <= ts);
      if (ring < 0) {
        ring = ringEnds.length;
        ringEnds.add(te);
      } else {
        ringEnds[ring] = te;
      }
      arcs.add(_Arc(i, arc.start, arc.sweep, math.min(ring, 2)));
    }
    final colors = viewColors(context, ref, config);
    final notifier = ref.read(plannerViewConfigProvider(_key).notifier);
    final current = items.where((i) => i.startUtc.isBefore(nowUtc) && i.endUtc.isAfter(nowUtc)).firstOrNull;
    final next = items.where((i) => i.startUtc.isAfter(nowUtc)).firstOrNull;
    return PlannerViewScaffold(
      viewKey: _key,
      toolbar: DatePagedToolbar(
        title: f.dayLong(_day),
        onPrevious: () => _go(_day.plusDays(-1)),
        onNext: () => _go(_day.plusDays(1)),
        onToday: () => _go(today),
        onTitleTap: () => unawaited(_pick()),
        previousLabel: l.pvPreviousDay,
        nextLabel: l.pvNextDay,
        trailing: [
          PopupMenuButton<String>(
            key: const Key('radial-options'),
            tooltip: l.pvRadialHours,
            icon: const Icon(Icons.av_timer),
            onSelected: (v) => v.startsWith('zoom:')
                ? notifier.change((c) => c.withOption('zoomHours', int.parse(v.substring(5))))
                : notifier.change((c) => c.withOption('hours', int.parse(v))),
            itemBuilder: (_) => [
              CheckedPopupMenuItem(value: '24', checked: hours == 24, child: Text(l.pvRadial24)),
              CheckedPopupMenuItem(value: '12', checked: hours == 12, child: Text(l.pvRadial12)),
              const PopupMenuDivider(),
              for (final z in radialZoomChoices)
                CheckedPopupMenuItem(
                  value: 'zoom:$z',
                  checked: z == zoom,
                  child: Text(z == 0 ? l.pvRadialHours : '${l.pvZoomAroundNow} · ${f.duration(z * 60)}'),
                ),
            ],
          ),
          PlannerFilterButton(viewKey: _key),
          PlannerMoreMenu(viewKey: _key, kind: ViewSettingsKind.list),
        ],
      ),
      body: PlannerKeys(
        onPrevious: () => _go(_day.plusDays(-1)),
        onNext: () => _go(_day.plusDays(1)),
        onToday: () => _go(today),
        child: Column(
          children: [
            ActiveFilterBar(viewKey: _key),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final size = math.min(box.maxWidth, box.maxHeight) - 2 * Space.md;
                  return Center(
                    child: _Dial(
                      size: math.max(120, size),
                      arcs: arcs,
                      window: window,
                      timeline: timeline,
                      nowT: isToday ? nowT : null,
                      format: f,
                      colorOf: (i) => colors.of(i).accent,
                      center: [
                        if (isToday) f.timeOf(ref.read(plannerNowProvider)),
                        if (current != null) current.title else if (next != null) '${l.pvNextUp}: ${next.title}',
                      ],
                      onTapItem: (i) => unawaited(showOccurrenceSheet(context, i)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      fab: PlannerFab(start: () => suggestedStart(_day, ref.read(plannerNowProvider))),
    );
  }
}

class _Dial extends StatelessWidget {
  const _Dial({
    required this.size,
    required this.arcs,
    required this.window,
    required this.timeline,
    required this.nowT,
    required this.format,
    required this.colorOf,
    required this.center,
    required this.onTapItem,
  });

  final double size;
  final List<_Arc> arcs;
  final DialWindow window;
  final DayTimeline timeline;
  final int? nowT;
  final AppFormat format;
  final Color Function(PlannerItem) colorOf;
  final List<String> center;
  final ValueChanged<PlannerItem> onTapItem;

  static const double stroke = 22;

  double _radius(int ring) => size / 2 - 26 - ring * (stroke + 3);

  PlannerItem? _hit(Offset local) {
    final c = Offset(size / 2, size / 2);
    final v = local - c;
    final r = v.distance;
    final t = tAtAngle(math.atan2(v.dy, v.dx), window);
    for (final a in arcs.reversed) {
      final ring = _radius(a.ring);
      if ((r - ring).abs() > stroke / 2 + 4) continue;
      final ts = timeline.tOfInstant(a.item.startUtc);
      final te = timeline.tOfInstant(a.item.endUtc);
      if (t >= ts && t < te) return a.item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final labels = <(String, double)>[];
    final step = window.lengthT >= 720 ? (window.lengthT >= 1380 ? 180 : 120) : 60;
    for (var t = (window.startT / 60).ceil() * 60; t < window.endT; t += step) {
      final (wall, _) = timeline.wallAt(t.clamp(0, timeline.lengthMinutes));
      labels.add((format.time(LocalTime.fromMinuteOfDay(wall % 1440)), angleOf(t, window)));
    }
    return Semantics(
      container: true,
      label: [
        ...center,
        for (final a in arcs) '${a.item.title}, ${format.timeRange(a.item.startLocal, a.item.endLocal)}',
      ].join('. '),
      child: GestureDetector(
        key: const Key('radial-dial'),
        onTapUp: (d) {
          final hit = _hit(d.localPosition);
          if (hit != null) onTapItem(hit);
        },
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _DialPainter(
              arcs: arcs,
              radius: _radius,
              stroke: stroke,
              track: c.surfaceContainerHighest,
              colorOf: colorOf,
              nowAngle: nowT == null || nowT! < window.startT || nowT! >= window.endT ? null : angleOf(nowT!, window),
              nowColor: context.appColors.nowLine,
              labels: labels,
              labelStyle: TextStyle(fontSize: 10, color: c.onSurfaceVariant),
              textDirection: Directionality.of(context),
            ),
            child: Center(
              child: SizedBox(
                width: size * 0.45,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (i, line) in center.indexed)
                      Text(
                        line,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: i == 0 ? context.text.headlineSmall : context.text.bodySmall,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.arcs,
    required this.radius,
    required this.stroke,
    required this.track,
    required this.colorOf,
    required this.nowAngle,
    required this.nowColor,
    required this.labels,
    required this.labelStyle,
    required this.textDirection,
  });

  final List<_Arc> arcs;
  final double Function(int ring) radius;
  final double stroke;
  final Color track;
  final Color Function(PlannerItem) colorOf;
  final double? nowAngle;
  final Color nowColor;
  final List<(String, double)> labels;
  final TextStyle labelStyle;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    // Free time = the bare track.
    canvas.drawCircle(
      center,
      radius(0),
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    for (final a in arcs) {
      final r = radius(a.ring);
      final done = a.item.isDone || a.item.status == OccurrenceStatus.skipped;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        a.start + 0.004,
        math.max(0.01, a.sweep - 0.008),
        false,
        Paint()
          ..color = colorOf(a.item).withValues(alpha: done ? 0.45 : 1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt,
      );
    }
    final outer = radius(0) + stroke / 2 + 10;
    for (final (text, angle) in labels) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: textDirection,
      )..layout();
      final p = center + Offset(math.cos(angle), math.sin(angle)) * outer;
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
      tp.dispose();
    }
    final now = nowAngle;
    if (now != null) {
      final paint = Paint()
        ..color = nowColor
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        center + Offset(math.cos(now), math.sin(now)) * (radius(2) - stroke),
        center + Offset(math.cos(now), math.sin(now)) * (radius(0) + stroke / 2 + 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.arcs != arcs || old.nowAngle != nowAngle || old.track != track || old.labels.length != labels.length;
}
