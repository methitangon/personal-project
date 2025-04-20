import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:investment_tracking/features/property_tracking/domain/entities/payment_status.dart';
import 'package:investment_tracking/features/property_tracking/domain/entities/property.dart';
import 'package:investment_tracking/features/property_tracking/domain/usecases/get_properties_with_status.dart';
import 'package:investment_tracking/features/property_tracking/domain/usecases/mark_rent_as_paid.dart';
import 'package:investment_tracking/features/property_tracking/presentation/manager/property_list_notifier.dart';

import 'property_list_notifier_test.mocks.dart';

@GenerateMocks([GetPropertiesWithStatus, MarkRentAsPaid])
void main() {
  late MockGetPropertiesWithStatus mockGetPropertiesUseCase;
  late MockMarkRentAsPaid mockMarkRentAsPaidUseCase;
  late PropertyListNotifier notifier;

  final now = DateTime.now();
  final currentMonth = DateTime(now.year, now.month);

  final propertiesList = [
    Property(id: 'house_a', name: 'House A'),
    Property(id: 'house_b', name: 'House B'),
  ];

  final propertiesStatusInfoList = [
    PropertyStatusInfo(
        property: propertiesList[0], status: PaymentStatus.pending),
    PropertyStatusInfo(property: propertiesList[1], status: PaymentStatus.paid),
  ];

  setUp(() {
    mockGetPropertiesUseCase = MockGetPropertiesWithStatus();
    mockMarkRentAsPaidUseCase = MockMarkRentAsPaid();

    when(mockGetPropertiesUseCase.call(currentMonth))
        .thenAnswer((_) async => propertiesStatusInfoList);

    notifier = PropertyListNotifier(
      getPropertiesUseCase: mockGetPropertiesUseCase,
      markRentAsPaidUseCase: mockMarkRentAsPaidUseCase,
    );
  });

  group('PropertyListNotifier Tests', () {
    test('initial state should have properties loaded and call fetchProperties',
        () async {
      verify(mockGetPropertiesUseCase.call(currentMonth)).called(1);
      await Future.delayed(Duration.zero);
      expect(notifier.isLoading, false);
      expect(notifier.properties, propertiesStatusInfoList);
      expect(notifier.error, null);
    });

    group('fetchProperties', () {
      test('should update state correctly on successful fetch', () async {
        when(mockGetPropertiesUseCase.call(currentMonth))
            .thenAnswer((_) async => propertiesStatusInfoList);

        final future = notifier.fetchProperties();
        expect(notifier.error, null);

        await future;

        expect(notifier.isLoading, false);
        expect(notifier.properties, propertiesStatusInfoList);
        expect(notifier.error, null);
        verify(mockGetPropertiesUseCase.call(currentMonth)).called(2);
      });

      test('should update state correctly on failed fetch', () async {
        final exception = Exception('Fetch Failed');
        when(mockGetPropertiesUseCase.call(currentMonth)).thenThrow(exception);

        final future = notifier.fetchProperties();

        await future;

        expect(notifier.isLoading, false);
        expect(notifier.properties, isEmpty);
        expect(notifier.error, contains('Fetch Failed'));
        verify(mockGetPropertiesUseCase.call(currentMonth)).called(2);
      });
    });

    group('markPropertyAsPaid', () {
      final propertyId = 'house_a';
      final params =
          MarkRentAsPaidParams(propertyId: propertyId, month: currentMonth);

      test('should call use case and refresh list on success', () async {
        when(mockMarkRentAsPaidUseCase.call(any)).thenAnswer((_) async {});
        when(mockGetPropertiesUseCase.call(currentMonth))
            .thenAnswer((_) async => propertiesStatusInfoList);

        await notifier.markPropertyAsPaid(propertyId);

        verify(mockMarkRentAsPaidUseCase.call(argThat(
            predicate<MarkRentAsPaidParams>((params) =>
                params.propertyId == propertyId &&
                params.month == currentMonth)))).called(1);
        verify(mockGetPropertiesUseCase.call(currentMonth)).called(2);
        expect(notifier.isLoading, false);
        expect(notifier.properties, propertiesStatusInfoList);
        expect(notifier.error, null);
      });

      test('should set error state and not refresh list on failure', () async {
        final exception = Exception('Update Failed');
        when(mockMarkRentAsPaidUseCase.call(any)).thenThrow(exception);

        await Future.delayed(Duration.zero);
        expect(notifier.properties, propertiesStatusInfoList);

        await notifier.markPropertyAsPaid(propertyId);

        verify(mockMarkRentAsPaidUseCase.call(any)).called(1);
        verify(mockGetPropertiesUseCase.call(currentMonth)).called(1);
        expect(notifier.isLoading, false);
        expect(notifier.properties, propertiesStatusInfoList);
        expect(notifier.error, contains('Update Failed'));
      });
    });
  });
}
