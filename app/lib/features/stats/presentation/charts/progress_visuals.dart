/// Progress & target visuals (T6.2.07): concentric progress rings (never beyond 100 % visually,
/// "+20 %" over-achievement text), bullet chart (actual bar, target marker, previous-period ghost,
/// qualitative bands), milestone bars (label, ETA, achieved check, range marker, supportive restart
/// note, sources) and the live counter (d/h/m/s from a shared 1 Hz ticker that runs only while
/// visible; screen-reader text updates at most once per minute).
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/presentation/charts/chart_support.dart';
import 'package:everslot/features/stats/presentation/charts/chart_theme.dart';
import 'package:material_ui/material_ui.dart';

class ProgressRings extends StatelessWidget {
  const ProgressRings(this.data, {super.key, this.size = 120});

  final RingData data;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);
    final f = statFormatOf(context);
    final center = data.centerValue;
    final over = data.rings.isEmpty ? 0.0 : data.rings.first.$2 - 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: chartAnimation(context),
                builder: (context, t, _) => CustomPaint(
                  size: Size.square(size),
                  painter: _RingsPainter([
                    for (final r in data.rings) (math.min(1, r.$2) * t, theme.resolve(r.$3)),
                  ], theme.grid),
                ),
              ),
              // The label scales down inside the ring (text scale 2.0 never overflows it).
              Padding(
                padding: EdgeInsets.all(size * 0.2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (center != null)
                        Text(
                          f.value(center, data.centerUnit),
                          style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      if (over > 0.005)
                        Text(
                          context.l10n.chartsOver(f.percent(over)),
                          style: context.text.labelSmall?.copyWith(color: theme.tone(ChartTone.positive)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (data.rings.length > 1) ...[
          const SizedBox(width: Space.md),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final r in data.rings)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: Space.xs),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ColorDot(theme.resolve(r.$3)),
                        const SizedBox(width: Space.xs),
                        Flexible(child: Text('${f.label(r.$1)} ${f.percent(r.$2)}', style: context.text.bodySmall)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.rings, this.track);

  final List<(double, Color)> rings;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    for (var i = 0; i < rings.length; i++) {
      final radius = size.width / 2 - stroke / 2 - i * (stroke + 3);
      if (radius <= 0) break;
      final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: radius);
      canvas.drawArc(
        rect,
        0,
        math.pi * 2,
        false,
        Paint()
          ..color = track
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * rings[i].$1,
        false,
        Paint()
          ..color = rings[i].$2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => true;
}

class BulletChart extends StatelessWidget {
  const BulletChart(this.data, {super.key, this.height = 56});

  final BulletData data;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);
    final f = statFormatOf(context);
    final maxV = [data.max ?? 0, data.actual, data.target ?? 0, data.previous ?? 0, ...data.bands].reduce(math.max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height * 0.55,
          width: double.infinity,
          child: CustomPaint(
            painter: _BulletPainter(
              data,
              maxV <= 0 ? 1 : maxV * 1.05,
              theme,
              rtl: Directionality.of(context) == TextDirection.rtl,
            ),
          ),
        ),
        const SizedBox(height: Space.xs),
        Wrap(
          spacing: Space.md,
          children: [
            Text(
              '${f.label(data.label ?? const TokenLabel(LabelToken.actual))} ${f.value(data.actual, data.unit)}',
              style: context.text.labelMedium,
            ),
            if (data.target != null)
              Text(context.l10n.chartsTarget(f.value(data.target!, data.unit)), style: context.text.labelSmall),
            if (data.previous != null)
              Text(context.l10n.chartsPrevious(f.value(data.previous!, data.unit)), style: context.text.labelSmall),
          ],
        ),
      ],
    );
  }
}

class _BulletPainter extends CustomPainter {
  _BulletPainter(this.data, this.maxV, this.theme, {required this.rtl});

  final BulletData data;
  final double maxV;
  final ChartTheme theme;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    double x(double v) {
      final t = (v / maxV).clamp(0.0, 1.0);
      return rtl ? size.width * (1 - t) : size.width * t;
    }

    Rect span(double from, double to, double top, double bottom) =>
        Rect.fromLTRB(math.min(x(from), x(to)), top, math.max(x(from), x(to)), bottom);

    // Qualitative bands (darker = better).
    var prev = 0.0;
    for (var i = 0; i < data.bands.length; i++) {
      canvas.drawRect(
        span(prev, data.bands[i], 0, size.height),
        Paint()..color = theme.grid.withValues(alpha: 0.35 + 0.2 * i),
      );
      prev = data.bands[i];
    }
    if (data.bands.isEmpty) canvas.drawRect(Offset.zero & size, Paint()..color = theme.grid.withValues(alpha: 0.35));
    if (data.previous != null) {
      canvas.drawRect(
        span(0, data.previous!, size.height * 0.2, size.height * 0.8),
        Paint()..color = theme.muted.withValues(alpha: 0.5),
      );
    }
    canvas.drawRect(span(0, data.actual, size.height * 0.3, size.height * 0.7), Paint()..color = theme.seriesColor(0));
    if (data.target != null) {
      final tx = x(data.target!);
      canvas.drawRect(Rect.fromLTRB(tx - 1.5, 0, tx + 1.5, size.height), Paint()..color = theme.onSurface);
    }
  }

  @override
  bool shouldRepaint(_BulletPainter old) => old.data != data || old.rtl != rtl || old.theme != theme;
}

class MilestoneBars extends StatelessWidget {
  const MilestoneBars(this.data, {super.key, this.labelOf, this.sourceName, this.now});

  final MilestoneData data;

  /// Text of a row label (health milestones pass their localized texts).
  final String Function(ChartLabel label)? labelOf;

  /// Display name of a source id.
  final String Function(String id)? sourceName;

  /// "Now" for ETAs (defaults to the device clock).
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);
    final f = statFormatOf(context);
    final at = (now ?? () => DateTime.now().toUtc())();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (data.restarted)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: Space.sm),
            child: Text(
              context.l10n.chartsMilestoneRestarted,
              style: context.text.bodySmall?.copyWith(color: theme.label),
            ),
          ),
        for (final row in data.rows)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: Space.sm),
            child: Semantics(
              label: '${labelOf?.call(row.label) ?? f.label(row.label)}, ${f.percent(row.progress)}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        row.state == MilestoneRowState.done
                            ? Icons.check_circle
                            : (row.isNext ? Icons.flag_outlined : Icons.radio_button_unchecked),
                        size: 18,
                        color: row.state == MilestoneRowState.done ? theme.tone(ChartTone.done) : theme.label,
                      ),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: Text(
                          labelOf?.call(row.label) ?? f.label(row.label),
                          style: context.text.bodyMedium?.copyWith(fontWeight: row.isNext ? FontWeight.w600 : null),
                        ),
                      ),
                      const SizedBox(width: Space.sm),
                      Text(switch (row.state) {
                        MilestoneRowState.done => context.l10n.chartsMilestoneReached,
                        MilestoneRowState.inWindow => context.l10n.chartsMilestoneInWindow,
                        MilestoneRowState.upcoming =>
                          row.eta == null
                              ? ''
                              : context.l10n.chartsMilestoneEta(f.duration(row.eta!.difference(at).inSeconds / 60)),
                      }, style: context.text.labelSmall?.copyWith(color: theme.label)),
                    ],
                  ),
                  const SizedBox(height: Space.xs),
                  SizedBox(
                    height: 8,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _ProgressBarPainter(
                        row.progress,
                        row.state == MilestoneRowState.done ? theme.tone(ChartTone.done) : theme.seriesColor(0),
                        theme.grid,
                        marker: row.rangeMarker,
                        rtl: Directionality.of(context) == TextDirection.rtl,
                      ),
                    ),
                  ),
                  if (row.sources.isNotEmpty)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(top: 2),
                      child: Text(
                        context.l10n.chartsMilestoneSources(
                          row.sources.map((s) => sourceName?.call(s) ?? s).join(', '),
                        ),
                        style: context.text.labelSmall?.copyWith(color: theme.label),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter(this.progress, this.color, this.track, {this.marker, required this.rtl});

  final double progress;
  final Color color;
  final Color track;
  final double? marker;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.height / 2);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, r), Paint()..color = track);
    final w = size.width * progress.clamp(0.0, 1.0);
    final fill = rtl ? Rect.fromLTRB(size.width - w, 0, size.width, size.height) : Rect.fromLTRB(0, 0, w, size.height);
    canvas.drawRRect(RRect.fromRectAndRadius(fill, r), Paint()..color = color);
    if (marker != null) {
      final mx = rtl ? size.width * (1 - marker!) : size.width * marker!;
      canvas.drawRect(Rect.fromLTRB(mx - 1, -2, mx + 1, size.height + 2), Paint()..color = track.withValues(alpha: 1));
    }
  }

  @override
  bool shouldRepaint(_ProgressBarPainter old) =>
      old.progress != progress || old.color != color || old.marker != marker || old.rtl != rtl;
}

/// A shared 1 Hz ticker: one timer for every visible counter, stopped when none listens.
class CounterTicker extends ChangeNotifier {
  CounterTicker._();

  static final CounterTicker shared = CounterTicker._();

  Timer? _timer;
  int _listeners = 0;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _listeners++;
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    _listeners--;
    if (_listeners <= 0) {
      _listeners = 0;
      _timer?.cancel();
      _timer = null;
    }
  }

  bool get isRunning => _timer != null;
}

/// Live counter since [since] ("3 d 04:12:09"). Ticks only while visible ([TickerMode]); the
/// semantics label changes once per minute.
class LiveCounter extends StatefulWidget {
  const LiveCounter({required this.since, super.key, this.label, this.now, this.style});

  final DateTime since;
  final String? label;

  /// Current instant (tests inject a fake clock).
  final DateTime Function()? now;
  final TextStyle? style;

  @override
  State<LiveCounter> createState() => _LiveCounterState();
}

class _LiveCounterState extends State<LiveCounter> {
  bool _listening = false;

  void _tick() {
    if (mounted) setState(() {});
  }

  void _sync(bool visible) {
    if (visible && !_listening) {
      CounterTicker.shared.addListener(_tick);
      _listening = true;
    } else if (!visible && _listening) {
      CounterTicker.shared.removeListener(_tick);
      _listening = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync(TickerMode.valuesOf(context).enabled);
  }

  @override
  void dispose() {
    _sync(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = statFormatOf(context);
    final now = (widget.now ?? () => DateTime.now().toUtc())();
    final d = now.isBefore(widget.since) ? Duration.zero : now.difference(widget.since);
    final spoken = context.l10n.chartsCounterSemantics('${d.inDays}', '${d.inHours % 24}', '${d.inMinutes % 60}');
    return Semantics(
      label: widget.label == null ? spoken : '${widget.label}: $spoken',
      liveRegion: false,
      excludeSemantics: true,
      child: Text(
        f.counter(d),
        style:
            widget.style ??
            context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w700, fontFeatures: AppTheme.tabular),
      ),
    );
  }
}
