import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:intl/intl.dart';

/// Locale-aware formatting of Everslot time values (T2.3.07). Pure (no BuildContext) so it can
/// be used in isolates and tests: pass the locale tag and the user's 12/24 h preference.
///
/// [arabicDigits] (the profile's optional Arabic-Indic digits, T1.3.13) renders every number with
/// Arabic-Indic digits and separators — `intl` formats Arabic with Latin digits by default.
class AppFormat {
  AppFormat(this.locale, {this.use24h = true, this.l10n, this.arabicDigits = false});

  final String locale;
  final bool use24h;
  final AppLocalizations? l10n;
  final bool arabicDigits;

  /// The user's 12/24 h preference is honoured in every locale (a French user who picks 12 h gets
  /// "7:03 PM"); end of day is "24:00" in 24 h mode and localized midnight in 12 h mode.
  String time(LocalTime t) {
    final pattern = use24h ? DateFormat.Hm(locale) : DateFormat('h:mm a', locale);
    if (t.isEndOfDay) return use24h ? _digits('24:00') : _digits(pattern.format(DateTime.utc(2000)));
    return _digits(pattern.format(DateTime.utc(2000, 1, 1, t.hour, t.minute)));
  }

  String timeOf(LocalDateTime t) => time(t.time);

  String timeRange(LocalDateTime start, LocalDateTime end) => '${timeOf(start)} – ${timeOf(end)}';

  /// "Mon 22"
  String dayShort(LocalDate d) => _digits(DateFormat('E d', locale).format(d.toDateTimeUtc()));

  /// "Monday, 22 September"
  String dayLong(LocalDate d) => _digits(DateFormat.MMMMEEEEd(locale).format(d.toDateTimeUtc()));

  /// "22 Sep 2026"
  String dateMedium(LocalDate d) => _digits(DateFormat.yMMMd(locale).format(d.toDateTimeUtc()));

  /// "September 2026"
  String monthYear(LocalDate d) => _digits(DateFormat.yMMMM(locale).format(d.toDateTimeUtc()));

  /// "Mon"
  String weekdayShort(Weekday w) => DateFormat.E(locale).format(DateTime.utc(2024, 1, w.iso)); // 2024-01-01 is a Monday

  String weekdayLong(Weekday w) => DateFormat.EEEE(locale).format(DateTime.utc(2024, 1, w.iso));

  String dateTime(LocalDateTime t) => '${dateMedium(t.date)} ${timeOf(t)}';

  String number(num value, {int decimals = 0}) =>
      _numeric(NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: decimals).format(value));

  String percent(double ratio, {int decimals = 0}) =>
      _numeric(NumberFormat.decimalPercentPattern(locale: locale, decimalDigits: decimals).format(ratio));

  String currency(num value, String code) =>
      _numeric(NumberFormat.simpleCurrency(locale: locale, name: code).format(value));

  /// "1 h 20 min", "45 min", "3 days".
  String duration(int minutes) {
    final l = l10n;
    final days = minutes ~/ 1440;
    final hours = (minutes % 1440) ~/ 60;
    final mins = minutes % 60;
    if (l == null) {
      if (days > 0 && hours == 0 && mins == 0) return '${days}d';
      if (minutes >= 60) return mins == 0 ? '${minutes ~/ 60}h' : '${minutes ~/ 60}h ${mins}m';
      return '${minutes}m';
    }
    if (days > 0 && hours == 0 && mins == 0) return _digits(l.durationDaysShort(days));
    final totalHours = minutes ~/ 60;
    if (totalHours == 0) return _digits(l.durationMinutesShort(mins));
    if (mins == 0) return _digits(l.durationHoursShort(totalHours));
    return _digits(l.durationHoursMinutesShort(totalHours, mins));
  }

  /// "in 5 minutes", "3 days ago", "now".
  String relative(DateTime target, DateTime now) {
    final l = l10n;
    final diff = target.difference(now);
    final minutes = diff.inMinutes;
    if (l == null) return '${minutes}m';
    if (minutes.abs() < 1) return l.relativeNow;
    if (minutes.abs() < 60) {
      return _digits(minutes > 0 ? l.relativeInMinutes(minutes) : l.relativeMinutesAgo(-minutes));
    }
    final hours = diff.inHours;
    if (hours.abs() < 24) {
      return _digits(hours > 0 ? l.relativeInHours(hours) : l.relativeHoursAgo(-hours));
    }
    final days = diff.inDays;
    return _digits(days > 0 ? l.relativeInDays(days) : l.relativeDaysAgo(-days));
  }

  static const _arabicIndic = '٠١٢٣٤٥٦٧٨٩';

  /// Arabic-Indic digits when [arabicDigits] is on (Latin digits otherwise).
  String _digits(String s) {
    if (!arabicDigits) return s;
    final out = StringBuffer();
    for (final c in s.codeUnits) {
      out.writeCharCode(c >= 0x30 && c <= 0x39 ? _arabicIndic.codeUnitAt(c - 0x30) : c);
    }
    return out.toString();
  }

  /// Numbers also switch to Arabic separators (٬ grouping, ٫ decimal) with Arabic-Indic digits.
  String _numeric(String s) {
    if (!arabicDigits || !locale.startsWith('ar')) return _digits(s);
    return _digits(s.replaceAll(',', '\u066C').replaceAll('.', '\u066B'));
  }

  /// Compact live counter "3d 04:12:09".
  static String counter(Duration d) {
    final days = d.inDays;
    final h = (d.inHours % 24).toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return days > 0 ? '${days}d $h:$m:$s' : '$h:$m:$s';
  }
}
