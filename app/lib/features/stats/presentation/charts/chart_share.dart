/// Share a chart as an image (T6.2.23): a preview sheet renders the chart card — title, period, the
/// chart and a small Everslot mark — and captures it as a 3× PNG for the share sheet. "Hide names"
/// replaces user-entered names (habits, lists, categories…) with "Item 1…". Nothing is uploaded: the
/// PNG is written to the temporary directory and handed to the platform share sheet.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/presentation/charts/chart_support.dart';
import 'package:everslot/features/stats/presentation/charts/chart_view.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Hands a PNG to the platform share sheet.
abstract interface class ChartImageSharer {
  Future<void> share(Uint8List png, {required String title});
}

/// Writes the PNG to the temporary directory and opens the share sheet.
final class PlatformChartImageSharer implements ChartImageSharer {
  const PlatformChartImageSharer();

  @override
  Future<void> share(Uint8List png, {required String title}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/everslot_chart.png');
    await file.writeAsBytes(png, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        subject: title,
      ),
    );
  }
}

/// The share target of charts (tests replace it).
ChartImageSharer chartImageSharer = const PlatformChartImageSharer();

/// Renders the [RepaintBoundary] behind [key] to PNG bytes at [pixelRatio].
Future<Uint8List?> captureChartPng(GlobalKey key, {double pixelRatio = 3}) async {
  final boundary = key.currentContext?.findRenderObject();
  if (boundary is! RenderRepaintBoundary) return null;
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// Opens the share preview of a chart.
Future<void> showChartShareSheet(
  BuildContext context, {
  required String title,
  required ChartData data,
  String? subtitle,
}) {
  final prefs = ChartPrefs.maybeOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ChartShareSheet(title: title, subtitle: subtitle, data: data, prefs: prefs),
  );
}

class ChartShareSheet extends StatefulWidget {
  const ChartShareSheet({required this.title, required this.data, super.key, this.subtitle, this.prefs});

  final String title;
  final String? subtitle;
  final ChartData data;

  /// Chart preferences of the screen the chart came from (12/24 h, digits, week start…).
  final ChartPrefs? prefs;

  @override
  State<ChartShareSheet> createState() => ChartShareSheetState();
}

class ChartShareSheetState extends State<ChartShareSheet> {
  /// The captured card (exposed for the export test).
  final boundaryKey = GlobalKey(debugLabel: 'chart-share-card');
  bool _hideNames = false;
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final failed = context.l10n.chartsShareFailed;
    try {
      final png = await captureChartPng(boundaryKey);
      if (png == null) {
        messenger?.showSnackBar(SnackBar(content: Text(failed)));
        return;
      }
      await chartImageSharer.share(png, title: widget.title);
    } on Object {
      messenger?.showSnackBar(SnackBar(content: Text(failed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.chartsShare, style: context.text.titleMedium),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.l10n.chartsShareHideNames),
            value: _hideNames,
            onChanged: (v) => setState(() => _hideNames = v),
          ),
          RepaintBoundary(
            key: boundaryKey,
            child: ChartShareCard(
              title: widget.title,
              subtitle: widget.subtitle,
              data: widget.data,
              hideNames: _hideNames,
              prefs: widget.prefs,
            ),
          ),
          const SizedBox(height: Space.md),
          FilledButton.icon(
            onPressed: _busy ? null : _share,
            icon: const Icon(Icons.ios_share),
            label: Text(context.l10n.chartsShareAction),
          ),
        ],
      ),
    ),
  );
}

/// The image card: title, period, chart, Everslot mark.
class ChartShareCard extends StatelessWidget {
  const ChartShareCard({
    required this.title,
    required this.data,
    super.key,
    this.subtitle,
    this.hideNames = false,
    this.prefs,
  });

  final String title;
  final String? subtitle;
  final ChartData data;
  final bool hideNames;
  final ChartPrefs? prefs;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(Radii.md),
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: ChartPrefs(
          use24h: prefs?.use24h ?? true,
          arabicDigits: prefs?.arabicDigits ?? false,
          weekStart: prefs?.weekStart ?? chartWeekStart(context),
          dayStartMinutes: prefs?.dayStartMinutes ?? 0,
          haptics: false,
          hideNames: hideNames,
          anonymousNames: hideNames ? anonymousNamesOf(data) : const {},
          child: Builder(
            builder: (context) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hideNames ? statFormatOf(context).label(TextLabel(title)) : title,
                  style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (subtitle != null)
                  Text(subtitle!, style: context.text.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
                const SizedBox(height: Space.sm),
                // The image is static: no animation, no interaction.
                MediaQuery(
                  data: MediaQuery.of(context).copyWith(disableAnimations: true),
                  child: IgnorePointer(child: ChartView(data, height: 180)),
                ),
                const SizedBox(height: Space.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.calendar_view_week, size: 14, color: colors.primary),
                    const SizedBox(width: Space.xs),
                    Text(context.l10n.chartsShareMark, style: context.text.labelSmall?.copyWith(color: colors.primary)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
