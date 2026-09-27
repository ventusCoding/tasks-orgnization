import 'dart:convert';

import 'package:everslot/features/habits/domain/quit.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bundled smoking health-milestone content (T5.3.11). Row ids match the stats fallback table
/// (`features/stats/domain/quit_health_content.dart`, T6.6.05).
const smokingMilestonesAsset = 'assets/content/quit_milestones_smoking.json';

/// Parses and validates milestone content; throws [FormatException] when a rule is broken (every
/// row needs ≥ 1 https source and texts in EN, FR and AR).
MilestoneContent parseMilestoneContent(String source) =>
    MilestoneContent.fromJson(Map<String, Object?>.from(jsonDecode(source) as Map));

/// The smoking health-milestone content, loaded once. Health content exists only for smoking
/// trackers (`quit_substance = cigarettes`); every other preset shows money and time only.
final smokingMilestoneContentProvider = FutureProvider<MilestoneContent>(
  (ref) async => parseMilestoneContent(await rootBundle.loadString(smokingMilestonesAsset)),
);
