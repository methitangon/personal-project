import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/services.dart';
import 'calendar_data_source.dart';
import 'package:timezone/timezone.dart' as tz;

// Keep Constants
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
        print("DATASOURCE: Calendar permissions denied.");
        return false;
      }
    }
    print("DATASOURCE: Calendar permissions granted.");
    return true;
  }

  Future<String?> _findWritableCalendarId() async {
    final calendarsResult = await _plugin.retrieveCalendars();
    if (!calendarsResult.isSuccess ||
        calendarsResult.data == null ||
        calendarsResult.data!.isEmpty) {
      print("DATASOURCE: Error retrieving calendars or no calendars found.");
      // Consider throwing PlatformException('NO_CALENDARS', ...)
      return null;
    }
    final calendar = calendarsResult.data!.firstWhere(
      (cal) => !(cal.isReadOnly ?? true),
      orElse: () => calendarsResult.data!.firstWhere(
        (cal) => cal.id != null,
        orElse: () {
          print("DATASOURCE: No usable calendars found at all.");
          return Calendar(id: null);
        },
      ),
    );
    if (calendar.id == null) return null;

    if (calendar.isReadOnly ?? true) {
      print(
          "DATASOURCE: Warning - Using read-only calendar ID: ${calendar.id}, Name: ${calendar.name}. Updates will fail.");
    } else {
      print(
          "DATASOURCE: Using writable calendar ID: ${calendar.id}, Name: ${calendar.name}");
    }
    return calendar.id;
  }

  // --- New/Modified Methods ---

  @override
  Future<List<Event>> getRawRentalEvents({required DateTime month}) async {
    print("DATASOURCE: getRawRentalEvents called for $month");
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
        print(
            "DATASOURCE: Error retrieving events for $month: ${eventsResult.errors}");
        throw PlatformException(
            code: 'RETRIEVE_FAILED',
            message:
                'Failed to retrieve calendar events: ${eventsResult.errors}');
      }

      // Filter the raw events to only include those starting with HOUSE_EMOJI
      final String prefix = HOUSE_EMOJI + EMOJI_SEPARATOR;
      final rentalEvents = eventsResult.data!
          .where((event) =>
              event.title != null && event.title!.trim().startsWith(prefix))
          .toList();

      print(
          "DATASOURCE: Found ${rentalEvents.length} events starting with '$prefix' for $month");
      return rentalEvents;
    } on PlatformException {
      // Re-throw specific exceptions
      rethrow;
    } catch (e) {
      print("DATASOURCE: Generic Exception retrieving events: $e");
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
    print("DATASOURCE: updateEventToPaid called for eventId $eventId");
    // Permissions are needed to check read-only status and update
    if (!await _requestPermissions()) {
      throw PlatformException(
          code: 'PERMISSIONS_DENIED', message: 'Calendar permissions denied.');
    }

    // Check if the provided calendar ID is writable (important!)
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
      print(
          "DATASOURCE: Cannot update event, selected calendar '$calendarId' is read-only.");
      throw PlatformException(
          code: 'READ_ONLY_CALENDAR',
          message: 'Cannot update events in a read-only calendar.');
    }

    if (currentTitle.trim().startsWith(PAID_EMOJI + EMOJI_SEPARATOR)) {
      print(
          "DATASOURCE: Event $eventId already marked paid. No update needed.");
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
      print(
          "DATASOURCE: Warning - Original title missing house emoji? Constructing full title.");
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
        if (updateResult.isSuccess &&
            updateResult.data != null &&
            updateResult.data!.isNotEmpty) {
          print(
              "DATASOURCE: Successfully updated event $eventId to paid. New ID: ${updateResult.data}");
        } else {
          print(
              "DATASOURCE: Error updating event $eventId: ${updateResult.errors}");
          throw PlatformException(
            code: 'UPDATE_FAILED',
            message:
                'Failed to update calendar event $eventId: ${updateResult.errors}',
          );
        }
      } else {
        print(
            "DATASOURCE: Failed to get a result from createOrUpdateEvent for $eventId (plugin returned null).");
        throw PlatformException(
          code: 'UPDATE_FAILED',
          message: 'Failed to update calendar event $eventId (null result).',
        );
      }
    } on PlatformException catch (e) {
      print(
          "DATASOURCE: PlatformException during event update for $eventId: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      print(
          "DATASOURCE: Generic Exception during event update for $eventId: $e");
      throw Exception(
          'An unexpected error occurred while updating event $eventId.');
    }
  }
}
