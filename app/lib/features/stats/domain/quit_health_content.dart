/// Smoking health-recovery milestones (T6.6.05) with their sources. Pure Dart.
///
/// TODO(integration): the canonical content file `assets/content/quit_milestones_cigarettes.json`
/// is owned by the habits feature ([5.3]); once it lands on `main`, load it through the habits
/// application API and keep this table only as the fallback. Texts are l10n keys
/// `statsQuitMilestone<Id>` in `app/lib/l10n/parts/stats_*.arb`.
library;

import 'package:everslot_metrics/everslot_metrics.dart' show QuitMilestone;
import 'package:meta/meta.dart';

/// Health sources cited by the milestones.
enum HealthSource {
  who('https://www.who.int/news-room/questions-and-answers/item/tobacco-health-benefits-of-smoking-cessation'),
  nhs('https://www.nhs.uk/better-health/quit-smoking/'),
  cdc('https://www.cdc.gov/tobacco/about/benefits-of-quitting.html'),
  acs(
    'https://www.cancer.org/cancer/risk-prevention/tobacco/guide-quitting-smoking/benefits-of-quitting-smoking-over-time.html',
  ),
  hse('https://www2.hse.ie/living-well/quit-smoking/get-help-to-quit/cravings-withdrawal/'),
  nci('https://www.cancer.gov/about-cancer/causes-prevention/risk/tobacco/withdrawal-fact-sheet'),
  jackson2025('https://doi.org/10.1111/add.16757'),
  bmj2000('https://pubmed.ncbi.nlm.nih.gov/10617536/'),
  lally2010('https://doi.org/10.1002/ejsp.674');

  HealthSource(this.url);

  final String url;
}

/// One content row: a point (`tMax` null) or a range milestone.
@immutable
final class HealthMilestone {
  const HealthMilestone(this.id, {required this.tMin, this.tMax, required this.sources});

  final String id;
  final Duration tMin;
  final Duration? tMax;
  final List<HealthSource> sources;

  QuitMilestone get milestone => QuitMilestone(id, tMin: tMin, tMax: tMax);
}

const _day = Duration(days: 1);
const _week = Duration(days: 7);
const _month = Duration(days: 30);
const _year = Duration(days: 365);

/// The T6.6.05 table (time since the last cigarette).
const List<HealthMilestone> smokingHealthMilestones = [
  HealthMilestone('Heart20m', tMin: Duration(minutes: 20), sources: [HealthSource.who, HealthSource.nhs]),
  HealthMilestone('Co8h', tMin: Duration(hours: 8), sources: [HealthSource.nhs]),
  HealthMilestone('Co12h', tMin: Duration(hours: 12), sources: [HealthSource.who]),
  HealthMilestone('Nicotine24h', tMin: _day, tMax: Duration(days: 3), sources: [HealthSource.cdc, HealthSource.acs]),
  HealthMilestone('Taste48h', tMin: Duration(hours: 48), sources: [HealthSource.nhs]),
  HealthMilestone('Breathing72h', tMin: Duration(hours: 72), sources: [HealthSource.nhs]),
  HealthMilestone(
    'Circulation',
    tMin: Duration(days: 14),
    tMax: Duration(days: 84),
    sources: [HealthSource.who, HealthSource.nhs],
  ),
  HealthMilestone('Cravings', tMin: Duration(days: 28), tMax: Duration(days: 42), sources: [HealthSource.hse]),
  HealthMilestone(
    'Lungs',
    tMin: _month,
    tMax: Duration(days: 365),
    sources: [HealthSource.who, HealthSource.nhs, HealthSource.cdc, HealthSource.acs],
  ),
  HealthMilestone('HeartHalf1y', tMin: _year, sources: [HealthSource.who, HealthSource.nhs]),
  HealthMilestone('HeartAttack', tMin: _year, tMax: Duration(days: 730), sources: [HealthSource.cdc, HealthSource.acs]),
  HealthMilestone('ChdAdded', tMin: Duration(days: 1095), tMax: Duration(days: 2190), sources: [HealthSource.cdc]),
  HealthMilestone(
    'MouthCancer',
    tMin: Duration(days: 1825),
    tMax: Duration(days: 3650),
    sources: [HealthSource.cdc, HealthSource.acs, HealthSource.who],
  ),
  HealthMilestone(
    'LungCancer10y',
    tMin: Duration(days: 3650),
    sources: [HealthSource.who, HealthSource.acs, HealthSource.nhs, HealthSource.cdc],
  ),
  HealthMilestone(
    'Chd15y',
    tMin: Duration(days: 5475),
    sources: [HealthSource.who, HealthSource.cdc, HealthSource.acs],
  ),
  HealthMilestone('Cancers20y', tMin: Duration(days: 7300), sources: [HealthSource.cdc, HealthSource.acs]),
];

/// Informational row without a bar (life-expectancy gains by quit age).
const HealthMilestone lifeExpectancyInfo = HealthMilestone(
  'LifeExpectancy',
  tMin: Duration.zero,
  sources: [HealthSource.who, HealthSource.cdc, HealthSource.acs],
);

/// Withdrawal phases (QT-25, NCI; informational).
const Duration withdrawalPeak = Duration(days: 3);
const Duration withdrawalWeek = _week;
const Duration withdrawalEasing = Duration(days: 28);
