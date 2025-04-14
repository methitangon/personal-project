import '../../domain/entities/payment_status.dart';

abstract class CalendarDataSource {
  /// Retrieves the payment status from the calendar event for a property/month.
  Future<PaymentStatus> getEventPaymentStatus({
    required String propertyId,
    required String propertyName, // May need name for searching event title
    required DateTime month,
  });

  /// Updates the calendar event to mark rent as paid for a property/month.
  Future<void> updateEventToPaid({
    required String propertyId,
    required String propertyName,
    required DateTime month,
  });
}
