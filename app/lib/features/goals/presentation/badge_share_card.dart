import 'dart:io';
import 'dart:ui' as ui;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/goals/domain/achievements.dart';
import 'package:everslot/features/goals/presentation/badge_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// The image card shared for a badge (T5.4.09): the badge and — only when the user chooses — the
/// habit's name and the date. Nothing else leaves the device.
class BadgeShareCard extends StatelessWidget {
  const BadgeShareCard({required this.code, super.key, this.habitName, this.dateText, this.currency});

  final AchievementCode code;
  final String? habitName;
  final String? dateText;
  final String? currency;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 320,
      padding: const EdgeInsets.all(Space.xl),
      decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(Radii.lg)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: colors.primary,
            child: Icon(badgeIcon(code), size: 40, color: colors.onPrimary),
          ),
          const SizedBox(height: Space.md),
          Text(
            badgeName(context, code, currency: currency),
            style: context.text.headlineSmall?.copyWith(color: colors.onPrimaryContainer),
            textAlign: TextAlign.center,
          ),
          if (habitName != null) ...[
            const SizedBox(height: Space.xs),
            Text(habitName!, style: context.text.titleMedium?.copyWith(color: colors.onPrimaryContainer)),
          ],
          if (dateText != null) ...[
            const SizedBox(height: Space.xs),
            Text(dateText!, style: context.text.bodyMedium?.copyWith(color: colors.onPrimaryContainer)),
          ],
          const SizedBox(height: Space.md),
          Text('Everslot', style: context.text.labelLarge?.copyWith(color: colors.onPrimaryContainer)),
        ],
      ),
    );
  }
}

/// Renders the card behind [boundaryKey] to a PNG and opens the share sheet with [text].
Future<void> shareBadgeCard(GlobalKey boundaryKey, {required String text}) async {
  final boundary = boundaryKey.currentContext?.findRenderObject();
  if (boundary is! RenderRepaintBoundary) return;
  final image = await boundary.toImage(pixelRatio: 3);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (bytes == null) return;
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/everslot_badge.png');
  await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'image/png')],
      text: text,
    ),
  );
}
