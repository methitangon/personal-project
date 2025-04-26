import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:investment_tracking/features/property_tracking/data/datasources/calendar_data_source.dart';
import 'package:investment_tracking/features/property_tracking/data/repositories/property_repository_impl.dart';
import 'package:investment_tracking/features/property_tracking/domain/entities/rental_event.dart';
import 'package:investment_tracking/features/property_tracking/domain/entities/payment_status.dart';

import 'property_repository_impl_test.mocks.dart';

@GenerateMocks([CalendarDataSource])
void main() {
  tz_data.initializeTimeZones();
  final tz.Location testLocation = tz.local;

  late MockCalendarDataSource mockCalendarDataSource;
  late PropertyRepositoryImpl repositoryImpl;

  final testMonth = DateTime(2025, 4);

  setUp(() {
    mockCalendarDataSource = MockCalendarDataSource();
    repositoryImpl =
        PropertyRepositoryImpl(calendarDataSource: mockCalendarDataSource);
  });

  final rawEvent1 = Event('cal1',
      eventId: 'ev1',
      title: '🏠 Alpha Condo',
      start: tz.TZDateTime.from(DateTime(2025, 4, 5), testLocation),
      end: tz.TZDateTime.from(DateTime(2025, 4, 5), testLocation));
  final rawEvent2 = Event('cal1',
      eventId: 'ev2',
      title: '✅ 🏠 Beta House',
      start: tz.TZDateTime.from(DateTime(2025, 4, 10), testLocation),
      end: tz.TZDateTime.from(DateTime(2025, 4, 10), testLocation));
  final rawEvent3Irrelevant = Event('cal1',
      eventId: 'ev3',
      title: 'Dentist Appointment',
      start: tz.TZDateTime.from(DateTime(2025, 4, 12), testLocation));
  final rawEvent4WrongEmoji = Event('cal1',
      eventId: 'ev4',
      title: '💰 Pay Rent Gamma',
      start: tz.TZDateTime.from(DateTime(2025, 4, 1), testLocation));

  final List<Event> rawEventListFromDataSource = [
    rawEvent1,
    rawEvent2,
    rawEvent3Irrelevant,
    rawEvent4WrongEmoji
  ];

  final expectedMappedEvent1 = RentalEvent(
      eventId: 'ev1',
      calendarId: 'cal1',
      title: '🏠 Alpha Condo',
      propertyName: 'Alpha Condo',
      start: tz.TZDateTime.from(DateTime(2025, 4, 5), testLocation),
      end: tz.TZDateTime.from(DateTime(2025, 4, 5), testLocation),
      status: PaymentStatus.pending);
  final expectedMappedEvent2 = RentalEvent(
      eventId: 'ev2',
      calendarId: 'cal1',
      title: '✅ 🏠 Beta House',
      propertyName: 'Beta House',
      start: tz.TZDateTime.from(DateTime(2025, 4, 10), testLocation),
      end: tz.TZDateTime.from(DateTime(2025, 4, 10), testLocation),
      status: PaymentStatus.paid);
  final List<RentalEvent> expectedRentalEvents = [
    expectedMappedEvent1,
    expectedMappedEvent2
  ];

  group('getRentalEventsForMonth', () {
    test('should call data source and map raw events to RentalEvents correctly',
        () async {
      when(mockCalendarDataSource.getRawRentalEvents(month: testMonth))
          .thenAnswer((_) async => rawEventListFromDataSource);

      final result =
          await repositoryImpl.getRentalEventsForMonth(month: testMonth);

      expect(result, equals(expectedRentalEvents));
      verify(mockCalendarDataSource.getRawRentalEvents(month: testMonth))
          .called(1);
      verifyNoMoreInteractions(mockCalendarDataSource);
    });

    test('should return empty list if data source returns empty list',
        () async {
      when(mockCalendarDataSource.getRawRentalEvents(month: testMonth))
          .thenAnswer((_) async => []);
      final result =
          await repositoryImpl.getRentalEventsForMonth(month: testMonth);
      expect(result, isEmpty);
      verify(mockCalendarDataSource.getRawRentalEvents(month: testMonth))
          .called(1);
      verifyNoMoreInteractions(mockCalendarDataSource);
    });

    test('should throw exception if data source throws exception', () async {
      final dataSourceException = Exception('Failed to read calendar');
      when(mockCalendarDataSource.getRawRentalEvents(month: testMonth))
          .thenThrow(dataSourceException);
      final call = repositoryImpl.getRentalEventsForMonth;
      await expectLater(
          () => call(month: testMonth), throwsA(isA<Exception>()));
      verify(mockCalendarDataSource.getRawRentalEvents(month: testMonth))
          .called(1);
      verifyNoMoreInteractions(mockCalendarDataSource);
    });
  });

  group('markEventAsPaid', () {
    const testEventId = 'ev1';
    const testCalendarId = 'cal1';
    const testCurrentTitle = '🏠 Alpha Condo';
    final tz.TZDateTime testStart =
        tz.TZDateTime.from(DateTime(2025, 4, 5), testLocation);
    final tz.TZDateTime testEnd =
        tz.TZDateTime.from(DateTime(2025, 4, 5), testLocation);
    final testException = Exception('Update failed in data source');

    test('should call updateEventToPaid on data source with correct parameters',
        () async {
      when(mockCalendarDataSource.updateEventToPaid(
        eventId: testEventId,
        calendarId: testCalendarId,
        currentTitle: testCurrentTitle,
        start: testStart,
        end: testEnd,
      )).thenAnswer((_) async {});

      await repositoryImpl.markEventAsPaid(
        eventId: testEventId,
        calendarId: testCalendarId,
        currentTitle: testCurrentTitle,
        start: testStart,
        end: testEnd,
      );

      verify(mockCalendarDataSource.updateEventToPaid(
        eventId: testEventId,
        calendarId: testCalendarId,
        currentTitle: testCurrentTitle,
        start: testStart,
        end: testEnd,
      )).called(1);
      verifyNoMoreInteractions(mockCalendarDataSource);
    });

    test('should throw exception if data source throws exception', () async {
      when(mockCalendarDataSource.updateEventToPaid(
        eventId: anyNamed('eventId'),
        calendarId: anyNamed('calendarId'),
        currentTitle: anyNamed('currentTitle'),
        start: anyNamed('start'),
        end: anyNamed('end'),
      )).thenThrow(testException);

      final call = repositoryImpl.markEventAsPaid;

      await expectLater(
          () => call(
                eventId: testEventId,
                calendarId: testCalendarId,
                currentTitle: testCurrentTitle,
                start: testStart,
                end: testEnd,
              ),
          throwsA(isA<Exception>()));

      verify(mockCalendarDataSource.updateEventToPaid(
        eventId: testEventId,
        calendarId: testCalendarId,
        currentTitle: testCurrentTitle,
        start: testStart,
        end: testEnd,
      )).called(1);
      verifyNoMoreInteractions(mockCalendarDataSource);
    });
  });
}
