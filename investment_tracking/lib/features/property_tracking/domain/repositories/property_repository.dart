// lib/features/property_tracking/domain/repositories/property_repository.dart
import '../entities/property.dart';
import '../entities/payment_status.dart';

abstract class PropertyRepository {
  /// Fetches the list of properties to track.
  Future<List<Property>> getProperties();

  /// Gets the payment status for a specific property for a given month.
  /// [month] should represent the month being queried (e.g., DateTime(2025, 4) for April 2025).
  Future<PaymentStatus> getPaymentStatus({
    required String propertyId,
    required DateTime month,
  });

  /// Marks the rent for a specific property as paid for the given month.
  Future<void> markRentAsPaid({
    required String propertyId,
    required DateTime month,
  });

  // Add other methods here later if needed
}
