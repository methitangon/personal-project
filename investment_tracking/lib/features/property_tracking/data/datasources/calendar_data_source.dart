import 'package:device_calendar/device_calendar.dart';

abstract class CalendarDataSource {
  Future<List<Event>> getRawRentalEvents({required DateTime month});

  Future<void> updateEventToPaid({
    required String eventId,
    required String calendarId,
    required String currentTitle,
    required TZDateTime? start,
    required TZDateTime? end,
  });
}
