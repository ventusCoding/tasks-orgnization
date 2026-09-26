import 'package:everslot/features/recurrence_ui/application/recurrence_preview.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';

/// Localized labels of the recurrence builder (issue codes, units, ordinals, warnings).
extension RecurrenceLabels on AppLocalizations {
  /// Message for a validation issue (arch §9.5 codes).
  String recurIssueText(RuleIssue issue) {
    int param(String name) => (issue.params[name] as num?)?.toInt() ?? 0;
    return switch (issue.code) {
      RuleIssueCode.intervalInvalid => recurIssueInterval,
      RuleIssueCode.untilBeforeStart => recurIssueUntilBeforeStart,
      RuleIssueCode.countAndUntil => recurIssueCountAndUntil,
      RuleIssueCode.emptyWeekdaySet => recurIssueEmptyWeekdays,
      RuleIssueCode.ordinalOnWeekly => recurIssueOrdinal,
      RuleIssueCode.windowEndBeforeStart => recurIssueWindow,
      RuleIssueCode.tooFrequent => recurIssueTooFrequent(param('perDay')),
      RuleIssueCode.quotaImpossible => recurIssueQuota(param('max')),
      RuleIssueCode.unsupportedCombo when issue.params['allDay'] == true => recurWarnAllDaySubDaily,
      RuleIssueCode.unsupportedCombo => recurIssueUnsupported,
      RuleIssueCode.valueOutOfRange => recurIssueValue,
      RuleIssueCode.invalidDate => recurIssueDate,
      RuleIssueCode.countInvalid => recurIssueCount,
      RuleIssueCode.missingField => recurIssueMissing,
    };
  }

  String recurWarningText(RecurrenceWarning warning) => switch (warning.kind) {
    RecurrenceWarningKind.tooManyPerDay => recurWarnPerDay(warning.count ?? 0),
    RecurrenceWarningKind.neverOccurs => recurWarnNever,
    RecurrenceWarningKind.dstShift => recurWarnDst,
    RecurrenceWarningKind.allDaySubDaily => recurWarnAllDaySubDaily,
  };

  /// "Minutes", "Hours", … for a frequency.
  String recurFrequencyUnit(Frequency f) => switch (f) {
    Frequency.minutely => recurUnitMinute,
    Frequency.hourly => recurUnitHour,
    Frequency.daily => recurUnitDay,
    Frequency.weekly => recurUnitWeek,
    Frequency.monthly => recurUnitMonth,
    Frequency.yearly => recurUnitYear,
  };

  /// Unit label of an after-completion delay.
  String recurDelayUnit(RecurrenceUnit u) => switch (u) {
    RecurrenceUnit.minute => recurUnitMinute,
    RecurrenceUnit.hour => recurUnitHour,
    RecurrenceUnit.day => recurUnitDay,
    RecurrenceUnit.week => recurUnitWeek,
    RecurrenceUnit.month => recurUnitMonth,
    RecurrenceUnit.year => recurUnitYear,
  };

  String recurPeriodUnit(PeriodUnit p) => switch (p) {
    PeriodUnit.day => recurPerDay,
    PeriodUnit.week => recurPerWeek,
    PeriodUnit.month => recurPerMonth,
    PeriodUnit.year => recurPerYear,
  };

  /// "1st", "2nd", …, "Last", "2nd to last"; other positions as plain numbers.
  String recurOrdinalLabel(int n) => switch (n) {
    1 => recurOrdinal1,
    2 => recurOrdinal2,
    3 => recurOrdinal3,
    4 => recurOrdinal4,
    5 => recurOrdinal5,
    -1 => recurOrdinalLast,
    -2 => recurOrdinalSecondLast,
    _ => n > 0 ? '$n' : '−${-n}',
  };
}

/// Ordinals offered by the builder's chips (1st … 5th, last, 2nd to last).
const List<int> recurCommonOrdinals = [1, 2, 3, 4, 5, -1, -2];
