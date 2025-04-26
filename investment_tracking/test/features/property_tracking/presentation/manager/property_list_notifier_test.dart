import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:clock/clock.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:investment_tracking/features/property_tracking/presentation/manager/property_list_notifier.dart';
import 'package:investment_tracking/features/property_tracking/domain/usecases/get_current_month_rental_events.dart';
import 'package:investment_tracking/features/property_tracking/domain/usecases/mark_event_as_paid.dart';
import 'package:investment_tracking/features/property_tracking/domain/entities/rental_event.dart';
import 'package:investment_tracking/features/property_tracking/domain/entities/payment_status.dart';

@GenerateMocks([GetCurrentMonthRentalEvents, MarkEventAsPaid])
import 'property_list_notifier_test.mocks.dart';

void main() {
  tz_data.initializeTimeZones();
  final location = tz.local;

  late MockGetCurrentMonthRentalEvents mockGetEventsUseCase;
  late MockMarkEventAsPaid mockMarkEventUseCase;
  late PropertyListNotifier notifier;

  final fixedTime = DateTime(2025, 4, 15);
  final testEvent1 = RentalEvent(
      eventId: 'ev1',
      calendarId: 'cal1',
      title: '🏠 Prop A',
      propertyName: 'Prop A',
      start: tz.TZDateTime.from(
          fixedTime.add(const Duration(days: -10)), location),
      end: null,
      status: PaymentStatus.pending);
  final testEvent2 = RentalEvent(
      eventId: 'ev2',
      calendarId: 'cal1',
      title: '✅ 🏠 Prop B',
      propertyName: 'Prop B',
      start:
          tz.TZDateTime.from(fixedTime.add(const Duration(days: -5)), location),
      end: null,
      status: PaymentStatus.paid);
  final List<RentalEvent> testEventList = [testEvent1, testEvent2];

  setUp(() {
    mockGetEventsUseCase = MockGetCurrentMonthRentalEvents();
    mockMarkEventUseCase = MockMarkEventAsPaid();

    when(mockGetEventsUseCase.call()).thenAnswer((_) async => testEventList);

    notifier = PropertyListNotifier(
      getCurrentMonthRentalEventsUseCase: mockGetEventsUseCase,
      markEventAsPaidUseCase: mockMarkEventUseCase,
    );
  });

  group('PropertyListNotifier Tests', () {
    test('initial state should call fetchEvents and load initial events',
        () async {
      verify(mockGetEventsUseCase.call()).called(1);
      await Future.delayed(Duration.zero);
      expect(notifier.isLoading, false);
      expect(notifier.rentalEvents, equals(testEventList));
      expect(notifier.error, null);
    });

    group('fetchEvents', () {
      final List<RentalEvent> anotherEventList = [testEvent1];

      test('should update state correctly on successful fetch', () async {
        when(mockGetEventsUseCase.call())
            .thenAnswer((_) async => anotherEventList);

        final future = notifier.fetchEvents();

        expect(notifier.isLoading, true);
        expect(notifier.error, null);

        await future;

        expect(notifier.isLoading, false);
        expect(notifier.rentalEvents, equals(anotherEventList));
        expect(notifier.error, null);
        verify(mockGetEventsUseCase.call()).called(2);
      });

      test('should update state correctly on failed fetch', () async {
        final fetchException = Exception('Fetch Failed');
        when(mockGetEventsUseCase.call()).thenThrow(fetchException);

        final future = notifier.fetchEvents();

        await future;

        expect(notifier.isLoading, false);
        expect(notifier.rentalEvents, isEmpty);
        expect(notifier.error, contains('Fetch Failed'));
        verify(mockGetEventsUseCase.call()).called(2);
      });
    });

    group('markEventPaid', () {
      final eventToMark = testEvent1;

      test('should call MarkEventAsPaid use case and refresh list on success',
          () async {
        when(mockMarkEventUseCase.call(eventToMark)).thenAnswer((_) async {});
        when(mockGetEventsUseCase.call())
            .thenAnswer((_) async => testEventList);

        await notifier.markEventPaid(eventToMark);

        verify(mockMarkEventUseCase.call(eventToMark)).called(1);
        verify(mockGetEventsUseCase.call()).called(2);
        expect(notifier.isLoading, false);
        expect(notifier.rentalEvents, equals(testEventList));
        expect(notifier.error, null);
      });

      test('should set error state and not refresh list on mark failure',
          () async {
        final updateException = Exception('Update Failed');
        when(mockMarkEventUseCase.call(eventToMark)).thenThrow(updateException);
        await Future.delayed(Duration.zero);
        expect(notifier.rentalEvents, testEventList);

        await notifier.markEventPaid(eventToMark);

        verify(mockMarkEventUseCase.call(eventToMark)).called(1);
        verify(mockGetEventsUseCase.call()).called(1);
        expect(notifier.isLoading, false);
        expect(notifier.rentalEvents, equals(testEventList));
        expect(notifier.error,
            contains("Failed to mark '${eventToMark.propertyName}' as paid"));
      });

      test('should not call use case if event is already paid', () async {
        final alreadyPaidEvent = testEvent2;
        expect(alreadyPaidEvent.status, PaymentStatus.paid);

        await notifier.markEventPaid(alreadyPaidEvent);

        verifyNever(mockMarkEventUseCase.call(any));
        verify(mockGetEventsUseCase.call()).called(1);
        expect(notifier.isLoading, false);
        expect(notifier.rentalEvents, equals(testEventList));
        expect(notifier.error, null);
      });
    });
  });
}
