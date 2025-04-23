import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:device_calendar/device_calendar.dart';

import 'package:investment_tracking/features/property_tracking/data/datasources/calendar_data_source.dart'; // Interface
import 'package:investment_tracking/features/property_tracking/data/repositories/property_repository_impl.dart'; // Implementation
import 'package:investment_tracking/features/property_tracking/domain/entities/rental_event.dart'; // Domain Entity
import 'package:investment_tracking/features/property_tracking/domain/entities/payment_status.dart'; // Domain Entity

@GenerateMocks([CalendarDataSource])
void main() {
  late MockCalendarDataSource mockCalendarDataSource;
  late PropertyRepositoryImpl repositoryImpl;

  final testMonth = DateTime(2025, 4);
  setUp(() {
    mockCalendarDataSource = MockCalendarDataSource();
    repositoryImpl =
        PropertyRepositoryImpl(calendarDataSource: mockCalendarDataSource);
  });
  final local = getLocation('local');
  final rawEvent1 = Event('cal1',
      eventId: 'ev1',
      title: '🏠 Alpha Condo',
      start: TZDateTime.from(DateTime(2025, 4, 5), local),
      end: TZDateTime.from(DateTime(2025, 4, 5), local));
  final rawEvent2 = Event('cal1',
      eventId: 'ev2',
      title: '✅ 🏠 Beta House',
      start: TZDateTime.from(DateTime(2025, 4, 10), local),
      end: TZDateTime.from(DateTime(2025, 4, 10), local));
  final rawEvent3Irrelevant = Event('cal1',
      eventId: 'ev3',
      title: 'Dentist Appointment',
      start: TZDateTime.from(DateTime(2025, 4, 12), local));
  final rawEvent4WrongEmoji = Event('cal1',
      eventId: 'ev4',
      title: '💰 Pay Rent Gamma',
      start: TZDateTime.from(DateTime(2025, 4, 1), local));

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
      start: DateTime(2025, 4, 5),
      end: DateTime(2025, 4, 5),
      status: PaymentStatus.pending);
  final expectedMappedEvent2 = RentalEvent(
      eventId: 'ev2',
      calendarId: 'cal1',
      title: '✅ 🏠 Beta House',
      propertyName: 'Beta House',
      start: DateTime(2025, 4, 10),
      end: DateTime(2025, 4, 10),
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

      // Act
      final result =
          await repositoryImpl.getRentalEventsForMonth(month: testMonth);

      // Assert
      expect(result, isEmpty);
      verify(mockCalendarDataSource.getRawRentalEvents(month: testMonth))
          .called(1);
      verifyNoMoreInteractions(mockCalendarDataSource);
    });

    test('should throw exception if data source throws exception', () async {
      // Arrange: Stub the data source method to throw an error
      final dataSourceException = Exception('Failed to read calendar');
      when(mockCalendarDataSource.getRawRentalEvents(month: testMonth))
          .thenThrow(dataSourceException);

      // Act
      final call = repositoryImpl.getRentalEventsForMonth;

      await expectLater(
          () => call(month: testMonth), throwsA(isA<Exception>()));
      verify(mockCalendarDataSource.getRawRentalEvents(month: testMonth))
          .called(1);
      verifyNoMoreInteractions(mockCalendarDataSource);
    });
  });
}
