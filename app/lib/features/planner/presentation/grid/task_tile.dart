import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';

/// Tile variants picked by available size (T3.3.10).
enum TileVariant {
  /// Title, time range and icons.
  full,

  /// Title only.
  compact,

  /// Time + title on one line.
  chip,

  /// Color bar only.
  minimal,
}

TileVariant tileVariantFor(double width, double height) {
  if (width < 18 || height < 8) return TileVariant.minimal;
  if (height < 30) return TileVariant.chip;
  if (height < 46 || width < 64) return TileVariant.compact;
  return TileVariant.full;
}

/// Leading area of a `check` tile that toggles done (hit tested by the grid with ≥ 48 dp slop).
const kTileCheckExtent = 22.0;

/// A task occurrence in the grid. Purely visual: the grid does the hit testing (cheap with thousands
/// of tiles); semantics expose tap and custom actions for screen readers.
class TaskTile extends StatelessWidget {
  const TaskTile({
    required this.item,
    required this.colors,
    required this.timeText,
    required this.semanticsLabel,
    this.variant = TileVariant.full,
    this.past = false,
    this.dimPast = true,
    this.selected = false,
    this.lifted = false,
    this.compactDensity = false,
    this.continuesBefore = false,
    this.continuesAfter = false,
    this.showCheck = true,
    this.onTap,
    this.onToggleDone,
    this.customActions = const {},
    super.key,
  });

  final PlannerItem item;
  final TileColors colors;

  /// "09:15–10:00" (already formatted).
  final String timeText;
  final String semanticsLabel;
  final TileVariant variant;
  final bool past;
  final bool dimPast;
  final bool selected;
  final bool lifted;
  final bool compactDensity;
  final bool continuesBefore;
  final bool continuesAfter;
  final bool showCheck;
  final VoidCallback? onTap;
  final VoidCallback? onToggleDone;
  final Map<CustomSemanticsAction, VoidCallback> customActions;

  bool get _done => item.status == OccurrenceStatus.done;
  bool get _struck => _done || item.status == OccurrenceStatus.cancelled;
  bool get _hasCheck => showCheck && item.trackingMode == TrackingMode.check;

  @override
  Widget build(BuildContext context) {
    final app = context.appColors;
    final faded = _done || item.status == OccurrenceStatus.skipped || item.status == OccurrenceStatus.cancelled;
    final opacity = faded ? 0.55 : (past && dimPast ? 0.72 : 1.0);
    final radius = BorderRadius.vertical(
      top: Radius.circular(continuesBefore ? 0 : Radii.sm),
      bottom: Radius.circular(continuesAfter ? 0 : Radii.sm),
    );
    final leading = item.status == OccurrenceStatus.missed ? app.missed : colors.accent;
    Widget body = variant == TileVariant.minimal
        ? DecoratedBox(decoration: BoxDecoration(color: colors.accent, borderRadius: radius))
        : DecoratedBox(
            decoration: BoxDecoration(
              color: item.status == OccurrenceStatus.skipped ? context.colors.surfaceContainerHighest : colors.background,
              borderRadius: radius,
              border: BorderDirectional(
                start: BorderSide(color: leading, width: item.status == OccurrenceStatus.missed ? 4 : 3),
              ),
              boxShadow: lifted ? const [BoxShadow(blurRadius: 8, offset: Offset(0, 3), color: Color(0x33000000))] : null,
            ),
            child: item.status == OccurrenceStatus.skipped
                ? CustomPaint(painter: _HatchPainter(context.appColors.skipped.withValues(alpha: 0.25)), child: _content(context))
                : _content(context),
          );
    if (selected) {
      body = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(border: Border.all(color: context.colors.primary, width: 2), borderRadius: radius),
        child: body,
      );
    }
    if (item.status == OccurrenceStatus.inProgress && variant != TileVariant.minimal) {
      body = context.reduceMotion
          ? DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(border: Border.all(color: app.ongoing, width: 2), borderRadius: radius),
              child: body,
            )
          : _PulsingBorder(color: app.ongoing, radius: radius, child: body);
    }
    return Semantics(
      container: true,
      button: true,
      label: semanticsLabel,
      checked: _hasCheck ? _done : null,
      onTap: onTap,
      customSemanticsActions: customActions.isEmpty ? null : customActions,
      child: ExcludeSemantics(child: Opacity(opacity: opacity, child: body)),
    );
  }

  Widget _content(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final fg = colors.foreground;
      final size = compactDensity ? 11.0 : 12.0;
      final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 200.0;
      final narrow = width < 40;
      final titleStyle = TextStyle(
        color: fg,
        fontSize: size,
        fontWeight: FontWeight.w600,
        height: 1.15,
        decoration: _struck ? TextDecoration.lineThrough : null,
        decorationColor: fg,
      );
      final timeStyle = TextStyle(color: fg.withValues(alpha: 0.85), fontSize: size - 1, height: 1.15);
      final Widget? check = narrow
          ? null
          : _hasCheck
          ? Padding(
              padding: const EdgeInsetsDirectional.only(end: 3),
              child: Icon(_done ? Icons.check_circle : Icons.radio_button_unchecked, size: size + 3, color: fg),
            )
          : (_done ? Padding(padding: const EdgeInsetsDirectional.only(end: 3), child: Icon(Icons.check, size: size + 2, color: fg)) : null);
      final pad = EdgeInsetsDirectional.fromSTEB(narrow ? 2 : (compactDensity ? 3 : 5), 2, narrow ? 1 : 3, 2);
      // Content never overflows: it is laid out with unbounded height and clipped to the tile.
      Widget clipped(Widget child) => ClipRect(
        child: OverflowBox(
          alignment: AlignmentDirectional.topStart,
          minHeight: 0,
          maxHeight: double.infinity,
          child: Padding(padding: pad, child: child),
        ),
      );
      switch (variant) {
        case TileVariant.minimal:
          return const SizedBox.shrink();
        case TileVariant.chip:
          return clipped(
            Row(
              children: [
                ?check,
                Flexible(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '$timeText ', style: timeStyle),
                      TextSpan(text: item.title, style: titleStyle),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              ],
            ),
          );
        case TileVariant.compact:
          return clipped(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ?check,
                Expanded(child: Text(item.title, style: titleStyle, maxLines: 2, overflow: TextOverflow.ellipsis)),
              ],
            ),
          );
        case TileVariant.full:
          final icons = <IconData>[
            if (item.isRecurring) Icons.repeat,
            if (item.timeZone != null) Icons.public,
            if (item.linkedChecklistId != null) Icons.checklist,
            if (item.location != null) Icons.place_outlined,
          ];
          final fit = ((width - pad.horizontal) / 13).floor().clamp(0, icons.length);
          return clipped(
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ?check,
                    Expanded(child: Text(item.title, style: titleStyle, maxLines: 2, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                Text(timeText, style: timeStyle, maxLines: 1, overflow: TextOverflow.clip, softWrap: false),
                if (fit > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final i in icons.take(fit)) Padding(padding: const EdgeInsetsDirectional.only(end: 2), child: Icon(i, size: 11, color: fg)),
                    ],
                  ),
              ],
            ),
          );
      }
    },
  );
}

class _HatchPainter extends CustomPainter {
  _HatchPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    canvas
      ..save()
      ..clipRect(Offset.zero & size);
    for (var d = -size.height; d < size.width; d += 7) {
      canvas.drawLine(Offset(d, size.height), Offset(d + size.height, 0), p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HatchPainter old) => old.color != color;
}

class _PulsingBorder extends StatefulWidget {
  const _PulsingBorder({required this.color, required this.radius, required this.child});

  final Color color;
  final BorderRadius radius;
  final Widget child;

  @override
  State<_PulsingBorder> createState() => _PulsingBorderState();
}

class _PulsingBorderState extends State<_PulsingBorder> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) => DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border.all(color: widget.color.withValues(alpha: 0.35 + 0.65 * _c.value), width: 2),
        borderRadius: widget.radius,
      ),
      child: child,
    ),
    child: widget.child,
  );
}

/// "+N" overflow chip (T3.3.05 / T3.4.14).
class OverflowChip extends StatelessWidget {
  const OverflowChip({required this.label, required this.semanticsLabel, this.onTap, super.key});

  final String label;
  final String semanticsLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticsLabel,
    onTap: onTap,
    child: ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.secondaryContainer,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(color: context.colors.outlineVariant),
        ),
        child: Center(
          child: FittedBox(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                label,
                style: TextStyle(color: context.colors.onSecondaryContainer, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
