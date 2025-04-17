// test/features/property_tracking/domain/usecases/get_properties_with_status_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:investment_tracking/features/property_tracking/domain/entities/property.dart';
import 'package:investment_tracking/features/property_tracking/domain/entities/payment_status.dart';
import 'package:investment_tracking/features/property_tracking/domain/repositories/property_repository.dart';
import 'package:investment_tracking/features/property_tracking/domain/usecases/get_properties_with_status.dart';

@GenerateMocks([PropertyRepository])
import 'get_properties_with_status_test.mocks.dart';

void main() {
  late GetPropertiesWithStatus usecase;
  late MockPropertyRepository mockPropertyRepository;

  setUp(() {
    mockPropertyRepository = MockPropertyRepository();
    usecase = GetPropertiesWithStatus(mockPropertyRepository);
  });

  final month = DateTime(2025, 4);
  final properties = [
    Property(id: 'house_a', name: 'House A'),
    Property(id: 'house_b', name: 'House B'),
  ];

  final expectedResult = [
    PropertyStatusInfo(property: properties[0], status: PaymentStatus.paid),
    PropertyStatusInfo(property: properties[1], status: PaymentStatus.pending),
  ];

  test(
      'should get properties from repository and their status for the given month',
      () async {
    when(mockPropertyRepository.getProperties())
        .thenAnswer((_) async => properties);

    when(mockPropertyRepository.getPaymentStatus(
            propertyId: 'house_a', month: month))
        .thenAnswer((_) async => PaymentStatus.paid);

    when(mockPropertyRepository.getPaymentStatus(
            propertyId: 'house_b', month: month))
        .thenAnswer((_) async => PaymentStatus.pending);

    final result = await usecase.call(month);

    expect(result.length, expectedResult.length);
    expect(result[0].property, expectedResult[0].property);
    expect(result[0].status, expectedResult[0].status);
    expect(result[1].property, expectedResult[1].property);
    expect(result[1].status, expectedResult[1].status);

    verify(mockPropertyRepository.getProperties()).called(1);
    verify(mockPropertyRepository.getPaymentStatus(
            propertyId: 'house_a', month: month))
        .called(1);
    verify(mockPropertyRepository.getPaymentStatus(
            propertyId: 'house_b', month: month))
        .called(1);

    verifyNoMoreInteractions(mockPropertyRepository);
  });
}
