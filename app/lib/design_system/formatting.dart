import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:intl/intl.dart';

/// Locale-aware formatting of Everslot time values (T2.3.07). Pure (no BuildContext) so it can
/// be used in isolates and tests: pass the locale tag and the user's 12/24 h preference.
class AppFormat {
  AppFormat(this.locale, {this.use24h = true, this.l10n});

  final String locale;
  final bool use24h;
  final AppLocalizations? l10n;

  String time(LocalTime t) {
    if (t.isEndOfDay) return use24h ? '24:00' : '12:00 AM';
    final dt = DateTime.utc(2000, 1, 1, t.hour, t.minute);
    return (use24h ? DateFormat.Hm(locale) : DateFormat.jm(locale)).format(dt);
  }

  String timeOf(LocalDateTime t) => time(t.time);

  String timeRange(LocalDateTime start, LocalDateTime end) => '${timeOf(start)} – ${timeOf(end)}';

  /// "Mon 22"
  String dayShort(LocalDate d) => DateFormat('E d', locale).format(d.toDateTimeUtc());

  /// "Monday, 22 September"
  String dayLong(LocalDate d) => DateFormat.MMMMEEEEd(locale).format(d.toDateTimeUtc());

  /// "22 Sep 2026"
  String dateMedium(LocalDate d) => DateFormat.yMMMd(locale).format(d.toDateTimeUtc());

  /// "September 2026"
  String monthYear(LocalDate d) => DateFormat.yMMMM(locale).format(d.toDateTimeUtc());

  /// "Mon"
  String weekdayShort(Weekday w) =>
      DateFormat.E(locale).format(DateTime.utc(2024, 1, w.iso)); // 2024-01-01 is a Monday

  String weekdayLong(Weekday w) => DateFormat.EEEE(locale).format(DateTime.utc(2024, 1, w.iso));

  String dateTime(LocalDateTime t) => '${dateMedium(t.date)} ${timeOf(t)}';

  String number(num value, {int decimals = 0}) =>
      NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: decimals).format(value);

  String percent(double ratio, {int decimals = 0}) =>
      NumberFormat.decimalPercentPattern(locale: locale, decimalDigits: decimals).format(ratio);

  String currency(num value, String code) =>
      NumberFormat.simpleCurrency(locale: locale, name: code).format(value);

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
    if (days > 0 && hours == 0 && mins == 0) return l.durationDaysShort(days);
    final totalHours = minutes ~/ 60;
    if (totalHours == 0) return l.durationMinutesShort(mins);
    if (mins == 0) return l.durationHoursShort(totalHours);
    return l.durationHoursMinutesShort(totalHours, mins);
  }

  /// "in 5 minutes", "3 days ago", "now".
  String relative(DateTime target, DateTime now) {
    final l = l10n;
    final diff = target.difference(now);
    final minutes = diff.inMinutes;
    if (l == null) return '${minutes}m';
    if (minutes.abs() < 1) return l.relativeNow;
    if (minutes.abs() < 60) {
      return minutes > 0 ? l.relativeInMinutes(minutes) : l.relativeMinutesAgo(-minutes);
    }
    final hours = diff.inHours;
    if (hours.abs() < 24) return hours > 0 ? l.relativeInHours(hours) : l.relativeHoursAgo(-hours);
    final days = diff.inDays;
    return days > 0 ? l.relativeInDays(days) : l.relativeDaysAgo(-days);
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
