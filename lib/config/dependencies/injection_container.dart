/// Dependency Injection Container
/// 
/// Initializes and registers all dependencies using get_it.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../presentation/blocs/blocs.dart';

final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> init() async {
  //===========================================================================
  // External Dependencies
  //===========================================================================
  
  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  
  // Firebase
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => GoogleSignIn());

  //===========================================================================
  // Data Sources
  //===========================================================================
  
  sl.registerLazySingleton<AuthDataSource>(
    () => AuthDataSourceImpl(
      firebaseAuth: sl(),
      firestore: sl(),
      googleSignIn: sl(),
    ),
  );

  //===========================================================================
  // Repositories
  //===========================================================================
  
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(dataSource: sl()),
  );

  //===========================================================================
  // BLoCs
  //===========================================================================
  
  sl.registerFactory(() => AuthBloc(authRepository: sl()));
}
