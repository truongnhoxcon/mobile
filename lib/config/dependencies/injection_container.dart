/// Dependency Injection Container
/// 
/// Initializes and registers all dependencies using get_it.

import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> init() async {
  //===========================================================================
  // External Dependencies
  //===========================================================================
  
  // SharedPreferences for local storage
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  
  // TODO: Register Firebase instances when configured
  // sl.registerLazySingleton(() => FirebaseAuth.instance);
  // sl.registerLazySingleton(() => FirebaseFirestore.instance);
  // sl.registerLazySingleton(() => FirebaseStorage.instance);
  // sl.registerLazySingleton(() => FirebaseMessaging.instance);

  //===========================================================================
  // Data Sources
  //===========================================================================
  
  // TODO: Register data sources
  // sl.registerLazySingleton<AuthDataSource>(
  //   () => AuthDataSourceImpl(firebaseAuth: sl()),
  // );

  //===========================================================================
  // Repositories
  //===========================================================================
  
  // TODO: Register repositories
  // sl.registerLazySingleton<AuthRepository>(
  //   () => AuthRepositoryImpl(authDataSource: sl()),
  // );

  //===========================================================================
  // BLoCs / Cubits
  //===========================================================================
  
  // TODO: Register BLoCs
  // sl.registerFactory(() => AuthBloc(authRepository: sl()));
}
