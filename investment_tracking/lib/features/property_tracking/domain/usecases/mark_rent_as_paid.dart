import '../repositories/property_repository.dart';

// Helper class for parameters to keep the call clean
class MarkRentAsPaidParams {
  final String propertyId;
  final DateTime month;

  MarkRentAsPaidParams({required this.propertyId, required this.month});
}

class MarkRentAsPaid {
  // This use case also depends on the PropertyRepository contract
  final PropertyRepository repository;

  MarkRentAsPaid(this.repository);

  // The 'call' method makes the class callable like a function
  Future<void> call(MarkRentAsPaidParams params) async {
    await repository.markRentAsPaid(
      propertyId: params.propertyId,
      month: params.month,
    );
  }
}
