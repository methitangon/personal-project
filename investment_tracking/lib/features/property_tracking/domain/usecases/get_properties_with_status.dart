import '../entities/property.dart';
import '../entities/payment_status.dart';
import '../repositories/property_repository.dart';

// Helper class to hold combined Property and Status info
class PropertyStatusInfo {
  final Property property;
  final PaymentStatus status;

  PropertyStatusInfo({required this.property, required this.status});
}

class GetPropertiesWithStatus {
  // This use case depends on the PropertyRepository contract
  final PropertyRepository repository;

  GetPropertiesWithStatus(this.repository);

  // The 'call' method makes the class callable like a function
  // Takes the target month as input
  Future<List<PropertyStatusInfo>> call(DateTime month) async {
    // 1. Get the list of all properties
    final properties = await repository.getProperties();

    // 2. For each property, get its payment status for the given month
    final List<PropertyStatusInfo> results = [];
    for (final property in properties) {
      final status = await repository.getPaymentStatus(
        propertyId: property.id,
        month: month,
      );
      results.add(PropertyStatusInfo(property: property, status: status));
    }

    // 3. Return the combined list
    return results;
  }
}
