import '../../domain/entities/property.dart';
import '../../domain/entities/payment_status.dart';
import '../../domain/repositories/property_repository.dart';
// import '../datasources/calendar_data_source.dart'; // Will need this later

class PropertyRepositoryImpl implements PropertyRepository {
  // final CalendarDataSource calendarDataSource; // Will need this later

  // Constructor - uncomment dataSource later
  // PropertyRepositoryImpl({required this.calendarDataSource});
  PropertyRepositoryImpl(); // Temporary constructor

  @override
  Future<List<Property>> getProperties() async {
    // --- TEMPORARY HARDCODED DATA ---
    print("REPOSITORY: Returning hardcoded properties"); // Log for debugging
    await Future.delayed(
        const Duration(milliseconds: 100)); // Simulate network delay
    return [
      Property(id: 'house_a', name: 'House A'),
      Property(id: 'house_b', name: 'House B'),
      Property(id: 'house_c', name: 'House C'),
    ];
    // --- END TEMPORARY DATA ---

    // LATER: Implement by potentially reading from a local DB or config
    // Or maybe inferring from distinct calendar event titles if designed that way.
  }

  @override
  Future<PaymentStatus> getPaymentStatus({
    required String propertyId,
    required DateTime month,
  }) async {
    // --- TEMPORARY HARDCODED DATA ---
    print(
        "REPOSITORY: Returning hardcoded PENDING status for $propertyId / $month"); // Log
    await Future.delayed(const Duration(milliseconds: 50)); // Simulate delay
    // For testing, maybe return 'paid' for House B?
    // if (propertyId == 'house_b') return PaymentStatus.paid;
    return PaymentStatus.pending;
    // --- END TEMPORARY DATA ---

    // LATER: Implement by calling calendarDataSource.getEventPaymentStatus(...)
    // Need to pass propertyName too, might need to fetch it based on id if not passed in.
  }

  @override
  Future<void> markRentAsPaid({
    required String propertyId,
    required DateTime month,
  }) async {
    // --- TEMPORARY NO-OP ---
    print(
        "REPOSITORY: Simulating marking $propertyId / $month as paid (doing nothing yet)"); // Log
    await Future.delayed(const Duration(milliseconds: 200)); // Simulate delay
    // --- END TEMPORARY NO-OP ---

    // LATER: Implement by calling calendarDataSource.updateEventToPaid(...)
    // Need to pass propertyName too.
  }
}
