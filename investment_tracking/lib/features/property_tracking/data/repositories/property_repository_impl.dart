// lib/features/property_tracking/data/repositories/property_repository_impl.dart

import '../../domain/entities/property.dart';
import '../../domain/entities/payment_status.dart';
import '../../domain/repositories/property_repository.dart';
import '../datasources/calendar_data_source.dart';

class PropertyRepositoryImpl implements PropertyRepository {
  final CalendarDataSource calendarDataSource;

  PropertyRepositoryImpl({required this.calendarDataSource});

  // Keep getProperties hardcoded for now, or implement differently if needed
  @override
  Future<List<Property>> getProperties() async {
    print("REPOSITORY: Returning hardcoded properties");
    await Future.delayed(const Duration(milliseconds: 100));
    return [
      Property(id: 'house_a', name: 'House A'),
      Property(id: 'house_b', name: 'House B'),
      Property(id: 'house_c', name: 'House C'),
    ];
  }

  @override
  Future<PaymentStatus> getPaymentStatus({
    required String propertyId,
    required DateTime month,
  }) async {
    print(
        "REPOSITORY: Calling DataSource getEventPaymentStatus for $propertyId / $month");
    // We need the property name. For now, let's derive it simply from the ID.
    // In a real app, you might fetch the property details first.
    final properties =
        await getProperties(); // Inefficient, ideally get name differently
    final property = properties.firstWhere((p) => p.id == propertyId,
        orElse: () => Property(id: propertyId, name: "Unknown Property"));

    return await calendarDataSource.getEventPaymentStatus(
      propertyId: propertyId,
      propertyName: property.name, // Pass the name
      month: month,
    );
  }

  @override
  Future<void> markRentAsPaid({
    required String propertyId,
    required DateTime month,
  }) async {
    print(
        "REPOSITORY: Calling DataSource updateEventToPaid for $propertyId / $month");
    // Again, derive property name simply for now.
    final properties = await getProperties(); // Inefficient
    final property = properties.firstWhere((p) => p.id == propertyId,
        orElse: () => Property(id: propertyId, name: "Unknown Property"));

    await calendarDataSource.updateEventToPaid(
      propertyId: propertyId,
      propertyName: property.name, // Pass the name
      month: month,
    );
  }
}
