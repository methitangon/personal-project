// lib/features/property_tracking/domain/usecases/mark_event_as_paid.dart

import '../entities/rental_event.dart';
import '../repositories/property_repository.dart';

class MarkEventAsPaid {
  final PropertyRepository repository;

  MarkEventAsPaid(this.repository);

  Future<void> call(RentalEvent event) async {
    throw UnimplementedError('MarkEventAsPaid call() not implemented yet');
  }
}
