import 'package:flutter/foundation.dart';
import '../../domain/entities/rental_event.dart';
import '../../domain/usecases/get_current_month_rental_events.dart';
import '../../domain/usecases/mark_event_as_paid.dart';
import '../../domain/entities/payment_status.dart';

class PropertyListNotifier extends ChangeNotifier {
  final GetCurrentMonthRentalEvents getCurrentMonthRentalEventsUseCase;
  final MarkEventAsPaid markEventAsPaidUseCase;

  PropertyListNotifier({
    required this.getCurrentMonthRentalEventsUseCase,
    required this.markEventAsPaidUseCase,
  }) {
    fetchEvents();
  }

  bool _isLoading = false;
  List<RentalEvent> _rentalEvents = [];
  String? _error;

  bool get isLoading => _isLoading;
  List<RentalEvent> get rentalEvents => _rentalEvents;
  String? get error => _error;

  Future<void> fetchEvents() async {
    print("NOTIFIER: Fetching rental events...");
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rentalEvents = await getCurrentMonthRentalEventsUseCase.call();
      print(
          "NOTIFIER: Events fetched successfully: ${_rentalEvents.length} items");
    } catch (e) {
      print("NOTIFIER: Error fetching events: $e");
      _error = "Failed to load events: $e";
      _rentalEvents = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markEventPaid(RentalEvent eventToMarkPaid) async {
    print(
        "NOTIFIER: Attempting to mark event ${eventToMarkPaid.eventId} as paid...");
    _error = null;

    if (eventToMarkPaid.status == PaymentStatus.paid) {
      print("NOTIFIER: Event ${eventToMarkPaid.eventId} is already paid.");
      return;
    }

    try {
      await markEventAsPaidUseCase.call(eventToMarkPaid);
      print(
          "NOTIFIER: Mark as paid successful for event ${eventToMarkPaid.eventId}. Refetching list...");

      await fetchEvents();
    } catch (e) {
      print(
          "NOTIFIER: Error marking event ${eventToMarkPaid.eventId} as paid: $e");
      _error = "Failed to mark '${eventToMarkPaid.propertyName}' as paid.";
      notifyListeners();
    } finally {}
  }
}
