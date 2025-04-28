import 'package:device_calendar/device_calendar.dart';
import '../../domain/entities/rental_event.dart';
import '../../domain/entities/payment_status.dart';
import '../../domain/repositories/property_repository.dart';
import '../datasources/calendar_data_source.dart';
import '../datasources/calendar_data_source_impl.dart';

class PropertyRepositoryImpl implements PropertyRepository {
  final CalendarDataSource calendarDataSource;

  PropertyRepositoryImpl({required this.calendarDataSource});

  @override
  Future<List<RentalEvent>> getRentalEventsForMonth(
      {required DateTime month}) async {
    final List<Event> rawEvents =
        await calendarDataSource.getRawRentalEvents(month: month);

    final List<RentalEvent> rentalEvents = [];
    const String paidPrefix =
        PAID_EMOJI + EMOJI_SEPARATOR + HOUSE_EMOJI + EMOJI_SEPARATOR;
    const String pendingPrefix = HOUSE_EMOJI + EMOJI_SEPARATOR;

    for (final rawEvent in rawEvents) {
      if (rawEvent.eventId == null ||
          rawEvent.calendarId == null ||
          rawEvent.title == null) {
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
        continue;
      }

      if (propertyName.isEmpty) {
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
    await calendarDataSource.updateEventToPaid(
      eventId: eventId,
      calendarId: calendarId,
      currentTitle: currentTitle,
      start: start,
      end: end,
    );
  }
}
