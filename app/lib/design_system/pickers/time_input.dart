import 'package:everslot_recurrence/everslot_recurrence.dart';

/// Keyboard time entry for the 1-minute time picker (T1.3.11). Accepts "7:03", "07:03", "0703",
/// "703", "7.03", "7h03", "19", with an optional am/pm marker ("7:03 pm", "7pm", "7 م"), and
/// Arabic-Indic digits. Without a marker the value is read as 24 h; a marker requires hour 1–12.
/// Returns null for anything else.
LocalTime? parseTimeInput(String input) {
  var s = _asciiDigits(input).trim().toLowerCase();
  if (s.isEmpty) return null;
  bool? pm;
  final marker = RegExp(r'\s*(a\.?m\.?|p\.?m\.?|ص|م)$').firstMatch(s);
  if (marker != null) {
    final m = marker.group(1)!;
    pm = m.startsWith('p') || m == 'م';
    s = s.substring(0, marker.start).trim();
  }
  int? hour;
  int? minute;
  final sep = RegExp(r'^(\d{1,2})\s*[:.h]\s*(\d{2})$').firstMatch(s);
  if (sep != null) {
    hour = int.parse(sep.group(1)!);
    minute = int.parse(sep.group(2)!);
  } else if (RegExp(r'^\d{1,4}$').hasMatch(s)) {
    if (s.length <= 2) {
      hour = int.parse(s);
      minute = 0;
    } else {
      hour = int.parse(s.substring(0, s.length - 2));
      minute = int.parse(s.substring(s.length - 2));
    }
  }
  if (hour == null || minute == null || minute > 59) return null;
  if (pm != null) {
    if (hour < 1 || hour > 12) return null;
    hour = hour % 12 + (pm ? 12 : 0);
  } else if (hour > 23) {
    return null;
  }
  return LocalTime(hour, minute);
}

/// Formats [time] for the entry field: "07:03" (24 h) or "7:03 AM" (12 h).
String formatTimeInput(LocalTime time, {required bool use24h, String am = 'AM', String pm = 'PM'}) {
  final mm = time.minute.toString().padLeft(2, '0');
  if (use24h) return '${time.hour.toString().padLeft(2, '0')}:$mm';
  final h = time.hour % 12 == 0 ? 12 : time.hour % 12;
  return '$h:$mm ${time.hour < 12 ? am : pm}';
}

String _asciiDigits(String value) {
  final out = StringBuffer();
  for (final rune in value.runes) {
    if (rune >= 0x0660 && rune <= 0x0669) {
      out.writeCharCode(0x30 + rune - 0x0660);
    } else if (rune >= 0x06F0 && rune <= 0x06F9) {
      out.writeCharCode(0x30 + rune - 0x06F0);
    } else {
      out.writeCharCode(rune);
    }
  }
  return out.toString();
}
