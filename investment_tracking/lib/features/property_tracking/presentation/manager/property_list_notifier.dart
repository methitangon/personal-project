import 'package:flutter/foundation.dart';
import 'package:investment_tracking/features/property_tracking/domain/entities/property.dart';
import '../../domain/entities/payment_status.dart';
import '../../domain/usecases/get_properties_with_status.dart';
import '../../domain/usecases/mark_rent_as_paid.dart';

class PropertyListNotifier extends ChangeNotifier {
  final GetPropertiesWithStatus getPropertiesUseCase;
  final MarkRentAsPaid markRentAsPaidUseCase;

  PropertyListNotifier({
    required this.getPropertiesUseCase,
    required this.markRentAsPaidUseCase,
  }) {
    // Fetch properties immediately when the notifier is created
    fetchProperties();
  }

  // Private state variables
  bool _isLoading = false;
  List<PropertyStatusInfo> _properties = [];
  String? _error;

  // Public getters for the UI to access the state
  bool get isLoading => _isLoading;
  List<PropertyStatusInfo> get properties => _properties;
  String? get error => _error;

  // Helper to get the current month (can be made more flexible later)
  DateTime get _currentMonth {
    final now = DateTime.now();
    // We only care about year and month for comparison/fetching
    return DateTime(now.year, now.month);
  }

  // Method to fetch properties and their status
  Future<void> fetchProperties() async {
    print("NOTIFIER: Fetching properties for month: $_currentMonth");
    _isLoading = true;
    _error = null;
    // Notify listeners immediately that loading has started and error is cleared
    notifyListeners();

    try {
      // Call the use case injected via constructor (resolved by get_it)
      _properties = await getPropertiesUseCase.call(_currentMonth);
      print(
          "NOTIFIER: Properties fetched successfully: ${_properties.length} items");
    } catch (e) {
      print("NOTIFIER: Error fetching properties: $e");
      _error = "Failed to load properties: $e";
      _properties = []; // Clear properties on error
    } finally {
      _isLoading = false;
      // Notify listeners that loading is complete (with new data or error)
      notifyListeners();
    }
  }

  // Method to mark a property's rent as paid
  Future<void> markPropertyAsPaid(String propertyId) async {
    print(
        "NOTIFIER: Attempting to mark $propertyId as paid for month: $_currentMonth");
    // Optional: You could add a specific loading state for the item being marked
    // _setLoadingStateForItem(propertyId, true);
    _error = null; // Clear previous errors potentially? Or display alongside?

    // Optimistic update (optional): Update UI immediately assuming success
    // final previousState = _properties;
    // _updateLocalStatus(propertyId, PaymentStatus.paid);
    // notifyListeners();

    try {
      // Call the use case
      await markRentAsPaidUseCase.call(
        MarkRentAsPaidParams(propertyId: propertyId, month: _currentMonth),
      );
      print(
          "NOTIFIER: Mark as paid successful for $propertyId. Refetching list...");

      // Refresh the entire list to show the updated status from the source
      // Alternatively, if successful, you could just keep the optimistic update
      await fetchProperties(); // Simplest way to ensure data consistency
    } catch (e) {
      print("NOTIFIER: Error marking property $propertyId as paid: $e");
      _error =
          "Failed to mark ${properties.firstWhere((p) => p.property.id == propertyId, orElse: () => PropertyStatusInfo(property: Property(id: propertyId, name: propertyId), status: PaymentStatus.unknown)).property.name} as paid: $e"; // Provide specific error
      // Optional: Revert optimistic update if you used one
      // _properties = previousState;
      notifyListeners(); // Notify UI about the error
    } finally {
      // Optional: Clear specific loading state for the item
      // _setLoadingStateForItem(propertyId, false);
    }
  }

  // --- Helper methods for optimistic updates (Optional) ---
  /*
  void _updateLocalStatus(String propertyId, PaymentStatus status) {
     _properties = _properties.map((info) {
        if (info.property.id == propertyId) {
           // Create a new instance with updated status
           return PropertyStatusInfo(property: info.property, status: status);
        }
        return info;
     }).toList();
  }
  */
}
