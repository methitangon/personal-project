import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:investment_tracking/features/property_tracking/domain/usecases/mark_rent_as_paid.dart';

import 'get_properties_with_status_test.mocks.dart';

void main() {
  late MarkRentAsPaid usecase;
  late MockPropertyRepository mockPropertyRepository;

  setUp(() {
    mockPropertyRepository = MockPropertyRepository();
    usecase = MarkRentAsPaid(mockPropertyRepository);
  });

  const propertyId = 'house_a';
  final month = DateTime(2025, 4);
  final params = MarkRentAsPaidParams(propertyId: propertyId, month: month);

  test('should call markRentAsPaid on the repository with correct parameters',
      () async {
    when(mockPropertyRepository.markRentAsPaid(
            propertyId: propertyId, month: month))
        .thenAnswer((_) async {});

    await usecase.call(params);

    verify(mockPropertyRepository.markRentAsPaid(
      propertyId: propertyId,
      month: month,
    )).called(1);

    verifyNoMoreInteractions(mockPropertyRepository);
  });

  test('should throw exception if repository call fails', () async {
    when(mockPropertyRepository.markRentAsPaid(
            propertyId: propertyId, month: month))
        .thenThrow(Exception('Failed to update calendar'));

    final call = usecase.call;

    expect(() => call(params), throwsA(isA<Exception>()));

    verify(mockPropertyRepository.markRentAsPaid(
            propertyId: propertyId, month: month))
        .called(1);
    verifyNoMoreInteractions(mockPropertyRepository);
  });
}
