import 'package:get_it/get_it.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:investment_tracking/features/property_tracking/data/datasources/calendar_data_source.dart';
import 'package:investment_tracking/features/property_tracking/data/datasources/calendar_data_source_impl.dart';
import 'package:investment_tracking/features/property_tracking/data/repositories/property_repository_impl.dart';
import 'package:investment_tracking/features/property_tracking/domain/repositories/property_repository.dart';
import 'package:investment_tracking/features/property_tracking/domain/usecases/get_current_month_rental_events.dart';
import 'package:investment_tracking/features/property_tracking/domain/usecases/mark_event_as_paid.dart';
import 'package:investment_tracking/features/property_tracking/presentation/manager/property_list_notifier.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerFactory(() => GetCurrentMonthRentalEvents(sl()));
  sl.registerFactory(() => MarkEventAsPaid(sl()));

  sl.registerFactory(
    () => PropertyListNotifier(
      getCurrentMonthRentalEventsUseCase: sl(),
      markEventAsPaidUseCase: sl(),
    ),
  );

  sl.registerLazySingleton<PropertyRepository>(
    () => PropertyRepositoryImpl(calendarDataSource: sl()),
  );

  sl.registerLazySingleton<CalendarDataSource>(
    () => CalendarDataSourceImpl(plugin: sl()),
  );
  sl.registerLazySingleton(() => DeviceCalendarPlugin());
}
