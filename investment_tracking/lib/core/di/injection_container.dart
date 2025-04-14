// lib/core/di/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:investment_tracking/features/property_tracking/data/datasources/calendar_data_source.dart';
import 'package:investment_tracking/features/property_tracking/data/datasources/calendar_data_source_impl.dart';
import 'package:investment_tracking/features/property_tracking/data/repositories/property_repository_impl.dart';
import 'package:investment_tracking/features/property_tracking/domain/repositories/property_repository.dart';
import 'package:investment_tracking/features/property_tracking/domain/usecases/get_properties_with_status.dart';
import 'package:investment_tracking/features/property_tracking/domain/usecases/mark_rent_as_paid.dart';
// Import the Notifier
import 'package:investment_tracking/features/property_tracking/presentation/manager/property_list_notifier.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // --- Register Core components ---
  sl.registerLazySingleton(() => DeviceCalendarPlugin());

  // --- Register Features ---

  // Feature: Property Tracking

  // Data Sources
  sl.registerLazySingleton<CalendarDataSource>(
    () => CalendarDataSourceImpl(plugin: sl()),
  );

  // Repository
  sl.registerLazySingleton<PropertyRepository>(
    () => PropertyRepositoryImpl(calendarDataSource: sl()),
  );

  // Use Cases
  sl.registerFactory(() => GetPropertiesWithStatus(sl()));
  sl.registerFactory(() => MarkRentAsPaid(sl()));

  // -- Presentation Layer -- // <-- Add this section/line
  sl.registerFactory(
    // <-- Add this registration
    () => PropertyListNotifier(
      getPropertiesUseCase: sl(), // Let get_it inject the use case
      markRentAsPaidUseCase: sl(), // Let get_it inject the use case
    ),
  );

  print(
      'Dependency Injection Initialized including Presentation'); // Updated message
}
