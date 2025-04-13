// lib/features/property_tracking/domain/entities/property.dart
class Property {
  final String id; // Unique identifier (e.g., "house_a")
  final String name; // e.g., "House A"

  Property({required this.id, required this.name});

  // Optional: Add Equatable later for easier comparison if needed
  // @override List<Object?> get props => [id, name];
}
