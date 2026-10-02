import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:everslot/features/integrations/domain/device_calendar.dart';

/// Read-only access to the device calendars (T8.2.13); faked in tests.
abstract interface class DeviceCalendarSource {
  Future<bool> hasAccess();
  Future<bool> requestAccess();
  Future<List<DeviceCalendarInfo>> calendars();
  Future<List<DeviceEventInfo>> events(List<String> calendarIds, DateTime from, DateTime to);
}

class PluginDeviceCalendarSource implements DeviceCalendarSource {
  DeviceCalendar get _plugin => DeviceCalendar.instance;

  @override
  Future<bool> hasAccess() async => await _plugin.hasPermissions() == CalendarPermissionStatus.granted;

  @override
  Future<bool> requestAccess() async => await _plugin.requestPermissions() == CalendarPermissionStatus.granted;

  @override
  Future<List<DeviceCalendarInfo>> calendars() async => [
    for (final c in await _plugin.listCalendars())
      if (!c.hidden)
        DeviceCalendarInfo(
          id: c.id,
          name: c.name,
          color: DeviceCalendarMapping.parseColor(c.colorHex),
          account: c.accountName,
        ),
  ];

  @override
  Future<List<DeviceEventInfo>> events(List<String> calendarIds, DateTime from, DateTime to) async {
    if (calendarIds.isEmpty) return const [];
    return [
      for (final e in await _plugin.listEvents(from, to, calendarIds: calendarIds))
        if (e.status != EventStatus.canceled)
          DeviceEventInfo(
            id: e.instanceId,
            calendarId: e.calendarId,
            title: e.title,
            start: e.startDate,
            end: e.endDate,
            allDay: e.isAllDay,
            color: DeviceCalendarMapping.parseColor(e.colorHex),
            busy: e.availability != EventAvailability.free,
          ),
    ];
  }
}
