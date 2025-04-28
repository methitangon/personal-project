import 'package:investment_tracking/features/property_tracking/domain/entities/rental_event.dart';
import 'package:timezone/timezone.dart';

abstract class PropertyRepository {
  Future<List<RentalEvent>> getRentalEventsForMonth({
    required DateTime month,
  });

  Future<void> markEventAsPaid({
    required String eventId,
    required String calendarId,
    required String currentTitle,
    required TZDateTime? start,
    required TZDateTime? end,
  });
}
