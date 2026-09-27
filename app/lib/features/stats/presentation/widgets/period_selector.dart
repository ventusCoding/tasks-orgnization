/// Period selector (T6.1.16): Today · Week · Month · Quarter · Year · All chips, a Rolling menu
/// (7/28/30/90/365), a custom range picker and the compare-with-previous toggle.
library;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_metrics/everslot_metrics.dart'
    show
        AllTimePeriod,
        CustomPeriod,
        LastMonthPeriod,
        LastQuarterPeriod,
        LastWeekPeriod,
        LastYearPeriod,
        RollingPeriod,
        StatsPeriod,
        ThisMonthPeriod,
        ThisQuarterPeriod,
        ThisWeekPeriod,
        ThisYearPeriod,
        TodayPeriod,
        YesterdayPeriod;
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate;
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

/// Localized name of a period.
String periodLabel(AppLocalizations l, StatsPeriod p, {String locale = 'en'}) => switch (p) {
  TodayPeriod() => l.statsPeriodToday,
  YesterdayPeriod() => l.statsPeriodYesterday,
  ThisWeekPeriod() => l.statsPeriodWeek,
  LastWeekPeriod() => l.statsPeriodLastWeek,
  ThisMonthPeriod() => l.statsPeriodMonth,
  LastMonthPeriod() => l.statsPeriodLastMonth,
  ThisQuarterPeriod() => l.statsPeriodQuarter,
  LastQuarterPeriod() => l.statsPeriodLastQuarter,
  ThisYearPeriod() => l.statsPeriodYear,
  LastYearPeriod() => l.statsPeriodLastYear,
  AllTimePeriod() => l.statsPeriodAll,
  RollingPeriod(:final days) => l.statsPeriodRolling('$days'),
  CustomPeriod(:final from, :final to) => l.statsPeriodCustomRange(
    DateFormat.MMMd(locale).format(from.toDateTimeUtc()),
    DateFormat.yMMMd(locale).format(to.toDateTimeUtc()),
  ),
};

class PeriodSelector extends StatelessWidget {
  const PeriodSelector({required this.selection, required this.onChanged, super.key, this.showCompare = true});

  final PeriodSelection selection;
  final ValueChanged<PeriodSelection> onChanged;
  final bool showCompare;

  static const _chips = <StatsPeriod>[
    StatsPeriod.today(),
    StatsPeriod.thisWeek(),
    StatsPeriod.thisMonth(),
    StatsPeriod.thisQuarter(),
    StatsPeriod.thisYear(),
    StatsPeriod.allTime(),
  ];

  static const rollingDays = [7, 28, 30, 90, 365];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final current = selection.period;
    final isRolling = current is RollingPeriod;
    final isCustom = current is CustomPeriod;
    return Semantics(
      label: l.statsPeriodSelected(periodLabel(l, current, locale: context.localeName)),
      container: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
        child: Row(
          children: [
            for (final p in _chips)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: Space.xs),
                child: ChoiceChip(
                  label: Text(periodLabel(l, p)),
                  selected: current.key == p.key,
                  onSelected: (_) => onChanged(selection.copyWith(period: p, clearGranularity: true)),
                ),
              ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: Space.xs),
              child: PopupMenuButton<int>(
                tooltip: l.statsPeriodRollingMenu,
                onSelected: (days) => onChanged(selection.copyWith(period: StatsPeriod.rolling(days), clearGranularity: true)),
                itemBuilder: (context) => [
                  for (final d in rollingDays)
                    CheckedPopupMenuItem(value: d, checked: current is RollingPeriod && current.days == d, child: Text(l.statsPeriodRolling('$d'))),
                ],
                child: IgnorePointer(
                  child: ChoiceChip(
                    label: Text(isRolling ? periodLabel(l, current) : l.statsPeriodRollingMenu),
                    avatar: const Icon(Icons.expand_more, size: 18),
                    selected: isRolling,
                    onSelected: (_) {},
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: Space.xs),
              child: ChoiceChip(
                avatar: const Icon(Icons.date_range, size: 18),
                label: Text(isCustom ? periodLabel(l, current, locale: context.localeName) : l.statsPeriodCustom),
                selected: isCustom,
                onSelected: (_) => _pickCustom(context),
              ),
            ),
            if (showCompare)
              FilterChip(
                avatar: const Icon(Icons.compare_arrows, size: 18),
                label: Text(l.chartsVsPrevious),
                selected: selection.compare,
                tooltip: l.statsCompareToggle,
                onSelected: (on) => onChanged(selection.copyWith(compare: on)),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustom(BuildContext context) async {
    final now = DateTime.now();
    final current = selection.period;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: current is CustomPeriod
          ? DateTimeRange(start: current.from.toDateTimeUtc(), end: current.to.toDateTimeUtc())
          : null,
    );
    if (range == null) return;
    onChanged(
      selection.copyWith(
        period: StatsPeriod.custom(LocalDate.fromDateTime(range.start), LocalDate.fromDateTime(range.end)),
        clearGranularity: true,
      ),
    );
  }
}
