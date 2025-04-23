import 'package:device_calendar/device_calendar.dart';

import '../../domain/entities/property.dart';
import '../../domain/entities/rental_event.dart';
import '../../domain/entities/payment_status.dart';
import '../../domain/repositories/property_repository.dart';
import '../datasources/calendar_data_source.dart';
import '../datasources/calendar_data_source_impl.dart';

class PropertyRepositoryImpl implements PropertyRepository {
  final CalendarDataSource calendarDataSource;

  PropertyRepositoryImpl({required this.calendarDataSource});

  @override
  Future<List<Property>> getProperties() async {
    print("REPOSITORY: Returning hardcoded properties");
    await Future.delayed(const Duration(milliseconds: 50));
    return [
      Property(id: 'house_a', name: 'House A'),
      Property(id: 'house_b', name: 'House B'),
      Property(id: 'house_c', name: 'House C'),
      Property(id: 'alpha_condo', name: 'Alpha Condo'),
      Property(id: 'beta_house', name: 'Beta House'),
    ];
  }

  @override
  Future<List<RentalEvent>> getRentalEventsForMonth(
      {required DateTime month}) async {
    print("REPOSITORY: getRentalEventsForMonth called for $month");
    final List<Event> rawEvents =
        await calendarDataSource.getRawRentalEvents(month: month);
    print(
        "REPOSITORY: Received ${rawEvents.length} raw events from data source.");

    final List<RentalEvent> rentalEvents = [];
    const String paidPrefix =
        PAID_EMOJI + EMOJI_SEPARATOR + HOUSE_EMOJI + EMOJI_SEPARATOR;
    const String pendingPrefix = HOUSE_EMOJI + EMOJI_SEPARATOR;

    for (final rawEvent in rawEvents) {
      if (rawEvent.eventId == null ||
          rawEvent.calendarId == null ||
          rawEvent.title == null) {
        print("REPOSITORY: Skipping raw event due to missing ID or title.");
        continue;
      }

      String title = rawEvent.title!.trim();
      PaymentStatus status = PaymentStatus.unknown;
      String propertyName = "Unknown";

      if (title.startsWith(paidPrefix)) {
        status = PaymentStatus.paid;
        propertyName = title.substring(paidPrefix.length).trim();
      } else if (title.startsWith(pendingPrefix)) {
        status = PaymentStatus.pending;
        propertyName = title.substring(pendingPrefix.length).trim();
      } else {
        print(
            "REPOSITORY: Skipping event with unexpected title format: $title");
        continue;
      }

      if (propertyName.isEmpty) {
        print(
            "REPOSITORY: Skipping event with empty property name after stripping prefixes: $title");
        continue;
      }

      rentalEvents.add(RentalEvent(
        eventId: rawEvent.eventId!,
        calendarId: rawEvent.calendarId!,
        title: rawEvent.title!,
        propertyName: propertyName,
        start: rawEvent.start,
        end: rawEvent.end,
        status: status,
      ));
    }
    print("REPOSITORY: Mapped to ${rentalEvents.length} RentalEvent objects.");
    return rentalEvents;
  }

  @override
  Future<void> markEventAsPaid({
    required String eventId,
    required String calendarId,
    required String currentTitle,
    required TZDateTime? start,
    required TZDateTime? end,
  }) async {
    print("REPOSITORY: markEventAsPaid called for eventId $eventId");
    await calendarDataSource.updateEventToPaid(
      eventId: eventId,
      calendarId: calendarId,
      currentTitle: currentTitle,
      start: start,
      end: end,
    );
    print(
        "REPOSITORY: Call to dataSource.updateEventToPaid completed for $eventId");
  }
}
