import 'dart:async';

import 'package:everslot/design_system/tokens.dart';
import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';

/// Section header used in lists and settings.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.padding});

  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding ?? const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.lg, Space.lg, Space.sm),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: context.text.titleSmall?.copyWith(color: context.colors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// Colored pill with icon + label (status, category…). Color is never the only signal.
class StatusPill extends StatelessWidget {
  const StatusPill({required this.label, required this.color, super.key, this.icon, this.dense = false});

  final String label;
  final Color color;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final tint = color.withValues(alpha: 0.14);
    // Text/icon stay ≥ 4.5:1 on the pill's own tint (T1.3.15): the status color is darkened
    // (light theme) or lightened (dark theme) only as much as needed.
    final foreground = CategoryColors.readableOn(color, Color.alphaBlend(tint, context.colors.surface));
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? Space.xs + 2 : Space.sm, vertical: dense ? 1 : Space.xxs + 1),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: dense ? 12 : 14, color: foreground), const SizedBox(width: Space.xs)],
          Text(label, style: (dense ? context.text.labelSmall : context.text.labelMedium)?.copyWith(color: foreground)),
        ],
      ),
    );
  }
}

/// Circular progress ring with centered child (habits, checklists).
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.progress,
    super.key,
    this.size = 40,
    this.stroke = 4,
    this.color,
    this.child,
    this.semanticsLabel,
  });

  final double progress;
  final double size;
  final double stroke;
  final Color? color;
  final Widget? child;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticsLabel,
    value: '${(progress.clamp(0, 1) * 100).round()}%',
    child: SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress.clamp(0, 1).toDouble(),
              strokeWidth: stroke,
              backgroundColor: context.colors.surfaceContainerHighest,
              color: color ?? context.colors.primary,
            ),
          ),
          ?child,
        ],
      ),
    ),
  );
}

/// One segment of a [SegmentedBar].
class BarSegment {
  const BarSegment(this.value, this.color, this.label);

  final double value;
  final Color color;
  final String label;
}

/// Horizontal bar split by status (checklist progress by status, T4.3.06).
class SegmentedBar extends StatelessWidget {
  const SegmentedBar({required this.segments, super.key, this.height = 6});

  final List<BarSegment> segments;
  final double height;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<double>(0, (a, s) => a + s.value);
    return Semantics(
      label: segments.map((s) => '${s.label}: ${s.value.toStringAsFixed(0)}').join(', '),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.pill),
        child: SizedBox(
          height: height,
          child: total <= 0
              ? ColoredBox(color: context.colors.surfaceContainerHighest)
              : Row(
                  children: [
                    for (final s in segments)
                      if (s.value > 0)
                        Expanded(
                          flex: (s.value * 1000 / total).round().clamp(1, 1000),
                          child: ColoredBox(color: s.color),
                        ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Small colored dot (categories).
class ColorDot extends StatelessWidget {
  const ColorDot(this.color, {super.key, this.size = 10});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// Announces a message to screen readers (T1.3.15).
void announce(BuildContext context, String message) {
  unawaited(SemanticsService.sendAnnouncement(View.of(context), message, Directionality.of(context)));
}
