import 'package:everslot/features/planner/domain/task.dart' show Priority;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// What a recognized piece of a quick-add phrase means (live highlighting, T8.1.17).
enum QuickSpanKind { date, time, duration, recurrence, category, priority, allDay }

@immutable
class QuickSpan {
  const QuickSpan(this.start, this.end, this.kind);

  final int start;
  final int end;
  final QuickSpanKind kind;

  @override
  bool operator ==(Object other) =>
      other is QuickSpan && other.start == start && other.end == end && other.kind == kind;

  @override
  int get hashCode => Object.hash(start, end, kind);

  @override
  String toString() => 'QuickSpan(${kind.name} $start-$end)';
}

/// The interpretation of a quick-add phrase (T8.1.17).
@immutable
class QuickParse {
  const QuickParse({
    required this.title,
    this.date,
    this.time,
    this.durationMinutes,
    this.allDay = false,
    this.rule,
    this.category,
    this.priority,
    this.spans = const [],
  });

  /// The phrase without the recognized parts.
  final String title;
  final LocalDate? date;
  final LocalTime? time;
  final int? durationMinutes;
  final bool allDay;
  final RecurrenceRule? rule;

  /// Category name as typed after `#`.
  final String? category;
  final Priority? priority;
  final List<QuickSpan> spans;

  bool get recognizedAnything => spans.isNotEmpty;

  LocalDateTime? get start =>
      date == null ? null : LocalDateTime(date!, allDay ? LocalTime.midnight : (time ?? LocalTime.midnight));
}

/// Deterministic natural-language parser for quick add (T8.1.17): English and French, no network.
///
/// "Gym tomorrow 7pm for 1h every Mon and Wed #health !high" → title *Gym*, tomorrow 19:00, 60 min,
/// weekly on Monday and Wednesday, category *health*, high priority. Text inside double quotes is
/// never interpreted. Ambiguities are resolved conservatively: abbreviated weekdays need a
/// connector (`on`, `every`, `next`…), `at 1`–`at 6` without am/pm mean the afternoon, bare `7h` is a
/// time (French) while `for 1h` / `30 min` are durations.
abstract final class QuickParser {
  static QuickParse parse(String input, {required LocalDateTime now, Weekday weekStart = Weekday.monday}) =>
      _Run(input, now, weekStart).run();
}

// ---------------------------------------------------------------------------------------------
// Vocabulary (folded: lower case, accents removed, typographic apostrophes → ').

const _wdFull = <String, Weekday>{
  'monday': Weekday.monday,
  'tuesday': Weekday.tuesday,
  'wednesday': Weekday.wednesday,
  'thursday': Weekday.thursday,
  'friday': Weekday.friday,
  'saturday': Weekday.saturday,
  'sunday': Weekday.sunday,
  'lundi': Weekday.monday,
  'mardi': Weekday.tuesday,
  'mercredi': Weekday.wednesday,
  'jeudi': Weekday.thursday,
  'vendredi': Weekday.friday,
  'samedi': Weekday.saturday,
  'dimanche': Weekday.sunday,
};

const _wdShort = <String, Weekday>{
  'mon': Weekday.monday,
  'tue': Weekday.tuesday,
  'tues': Weekday.tuesday,
  'wed': Weekday.wednesday,
  'thu': Weekday.thursday,
  'thur': Weekday.thursday,
  'thurs': Weekday.thursday,
  'fri': Weekday.friday,
  'sat': Weekday.saturday,
  'sun': Weekday.sunday,
  'lun': Weekday.monday,
  'mar': Weekday.tuesday,
  'mer': Weekday.wednesday,
  'jeu': Weekday.thursday,
  'ven': Weekday.friday,
  'sam': Weekday.saturday,
  'dim': Weekday.sunday,
};

const _months = <String, int>{
  'january': 1, 'jan': 1, 'janvier': 1, 'janv': 1, //
  'february': 2, 'feb': 2, 'fevrier': 2, 'fevr': 2, 'fev': 2,
  'march': 3, 'mars': 3,
  'april': 4, 'apr': 4, 'avril': 4, 'avr': 4,
  'may': 5, 'mai': 5,
  'june': 6, 'jun': 6, 'juin': 6,
  'july': 7, 'jul': 7, 'juillet': 7, 'juil': 7,
  'august': 8, 'aug': 8, 'aout': 8,
  'september': 9, 'sept': 9, 'sep': 9, 'septembre': 9,
  'october': 10, 'oct': 10, 'octobre': 10,
  'november': 11, 'nov': 11, 'novembre': 11,
  'december': 12, 'dec': 12, 'decembre': 12,
};

const _numberWords = <String, int>{
  'a': 1, 'an': 1, 'one': 1, 'un': 1, 'une': 1, //
  'two': 2, 'deux': 2,
  'three': 3, 'trois': 3,
  'four': 4, 'quatre': 4,
  'five': 5, 'cinq': 5,
  'six': 6,
  'seven': 7, 'sept': 7,
  'eight': 8, 'huit': 8,
  'nine': 9, 'neuf': 9,
  'ten': 10, 'dix': 10,
  'other': 2, 'second': 2,
};

const _ordinals = <String, int>{
  'first': 1, '1st': 1, 'premier': 1, '1er': 1, //
  'second': 2, '2nd': 2, 'deuxieme': 2, '2e': 2, '2eme': 2,
  'third': 3, '3rd': 3, 'troisieme': 3, '3e': 3, '3eme': 3,
  'fourth': 4, '4th': 4, 'quatrieme': 4, '4e': 4, '4eme': 4,
  'last': -1, 'dernier': -1,
};

String _alt(Iterable<String> words) => (words.toList()..sort((a, b) => b.length.compareTo(a.length))).join('|');

final _wdFullAlt = _alt(_wdFull.keys);
final _wdAnyAlt = _alt([..._wdFull.keys, ..._wdShort.keys]);
final _monthAlt = _alt(_months.keys);
final _numAlt = r'\d+|' + _alt(_numberWords.keys.where((w) => w != 'other' && w != 'second'));
final _ordAlt = _alt(_ordinals.keys);

const _every = '(?:every|each|chaque|tous les|toutes les|tous|toutes)';
const _unitDay = '(?:days?|jours?)';
const _unitWeek = '(?:weeks?|semaines?)';
const _unitMonth = '(?:months?|mois)';
const _unitYear = '(?:years?|ans|annees?)';
const _ordSuffix = '(?:st|nd|rd|th|er|e|eme)?';

/// A clock time: `7pm`, `7:30 pm`, `19:00`, `19h`, `19h30`.
const _clock = r'\d{1,2}(?:(?::|h)\d{2})?\s?(?:am|pm|a\.m\.|p\.m\.)|\d{1,2}:\d{2}|\d{1,2}h(?:\d{2})?';

/// A date expression (see [_Run._dateOf]).
final _date = [
  'day after tomorrow|apres-demain|apres demain|apresdemain',
  "today|aujourd'hui|aujourdhui|auj",
  'tomorrow|tmrw|tmr|demain',
  'next week|la semaine prochaine|semaine prochaine',
  'next month|le mois prochain|mois prochain',
  "next year|l'annee prochaine|annee prochaine",
  '(?:in|dans) (?:$_numAlt) (?:$_unitDay|$_unitWeek|$_unitMonth)',
  '(?:next|this|ce|on) (?:$_wdAnyAlt)(?! (?:of|du|de))',
  '(?:$_wdFullAlt) (?:prochain|next)',
  '(?:$_wdFullAlt)(?:\\s\\d{1,2}$_ordSuffix(?![:.]|\\s?(?:am|pm|a\\.m|p\\.m))(?:\\s(?:$_monthAlt))?)?',
  '\\d{1,2}$_ordSuffix(?: of)? (?:$_monthAlt)(?:,? \\d{4})?',
  '(?:$_monthAlt) \\d{1,2}$_ordSuffix(?:,? \\d{4})?',
  r'\d{4}-\d{2}-\d{2}',
  r'\d{1,2}/\d{1,2}(?:/\d{2,4})?',
  '(?:on )?the \\d{1,2}(?:st|nd|rd|th)(?! of (?:$_monthAlt))',
  'le \\d{1,2}(?:er)?(?! ?(?:h|:|\\d|/|-|(?:$_monthAlt)))',
].join('|');

// ---------------------------------------------------------------------------------------------

class _Run {
  _Run(this.input, this.now, this.weekStart) : f = _fold(input), claimed = List.filled(input.length, false);

  final String input;
  final LocalDateTime now;
  final Weekday weekStart;

  /// Folded copy of [input] with the same length (indices line up).
  final String f;
  final List<bool> claimed;
  final spans = <QuickSpan>[];
  final quoted = <(int, int)>[];

  LocalDate? date;
  LocalTime? time;
  int? duration;
  bool allDay = false;
  Frequency? freq;
  int interval = 1;
  List<WeekdayRule>? byWeekday;
  List<int> byMonthDay = const [];
  int? count;
  LocalDate? until;
  LocalTime? ruleTime;

  /// Time implied by `tonight` when no clock time is given.
  LocalTime? defaultTime;
  String? category;
  Priority? priority;

  LocalDate get today => now.date;

  static String _fold(String s) {
    const map = {
      'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ç': 'c', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
      'î': 'i', 'ï': 'i', 'í': 'i', 'ô': 'o', 'ö': 'o', 'ó': 'o', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
      'ÿ': 'y', 'ñ': 'n', '’': "'", '‘': "'", '–': '-', '—': '-', '\u00a0': ' ',
    };
    final out = StringBuffer();
    for (final ch in s.split('')) {
      final lower = ch.toLowerCase();
      final one = lower.length == 1 ? lower : ch;
      out.write(map[one] ?? one);
    }
    return out.toString();
  }

  bool _free(int start, int end) {
    for (var i = start; i < end; i++) {
      if (claimed[i]) return false;
    }
    return true;
  }

  void _claim(int start, int end, QuickSpanKind kind) {
    for (var i = start; i < end; i++) {
      claimed[i] = true;
    }
    spans.add(QuickSpan(start, end, kind));
  }

  /// Runs [pattern] (whole words) over the folded text; [onMatch] returns false to decline a match.
  void _scan(String pattern, QuickSpanKind kind, bool Function(RegExpMatch m) onMatch) {
    final re = RegExp("(?<![\\p{L}\\p{N}'-])(?:$pattern)(?![\\p{L}\\p{N}])", unicode: true);
    for (final m in re.allMatches(f)) {
      if (!_free(m.start, m.end)) continue;
      if (onMatch(m)) _claim(m.start, m.end, kind);
    }
  }

  QuickParse run() {
    // Quoted text is literal.
    for (final m in RegExp('"[^"]*"').allMatches(input)) {
      for (var i = m.start; i < m.end; i++) {
        claimed[i] = true;
      }
      quoted.add((m.start, m.end));
    }
    _tags();
    _recurrence();
    _allDay();
    _ranges();
    _durations();
    _dateTimes();
    _dates();
    _times();
    return _result();
  }

  // --- category & priority ----------------------------------------------------------------

  void _tags() {
    for (final m in RegExp(r'(?<![\p{L}\p{N}#])#([\p{L}\p{N}_-]+)', unicode: true).allMatches(input)) {
      if (!_free(m.start, m.end) || category != null) continue;
      category = m[1];
      _claim(m.start, m.end, QuickSpanKind.category);
    }
    const levels = {
      'urgent': Priority.urgent, 'urgente': Priority.urgent, '4': Priority.urgent, '!!': Priority.urgent, //
      'high': Priority.high, 'haute': Priority.high, 'haut': Priority.high, 'important': Priority.high,
      '3': Priority.high, '!': Priority.high,
      'medium': Priority.medium, 'med': Priority.medium, 'moyenne': Priority.medium, 'moyen': Priority.medium,
      'normal': Priority.medium, 'normale': Priority.medium, '2': Priority.medium,
      'low': Priority.low, 'basse': Priority.low, 'bas': Priority.low, '1': Priority.low,
    };
    // `!high`, `!1`–`!4`, `!!` (high), `!!!` (urgent); a lone `!` stays punctuation.
    for (final m in RegExp(r'(?<!\S)!([\p{L}\d]+|!{1,2})(?!\S)', unicode: true).allMatches(f)) {
      final level = levels[m[1]];
      if (level == null || !_free(m.start, m.end) || priority != null) continue;
      priority = level;
      _claim(m.start, m.end, QuickSpanKind.priority);
    }
  }

  // --- recurrence -------------------------------------------------------------------------

  static List<Weekday> _weekdays(String list) => [
    for (final w in RegExp('[a-z]+').allMatches(list).map((m) => m[0]!))
      if (_wdFull[w] ?? _wdFull[_singular(w)] ?? _wdShort[w] ?? _wdShort[_singular(w)] case final d?) d,
  ];

  static String _singular(String w) => w.endsWith('s') ? w.substring(0, w.length - 1) : w;

  static int _num(String s) => int.tryParse(s) ?? _numberWords[s] ?? 1;

  void _setRule(Frequency fr, {int every = 1, List<WeekdayRule>? days, List<int> monthDays = const []}) {
    freq = fr;
    interval = every;
    byWeekday = days;
    byMonthDay = monthDays;
  }

  void _recurrence() {
    const rec = QuickSpanKind.recurrence;
    final wdList = '(?:$_wdAnyAlt)s?(?:\\s*(?:,|and|et|&|/|\\+)\\s*(?:$_wdAnyAlt)s?)*';
    final pluralList = '(?:$_wdFullAlt)s(?:\\s*(?:,|and|et|&|/|\\+)\\s*(?:$_wdFullAlt)s)*';
    bool once(RegExpMatch m) => freq == null;

    // Count and end.
    _scan(r'(?:for )?(\d+) (?:times|fois)', rec, (m) {
      count = int.parse(m[1]!);
      return true;
    });
    _scan("(?:until|till|through|jusqu'au|jusqu'a|jusqu au|jusqu a|jusqu'en) ($_date)", rec, (m) {
      until = _dateOf(m[1]!, preferFuture: true);
      return until != null;
    });

    // Nth weekday of the month.
    _scan(
      '(?:$_every |the |le |on the )?($_ordAlt) ($_wdAnyAlt)(?: (?:of|du|de) (?:the|every|each|chaque|tous les) ?(?:month|mois)| du mois)',
      rec,
      (m) {
        if (!once(m)) return false;
        _setRule(Frequency.monthly, days: [WeekdayRule(_weekdays(m[2]!).single, _ordinals[m[1]!])]);
        return true;
      },
    );
    _scan('$_every ($_ordAlt) ($_wdAnyAlt)', rec, (m) {
      if (!once(m)) return false;
      _setRule(Frequency.monthly, days: [WeekdayRule(_weekdays(m[2]!).single, _ordinals[m[1]!])]);
      return true;
    });

    // Day of month.
    for (final pattern in [
      '(?:$_every|monthly|mensuel|mensuellement) (?:month |mois )?(?:on )?(?:the |le )?(\\d{1,2})$_ordSuffix(?: (?:of|de|du) (?:the |every |each |chaque |tous les )?(?:month|mois))?(?=\\s|\$)',
      r'(?:on )?the (\d{1,2})(?:st|nd|rd|th) of (?:every|each) month',
      '(?:le|tous les) (\\d{1,2})$_ordSuffix (?:de chaque mois|du mois|de tous les mois)',
      r'(?:chaque mois|tous les mois) le (\d{1,2})(?:er)?',
    ]) {
      _scan(pattern, rec, (m) {
        final day = int.parse(m[1]!);
        // `every 2 weeks` is not a day of month: units are handled below.
        if (!once(m) || day < 1 || day > 31) return false;
        if (RegExp('^$_every \\d{1,2}\$').hasMatch(m[0]!)) return false;
        _setRule(Frequency.monthly, monthDays: [day]);
        return true;
      });
    }

    // Every other / every N units.
    _scan('(?:$_every) (?:other|second|($_numAlt)) ($_unitDay|$_unitWeek|$_unitMonth|$_unitYear)', rec, (m) {
      if (!once(m)) return false;
      final n = m[1] == null ? 2 : _num(m[1]!);
      _setRule(_unitFreq(m[2]!), every: n);
      return true;
    });
    _scan('(?:un|une) ($_unitDay|$_unitWeek|$_unitMonth|$_unitYear) sur (deux|trois|$_numAlt)', rec, (m) {
      if (!once(m)) return false;
      _setRule(_unitFreq(m[1]!), every: _num(m[2]!));
      return true;
    });

    // Weekdays / weekends.
    _scan(
      '(?:every |each |on )?(?:weekdays?|workdays?|work days?|business days?)|en semaine|(?:tous les |chaque )?jours? (?:de semaine|ouvres?|ouvrables?)|(?:du )?lundi au vendredi|(?:from )?monday to friday|mon-fri|lun-ven',
      rec,
      (m) {
        if (!once(m)) return false;
        _setRule(Frequency.weekly, days: [for (final d in Weekday.values.take(5)) WeekdayRule(d)]);
        return true;
      },
    );
    _scan('(?:every |each |on )?weekends?|(?:le |chaque |tous les |les )week-?ends?', rec, (m) {
      if (!once(m)) return false;
      _setRule(Frequency.weekly, days: const [WeekdayRule(Weekday.saturday), WeekdayRule(Weekday.sunday)]);
      return true;
    });

    // Every other Monday.
    _scan('$_every (?:other|second) ($_wdAnyAlt)', rec, (m) {
      if (!once(m)) return false;
      _setRule(Frequency.weekly, every: 2, days: [WeekdayRule(_weekdays(m[1]!).single)]);
      return true;
    });

    // Weekday lists, optionally with a time of day (`every saturday morning`).
    const period = '(?: (morning|afternoon|evening|night|matin|apres-midi|soir))?';
    _scan('(?:$_every|on|les) ($wdList)$period', rec, (m) {
      final days = _weekdays(m[1]!);
      final plural = RegExp('(?:$_wdFullAlt)s').hasMatch(m[1]!);
      if (!once(m) || days.isEmpty) return false;
      if (m[0]!.startsWith('on ') || m[0]!.startsWith('les ')) {
        if (!plural) return false; // `on friday` is a date
      }
      _setRule(Frequency.weekly, days: [for (final d in days.toSet()) WeekdayRule(d)]);
      if (m[2] != null) ruleTime = _periodTime(m[2]!);
      return true;
    });
    _scan('($pluralList)$period', rec, (m) {
      if (!once(m)) return false;
      _setRule(Frequency.weekly, days: [for (final d in _weekdays(m[1]!).toSet()) WeekdayRule(d)]);
      if (m[2] != null) ruleTime = _periodTime(m[2]!);
      return true;
    });

    // Every morning / tous les soirs: daily at a time of day.
    _scan('$_every (?:the )?(morning|afternoon|evening|night|matin|apres-midi|soir|nuit)s?', rec, (m) {
      if (!once(m)) return false;
      _setRule(Frequency.daily);
      ruleTime = _periodTime(m[1]!);
      return true;
    });

    // Plain units: `every week` before the adjectives, so `Weekly sync every week` keeps its title.
    Frequency unitOf(String w) => switch (w) {
      'day' || 'jour' || 'everyday' || 'daily' => Frequency.daily,
      'week' || 'semaine' || 'weekly' || 'hebdo' => Frequency.weekly,
      'month' || 'mois' || 'monthly' => Frequency.monthly,
      'year' || 'an' || 'annee' || 'yearly' || 'annually' => Frequency.yearly,
      _ when w.startsWith('quotidien') => Frequency.daily,
      _ when w.startsWith('hebdomadaire') => Frequency.weekly,
      _ when w.startsWith('mensuel') => Frequency.monthly,
      _ => Frequency.yearly,
    };
    _scan('(?:every|each|chaque|tous les|toutes les) (day|jour|week|semaine|month|mois|year|an|annee)s?', rec, (m) {
      if (!once(m)) return false;
      _setRule(unitOf(m[1]!));
      return true;
    });
    _scan(
      'everyday|daily|weekly|monthly|yearly|annually|quotidien(?:ne)?(?:ment)?|hebdomadaire(?:ment)?|hebdo|mensuel(?:le)?(?:ment)?|annuel(?:le)?(?:ment)?',
      rec,
      (m) {
        if (!once(m)) return false;
        _setRule(unitOf(m[0]!));
        return true;
      },
    );
  }

  static Frequency _unitFreq(String unit) => switch (unit) {
    _ when unit.startsWith('day') || unit.startsWith('jour') => Frequency.daily,
    _ when unit.startsWith('week') || unit.startsWith('semaine') => Frequency.weekly,
    _ when unit.startsWith('month') || unit == 'mois' => Frequency.monthly,
    _ => Frequency.yearly,
  };

  // --- all day, ranges, durations ---------------------------------------------------------

  void _allDay() {
    _scan('all[ -]day|toute la journee|journee entiere', QuickSpanKind.allDay, (m) {
      allDay = true;
      return true;
    });
  }

  void _ranges() {
    const t = r'(\d{1,2})(?:(?::|h)(\d{2}))?\s?(am|pm|a\.m\.|p\.m\.|h)?';
    _scan('(from |de |between |entre )?$t ?(-|to|till|until|a|and|et) ?$t', QuickSpanKind.time, (m) {
      // Groups: 1 prefix, 2–4 start, 5 connector, 6–8 end.
      final startMarked = m[3] != null || m[4] != null;
      final endMarked = m[7] != null || m[8] != null;
      if (!startMarked && !endMarked) return false; // `7-8` alone is not a time range
      // `le 15 à 9h`: a word connector without `from`/`de` needs a marked start.
      if (m[1] == null && m[5] != '-' && !startMarked) return false;
      if (time != null) return false;
      final endMer = m[8];
      final startMer = m[4] ?? (endMer == 'h' ? 'h' : null);
      final a = _clockOf(int.parse(m[2]!), m[3] == null ? 0 : int.parse(m[3]!), startMer, endMeridiem: endMer);
      final b = _clockOf(int.parse(m[6]!), m[7] == null ? 0 : int.parse(m[7]!), endMer);
      if (a == null || b == null) return false;
      time = a;
      final minutes = b.minuteOfDay - a.minuteOfDay;
      duration = minutes > 0 ? minutes : minutes + 1440;
      return true;
    });
  }

  void _durations() {
    const d = QuickSpanKind.duration;
    _scan(
      '(?:for|pendant|pour|durant|during) (?:an hour and a half|une heure et demie|1 ?h ?et demie)',
      d,
      (m) => _setDuration(90),
    );
    _scan(
      '(?:for|pendant|pour|durant|during) (?:half an hour|a half hour|une demi-?heure)',
      d,
      (m) => _setDuration(30),
    );
    _scan(
      r'(?:for|pendant|pour|durant|during|lasting) (\d+(?:[.,]\d+)?|an?|one|two|three|une?|deux|trois) ?(h|hrs?|hours?|heures?)(?: ?(?:and )?(\d{1,2}) ?(?:m|mins?|minutes?)?)?',
      d,
      (m) {
        final hours = double.tryParse(m[1]!.replaceAll(',', '.')) ?? _num(m[1]!).toDouble();
        return _setDuration((hours * 60).round() + (m[3] == null ? 0 : int.parse(m[3]!)));
      },
    );
    _scan(r'(?<!(?:in|dans) )(?:(?:for|pendant|pour|durant|during|lasting) )?(\d+) ?(?:m|mins?|minutes?)', d, (m) {
      // A bare `5m` needs the connector; `30 min` / `30mins` stand alone.
      if (!m[0]!.contains(RegExp('min|for|pendant|pour|durant|during|lasting'))) return false;
      return _setDuration(int.parse(m[1]!));
    });
    _scan(r'(?<!(?:in|dans) )(\d+(?:[.,]\d+)?) ?(?:hours?|hrs?|heures?)', d, (m) {
      return _setDuration((double.parse(m[1]!.replaceAll(',', '.')) * 60).round());
    });
  }

  bool _setDuration(int minutes) {
    if (duration != null || minutes <= 0) return false;
    duration = minutes;
    return true;
  }

  // --- dates and times --------------------------------------------------------------------

  void _dateTimes() {
    // `tonight` / `ce soir`, `tomorrow morning`, `this afternoon`…
    _scan('tonight|ce soir', QuickSpanKind.date, (m) {
      if (date != null) return false;
      date = today;
      defaultTime = LocalTime(20, 0);
      return true;
    });
    _scan(
      '($_date|this|ce|cet|in the|le|du|en) (morning|afternoon|evening|night|matin|apres-midi|soir|nuit)',
      QuickSpanKind.time,
      (m) {
        if (time != null) return false;
        final head = m[1]!;
        if (!const {'this', 'ce', 'cet', 'in the', 'le', 'du', 'en'}.contains(head)) {
          final d = _dateOf(head);
          if (d == null || date != null) return false;
          date = d;
        } else if (head == 'this' || head == 'ce' || head == 'cet') {
          date ??= today;
        }
        time = _periodTime(m[2]!);
        return true;
      },
    );
    // `in 2 hours`, `dans 30 min`: a start relative to now.
    _scan(r'(?:in|dans) (\d+|an?|une?|half an) ?(hours?|h|heures?|mins?|minutes?)', QuickSpanKind.time, (m) {
      if (date != null || time != null) return false;
      final n = m[1] == 'half an' ? 30 : _num(m[1]!);
      final minutes = m[2]!.startsWith('h') ? n * 60 : n;
      final at = now.plusMinutes(minutes);
      date = at.date;
      time = at.time;
      return true;
    });
  }

  void _dates() {
    _scan(_date, QuickSpanKind.date, (m) {
      if (date != null) return false;
      final d = _dateOf(m[0]!);
      if (d == null) return false;
      date = d;
      return true;
    });
  }

  void _times() {
    const t = QuickSpanKind.time;
    _scan('(at |@ ?|a |vers |around )?($_clock)', t, (m) {
      if (time != null) return false;
      var c = _parseClock(m[2]!);
      if (c == null) return false;
      // English `at 3:30` without am/pm: the afternoon (as for `at 3`).
      final conn = m[1] ?? '';
      final english = conn.startsWith('at') || conn.startsWith('@') || conn.startsWith('around');
      if (english && !m[2]!.contains(RegExp(r'am|pm|a\.m|p\.m|h')) && c.hour >= 1 && c.hour <= 6) {
        c = LocalTime(c.hour + 12, c.minute);
      }
      time = c;
      return true;
    });
    // `at 7` / `à 15` (no marker): needs the connector.
    _scan(r'(?:at|@|a|vers|around) (\d{1,2})(?! ?(?:%|€|\$|[.,]\d))', t, (m) {
      if (time != null) return false;
      var h = int.parse(m[1]!);
      if (h > 23) return false;
      // English `at 1`–`at 6` without am/pm: the afternoon.
      if (h >= 1 && h <= 6 && (m[0]!.startsWith('at') || m[0]!.startsWith('around') || m[0]!.startsWith('@'))) {
        h += 12;
      }
      time = LocalTime(h, 0);
      return true;
    });
    _scan('(?:at |a )?(noon|midday|midi|midnight|minuit)', t, (m) {
      if (time != null) return false;
      time = const {'noon', 'midday', 'midi'}.contains(m[1]) ? LocalTime(12, 0) : LocalTime.midnight;
      return true;
    });
  }

  static LocalTime _periodTime(String word) => switch (word) {
    'morning' || 'matin' => LocalTime(9, 0),
    'afternoon' || 'apres-midi' => LocalTime(14, 0),
    'evening' || 'soir' => LocalTime(19, 0),
    _ => LocalTime(21, 0),
  };

  static LocalTime? _parseClock(String s) {
    final m = RegExp(r'^(\d{1,2})(?:(?::|h)(\d{2}))?\s?(am|pm|a\.m\.|p\.m\.|h)?$')
        .firstMatch(s.replaceAll(RegExp(r'h$'), 'h'));
    if (m == null) return null;
    final mer = m[3] ?? (s.contains('h') ? 'h' : null);
    return _clockOf(int.parse(m[1]!), m[2] == null ? 0 : int.parse(m[2]!), mer);
  }

  /// 12-hour clocks for am/pm; [endMeridiem] lets `7-8pm` borrow the pm.
  static LocalTime? _clockOf(int h, int min, String? meridiem, {String? endMeridiem}) {
    if (min > 59) return null;
    var mer = meridiem;
    if (mer == null && endMeridiem != null && endMeridiem != 'h') mer = endMeridiem;
    final pm = mer == 'pm' || mer == 'p.m.';
    final am = mer == 'am' || mer == 'a.m.';
    if (pm || am) {
      if (h < 1 || h > 12) return null;
      final hour = (h % 12) + (pm ? 12 : 0);
      return LocalTime(hour, min);
    }
    if (h > 23) return null;
    return LocalTime(h, min);
  }

  /// The date of a [_date] expression (relative to [today]); dates without a year are the next
  /// occurrence on or after today.
  LocalDate? _dateOf(String s, {bool preferFuture = false}) {
    final words = s.trim();
    switch (words) {
      case 'today' || "aujourd'hui" || 'aujourdhui' || 'auj':
        return today;
      case 'tomorrow' || 'tmrw' || 'tmr' || 'demain':
        return today.plusDays(1);
      case 'day after tomorrow' || 'apres-demain' || 'apres demain' || 'apresdemain':
        return today.plusDays(2);
      case 'next week' || 'la semaine prochaine' || 'semaine prochaine':
        return _weekStartOf(today).plusDays(7);
      case 'next month' || 'le mois prochain' || 'mois prochain':
        return LocalDate(today.year, today.month, 1).plusMonths(1);
      case 'next year' || "l'annee prochaine" || 'annee prochaine':
        return LocalDate(today.year + 1, 1, 1);
    }
    var m = RegExp('^(?:in|dans) ($_numAlt) ($_unitDay|$_unitWeek|$_unitMonth)\$').firstMatch(words);
    if (m != null) {
      final n = _num(m[1]!);
      return switch (_unitFreq(m[2]!)) {
        Frequency.daily => today.plusDays(n),
        Frequency.weekly => today.plusDays(7 * n),
        _ => today.plusMonths(n),
      };
    }
    m = RegExp('^(next|this|ce|on) ($_wdAnyAlt)\$').firstMatch(words);
    if (m != null) {
      final day = _weekdays(m[2]!).single;
      return m[1] == 'next' ? _nextWeekday(day) : _upcoming(day);
    }
    m = RegExp('^($_wdFullAlt) (?:prochain|next)\$').firstMatch(words);
    if (m != null) return _nextWeekday(_wdFull[m[1]]!);
    m = RegExp('^($_wdFullAlt)(?:\\s(\\d{1,2})$_ordSuffix(?:\\s($_monthAlt))?)?\$').firstMatch(words);
    if (m != null) {
      if (m[2] == null) return _upcoming(_wdFull[m[1]]!);
      final day = int.parse(m[2]!);
      return m[3] == null ? _nextMonthDay(day) : _nextDayMonth(day, _months[m[3]]!, null);
    }
    m = RegExp('^(\\d{1,2})$_ordSuffix(?: of)? ($_monthAlt)(?:,? (\\d{4}))?\$').firstMatch(words);
    if (m != null) return _nextDayMonth(int.parse(m[1]!), _months[m[2]]!, m[3] == null ? null : int.parse(m[3]!));
    m = RegExp('^($_monthAlt) (\\d{1,2})$_ordSuffix(?:,? (\\d{4}))?\$').firstMatch(words);
    if (m != null) return _nextDayMonth(int.parse(m[2]!), _months[m[1]]!, m[3] == null ? null : int.parse(m[3]!));
    m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(words);
    if (m != null) return LocalDate.tryCreate(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
    m = RegExp(r'^(\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?$').firstMatch(words);
    if (m != null) {
      var (a, b) = (int.parse(m[1]!), int.parse(m[2]!));
      // Day/month unless that is impossible (then month/day).
      if (b > 12 && a <= 12) (a, b) = (b, a);
      final y = m[3] == null ? null : (m[3]!.length == 2 ? 2000 + int.parse(m[3]!) : int.parse(m[3]!));
      return _nextDayMonth(a, b, y);
    }
    m = RegExp(r'^(?:on )?the (\d{1,2})(?:st|nd|rd|th)$|^le (\d{1,2})(?:er)?$').firstMatch(words);
    if (m != null) return _nextMonthDay(int.parse(m[1] ?? m[2]!));
    return null;
  }

  LocalDate _weekStartOf(LocalDate d) => d.plusDays(-((d.weekday.iso - weekStart.iso + 7) % 7));

  /// On or after today.
  LocalDate _upcoming(Weekday wd) => today.plusDays((wd.iso - today.weekday.iso + 7) % 7);

  /// That weekday in the next week (`next friday` on a Tuesday is the Friday after this one).
  LocalDate _nextWeekday(Weekday wd) => _weekStartOf(today).plusDays(7 + (wd.iso - weekStart.iso + 7) % 7);

  LocalDate? _nextMonthDay(int day) {
    for (var i = 0; i < 13; i++) {
      final first = LocalDate(today.year, today.month, 1).plusMonths(i);
      final d = LocalDate.tryCreate(first.year, first.month, day);
      if (d != null && !d.isBefore(today)) return d;
    }
    return null;
  }

  LocalDate? _nextDayMonth(int day, int month, int? year) {
    if (year != null) return LocalDate.tryCreate(year, month, day);
    final d = LocalDate.tryCreate(today.year, month, day);
    if (d != null && !d.isBefore(today)) return d;
    return LocalDate.tryCreate(today.year + 1, month, day);
  }

  // --- result -----------------------------------------------------------------------------

  QuickParse _result() {
    RecurrenceRule? rule;
    if (freq != null) {
      rule = RecurrenceRule(
        freq: freq!,
        interval: interval,
        byWeekday: byWeekday,
        byMonthDay: byMonthDay,
        wkst: weekStart,
        count: count,
        until: until == null ? null : LocalDateTime(until!, LocalTime.fromMinuteOfDay(1439)),
      );
      time ??= ruleTime ?? defaultTime;
      date ??= _firstOccurrence();
    } else if (date == null && time != null && !allDay) {
      date = time!.minuteOfDay > now.time.minuteOfDay ? today : today.plusDays(1);
    }
    time ??= defaultTime;
    if (allDay) {
      time = null;
      date ??= today;
    }
    return QuickParse(
      title: _title(),
      date: date,
      time: time,
      durationMinutes: allDay ? null : duration,
      allDay: allDay,
      rule: rule,
      category: category,
      priority: priority,
      spans: [...spans]..sort((a, b) => a.start.compareTo(b.start)),
    );
  }

  /// First day on or after today matching the rule's day filters.
  LocalDate _firstOccurrence() {
    for (var i = 0; i < 400; i++) {
      final d = today.plusDays(i);
      final days = byWeekday;
      if (days != null && days.isNotEmpty) {
        final ok = days.any((w) {
          if (w.day != d.weekday) return false;
          final n = w.n;
          if (n == null) return true;
          if (n > 0) return (d.day - 1) ~/ 7 + 1 == n;
          return d.day > LocalDate.daysInMonth(d.year, d.month) - 7;
        });
        if (ok) return d;
        continue;
      }
      if (byMonthDay.isNotEmpty) {
        if (byMonthDay.contains(d.day)) return d;
        continue;
      }
      return d;
    }
    return today;
  }

  String _title() {
    final out = StringBuffer();
    for (var i = 0; i < input.length; i++) {
      final inQuote = quoted.any((q) => i >= q.$1 && i < q.$2);
      if (inQuote) {
        if (input[i] != '"') out.write(input[i]);
      } else if (!claimed[i]) {
        out.write(input[i]);
      } else {
        out.write(' ');
      }
    }
    var title = out.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    // Connectors left dangling by removed parts.
    final dangling = RegExp(
      r'(?:^|\s)(?:at|on|for|from|by|in|every|each|and|the|starting|le|les|pour|pendant|de|du|dans|et|chaque|tous|toutes|,|–)$',
      caseSensitive: false,
    );
    for (var guard = 0; guard < 4; guard++) {
      final next = title.replaceFirst(dangling, '').trim();
      if (next == title) break;
      title = next;
    }
    return title.replaceAllMapped(RegExp(r'\s+([,.;:!?])'), (m) => m[1]!).replaceAll(RegExp(r'[,;:\-–]+$'), '').trim();
  }
}
