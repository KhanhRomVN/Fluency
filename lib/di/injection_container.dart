import 'package:fluency/core/services/activity/activity_repository.dart';
import 'package:fluency/core/services/activity/activity_repository_impl.dart';
import 'package:fluency/core/services/usage/app_usage_service.dart';
import 'package:fluency/core/services/usage/daily_usage_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Repository
  sl.registerLazySingleton<ActivityRepository>(
    () => ActivityRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => DailyUsageRepository(sl()));

  // Services
  sl.registerLazySingleton(() => AppUsageService(sl()));

  // Logic needed for core services (e.g. NavigationService) can be registered here
}
