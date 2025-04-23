// test/features/property_tracking/domain/usecases/mark_event_as_paid_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:investment_tracking/features/property_tracking/domain/entities/rental_event.dart';
import 'package:investment_tracking/features/property_tracking/domain/entities/payment_status.dart';
import 'package:investment_tracking/features/property_tracking/domain/repositories/property_repository.dart';
import 'package:investment_tracking/features/property_tracking/domain/usecases/mark_event_as_paid.dart';

@GenerateMocks([PropertyRepository])
import 'get_current_month_rental_events_test.mocks.dart';

void main() {
  late MockPropertyRepository mockPropertyRepository;
  late MarkEventAsPaid usecase;

  setUp(() {
    mockPropertyRepository = MockPropertyRepository();
    usecase = MarkEventAsPaid(mockPropertyRepository);
  });

  final testEvent = RentalEvent(
    eventId: 'ev1',
    calendarId: 'cal1',
    title: '🏠 Pending Event',
    propertyName: 'Pending Event',
    start: DateTime(2025, 4, 5),
    end: DateTime(2025, 4, 6),
    status: PaymentStatus.pending,
  );

  final testException = Exception('Failed to update repository');

  test(
      'should call markEventAsPaid on the repository with correct event details',
      () async {
    when(mockPropertyRepository.markEventAsPaid(
      eventId: anyNamed('eventId'),
      calendarId: anyNamed('calendarId'),
      currentTitle: anyNamed('currentTitle'),
      start: anyNamed('start'),
      end: anyNamed('end'),
    )).thenAnswer((_) async {});

    await usecase.call(testEvent);

    verify(mockPropertyRepository.markEventAsPaid(
      eventId: testEvent.eventId,
      calendarId: testEvent.calendarId,
      currentTitle: testEvent.title,
      start: testEvent.start,
      end: testEvent.end,
    )).called(1);

    verifyNoMoreInteractions(mockPropertyRepository);
  });

  test('should throw exception when repository call fails', () async {
    when(mockPropertyRepository.markEventAsPaid(
      eventId: anyNamed('eventId'),
      calendarId: anyNamed('calendarId'),
      currentTitle: anyNamed('currentTitle'),
      start: anyNamed('start'),
      end: anyNamed('end'),
    )).thenThrow(testException);

    final call = usecase.call;

    await expectLater(() => call(testEvent), throwsA(isA<Exception>()));

    verify(mockPropertyRepository.markEventAsPaid(
      eventId: testEvent.eventId,
      calendarId: testEvent.calendarId,
      currentTitle: testEvent.title,
      start: testEvent.start,
      end: testEvent.end,
    )).called(1);
    verifyNoMoreInteractions(mockPropertyRepository);
  });
}
