import 'package:everslot/design_system/formatting.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Locale-aware formatting helpers and ICU plurals (T1.3.13, T2.3.07).
void main() {
  setUpAll(initializeDateFormatting);

  AppLocalizations l10n(String locale) => lookupAppLocalizations(Locale(locale));

  AppFormat format(String locale, {bool use24h = true, bool arabicDigits = false}) =>
      AppFormat(locale, use24h: use24h, l10n: l10n(locale), arabicDigits: arabicDigits);

  /// CLDR uses narrow/no-break spaces (e.g. "7:03\u202fPM"); compare with plain spaces.
  String plain(String s) => s.replaceAll(RegExp('[\u00a0\u202f]'), ' ');

  group('time', () {
    test('24 h in every locale, including 07:03 entered by keyboard', () {
      for (final locale in ['en', 'fr', 'ar']) {
        expect(format(locale).time(LocalTime(7, 3)), '07:03', reason: locale);
        expect(format(locale).time(LocalTime(19, 3)), '19:03', reason: locale);
        expect(format(locale).time(LocalTime.midnight), '00:00', reason: locale);
      }
    });

    test('12 h preference is honoured in every locale', () {
      expect(plain(format('en', use24h: false).time(LocalTime(19, 3))), '7:03 PM');
      expect(plain(format('en', use24h: false).time(LocalTime(7, 3))), '7:03 AM');
      expect(plain(format('fr', use24h: false).time(LocalTime(19, 3))), '7:03 PM');
      expect(plain(format('ar', use24h: false).time(LocalTime(19, 3))), '7:03 م');
      expect(plain(format('ar', use24h: false).time(LocalTime(7, 3))), '7:03 ص');
    });

    test('end of day is 24:00, or localized midnight in 12 h mode', () {
      expect(format('en').time(LocalTime.endOfDay), '24:00');
      expect(plain(format('en', use24h: false).time(LocalTime.endOfDay)), '12:00 AM');
      expect(plain(format('ar', use24h: false).time(LocalTime.endOfDay)), '12:00 ص');
    });

    test('ranges and date-times combine the pieces', () {
      final f = format('en');
      final start = LocalDateTime(LocalDate(2026, 9, 22), LocalTime(8, 0));
      final end = LocalDateTime(LocalDate(2026, 9, 22), LocalTime(9, 30));
      expect(f.timeRange(start, end), '08:00 – 09:30');
      expect(f.dateTime(start), 'Sep 22, 2026 08:00');
    });
  });

  group('dates', () {
    final d = LocalDate(2026, 9, 22); // a Tuesday

    test('English', () {
      final f = format('en');
      expect(f.dayShort(d), 'Tue 22');
      expect(f.dayLong(d), 'Tuesday, September 22');
      expect(f.dateMedium(d), 'Sep 22, 2026');
      expect(f.monthYear(d), 'September 2026');
      expect(f.weekdayShort(Weekday.monday), 'Mon');
      expect(f.weekdayLong(Weekday.sunday), 'Sunday');
    });

    test('French', () {
      final f = format('fr');
      expect(f.dayShort(d), 'mar. 22');
      expect(f.dayLong(d), 'mardi 22 septembre');
      expect(f.dateMedium(d), '22 sept. 2026');
      expect(f.monthYear(d), 'septembre 2026');
      expect(f.weekdayLong(Weekday.monday), 'lundi');
    });

    test('Arabic', () {
      final f = format('ar');
      expect(f.dayShort(d), 'الثلاثاء 22');
      expect(f.dayLong(d), 'الثلاثاء، 22 سبتمبر');
      expect(f.dateMedium(d), '22 سبتمبر 2026');
      expect(f.weekdayLong(Weekday.friday), 'الجمعة');
    });
  });

  group('date ranges', () {
    test('the shared year is written once; each part keeps the locale order', () {
      final en = format('en');
      expect(en.dateRange(LocalDate(2026, 9, 22), LocalDate(2026, 9, 22)), 'Sep 22, 2026');
      expect(en.dateRange(LocalDate(2026, 9, 22), LocalDate(2026, 9, 28)), 'Sep 22 – Sep 28, 2026');
      expect(en.dateRange(LocalDate(2026, 12, 29), LocalDate(2027, 1, 4)), 'Dec 29, 2026 – Jan 4, 2027');
      expect(format('fr').dateRange(LocalDate(2026, 9, 29), LocalDate(2026, 10, 5)), '29 sept. – 5 oct. 2026');
      expect(format('ar').dateRange(LocalDate(2026, 9, 22), LocalDate(2026, 9, 28)), '22 سبتمبر – 28 سبتمبر 2026');
      expect(
        format('ar', arabicDigits: true).dateRange(LocalDate(2026, 9, 22), LocalDate(2026, 9, 28)),
        '٢٢ سبتمبر – ٢٨ سبتمبر ٢٠٢٦',
      );
    });
  });

  group('numbers', () {
    test('grouping, decimals, percent and currency per locale', () {
      expect(format('en').number(1234.5, decimals: 1), '1,234.5');
      expect(plain(format('fr').number(1234.5, decimals: 1)), '1 234,5');
      expect(format('ar').number(1234.5, decimals: 1), '1,234.5');
      expect(format('en').percent(0.425), '43%');
      expect(plain(format('fr').percent(0.425)), '43 %');
      expect(format('en').currency(12.5, 'EUR'), '€12.50');
      expect(plain(format('fr').currency(12.5, 'EUR')), '12,50 €');
    });

    test('optional Arabic-Indic digits', () {
      final f = format('ar', arabicDigits: true);
      expect(f.time(LocalTime(7, 3)), '٠٧:٠٣');
      expect(f.number(1234.5, decimals: 1), '١٬٢٣٤٫٥');
      expect(f.dateMedium(LocalDate(2026, 9, 22)), '٢٢ سبتمبر ٢٠٢٦');
      expect(f.duration(80), '١ س ٢٠ د');
      expect(f.relative(DateTime.utc(2026, 9, 22, 9, 5), DateTime.utc(2026, 9, 22, 9)), 'بعد ٥ دقائق');
      // Off by default: intl formats Arabic with Latin digits.
      expect(format('ar').time(LocalTime(7, 3)), '07:03');
    });
  });

  group('durations', () {
    test('English', () {
      final f = format('en');
      expect(f.duration(1), '1 min');
      expect(f.duration(45), '45 min');
      expect(f.duration(60), '1 h');
      expect(f.duration(80), '1 h 20 min');
      expect(f.duration(1440), '1 day');
      expect(f.duration(2880), '2 days');
      expect(f.duration(1500), '25 h');
    });

    test('French and Arabic plural forms', () {
      expect(format('fr').duration(1440), '1 jour');
      expect(format('fr').duration(2880), '2 jours');
      final ar = format('ar');
      expect(ar.duration(1440), 'يوم واحد');
      expect(ar.duration(2880), 'يومان');
      expect(ar.duration(3 * 1440), '3 أيام');
      expect(ar.duration(11 * 1440), '11 يومًا');
      expect(ar.duration(100 * 1440), '100 يوم');
    });

    test('without localizations a compact fallback is used', () {
      final f = AppFormat('en');
      expect(f.duration(45), '45m');
      expect(f.duration(90), '1h 30m');
      expect(f.duration(120), '2h');
      expect(f.duration(2880), '2d');
    });
  });

  group('relative times', () {
    final now = DateTime.utc(2026, 9, 22, 9);

    test('English', () {
      final f = format('en');
      expect(f.relative(now.add(const Duration(seconds: 20)), now), 'now');
      expect(f.relative(now.add(const Duration(minutes: 1)), now), 'in 1 minute');
      expect(f.relative(now.add(const Duration(minutes: 5)), now), 'in 5 minutes');
      expect(f.relative(now.subtract(const Duration(minutes: 5)), now), '5 minutes ago');
      expect(f.relative(now.add(const Duration(hours: 2)), now), 'in 2 hours');
      expect(f.relative(now.add(const Duration(days: 1)), now), 'tomorrow');
      expect(f.relative(now.subtract(const Duration(days: 1)), now), 'yesterday');
      expect(f.relative(now.subtract(const Duration(days: 3)), now), '3 days ago');
    });

    test('French and Arabic (dual forms)', () {
      expect(format('fr').relative(now.subtract(const Duration(days: 3)), now), 'il y a 3 jours');
      expect(format('fr').relative(now.add(const Duration(minutes: 5)), now), 'dans 5 minutes');
      final ar = format('ar');
      expect(ar.relative(now, now), 'الآن');
      expect(ar.relative(now.add(const Duration(hours: 2)), now), 'بعد ساعتين');
      expect(ar.relative(now.add(const Duration(minutes: 2)), now), 'بعد دقيقتين');
      expect(ar.relative(now.subtract(const Duration(hours: 5)), now), 'منذ 5 ساعات');
    });
  });

  test('live counter', () {
    expect(AppFormat.counter(const Duration(hours: 4, minutes: 12, seconds: 9)), '04:12:09');
    expect(AppFormat.counter(const Duration(days: 3, hours: 4, minutes: 12, seconds: 9)), '3d 04:12:09');
  });

  group('ICU plurals', () {
    test('Arabic uses zero/one/two/few/many/other', () {
      final l = l10n('ar');
      expect(l.filterActiveCount(0), 'لا توجد عوامل تصفية');
      expect(l.filterActiveCount(1), 'عامل تصفية واحد نشط');
      expect(l.filterActiveCount(2), 'عاملا تصفية نشطان');
      expect(l.filterActiveCount(3), '3 عوامل تصفية نشطة');
      expect(l.filterActiveCount(11), '11 عامل تصفية نشطًا');
      expect(l.filterActiveCount(100), '100 عامل تصفية نشط');
      expect(l.tagUsage(2), 'عنصران');
      expect(l.tagUsage(5), '5 عناصر');
    });

    test('English and French', () {
      expect(l10n('en').tagUsage(0), 'Not used');
      expect(l10n('en').tagUsage(1), '1 item');
      expect(l10n('en').tagUsage(7), '7 items');
      expect(l10n('fr').tagUsage(1), '1 élément');
      expect(l10n('fr').tagUsage(7), '7 éléments');
      expect(l10n('fr').filterActiveCount(2), '2 filtres actifs');
    });
  });
}
