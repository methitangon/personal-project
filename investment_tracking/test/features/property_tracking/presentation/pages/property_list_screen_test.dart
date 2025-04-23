import 'package:flutter_test/flutter_test.dart';
import 'package:investment_tracking/features/property_tracking/domain/entities/payment_status.dart';
import 'package:investment_tracking/features/property_tracking/domain/entities/property.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:investment_tracking/core/di/injection_container.dart' as di;
import 'package:investment_tracking/features/property_tracking/presentation/pages/property_list_screen.dart';
import 'package:investment_tracking/features/property_tracking/presentation/manager/property_list_notifier.dart';

@GenerateMocks([PropertyListNotifier])
void main() {
  late MockPropertyListNotifier mockNotifier;

  final properties = [
    Property(id: 'p1', name: 'Condo Alpha'),
    Property(id: 'p2', name: 'Townhouse Beta'),
  ];
  final propertiesInfoList = [
    PropertyStatusInfo(property: properties[0], status: PaymentStatus.pending),
    PropertyStatusInfo(property: properties[1], status: PaymentStatus.paid),
  ];

  setUp(() async {
    await di.sl.reset();
    mockNotifier = MockPropertyListNotifier();
    di.sl.registerLazySingleton<PropertyListNotifier>(() => mockNotifier);
  });

  tearDown(() async {
    await di.sl.reset();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: ChangeNotifierProvider<PropertyListNotifier>.value(
        value: mockNotifier,
        child: const PropertyListScreen(),
      ),
    );
  }

  group('PropertyListScreen Widget Tests', () {
    testWidgets('should display loading indicator when loading initially',
        (WidgetTester tester) async {
      when(mockNotifier.isLoading).thenReturn(true);
      when(mockNotifier.properties).thenReturn([]);
      when(mockNotifier.error).thenReturn(null);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('should display error message when error occurs initially',
        (WidgetTester tester) async {
      const errorMessage = 'Failed to connect';
      when(mockNotifier.isLoading).thenReturn(false);
      when(mockNotifier.properties).thenReturn([]);
      when(mockNotifier.error).thenReturn(errorMessage);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.textContaining(errorMessage), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('should display list of properties when data is available',
        (WidgetTester tester) async {
      when(mockNotifier.isLoading).thenReturn(false);
      when(mockNotifier.properties).thenReturn(propertiesInfoList);
      when(mockNotifier.error).thenReturn(null);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('Error:'), findsNothing);
      expect(find.byType(ListView), findsOneWidget);
      // expect(find.byType(PropertyListItem), // This requires PropertyListItem to be defined
      //     findsNWidgets(propertiesInfoList.length));
      expect(find.text(properties[0].name), findsOneWidget);
      expect(find.text(properties[1].name), findsOneWidget);
      expect(
          find.widgetWithIcon(IconButton, Icons.price_check), findsOneWidget);
    });

    testWidgets(
        'should call fetchProperties on notifier when refresh button tapped',
        (WidgetTester tester) async {
      when(mockNotifier.isLoading).thenReturn(false);
      when(mockNotifier.properties).thenReturn([]);
      when(mockNotifier.error).thenReturn(null);
      when(mockNotifier.fetchProperties()).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());
      final refreshButtonFinder = find.byIcon(Icons.refresh);
      expect(refreshButtonFinder, findsOneWidget);
      await tester.tap(refreshButtonFinder);
      await tester.pump();

      verify(mockNotifier.fetchProperties()).called(1);
    });

    testWidgets(
        'should call markPropertyAsPaid on notifier when payment button tapped',
        (WidgetTester tester) async {
      when(mockNotifier.isLoading).thenReturn(false);
      when(mockNotifier.properties).thenReturn(propertiesInfoList);
      when(mockNotifier.error).thenReturn(null);
      when(mockNotifier.markPropertyAsPaid(properties[0].id))
          .thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());
      final paymentButtonFinder = find.descendant(
        of: find.byWidgetPredicate((widget) =>
            widget is ListTile &&
            (widget.title as Text).data == properties[0].name),
        matching: find.byIcon(Icons.price_check),
      );
      expect(paymentButtonFinder, findsOneWidget);
      await tester.tap(paymentButtonFinder);
      await tester.pump();

      verify(mockNotifier.markPropertyAsPaid(properties[0].id)).called(1);
    });
  });
}
