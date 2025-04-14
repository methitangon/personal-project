// lib/core/di/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:device_calendar/device_calendar.dart'; // <-- Import device_calendar
import 'package:investment_tracking/features/property_tracking/data/datasources/calendar_data_source.dart'; // <-- Import DS Interface
import 'package:investment_tracking/features/property_tracking/data/datasources/calendar_data_source_impl.dart'; // <-- Import DS Impl
import 'package:investment_tracking/features/property_tracking/data/repositories/property_repository_impl.dart';
import 'package:investment_tracking/features/property_tracking/domain/repositories/property_repository.dart';
import 'package:investment_tracking/features/property_tracking/domain/usecases/get_properties_with_status.dart';
import 'package:investment_tracking/features/property_tracking/domain/usecases/mark_rent_as_paid.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // --- Register Core components ---
  // Register the DeviceCalendarPlugin instance
  sl.registerLazySingleton(() => DeviceCalendarPlugin());

  sl.registerFactory(() => GetPropertiesWithStatus(sl()));
  sl.registerFactory(() => MarkRentAsPaid(sl()));

  // Repository
  sl.registerLazySingleton<PropertyRepository>(
    () => PropertyRepositoryImpl(
        calendarDataSource: sl()), // <-- Inject data source
  );

  // Data Sources
  sl.registerLazySingleton<CalendarDataSource>(
    () => CalendarDataSourceImpl(plugin: sl()), // <-- Inject plugin
  );

  print('Dependency Injection Initialized with Calendar Logic');
}
