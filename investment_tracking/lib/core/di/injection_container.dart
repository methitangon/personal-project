import 'package:get_it/get_it.dart';

// Create a global instance of GetIt. We often call it 'sl' (Service Locator).
final sl = GetIt.instance;

// This function will be used to register all the dependencies.
// It's async in case some setup needs async work later.
Future<void> init() async {
  // --- Register Core components ---
  // Example: sl.registerLazySingleton(() => MyHttpClient());

  // --- Register Features ---

  // Feature: Property Tracking
  // Register Data sources, Repositories, Use cases, State Notifiers etc. here later
  // Example:
  // sl.registerLazySingleton<PropertyRepository>(() => PropertyRepositoryImpl(dataSource: sl()));
  // sl.registerLazySingleton<CalendarDataSource>(() => CalendarDataSourceImpl(deviceCalendarPlugin: sl()));
  // sl.registerFactory(() => GetPropertiesUseCase(repository: sl())); // Factory if needs fresh instance

  print('Dependency Injection Initialized'); // Optional: for confirmation
}
