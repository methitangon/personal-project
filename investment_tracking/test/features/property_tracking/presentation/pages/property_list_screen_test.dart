import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:investment_tracking/features/property_tracking/presentation/pages/property_list_screen.dart';
import 'package:investment_tracking/features/property_tracking/presentation/manager/property_list_notifier.dart';
import 'package:investment_tracking/features/property_tracking/domain/usecases/get_current_month_rental_events.dart';
import 'package:investment_tracking/features/property_tracking/domain/usecases/mark_event_as_paid.dart';
import 'package:investment_tracking/features/property_tracking/domain/entities/rental_event.dart';
import 'package:investment_tracking/features/property_tracking/domain/entities/payment_status.dart';
import 'package:investment_tracking/features/property_tracking/presentation/widgets/property_list_item.dart';

@GenerateMocks(
    [PropertyListNotifier, GetCurrentMonthRentalEvents, MarkEventAsPaid])
import 'property_list_screen_test.mocks.dart';

void main() {
  tz_data.initializeTimeZones();
  final location = tz.local;

  late MockPropertyListNotifier mockNotifier;

  final fixedTime = DateTime(2025, 4, 15);
  final testEventPending = RentalEvent(
      eventId: 'ev1',
      calendarId: 'cal1',
      title: '🏠 Pending Prop',
      propertyName: 'Pending Prop',
      start: tz.TZDateTime.from(
          fixedTime.add(const Duration(days: -10)), location),
      end: null,
      status: PaymentStatus.pending);
  final testEventPaid = RentalEvent(
      eventId: 'ev2',
      calendarId: 'cal1',
      title: '✅ 🏠 Paid Prop',
      propertyName: 'Paid Prop',
      start:
          tz.TZDateTime.from(fixedTime.add(const Duration(days: -5)), location),
      end: null,
      status: PaymentStatus.paid);
  final List<RentalEvent> testEventList = [testEventPending, testEventPaid];

  setUp(() {
    mockNotifier = MockPropertyListNotifier();
    when(mockNotifier.isLoading).thenReturn(false);
    when(mockNotifier.error).thenReturn(null);
    when(mockNotifier.rentalEvents).thenReturn([]);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: ChangeNotifierProvider<PropertyListNotifier>.value(
        value: mockNotifier,
        child: const PropertyListScreen(),
      ),
    );
  }

  group('PropertyListScreen Widget Tests (Updated)', () {
    testWidgets('should display loading indicator when loading initially',
        (WidgetTester tester) async {
      when(mockNotifier.isLoading).thenReturn(true);
      when(mockNotifier.rentalEvents).thenReturn([]);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('should display error message when error occurs initially',
        (WidgetTester tester) async {
      const errorMessage = 'Failed to connect';
      when(mockNotifier.isLoading).thenReturn(false);
      when(mockNotifier.rentalEvents).thenReturn([]);
      when(mockNotifier.error).thenReturn(errorMessage);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.textContaining(errorMessage), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('should display empty message when no events are found',
        (WidgetTester tester) async {
      when(mockNotifier.isLoading).thenReturn(false);
      when(mockNotifier.rentalEvents).thenReturn([]);
      when(mockNotifier.error).thenReturn(null);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.textContaining('No rental events'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('should display list of rental events when data is available',
        (WidgetTester tester) async {
      when(mockNotifier.isLoading).thenReturn(false);
      when(mockNotifier.rentalEvents).thenReturn(testEventList);
      when(mockNotifier.error).thenReturn(null);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('Error:'), findsNothing);
      expect(find.byType(ListView), findsOneWidget);
      expect(
          find.byType(PropertyListItem), findsNWidgets(testEventList.length));
      expect(find.text(testEventPending.title), findsOneWidget);
      expect(find.text(testEventPaid.title), findsOneWidget);
      final pendingItemFinder = find.ancestor(
          of: find.text(testEventPending.title),
          matching: find.byType(PropertyListItem));
      expect(
          find.descendant(
              of: pendingItemFinder, matching: find.byIcon(Icons.price_check)),
          findsOneWidget);

      final paidItemFinder = find.ancestor(
          of: find.text(testEventPaid.title),
          matching: find.byType(PropertyListItem));
      expect(
          find.descendant(
              of: paidItemFinder, matching: find.byIcon(Icons.price_check)),
          findsNothing);
    });

    testWidgets(
        'should call fetchEvents on notifier when refresh button tapped',
        (WidgetTester tester) async {
      when(mockNotifier.isLoading).thenReturn(false);
      when(mockNotifier.rentalEvents).thenReturn([]);
      when(mockNotifier.error).thenReturn(null);
      when(mockNotifier.fetchEvents()).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());
      final refreshButtonFinder = find.byIcon(Icons.refresh);
      expect(refreshButtonFinder, findsOneWidget);
      await tester.tap(refreshButtonFinder);
      await tester.pump();

      verify(mockNotifier.fetchEvents()).called(1);
    });

    testWidgets(
        'should call markEventPaid on notifier when payment button tapped',
        (WidgetTester tester) async {
      when(mockNotifier.isLoading).thenReturn(false);
      when(mockNotifier.rentalEvents).thenReturn(testEventList);
      when(mockNotifier.error).thenReturn(null);
      when(mockNotifier.markEventPaid(testEventPending))
          .thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());
      final pendingItemFinder = find.ancestor(
          of: find.text(testEventPending.title),
          matching: find.byType(PropertyListItem));
      final paymentButtonFinder = find.descendant(
          of: pendingItemFinder, matching: find.byIcon(Icons.price_check));

      expect(paymentButtonFinder, findsOneWidget);
      await tester.tap(paymentButtonFinder);
      await tester.pump();

      verify(mockNotifier.markEventPaid(testEventPending)).called(1);
    });
  });
}
