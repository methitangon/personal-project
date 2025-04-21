import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/payment_status.dart';
import 'calendar_data_source.dart';

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

    if (calendar.id == null) {
      return null;
    }

    if (calendar.isReadOnly ?? true) {
      print(
          "DATASOURCE: Warning - Using read-only calendar ID: ${calendar.id}, Name: ${calendar.name}. Updates will fail.");
    } else {
      print(
          "DATASOURCE: Using writable calendar ID: ${calendar.id}, Name: ${calendar.name}");
    }

    return calendar.id;
  }

  Event? _findMatchingEvent(List<Event> events, String propertyName) {
    print(
        "DATASOURCE: Searching for event starting with '$HOUSE_EMOJI$EMOJI_SEPARATOR' and matching name '$propertyName'");
    print("DATASOURCE: Total events fetched for month: ${events.length}");

    final String prefix = HOUSE_EMOJI + EMOJI_SEPARATOR;

    for (final event in events) {
      if (event.title != null && event.title!.startsWith(prefix)) {
        final String extractedName =
            event.title!.substring(prefix.length).trim();
        print(
            "DATASOURCE: Checking event: '${event.title}' -> Extracted Name: '$extractedName'");

        if (extractedName.toLowerCase() == propertyName.toLowerCase()) {
          print(
              "DATASOURCE: Found matching event: ${event.title} (ID: ${event.eventId})");
          return event;
        }
      }
    }
    print("DATASOURCE: No matching event found for '$propertyName'.");
    return null;
  }

  @override
  Future<PaymentStatus> getEventPaymentStatus({
    required String propertyId,
    required String propertyName,
    required DateTime month,
  }) async {
    print(
        "DATASOURCE: getEventPaymentStatus called for $propertyName / $month (ID: $propertyId)");
    if (!await _requestPermissions()) return PaymentStatus.unknown;

    final calendarId = await _findWritableCalendarId();
    if (calendarId == null) return PaymentStatus.unknown;

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
        return PaymentStatus.unknown;
      }

      final matchingEvent =
          _findMatchingEvent(eventsResult.data!, propertyName);

      if (matchingEvent == null) {
        print(
            "DATASOURCE: No event found starting with '$HOUSE_EMOJI ' for '$propertyName', assuming PENDING.");
        return PaymentStatus.pending;
      }

      if (matchingEvent.title != null &&
          matchingEvent.title!
              .trim()
              .startsWith(PAID_EMOJI + EMOJI_SEPARATOR)) {
        print("DATASOURCE: Event for $propertyName is marked as PAID.");
        return PaymentStatus.paid;
      } else {
        print(
            "DATASOURCE: Event for $propertyName is PENDING (found house emoji, no paid emoji).");
        return PaymentStatus.pending;
      }
    } catch (e) {
      print("DATASOURCE: Exception retrieving/parsing events: $e");
      return PaymentStatus.unknown;
    }
  }

  @override
  Future<void> updateEventToPaid({
    required String propertyId,
    required String propertyName,
    required DateTime month,
  }) async {
    print(
        "DATASOURCE: updateEventToPaid called for $propertyName / $month (ID: $propertyId)");
    if (!await _requestPermissions()) return;

    final calendarId = await _findWritableCalendarId();
    if (calendarId == null) return;

    final calendarsResult = await _plugin.retrieveCalendars();
    final selectedCalendar =
        calendarsResult.data?.firstWhere((cal) => cal.id == calendarId);
    if (selectedCalendar?.isReadOnly ?? true) {
      print(
          "DATASOURCE: Cannot update event, selected calendar '$calendarId' is read-only.");
      throw PlatformException(
          code: 'READ_ONLY_CALENDAR',
          message: 'Cannot update events in a read-only calendar.');
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
            "DATASOURCE: Error retrieving events before update: ${eventsResult.errors}");
        return;
      }

      final eventToUpdate =
          _findMatchingEvent(eventsResult.data!, propertyName);

      if (eventToUpdate == null) {
        print(
            "DATASOURCE: Cannot update - event starting with '$HOUSE_EMOJI ' not found for '$propertyName'.");
        return;
      }

      final originalTitle = eventToUpdate.title ?? '';

      if (originalTitle.trim().startsWith(PAID_EMOJI + EMOJI_SEPARATOR)) {
        print("DATASOURCE: Event already marked paid. No update needed.");
        return;
      }

      String updatedTitle;
      if (originalTitle.startsWith(HOUSE_EMOJI + EMOJI_SEPARATOR)) {
        updatedTitle = PAID_EMOJI + EMOJI_SEPARATOR + originalTitle;
      } else {
        updatedTitle = PAID_EMOJI +
            EMOJI_SEPARATOR +
            HOUSE_EMOJI +
            EMOJI_SEPARATOR +
            propertyName;
        print(
            "DATASOURCE: Warning - Original title didn't start with house emoji, constructing full new title.");
      }

      final updatedEvent = Event(
        calendarId,
        eventId: eventToUpdate.eventId,
        title: updatedTitle.trim(),
        description: eventToUpdate.description,
        start: eventToUpdate.start,
        end: eventToUpdate.end,
        allDay: eventToUpdate.allDay,
      );

      final updateResult = await _plugin.createOrUpdateEvent(updatedEvent);

      if (updateResult != null) {
        if (updateResult.isSuccess &&
            updateResult.data != null &&
            updateResult.data!.isNotEmpty) {
          print(
              "DATASOURCE: Successfully updated event for $propertyName to paid. Event ID: ${updateResult.data}");
        } else {
          print("DATASOURCE: Error updating event: ${updateResult.errors}");
          throw PlatformException(
            code: 'UPDATE_FAILED',
            message: 'Failed to update calendar event: ${updateResult.errors}',
          );
        }
      } else {
        print(
            "DATASOURCE: Failed to get a result from createOrUpdateEvent (plugin returned null).");
        throw PlatformException(
          code: 'UPDATE_FAILED',
          message: 'Failed to update calendar event (null result).',
        );
      }
    } on PlatformException catch (e) {
      print(
          "DATASOURCE: PlatformException during event update: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      print("DATASOURCE: Generic Exception during event update: $e");
      throw Exception(
          'An unexpected error occurred while updating the calendar event.');
    }
  }
}
