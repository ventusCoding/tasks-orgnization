import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// A calendar of the device (Google / iCloud / Exchange accounts via the OS, T8.2.13).
@immutable
class DeviceCalendarInfo {
  const DeviceCalendarInfo({required this.id, required this.name, this.color, this.account});

  final String id;
  final String name;

  /// ARGB.
  final int? color;
  final String? account;
}

/// One event instance read from a device calendar (never stored).
@immutable
class DeviceEventInfo {
  const DeviceEventInfo({
    required this.id,
    required this.calendarId,
    required this.title,
    required this.start,
    required this.end,
    this.allDay = false,
    this.color,
    this.busy = true,
  });

  final String id;
  final String calendarId;
  final String title;

  /// Instants for timed events; for all-day events only the calendar date matters (floating).
  final DateTime start;
  final DateTime end;
  final bool allDay;
  final int? color;

  /// Free / tentative-as-free events don't block the free-slot finder.
  final bool busy;
}

/// The part of an event inside one day, in the viewer's wall clock.
@immutable
class DeviceEventSpan {
  const DeviceEventSpan({
    required this.eventId,
    required this.day,
    required this.start,
    required this.end,
    required this.title,
    this.allDay = false,
    this.color,
    this.busy = true,
  });

  final String eventId;
  final LocalDate day;
  final LocalDateTime start;
  final LocalDateTime end;
  final String title;
  final bool allDay;
  final int? color;
  final bool busy;

  @override
  bool operator ==(Object other) =>
      other is DeviceEventSpan &&
      other.eventId == eventId &&
      other.day == day &&
      other.start == start &&
      other.end == end &&
      other.title == title &&
      other.allDay == allDay &&
      other.color == color &&
      other.busy == busy;

  @override
  int get hashCode => Object.hash(eventId, day, start, end, title, allDay, color, busy);
}

abstract final class DeviceCalendarMapping {
  /// Per-day spans of [events] within [from]..[to] (inclusive days), timed events converted with
  /// [toLocal] (viewer zone), all-day events on their floating dates.
  static List<DeviceEventSpan> spans(
    List<DeviceEventInfo> events, {
    required LocalDateTime Function(DateTime utc) toLocal,
    required LocalDate from,
    required LocalDate to,
  }) {
    final out = <DeviceEventSpan>[];
    for (final e in events) {
      if (e.allDay) {
        final first = LocalDate(e.start.year, e.start.month, e.start.day);
        // Exclusive end at midnight; inclusive end otherwise (platforms differ).
        final endIsMidnight = e.end.hour == 0 && e.end.minute == 0;
        var last = LocalDate(e.end.year, e.end.month, e.end.day);
        if (endIsMidnight && last.isAfter(first)) last = last.plusDays(-1);
        for (var d = first; !d.isAfter(last); d = d.plusDays(1)) {
          if (d.isBefore(from) || d.isAfter(to)) continue;
          out.add(
            DeviceEventSpan(
              eventId: e.id,
              day: d,
              start: d.atStartOfDay,
              end: d.plusDays(1).atStartOfDay,
              title: e.title,
              allDay: true,
              color: e.color,
              busy: false,
            ),
          );
        }
        continue;
      }
      final start = toLocal(e.start.toUtc());
      final end = toLocal(e.end.toUtc());
      if (!end.isAfter(start)) continue;
      for (var d = start.date; !d.isAfter(end.date); d = d.plusDays(1)) {
        if (d.isBefore(from) || d.isAfter(to)) continue;
        final s = d == start.date ? start : d.atStartOfDay;
        final en = d == end.date ? end : d.plusDays(1).atStartOfDay;
        if (!en.isAfter(s)) continue;
        out.add(
          DeviceEventSpan(eventId: e.id, day: d, start: s, end: en, title: e.title, color: e.color, busy: e.busy),
        );
      }
    }
    out.sort((a, b) => a.start.compareTo(b.start));
    return out;
  }

  /// `#RRGGBB` / `#AARRGGBB` → opaque ARGB.
  static int? parseColor(String? hex) {
    if (hex == null) return null;
    final h = hex.replaceFirst('#', '');
    final v = int.tryParse(h, radix: 16);
    if (v == null) return null;
    return switch (h.length) {
      6 => 0xFF000000 | v,
      8 => 0xFF000000 | (v & 0xFFFFFF),
      _ => null,
    };
  }
}
