import 'package:flutter/foundation.dart';
import 'package:investment_tracking/features/property_tracking/domain/entities/property.dart';
import '../../domain/entities/payment_status.dart';

import '../../domain/usecases/mark_event_as_paid.dart';

class PropertyListNotifier extends ChangeNotifier {
  final GetPropertiesWithStatus getPropertiesUseCase;
  final MarkEventAsPaid markEventAsPaidUseCase;

  PropertyListNotifier({
    required this.getPropertiesUseCase,
    required this.markEventAsPaidUseCase,
  }) {
    fetchProperties();
  }

  bool _isLoading = false;
  List<PropertyStatusInfo> _properties = [];
  String? _error;

  bool get isLoading => _isLoading;
  List<PropertyStatusInfo> get properties => _properties;
  String? get error => _error;

  DateTime get _currentMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  // Method to fetch properties and their status
  Future<void> fetchProperties() async {
    print("NOTIFIER: Fetching properties for month: $_currentMonth");
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _properties = await getPropertiesUseCase.call(_currentMonth);
      print(
          "NOTIFIER: Properties fetched successfully: ${_properties.length} items");
    } catch (e) {
      print("NOTIFIER: Error fetching properties: $e");
      _error = "Failed to load properties: $e";
      _properties = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markPropertyAsPaid(String propertyId) async {
    print(
        "NOTIFIER: Attempting to mark $propertyId as paid for month: $_currentMonth");
    _error = null;

    try {
      await markEventAsPaidUseCase.call(
        MarkEventAsPaidParams(propertyId: propertyId, month: _currentMonth),
      );
      print(
          "NOTIFIER: Mark as paid successful for $propertyId. Refetching list...");
      await fetchProperties();
    } catch (e) {
      print("NOTIFIER: Error marking property $propertyId as paid: $e");
      _error =
          "Failed to mark ${properties.firstWhere((p) => p.property.id == propertyId, orElse: () => PropertyStatusInfo(property: Property(id: propertyId, name: propertyId), status: PaymentStatus.unknown)).property.name} as paid: $e"; // Provide specific error
      notifyListeners();
    }
  }
}
