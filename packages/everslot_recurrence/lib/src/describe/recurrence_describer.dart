import 'package:everslot_recurrence/src/describe/messages.dart';
import 'package:everslot_recurrence/src/describe/plural.dart';
import 'package:everslot_recurrence/src/rule/recurrence_anchor.dart';
import 'package:everslot_recurrence/src/rule/recurrence_rule.dart';
import 'package:everslot_recurrence/src/rule/rule_enums.dart';
import 'package:everslot_recurrence/src/rule/rule_parts.dart';
import 'package:everslot_recurrence/src/time/local_date.dart';
import 'package:everslot_recurrence/src/time/local_time.dart';
import 'package:everslot_recurrence/src/time/weekday.dart';

/// Natural-language descriptions of rules in English, French and Arabic (T2.1.12).
///
/// Examples (en): "Every Monday and Tuesday at 08:00", "Every 90 minutes
/// between 08:00 and 20:00 on weekdays", "3 times a week", "2 days after
/// completion", "Monthly on the last weekday, 10 times". Plurals follow the
/// CLDR rules (Arabic zero/one/two/few/many/other); weekday sets collapse to
/// "weekdays", "weekends" and "every day". Values the rule derives from the
/// anchor (weekday, month day, time of day) are described explicitly.
final class RecurrenceDescriber {
  const new();

  /// Locales with a message catalog; others fall back to English.
  static const List<String> supportedLocales = ['en', 'fr', 'ar'];

  /// Describes [rule] anchored at [anchor].
  ///
  /// [use24h] selects `08:00` vs `8:00 AM`; [weekStart] orders weekday lists.
  String describe(
    RecurrenceRule rule,
    RecurrenceAnchor anchor, {
    String locale = 'en',
    bool use24h = true,
    Weekday weekStart = Weekday.monday,
  }) {
    final c = _Messages(locale, use24h: use24h, weekStart: weekStart);
    final main = switch (rule.type) {
      RuleType.afterCompletion => _afterCompletion(c, rule),
      RuleType.quota => _quota(c, rule),
      RuleType.fixed => _fixed(c, rule, anchor),
    };
    return main + _bounds(c, rule, anchor);
  }

  String _afterCompletion(_Messages c, RecurrenceRule rule) {
    final after = rule.afterCompletion ?? const AfterCompletion(1, RecurrenceUnit.day);
    return c.plural('after.${after.unit.name}', after.amount);
  }

  String _quota(_Messages c, RecurrenceRule rule) {
    final quota = rule.quota ?? const Quota(1, PeriodUnit.week);
    final out = StringBuffer(c.plural('quota', quota.times, {'per': c.text('per.${quota.per.name}')}));
    final days = rule.byWeekday;
    if (days != null) out.write(c.dayFilter({for (final d in days) d.day}));
    if (quota.minGapDays > 0) {
      out.write(c.plural('quota.gap', quota.minGapDays));
    }
    return out.toString();
  }

  String _bounds(_Messages c, RecurrenceRule rule, RecurrenceAnchor anchor) {
    final out = StringBuffer();
    final count = rule.count;
    if (count != null) {
      out.write(c.plural(rule.countMode == CountMode.occurrences ? 'count' : 'completions', count));
    }
    final until = rule.until;
    if (until != null) out.write(c.text('until', {'date': c.date(until.date)}));
    return out.toString();
  }

  String _fixed(_Messages c, RecurrenceRule rule, RecurrenceAnchor anchor) {
    final start = anchor.allDay ? anchor.start.date.atStartOfDay : anchor.start;
    final n = rule.interval;
    final weekdays = rule.byWeekday;
    final allDays = weekdays == null ? null : {for (final w in weekdays) w.day};
    final out = StringBuffer();
    switch (rule.freq) {
      case Frequency.minutely:
      case Frequency.hourly:
        final hourly = rule.freq == Frequency.hourly;
        if (hourly && n == 1 && rule.byHour.isNotEmpty && rule.window == null) {
          // Every hour limited to some hours = those times every day.
          out
            ..write(allDays == null ? c.plural('every.day', 1) : c.weeklyStart(allDays))
            ..write(_dateFilters(c, rule))
            ..write(_times(c, rule, anchor));
          return out.toString();
        }
        out.write(c.plural(hourly ? 'every.hour' : 'every.minute', n));
        if (rule.byMinute.isNotEmpty) {
          String item(int m) => hourly ? c.text('hourMinute.item', {'mm': '$m'.padLeft(2, '0'), 'm': '$m'}) : '$m';
          final minutes = c.join([for (final m in _sorted(rule.byMinute)) item(m)]);
          out.write(c.text(hourly ? 'hourMinutes' : 'minutes', {'list': minutes}));
        }
        final window = rule.window;
        if (window != null) out.write(c.window(window.start, window.end));
        if (rule.byHour.isNotEmpty) out.write(c.hours(_sorted(rule.byHour)));
        if (allDays != null) out.write(c.dayFilter(allDays));
        out.write(_dateFilters(c, rule));
      case Frequency.daily:
        if (allDays != null && n == 1) {
          out.write(c.weeklyStart(allDays));
        } else {
          out.write(c.plural('every.day', n));
          if (allDays != null) out.write(c.dayFilter(allDays));
        }
        out
          ..write(_dateFilters(c, rule))
          ..write(_times(c, rule, anchor));
      case Frequency.weekly:
        final days = allDays ?? {start.date.weekday};
        out.write(n == 1 ? c.weeklyStart(days) : c.weeklyEvery(days, c.plural('every.week', n)));
        if (rule.byMonth.isNotEmpty) {
          out.write(c.text('filter.months', {'months': c.months(rule.byMonth)}));
        }
        out.write(_times(c, rule, anchor));
      case Frequency.monthly:
        out
          ..write(c.plural('every.month', n))
          ..write(_monthSpec(c, rule, start.day, scope: c.text('scope.month')));
        if (rule.byMonth.isNotEmpty) {
          out.write(c.text('filter.months', {'months': c.months(rule.byMonth)}));
        }
        out.write(_times(c, rule, anchor));
      case Frequency.yearly:
        out
          ..write(c.plural('every.year', n))
          ..write(_yearSpec(c, rule, start.month, start.day))
          ..write(_times(c, rule, anchor));
    }
    return out.toString();
  }

  /// Limits of daily / sub-daily rules (months, month days, year days).
  String _dateFilters(_Messages c, RecurrenceRule rule) {
    final out = StringBuffer();
    if (rule.byMonthDay.isNotEmpty) {
      out.write(c.text('monthDays', {'list': c.monthDays(rule.byMonthDay)}));
    }
    if (rule.byMonth.isNotEmpty) {
      out.write(c.text('filter.months', {'months': c.months(rule.byMonth)}));
    }
    if (rule.byYearDay.isNotEmpty) out.write(c.yearDays(rule.byYearDay));
    return out.toString();
  }

  String _monthSpec(_Messages c, RecurrenceRule rule, int anchorDay, {required String scope}) {
    final weekdays = rule.byWeekday ?? const <WeekdayRule>[];
    final plain = {
      for (final w in weekdays)
        if (w.n == null) w.day,
    };
    final ordinals = [
      for (final w in weekdays)
        if (w.n != null) w,
    ];
    final monthDays = rule.byMonthDay;
    if (rule.bySetPos.isNotEmpty && ordinals.isEmpty && monthDays.isEmpty && plain.isNotEmpty) {
      return c.setPos(rule.bySetPos, plain) + scope;
    }
    if (monthDays.isNotEmpty && weekdays.isNotEmpty) {
      return c.text('dayCombo', {
        'days': c.joinOr([for (final d in c.sortDays(weekdays.map((w) => w.day))) c.dayName(d)]),
        'monthDays': c.monthDays(monthDays),
      });
    }
    if (monthDays.isNotEmpty) {
      return c.text('monthDays', {'list': c.monthDays(monthDays)}) + _clampNote(c, rule, monthDays);
    }
    if (ordinals.isNotEmpty || plain.isNotEmpty) {
      final parts = <String>[];
      if (ordinals.isNotEmpty) {
        parts.add(
          c.text('nthWeekday.list', {
                'list': c.join([for (final w in ordinals) c.nthWeekday(w)]),
              }) +
              scope,
        );
      }
      if (plain.isNotEmpty) parts.add(c.dayFilter(plain));
      return parts.join();
    }
    return c.text('monthDays', {
          'list': c.monthDays([anchorDay]),
        }) +
        _clampNote(c, rule, [anchorDay]);
  }

  /// Mentions clamping when a month day may not exist in every month.
  String _clampNote(_Messages c, RecurrenceRule rule, List<int> monthDays) =>
      rule.monthDayOverflow == MonthOverflow.clamp && monthDays.any((d) => d.abs() > 28) ? c.text('clampNote') : '';

  String _yearSpec(_Messages c, RecurrenceRule rule, int anchorMonth, int anchorDay) {
    final weekdays = rule.byWeekday ?? const <WeekdayRule>[];
    final ordinals = [
      for (final w in weekdays)
        if (w.n != null) w,
    ];
    final plain = {
      for (final w in weekdays)
        if (w.n == null) w.day,
    };
    final months = rule.byMonth;
    final monthsText = months.isEmpty ? '' : c.months(months);
    if (rule.byYearDay.isNotEmpty) {
      return c.yearDays(rule.byYearDay) + (plain.isEmpty ? '' : c.dayFilter(plain));
    }
    if (rule.byWeekNo.isNotEmpty) {
      return c.weekNos(rule.byWeekNo) + (weekdays.isEmpty ? '' : c.dayFilter({for (final w in weekdays) w.day}));
    }
    final monthScope = months.isEmpty
        ? c.text('scope.year')
        : c.text('scope.months', {'months': monthsText, 'deMonths': c.deMonths(months)});
    if (ordinals.isNotEmpty && rule.byMonthDay.isEmpty) {
      return c.text('nthWeekday.list', {
            'list': c.join([for (final w in ordinals) c.nthWeekday(w)]),
          }) +
          monthScope +
          (plain.isEmpty ? '' : c.dayFilter(plain));
    }
    if (rule.bySetPos.isNotEmpty && plain.isNotEmpty && rule.byMonthDay.isEmpty) {
      return c.setPos(rule.bySetPos, plain) + monthScope;
    }
    if (rule.byMonthDay.isNotEmpty) {
      if (weekdays.isNotEmpty) {
        return c.text('dayCombo', {
              'days': c.joinOr([for (final d in c.sortDays(weekdays.map((w) => w.day))) c.dayName(d)]),
              'monthDays': c.monthDays(rule.byMonthDay),
            }) +
            (months.isEmpty ? '' : c.text('inMonths', {'months': monthsText}));
      }
      if (months.isEmpty) {
        return c.text('yearly.eachMonth', {'monthDays': c.monthDays(rule.byMonthDay)});
      }
      return _yearlyDates(c, months, rule.byMonthDay);
    }
    if (plain.isNotEmpty) {
      return c.dayFilter(plain) + (months.isEmpty ? '' : c.text('inMonths', {'months': monthsText}));
    }
    return _yearlyDates(c, months.isEmpty ? [anchorMonth] : months, [anchorDay]);
  }

  String _yearlyDates(_Messages c, List<int> months, List<int> days) {
    if (months.length == 1 && days.length == 1 && days.single > 0) {
      return c.text('yearly.date', {'month': c.monthName(months.single), 'day': c.dayNumber(days.single)});
    }
    return c.text('yearly.monthDays', {
      'monthDays': c.monthDays(days),
      'months': c.months(months),
      'deMonths': c.deMonths(months),
    });
  }

  String _times(_Messages c, RecurrenceRule rule, RecurrenceAnchor anchor) {
    if (anchor.allDay) return '';
    final List<int> minutes;
    if (rule.times.isNotEmpty) {
      minutes = _sorted([for (final t in rule.times) t.minuteOfDay]);
    } else {
      final hours = rule.byHour.isEmpty ? [anchor.start.hour] : _sorted(rule.byHour);
      final mins = rule.byMinute.isEmpty ? [anchor.start.minute] : _sorted(rule.byMinute);
      minutes = [
        for (final h in hours)
          for (final m in mins) h * 60 + m,
      ];
    }
    if (minutes.length > 6) {
      return c.plural('timesPerDay', minutes.length, {'first': c.time(minutes.first), 'last': c.time(minutes.last)});
    }
    return c.text('at', {
      'times': c.join([for (final m in minutes) c.time(m)]),
    });
  }

  static List<int> _sorted(Iterable<int> values) => values.toSet().toList()..sort();
}

/// Catalog access and locale-aware formatting helpers.
final class _Messages {
  new(String locale, {required this.use24h, required this.weekStart})
    : language = recurrenceMessages.containsKey(_languageOf(locale)) ? _languageOf(locale) : 'en';

  final String language;
  final bool use24h;
  final Weekday weekStart;

  Map<String, Object> get _catalog => recurrenceMessages[language]!;

  static String _languageOf(String locale) => locale.split(RegExp('[-_]')).first.toLowerCase();

  static String _fill(String template, Map<String, String> args) {
    var result = template;
    for (final entry in args.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }

  String text(String key, [Map<String, String> args = const {}]) => _fill(_catalog[key]! as String, args);

  String plural(String key, int n, [Map<String, String> args = const {}]) =>
      _fill(selectPlural(language, n, (_catalog[key]! as Map).cast<String, String>()), args);

  List<String> _list(String key) => (_catalog[key]! as List).cast<String>();

  String join(List<String> items) {
    if (items.length <= 1) return items.join();
    return '${items.sublist(0, items.length - 1).join(text('listSep'))}${text('and')}${items.last}';
  }

  String joinOr(List<String> items) {
    if (items.length <= 1) return items.join();
    return '${items.sublist(0, items.length - 1).join(text('orSep'))}${text('or')}${items.last}';
  }

  List<Weekday> sortDays(Iterable<Weekday> days) =>
      days.toSet().toList()..sort((a, b) => a.offsetFrom(weekStart).compareTo(b.offsetFrom(weekStart)));

  String dayName(Weekday day) => _list('weekdays')[day.iso - 1];

  String _dayPlural(Weekday day) => _list('weekdaysPlural')[day.iso - 1];

  String _dayBare(Weekday day) => _list('weekdaysBare')[day.iso - 1];

  String monthName(int month) => _list('months')[month - 1];

  String months(List<int> values) => join([for (final m in (values.toSet().toList()..sort())) monthName(m)]);

  /// French "de janvier et juillet" / "d'avril" (other locales: the month list).
  String deMonths(List<int> values) {
    final list = months(values);
    if (language != 'fr') return list;
    return _startsWithVowel(list) ? "d'$list" : 'de $list';
  }

  static bool _startsWithVowel(String text) => text.isNotEmpty && 'aeiouyàâéèêëîïôûùAEIOUYÉ'.contains(text[0]);

  /// French article before an ordinal ("le premier", "l'avant-dernier").
  String _article(String word) {
    if (language != 'fr') return '';
    return _startsWithVowel(word) ? "l'" : 'le ';
  }

  static bool _isWeekdays(Set<Weekday> days) => days.length == 5 && days.every((d) => !d.isWeekend);

  static bool _isWeekend(Set<Weekday> days) => days.length == 2 && days.every((d) => d.isWeekend);

  Map<String, String> _dayArgs(Set<Weekday> days) {
    final sorted = sortDays(days);
    final names = join([for (final d in sorted) dayName(d)]);
    return {
      'days': names,
      'daysPlural': join([for (final d in sorted) _dayPlural(d)]),
      'onDays': plural('onDays', sorted.length, {
        'days': names,
        'leDays': join([for (final d in sorted) '${text('dayArticle')}${dayName(d)}']),
      }),
    };
  }

  /// "Every Monday and Tuesday" / "Every weekday" / "Every day".
  String weeklyStart(Set<Weekday> days) {
    if (days.length == 7) return plural('every.day', 1);
    if (_isWeekdays(days)) return text('weekly.weekdays1');
    if (_isWeekend(days)) return text('weekly.weekend1');
    return text('weekly.days1', _dayArgs(days));
  }

  /// "Every 2 weeks on Monday" / "Every 2 weeks on weekdays".
  String weeklyEvery(Set<Weekday> days, String every) {
    if (_isWeekdays(days)) return text('weekly.weekdaysN', {'every': every});
    if (_isWeekend(days)) return text('weekly.weekendN', {'every': every});
    return text('weekly.daysN', {'every': every, ..._dayArgs(days)});
  }

  /// " on weekdays" / " on Monday and Wednesday" ('' for every day).
  String dayFilter(Set<Weekday> days) {
    if (days.length == 7) return '';
    if (_isWeekdays(days)) return text('filter.weekdays');
    if (_isWeekend(days)) return text('filter.weekend');
    return text('filter.days', _dayArgs(days));
  }

  /// English ordinal suffix: 1st, 2nd, 3rd, 11th, 22nd…
  static String englishOrdinal(int n) {
    final mod100 = n % 100;
    if (mod100 >= 11 && mod100 <= 13) return '${n}th';
    return switch (n % 10) {
      1 => '${n}st',
      2 => '${n}nd',
      3 => '${n}rd',
      _ => '${n}th',
    };
  }

  /// Day number inside dates ("1er" in French).
  String dayNumber(int day) => language == 'fr' && day == 1 ? '1er' : '$day';

  String monthDays(List<int> values) {
    final sorted = values.toSet().toList()
      ..sort((a, b) {
        // Positive days first (ascending), then negatives from the start.
        if ((a > 0) != (b > 0)) return a > 0 ? -1 : 1;
        return a.compareTo(b);
      });
    return join([
      for (final v in sorted)
        if (v == -1)
          text('monthDay.last')
        else if (v == -2)
          text('monthDay.secondLast')
        else if (v < 0)
          text('monthDay.nthLast', {'n': '${-v}', 'nth': englishOrdinal(-v)})
        else
          text('monthDay.nth', {'n': '$v', 'nth': englishOrdinal(v), 'day': dayNumber(v)}),
    ]);
  }

  String _ordinal(int n) {
    final word = _catalog['ord.$n'];
    if (word is String) return word;
    return n > 0
        ? text('ord.numeric', {'n': '$n', 'nth': englishOrdinal(n)})
        : text('ord.numericLast', {'n': '${-n}', 'nth': englishOrdinal(-n)});
  }

  String nthWeekday(WeekdayRule rule) {
    final n = rule.n!;
    final ord = _ordinal(n);
    final key = _catalog.containsKey('ord.$n')
        ? 'nthWeekday'
        : (n > 0 ? 'nthWeekday.numeric' : 'nthWeekday.numericLast');
    return text(key, {
      'n': '${n.abs()}',
      'ord': ord,
      'le': _article(ord),
      'day': dayName(rule.day),
      'bareDay': _dayBare(rule.day),
    });
  }

  /// " on the last weekday" / " on the first and last weekend day".
  String setPos(List<int> positions, Set<Weekday> days) {
    final sortedPositions = positions.toSet().toList()
      ..sort((a, b) {
        if ((a > 0) != (b > 0)) return a > 0 ? -1 : 1;
        return a.compareTo(b);
      });
    final ords = join([
      for (final p in sortedPositions) text('setPos.ordItem', {'ord': _ordinal(p), 'le': _article(_ordinal(p))}),
    ]);
    final String set;
    if (days.length == 7) {
      set = text('set.day');
    } else if (_isWeekdays(days)) {
      set = text('set.weekday');
    } else if (_isWeekend(days)) {
      set = text('set.weekend');
    } else {
      set = joinOr([for (final d in sortDays(days)) _dayBare(d)]);
    }
    return text('setPos', {'ords': ords, 'set': set});
  }

  String yearDays(List<int> values) {
    if (values.length == 1 && values.single == -1) return text('yearDay.last');
    final items = [for (final v in values) _positionText(v)];
    return plural('yearDays', values.length, {'list': join(items)});
  }

  String _positionText(int v) => v > 0 ? '$v' : text('fromEnd', {'n': '${-v}'});

  String weekNos(List<int> values) {
    if (values.length == 1 && values.single == -1) return text('weekNo.last');
    final items = [for (final v in values) _positionText(v)];
    return plural('weekNo', values.length, {'list': join(items)});
  }

  String time(int minuteOfDay) {
    final t = LocalTime.fromMinuteOfDay(minuteOfDay % 1440);
    if (use24h) return t.toIso();
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour12:$minute ${text(t.hour < 12 ? 'am' : 'pm')}';
  }

  String window(LocalTime start, LocalTime end) => text('window', {
    'start': time(start.minuteOfDay),
    'end': end.isEndOfDay ? text('midnight') : time(end.minuteOfDay),
  });

  /// Hour limits of sub-daily rules: a range when contiguous, else a list.
  String hours(List<int> hours) {
    final contiguous = hours.last - hours.first == hours.length - 1;
    if (contiguous && hours.length > 1) {
      return window(LocalTime(hours.first, 0), LocalTime(hours.last, 59));
    }
    return text('hours', {
      'list': join([for (final h in hours) '$h']),
    });
  }

  String date(LocalDate date) =>
      text('date', {'month': monthName(date.month), 'day': dayNumber(date.day), 'year': '${date.year}'});
}
