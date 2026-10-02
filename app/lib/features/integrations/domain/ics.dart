import 'dart:convert';

import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// One calendar event (RFC 5545 VEVENT) as Everslot reads and writes it (T8.2.11 / T8.2.12).
@immutable
class IcsEvent {
  const IcsEvent({
    required this.uid,
    required this.summary,
    required this.start,
    this.end,
    this.allDay = false,
    this.timeZone,
    this.description,
    this.location,
    this.url,
    this.recurrence,
    this.recurrenceId,
    this.cancelled = false,
    this.alarmsMinutesBefore = const [],
  });

  final String uid;
  final String summary;

  /// Wall clock in [timeZone] (null = floating; `UTC` for `…Z` values). All-day: midnight.
  final LocalDateTime start;

  /// Exclusive end (all-day: the day after the last day).
  final LocalDateTime? end;
  final bool allDay;
  final String? timeZone;
  final String? description;
  final String? location;
  final String? url;

  /// `DTSTART` + `RRULE` / `EXDATE` / `RDATE` lines (the [RRuleCodec] block), null for one-off events.
  final String? recurrence;

  /// Set on an override of one occurrence of the series [uid] (its original start).
  final LocalDateTime? recurrenceId;

  /// `STATUS:CANCELLED` (an override that removes the occurrence).
  final bool cancelled;

  /// `VALARM` triggers relative to the start (minutes before; 0 = at start).
  final List<int> alarmsMinutesBefore;

  int get durationMinutes {
    final e = end;
    if (e == null) return allDay ? 1440 : 60;
    final minutes = e.epochMinute - start.epochMinute;
    return minutes <= 0 ? (allDay ? 1440 : 60) : minutes;
  }

  @override
  bool operator ==(Object other) =>
      other is IcsEvent &&
      other.uid == uid &&
      other.summary == summary &&
      other.start == start &&
      other.end == end &&
      other.allDay == allDay &&
      other.timeZone == timeZone &&
      other.description == description &&
      other.location == location &&
      other.url == url &&
      other.recurrence == recurrence &&
      other.recurrenceId == recurrenceId &&
      other.cancelled == cancelled &&
      _sameInts(other.alarmsMinutesBefore, alarmsMinutesBefore);

  @override
  int get hashCode => Object.hash(
    uid,
    summary,
    start,
    end,
    allDay,
    timeZone,
    description,
    location,
    url,
    recurrence,
    recurrenceId,
    cancelled,
    Object.hashAll(alarmsMinutesBefore),
  );

  @override
  String toString() => 'IcsEvent($uid "$summary" $start${recurrence == null ? '' : ' ↻'})';

  static bool _sameInts(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// RFC 5545 writer: CRLF lines folded at 75 octets, escaped text, `TZID` references by IANA name.
abstract final class IcsWriter {
  static String calendar(List<IcsEvent> events, {required DateTime stamp, String name = 'Everslot'}) {
    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Everslot//Everslot//EN',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      'X-WR-CALNAME:${escape(name)}',
      for (final e in events) ..._event(e, stamp),
      'END:VCALENDAR',
    ];
    return '${lines.map(fold).join('\r\n')}\r\n';
  }

  static List<String> _event(IcsEvent e, DateTime stamp) {
    final recurrenceLines = e.recurrence?.split('\n').where((l) => l.trim().isNotEmpty).toList() ?? const [];
    final hasStart = recurrenceLines.any((l) => l.startsWith('DTSTART'));
    return [
      'BEGIN:VEVENT',
      'UID:${e.uid}',
      'DTSTAMP:${_utc(stamp)}',
      if (!hasStart) 'DTSTART${_value(e.start, e.allDay, e.timeZone)}',
      ...recurrenceLines,
      if (e.end case final end?) 'DTEND${_value(end, e.allDay, e.timeZone)}',
      if (e.recurrenceId case final rid?) 'RECURRENCE-ID${_value(rid, e.allDay, e.timeZone)}',
      'SUMMARY:${escape(e.summary)}',
      if (e.description case final d? when d.isNotEmpty) 'DESCRIPTION:${escape(d)}',
      if (e.location case final l? when l.isNotEmpty) 'LOCATION:${escape(l)}',
      if (e.url case final u? when u.isNotEmpty) 'URL:$u',
      if (e.cancelled) 'STATUS:CANCELLED',
      for (final m in e.alarmsMinutesBefore) ...[
        'BEGIN:VALARM',
        'ACTION:DISPLAY',
        'DESCRIPTION:${escape(e.summary)}',
        'TRIGGER:${m == 0 ? 'PT0M' : '-PT${m}M'}',
        'END:VALARM',
      ],
      'END:VEVENT',
    ];
  }

  static String _value(LocalDateTime v, bool allDay, String? zone) {
    String d(LocalDate x) => x.toIso().replaceAll('-', '');
    if (allDay) return ';VALUE=DATE:${d(v.date)}';
    final t = '${d(v.date)}T${v.time.toIso().replaceAll(':', '')}00';
    if (zone == null) return ':$t';
    if (zone == 'UTC' || zone == 'Etc/UTC') return ':${t}Z';
    return ';TZID=$zone:$t';
  }

  static String _utc(DateTime t) {
    final u = t.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${u.year}${two(u.month)}${two(u.day)}T${two(u.hour)}${two(u.minute)}${two(u.second)}Z';
  }

  static String escape(String text) =>
      text.replaceAll(r'\', r'\\').replaceAll(';', r'\;').replaceAll(',', r'\,').replaceAll(RegExp(r'\r?\n'), r'\n');

  /// Folds a content line at 75 octets without splitting UTF-8 sequences.
  static String fold(String line) {
    final bytes = utf8.encode(line);
    if (bytes.length <= 75) return line;
    final out = StringBuffer();
    var count = 0;
    var limit = 75;
    for (final rune in line.runes) {
      final ch = String.fromCharCode(rune);
      final size = utf8.encode(ch).length;
      if (count + size > limit) {
        out.write('\r\n ');
        count = 0;
        limit = 74;
      }
      out.write(ch);
      count += size;
    }
    return out.toString();
  }
}

/// What a calendar file contained (T8.2.12).
@immutable
class IcsParseResult {
  const IcsParseResult({this.events = const [], this.skipped = 0, this.calendarName});

  /// Series / one-off events, then their overrides (events with a `recurrenceId`).
  final List<IcsEvent> events;

  /// Components that could not be read (no UID / start, unsupported values).
  final int skipped;
  final String? calendarName;
}

/// RFC 5545 reader for VEVENTs from Google Calendar, Apple Calendar and Outlook exports.
abstract final class IcsParser {
  static IcsParseResult parse(String text) {
    final lines = _unfold(text);
    final events = <IcsEvent>[];
    var skipped = 0;
    String? calName;
    List<_Prop>? current;
    List<_Prop>? alarm;
    final alarms = <List<_Prop>>[];
    for (final line in lines) {
      final p = _Prop.parse(line);
      if (p == null) continue;
      if (p.name == 'BEGIN' && p.value.toUpperCase() == 'VEVENT') {
        current = [];
        alarms.clear();
      } else if (p.name == 'END' && p.value.toUpperCase() == 'VEVENT') {
        if (current != null) {
          final e = _event(current, alarms);
          if (e == null) {
            skipped++;
          } else {
            events.add(e);
          }
        }
        current = null;
      } else if (p.name == 'BEGIN' && p.value.toUpperCase() == 'VALARM') {
        alarm = [];
      } else if (p.name == 'END' && p.value.toUpperCase() == 'VALARM') {
        if (alarm != null) alarms.add(alarm);
        alarm = null;
      } else if (alarm != null) {
        alarm.add(p);
      } else if (current != null) {
        current.add(p);
      } else if (p.name == 'X-WR-CALNAME') {
        calName = unescape(p.value);
      }
    }
    events.sort((a, b) => (a.recurrenceId == null ? 0 : 1).compareTo(b.recurrenceId == null ? 0 : 1));
    return IcsParseResult(events: events, skipped: skipped, calendarName: calName);
  }

  static IcsEvent? _event(List<_Prop> props, List<List<_Prop>> alarms) {
    _Prop? first(String name) => props.where((p) => p.name == name).firstOrNull;
    final uid = first('UID')?.value.trim();
    final dtStart = first('DTSTART');
    if (uid == null || uid.isEmpty || dtStart == null) return null;
    final start = _time(dtStart);
    if (start == null) return null;
    final dtEnd = first('DTEND');
    var end = dtEnd == null ? null : _time(dtEnd)?.value;
    final duration = first('DURATION');
    if (end == null && duration != null) {
      final minutes = parseDuration(duration.value);
      if (minutes != null) end = start.value.plusMinutes(minutes);
    }
    if (end == null && start.allDay) end = start.value.date.plusDays(1).atStartOfDay;
    final ruleLines = [
      for (final p in props)
        if (const {'RRULE', 'EXDATE', 'RDATE'}.contains(p.name)) p.raw,
    ];
    final rid = first('RECURRENCE-ID');
    return IcsEvent(
      uid: uid,
      summary: unescape(first('SUMMARY')?.value ?? '').trim(),
      start: start.value,
      end: end,
      allDay: start.allDay,
      timeZone: start.zone,
      description: first('DESCRIPTION') == null ? null : unescape(first('DESCRIPTION')!.value),
      location: first('LOCATION') == null ? null : unescape(first('LOCATION')!.value),
      url: first('URL')?.value,
      recurrence: ruleLines.isEmpty ? null : [_dtStartLine(dtStart, start.zone), ...ruleLines].join('\n'),
      recurrenceId: rid == null ? null : _time(rid)?.value,
      cancelled: (first('STATUS')?.value.toUpperCase() ?? '') == 'CANCELLED',
      alarmsMinutesBefore: [
        for (final a in alarms)
          if (a.where((p) => p.name == 'TRIGGER').firstOrNull case final t?
              when t.params['VALUE'] != 'DATE-TIME' && t.params['RELATED'] != 'END')
            if (parseDuration(t.value) case final m?) -m,
      ].where((m) => m >= 0).toList(),
    );
  }

  /// DTSTART line for the [RRuleCodec] block, with a normalized (IANA) zone.
  static String _dtStartLine(_Prop p, String? zone) {
    final value = p.value.trim();
    if (p.params['VALUE'] == 'DATE') return 'DTSTART;VALUE=DATE:$value';
    if (zone == null || value.endsWith('Z')) return 'DTSTART:$value';
    return 'DTSTART;TZID=$zone:$value';
  }

  static ({LocalDateTime value, bool allDay, String? zone})? _time(_Prop p) {
    final v = p.value.trim();
    final m = RegExp(r'^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})(Z?))?$').firstMatch(v);
    if (m == null) return null;
    final date = LocalDate.tryCreate(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
    if (date == null) return null;
    if (m[4] == null) return (value: date.atStartOfDay, allDay: true, zone: null);
    final h = int.parse(m[4]!);
    final min = int.parse(m[5]!);
    if (h > 23 || min > 59) return null;
    final value = LocalDateTime(date, LocalTime(h, min));
    if (m[7] == 'Z') return (value: value, allDay: false, zone: 'UTC');
    final tzid = p.params['TZID'];
    return (value: value, allDay: false, zone: tzid == null ? null : ianaZone(tzid));
  }

  /// `-PT15M`, `PT1H30M`, `P1D`, `P1W` → minutes (signed); null when unreadable.
  static int? parseDuration(String text) {
    final m = RegExp(r'^([+-])?P(?:(\d+)W)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$')
        .firstMatch(text.trim());
    if (m == null) return null;
    int n(int i) => int.tryParse(m[i] ?? '') ?? 0;
    final minutes = n(2) * 7 * 1440 + n(3) * 1440 + n(4) * 60 + n(5) + n(6) ~/ 60;
    return m[1] == '-' ? -minutes : minutes;
  }

  /// IANA name for a `TZID`: IANA names pass through (also `/mozilla.org/…/Europe/Paris` prefixes);
  /// common Windows names from Outlook are mapped; anything else is kept (the resolver decides).
  static String ianaZone(String tzid) {
    final clean = tzid.replaceAll('"', '').trim();
    final mapped = _windowsZones[clean];
    if (mapped != null) return mapped;
    final iana = RegExp(r'([A-Za-z]+/[A-Za-z_\-+0-9]+(?:/[A-Za-z_\-+0-9]+)?)$').firstMatch(clean);
    return iana?[1] ?? clean;
  }

  static const _windowsZones = {
    'UTC': 'UTC',
    'GMT Standard Time': 'Europe/London',
    'W. Europe Standard Time': 'Europe/Berlin',
    'Romance Standard Time': 'Europe/Paris',
    'Central Europe Standard Time': 'Europe/Budapest',
    'Central European Standard Time': 'Europe/Warsaw',
    'E. Europe Standard Time': 'Europe/Chisinau',
    'FLE Standard Time': 'Europe/Kiev',
    'GTB Standard Time': 'Europe/Bucharest',
    'Russian Standard Time': 'Europe/Moscow',
    'W. Central Africa Standard Time': 'Africa/Lagos',
    'Morocco Standard Time': 'Africa/Casablanca',
    'Egypt Standard Time': 'Africa/Cairo',
    'Arab Standard Time': 'Asia/Riyadh',
    'Arabian Standard Time': 'Asia/Dubai',
    'India Standard Time': 'Asia/Kolkata',
    'China Standard Time': 'Asia/Shanghai',
    'Tokyo Standard Time': 'Asia/Tokyo',
    'AUS Eastern Standard Time': 'Australia/Sydney',
    'Eastern Standard Time': 'America/New_York',
    'Central Standard Time': 'America/Chicago',
    'Mountain Standard Time': 'America/Denver',
    'Pacific Standard Time': 'America/Los_Angeles',
    'SA Pacific Standard Time': 'America/Bogota',
    'E. South America Standard Time': 'America/Sao_Paulo',
  };

  static String unescape(String text) {
    final out = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      if (c == r'\' && i + 1 < text.length) {
        final n = text[++i];
        out.write(switch (n) {
          'n' || 'N' => '\n',
          _ => n,
        });
      } else {
        out.write(c);
      }
    }
    return out.toString();
  }

  static List<String> _unfold(String text) {
    final out = <String>[];
    for (final raw in text.split(RegExp(r'\r?\n'))) {
      if (raw.isEmpty) continue;
      if ((raw.startsWith(' ') || raw.startsWith('\t')) && out.isNotEmpty) {
        out[out.length - 1] += raw.substring(1);
      } else {
        out.add(raw);
      }
    }
    return out;
  }
}

class _Prop {
  _Prop(this.name, this.params, this.value, this.raw);

  final String name;
  final Map<String, String> params;
  final String value;
  final String raw;

  static _Prop? parse(String line) {
    // The value starts at the first ':' outside a quoted parameter value.
    var quoted = false;
    var colon = -1;
    for (var i = 0; i < line.length; i++) {
      if (line[i] == '"') quoted = !quoted;
      if (line[i] == ':' && !quoted) {
        colon = i;
        break;
      }
    }
    if (colon <= 0) return null;
    final head = line.substring(0, colon).split(';');
    final params = <String, String>{};
    for (final p in head.skip(1)) {
      final eq = p.indexOf('=');
      if (eq > 0) params[p.substring(0, eq).toUpperCase()] = p.substring(eq + 1).replaceAll('"', '');
    }
    final name = head.first.toUpperCase();
    final value = line.substring(colon + 1);
    // Normalize the rule lines' zone the same way as DTSTART (Outlook / Mozilla TZIDs).
    var raw = line;
    if (params['TZID'] case final tzid? when name == 'EXDATE' || name == 'RDATE') {
      raw = '$name;TZID=${IcsParser.ianaZone(tzid)}:$value';
    }
    return _Prop(name, params, value, raw);
  }
}
