import 'package:clock/clock.dart';
import '../entities/rental_event.dart';
import '../repositories/property_repository.dart';

class GetCurrentMonthRentalEvents {
  final PropertyRepository repository;

  GetCurrentMonthRentalEvents(this.repository);

  Future<List<RentalEvent>> call() async {
    final now = clock.now();
    final currentMonth = DateTime(now.year, now.month);

    return await repository.getRentalEventsForMonth(month: currentMonth);
  }
}
