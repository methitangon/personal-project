import 'package:device_calendar/device_calendar.dart';

import '../../domain/entities/payment_status.dart';
import 'calendar_data_source.dart';

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

    // Try to find the first writable calendar. In a real app, you might let the user choose.
    final writableCalendar = calendarsResult.data!.firstWhere(
      (cal) => !(cal.isReadOnly ?? true),
      orElse: () {
        print("DATASOURCE: No writable calendar found.");
        // Fallback: maybe try the first calendar even if read-only for reading events?
        return calendarsResult.data!.first;
      },
    );

    print(
        "DATASOURCE: Using calendar ID: ${writableCalendar.id}, Name: ${writableCalendar.name}");
    return writableCalendar.id;
  }

  Event? _findMatchingEvent(
      List<Event> events, String propertyName, DateTime month) {
    print(
        "DATASOURCE: Searching for event matching '$propertyName' in month ${month.year}-${month.month}");
    print("DATASOURCE: Total events fetched for month: ${events.length}");

    // --- CRUCIAL & POTENTIALLY FRAGILE LOGIC ---
    // How do we reliably find the correct event?
    // Assumptions:
    // 1. Event title contains the property name (e.g., "🏠 House A Rent").
    // 2. Event occurs within the specified month. (retrieveEvents already filtered by month range).

    String searchTerm = propertyName; // Basic search term
    // Maybe prefix with your emoji? Be consistent!
    // String searchTerm = "🏠 $propertyName";

    for (final event in events) {
      print(
          "DATASOURCE: Checking event: ${event.title} (Start: ${event.start}, End: ${event.end})");
      // Check if title contains the property name (case-insensitive)
      if (event.title != null &&
          event.title!.toLowerCase().contains(searchTerm.toLowerCase())) {
        // Additional check: Ensure the event actually falls within the target month
        // (RetrieveEvents should handle this, but double-checking might be wise depending on recurrence)
        // bool isInMonth = (event.start != null && event.start!.year == month.year && event.start!.month == month.month) ||
        //                  (event.end != null && event.end!.year == month.year && event.end!.month == month.month);
        // if (isInMonth) { // <-- Add this condition if needed
        print("DATASOURCE: Found potential match: ${event.title}");
        return event;
        // }
      }
    }
    print("DATASOURCE: No matching event found for '$propertyName'.");
    return null; // No matching event found
  }

  @override
  Future<PaymentStatus> getEventPaymentStatus({
    required String
        propertyId, // Not directly used for searching calendar, name is used
    required String propertyName,
    required DateTime month,
  }) async {
    print(
        "DATASOURCE: getEventPaymentStatus called for $propertyName / $month");
    if (!await _requestPermissions())
      return PaymentStatus.unknown; // Or throw an error

    final calendarId = await _findWritableCalendarId();
    if (calendarId == null) return PaymentStatus.unknown; // Or throw

    // Define the date range for the month
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(
        month.year, month.month + 1, 0, 23, 59, 59); // Last moment of the month

    try {
      final eventsResult = await _plugin.retrieveEvents(
        calendarId,
        RetrieveEventsParams(startDate: startOfMonth, endDate: endOfMonth),
      );

      if (!eventsResult.isSuccess || eventsResult.data == null) {
        print("DATASOURCE: Error retrieving events for $month.");
        return PaymentStatus.unknown;
      }

      final matchingEvent =
          _findMatchingEvent(eventsResult.data!, propertyName, month);

      if (matchingEvent == null) {
        return PaymentStatus
            .pending; // Assuming if no event found, it's pending
      }

      // Check for the paid marker (e.g., "✅" in the title)
      // This is also fragile - depends on exact format!
      if (matchingEvent.title != null && matchingEvent.title!.contains("✅")) {
        print("DATASOURCE: Event for $propertyName is marked as PAID.");
        return PaymentStatus.paid;
      } else {
        print(
            "DATASOURCE: Event for $propertyName is PENDING (found but not marked paid).");
        return PaymentStatus.pending;
      }
    } catch (e) {
      print("DATASOURCE: Exception retrieving/parsing events: $e");
      return PaymentStatus.unknown; // Error state
    }
  }

  @override
  Future<void> updateEventToPaid({
    required String propertyId, // Not used directly
    required String propertyName,
    required DateTime month,
  }) async {
    print("DATASOURCE: updateEventToPaid called for $propertyName / $month");
    if (!await _requestPermissions()) return; // Or throw

    final calendarId = await _findWritableCalendarId();
    if (calendarId == null) return; // Or throw

    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    try {
      final eventsResult = await _plugin.retrieveEvents(
        calendarId,
        RetrieveEventsParams(startDate: startOfMonth, endDate: endOfMonth),
      );

      if (!eventsResult.isSuccess || eventsResult.data == null) {
        print("DATASOURCE: Error retrieving events before update.");
        return; // Or throw
      }

      final eventToUpdate =
          _findMatchingEvent(eventsResult.data!, propertyName, month);

      if (eventToUpdate == null) {
        print(
            "DATASOURCE: Cannot update - event not found for $propertyName / $month.");
        return; // Or maybe create it? For now, just return.
      }

      // Check if already marked paid
      if (eventToUpdate.title != null && eventToUpdate.title!.contains("✅")) {
        print("DATASOURCE: Event already marked paid. No update needed.");
        return;
      }

      // --- Create the updated event ---
      // Prepend the checkmark. Be careful not to exceed title length limits.
      String updatedTitle =
          "✅ ${eventToUpdate.title ?? propertyName}"; // Add checkmark

      // Create a new Event object based on the old one
      final updatedEvent = Event(
        calendarId, // Must match the calendar it came from
        eventId: eventToUpdate
            .eventId, // MUST provide the original event ID to update
        title: updatedTitle,
        description: eventToUpdate.description,
        start: eventToUpdate.start,
        end: eventToUpdate.end,
        allDay: eventToUpdate.allDay,
        // Copy other relevant fields if necessary (location, attendees, recurrenceRule etc.)
      );
      final updateResult = await _plugin.createOrUpdateEvent(updatedEvent);

      if (updateResult != null) {
        // <-- Check if the result object itself is null
        if (updateResult.isSuccess) {
          // <-- Now safe to access isSuccess
          print(
              "DATASOURCE: Successfully updated event for $propertyName to paid. Event ID: ${updateResult.data}"); // Result.data often contains the event ID
        } else {
          // Operation failed, log errors from the Result object
          print("DATASOURCE: Error updating event: ${updateResult.errors}");
          // Handle error appropriately (e.g., throw custom exception, return failure status)
        }
      } else {
        // The call to createOrUpdateEvent itself failed to return a Result object
        print(
            "DATASOURCE: Failed to get a result from createOrUpdateEvent (plugin returned null).");
        // Handle this severe error case appropriately
      }
    } catch (e) {
      print("DATASOURCE: Exception during event update: $e");
      // Handle error appropriately
    }
  }
}
