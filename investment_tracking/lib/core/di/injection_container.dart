import 'package:get_it/get_it.dart';
import 'package:investment_tracking/features/property_tracking/data/repositories/property_repository_impl.dart'; //<- Import Impl
import 'package:investment_tracking/features/property_tracking/domain/repositories/property_repository.dart'; //<- Import Interface
import 'package:investment_tracking/features/property_tracking/domain/usecases/get_properties_with_status.dart'; //<- Import UseCase 1
import 'package:investment_tracking/features/property_tracking/domain/usecases/mark_rent_as_paid.dart'; //<- Import UseCase 2
// import 'package:investment_tracking/features/property_tracking/data/datasources/calendar_data_source.dart'; //<- Needed later

final sl = GetIt.instance;

Future<void> init() async {
  // --- Register Core components ---
  // e.g., sl.registerLazySingleton(() => http.Client());

  // --- Register Features ---

  // Feature: Property Tracking
  // Use Cases (Factories are often suitable for use cases)
  sl.registerFactory(
      () => GetPropertiesWithStatus(sl())); // Pass repository implementation
  sl.registerFactory(
      () => MarkRentAsPaid(sl())); // Pass repository implementation

  // Repository (Lazy Singleton - create instance only when first needed)
  // Register the Implementation, but provide it when the Interface is requested
  sl.registerLazySingleton<PropertyRepository>(
    () =>
        PropertyRepositoryImpl(), // Pass dependencies here later (e.g., dataSource: sl())
  );

  // Data Sources (Register later)
  // sl.registerLazySingleton<CalendarDataSource>(() => CalendarDataSourceImpl(deviceCalendarPlugin: sl()));
  // sl.registerLazySingleton(() => DeviceCalendarPlugin()); // Register the plugin itself

  print('Dependency Injection Initialized');
}
