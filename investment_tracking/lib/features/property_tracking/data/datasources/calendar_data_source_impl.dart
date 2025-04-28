import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/services.dart';
import 'calendar_data_source.dart';
import 'package:timezone/timezone.dart' as tz;

const String HOUSE_EMOJI = '🏠';
const String PAID_EMOJI = '✅';
const String EMOJI_SEPARATOR = ' ';

class CalendarDataSourceImpl implements CalendarDataSource {
  final DeviceCalendarPlugin _plugin;

  CalendarDataSourceImpl({required DeviceCalendarPlugin plugin})
      : _plugin = plugin;

  Future<bool> _requestPermissions() async {
    var permissionsGranted = await _plugin.hasPermissions();
    if (permissionsGranted.isSuccess && !(permissionsGranted.data ?? false)) {
      permissionsGranted = await _plugin.requestPermissions();
      if (!permissionsGranted.isSuccess ||
          !(permissionsGranted.data ?? false)) {
        return false;
      }
    }
    return true;
  }

  Future<String?> _findWritableCalendarId() async {
    final calendarsResult = await _plugin.retrieveCalendars();
    if (!calendarsResult.isSuccess ||
        calendarsResult.data == null ||
        calendarsResult.data!.isEmpty) {
      return null;
    }
    final calendar = calendarsResult.data!.firstWhere(
      (cal) => !(cal.isReadOnly ?? true),
      orElse: () => calendarsResult.data!.firstWhere(
        (cal) => cal.id != null,
        orElse: () {
          return Calendar(id: null);
        },
      ),
    );
    if (calendar.id == null) return null;
    return calendar.id;
  }

  @override
  Future<List<Event>> getRawRentalEvents({required DateTime month}) async {
    if (!await _requestPermissions()) {
      throw PlatformException(
          code: 'PERMISSIONS_DENIED', message: 'Calendar permissions denied.');
    }

    final calendarId = await _findWritableCalendarId();
    if (calendarId == null) {
      throw PlatformException(
          code: 'NO_CALENDAR_FOUND', message: 'No suitable calendar found.');
    }

    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    try {
      final eventsResult = await _plugin.retrieveEvents(
        calendarId,
        RetrieveEventsParams(startDate: startOfMonth, endDate: endOfMonth),
      );

      if (!eventsResult.isSuccess || eventsResult.data == null) {
        throw PlatformException(
            code: 'RETRIEVE_FAILED',
            message:
                'Failed to retrieve calendar events: ${eventsResult.errors}');
      }

      final String prefix = HOUSE_EMOJI + EMOJI_SEPARATOR;
      final rentalEvents = eventsResult.data!
          .where((event) =>
              event.title != null && event.title!.trim().startsWith(prefix))
          .toList();

      return rentalEvents;
    } on PlatformException {
      rethrow;
    } catch (e) {
      throw Exception(
          'An unexpected error occurred while retrieving calendar events.');
    }
  }

  @override
  Future<void> updateEventToPaid({
    required String eventId,
    required String calendarId,
    required String currentTitle,
    required DateTime? start,
    required DateTime? end,
  }) async {
    if (!await _requestPermissions()) {
      throw PlatformException(
          code: 'PERMISSIONS_DENIED', message: 'Calendar permissions denied.');
    }

    final calendarsResult = await _plugin.retrieveCalendars();
    final selectedCalendar = calendarsResult.data?.firstWhere(
        (cal) => cal.id == calendarId,
        orElse: () => Calendar(id: null));

    if (selectedCalendar == null) {
      throw PlatformException(
          code: 'CALENDAR_NOT_FOUND',
          message: 'Calendar with ID $calendarId not found.');
    }
    if (selectedCalendar.isReadOnly ?? true) {
      throw PlatformException(
          code: 'READ_ONLY_CALENDAR',
          message: 'Cannot update events in a read-only calendar.');
    }

    if (currentTitle.trim().startsWith(PAID_EMOJI + EMOJI_SEPARATOR)) {
      return;
    }

    String updatedTitle;
    String baseTitle =
        currentTitle.replaceAll(PAID_EMOJI + EMOJI_SEPARATOR, "").trim();
    if (baseTitle.startsWith(HOUSE_EMOJI + EMOJI_SEPARATOR)) {
      updatedTitle = PAID_EMOJI + EMOJI_SEPARATOR + baseTitle;
    } else if (baseTitle.isNotEmpty) {
      updatedTitle = PAID_EMOJI +
          EMOJI_SEPARATOR +
          HOUSE_EMOJI +
          EMOJI_SEPARATOR +
          baseTitle;
    } else {
      throw ArgumentError('Cannot determine base title for event ID $eventId');
    }

    final updatedEvent = Event(
      calendarId,
      eventId: eventId,
      title: updatedTitle.trim(),
      start: start != null ? TZDateTime.from(start, tz.local) : null,
      end: end != null ? TZDateTime.from(end, tz.local) : null,
    );

    try {
      final updateResult = await _plugin.createOrUpdateEvent(updatedEvent);

      if (updateResult != null) {
        if (!(updateResult.isSuccess &&
            updateResult.data != null &&
            updateResult.data!.isNotEmpty)) {
          throw PlatformException(
            code: 'UPDATE_FAILED',
            message:
                'Failed to update calendar event $eventId: ${updateResult.errors}',
          );
        }
      } else {
        throw PlatformException(
          code: 'UPDATE_FAILED',
          message: 'Failed to update calendar event $eventId (null result).',
        );
      }
    } on PlatformException catch (e) {
      rethrow;
    } catch (e) {
      throw Exception(
          'An unexpected error occurred while updating event $eventId.');
    }
  }
}
