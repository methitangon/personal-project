import 'package:investment_tracking/features/property_tracking/domain/entities/rental_event.dart';

import '../entities/property.dart';
import '../entities/payment_status.dart';

abstract class PropertyRepository {
  Future<List<Property>> getProperties();

  Future<List<RentalEvent>> getRentalEventsForMonth({
    required DateTime month,
  });

  Future<PaymentStatus> getPaymentStatus({
    required String propertyId,
    required DateTime month,
  });

  Future<void> markEventAsPaid({
    required String eventId,
    required String calendarId,
    required String currentTitle,
    required DateTime? start,
    required DateTime? end,
  });
}
