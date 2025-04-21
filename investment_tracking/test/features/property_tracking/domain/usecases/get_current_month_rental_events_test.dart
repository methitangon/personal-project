import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:clock/clock.dart';

import 'package:investment_tracking/features/property_tracking/domain/entities/rental_event.dart';
import 'package:investment_tracking/features/property_tracking/domain/entities/payment_status.dart';
import 'package:investment_tracking/features/property_tracking/domain/repositories/property_repository.dart';
import 'package:investment_tracking/features/property_tracking/domain/usecases/get_current_month_rental_events.dart';

@GenerateMocks([PropertyRepository])
import 'get_properties_with_status_test.mocks.dart';

void main() {
  final fixedTime = DateTime(2025, 4, 15, 10, 30, 0);
  final expectedMonth = DateTime(2025, 4);

  withClock(Clock.fixed(fixedTime), () {
    late MockPropertyRepository mockPropertyRepository;
    late GetCurrentMonthRentalEvents usecase;

    setUp(() {
      mockPropertyRepository = MockPropertyRepository();
      usecase = GetCurrentMonthRentalEvents(mockPropertyRepository);
    });

    final rentalEvent1 = RentalEvent(
        eventId: 'ev1',
        calendarId: 'cal1',
        title: '🏠 House A',
        propertyName: 'A',
        start: DateTime(expectedMonth.year, expectedMonth.month, 5),
        end: null,
        status: PaymentStatus.pending);
    final rentalEvent2 = RentalEvent(
        eventId: 'ev2',
        calendarId: 'cal1',
        title: '✅ 🏠 House B',
        propertyName: 'B',
        start: DateTime(expectedMonth.year, expectedMonth.month, 10),
        end: null,
        status: PaymentStatus.paid);

    final List<RentalEvent> eventListWithMultiple = [
      rentalEvent1,
      rentalEvent2
    ];
    final List<RentalEvent> eventListWithOne = [rentalEvent1];
    final List<RentalEvent> eventListEmpty = [];
    final testException = Exception('Failed to fetch from repository');

    test(
        'should get list of rental events for current month (April 2025) from repository',
        () async {
      when(mockPropertyRepository.getRentalEventsForMonth(month: expectedMonth))
          .thenAnswer((_) async => eventListWithMultiple);

      final result = await usecase.call();

      expect(result, equals(eventListWithMultiple));
      verify(mockPropertyRepository.getRentalEventsForMonth(
              month: expectedMonth))
          .called(1);
    });

    test(
        'should get single rental event for current month (April 2025) from repository',
        () async {
      when(mockPropertyRepository.getRentalEventsForMonth(month: expectedMonth))
          .thenAnswer((_) async => eventListWithOne);

      final result = await usecase.call();

      expect(result, equals(eventListWithOne));
      verify(mockPropertyRepository.getRentalEventsForMonth(
              month: expectedMonth))
          .called(1);
    });

    test('should get empty list for current month (April 2025) from repository',
        () async {
      when(mockPropertyRepository.getRentalEventsForMonth(month: expectedMonth))
          .thenAnswer((_) async => eventListEmpty);

      final result = await usecase.call();

      expect(result, equals(eventListEmpty));
      verify(mockPropertyRepository.getRentalEventsForMonth(
              month: expectedMonth))
          .called(1);
    });

    test('should throw exception when repository call fails', () async {
      when(mockPropertyRepository.getRentalEventsForMonth(month: expectedMonth))
          .thenThrow(testException);

      final call = usecase.call;

      await expectLater(() => call(), throwsA(isA<Exception>()));
      verify(mockPropertyRepository.getRentalEventsForMonth(
              month: expectedMonth))
          .called(1);
    });
  });
}
