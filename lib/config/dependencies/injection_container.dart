import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/location_service.dart';
import '../../data/datasources/auth_datasource.dart';
import '../../data/datasources/attendance_datasource.dart';
import '../../data/datasources/project_datasource.dart';
import '../../data/datasources/issue_datasource.dart';
import '../../data/datasources/chat_datasource.dart';
import '../../data/datasources/ai_chat_datasource.dart';
import '../../data/datasources/hr_datasource.dart';
import '../../data/datasources/storage_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/hr_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/hr_repository.dart';
import '../../presentation/blocs/blocs.dart';

final sl = GetIt.instance;

// TODO: Replace with your Groq API key from https://console.groq.com/keys
const String _groqApiKey = 'xxxxx';

Future<void> init() async {
  //===========================================================================
  // External Dependencies
  //===========================================================================
  
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => GoogleSignIn());
  
  // Location Service
  sl.registerLazySingleton(() => LocationService());

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

  sl.registerLazySingleton<AttendanceDataSource>(
    () => AttendanceDataSourceImpl(firestore: sl()),
  );

  sl.registerLazySingleton<ProjectDataSource>(
    () => ProjectDataSourceImpl(firestore: sl()),
  );

  sl.registerLazySingleton<IssueDataSource>(
    () => IssueDataSourceImpl(firestore: sl()),
  );

  sl.registerLazySingleton<ChatDataSource>(
    () => ChatDataSourceImpl(firestore: sl(), storage: sl()),
  );

  sl.registerLazySingleton<AIChatDataSource>(
    () => AIChatDataSourceImpl(apiKey: _groqApiKey, prefs: sl()),
  );

  sl.registerLazySingleton<HRDataSource>(
    () => HRDataSourceImpl(firestore: sl()),
  );

  sl.registerLazySingleton<StorageDataSource>(
    () => StorageDataSourceImpl(firestore: sl(), storage: sl()),
  );

  //===========================================================================
  // Repositories
  //===========================================================================
  
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(dataSource: sl()),
  );

  sl.registerLazySingleton<HRRepository>(
    () => HRRepositoryImpl(dataSource: sl()),
  );

  //===========================================================================
  // BLoCs
  //===========================================================================
  
  sl.registerFactory(() => AuthBloc(authRepository: sl()));
  sl.registerFactory(() => AttendanceBloc(dataSource: sl()));
  sl.registerFactory(() => ProjectBloc(dataSource: sl()));
  sl.registerFactory(() => IssueBloc(dataSource: sl()));
  sl.registerFactory(() => ChatBloc(dataSource: sl()));
  sl.registerFactory(() => AIChatBloc(dataSource: sl()));
  sl.registerFactory(() => HRBloc(repository: sl()));
  sl.registerFactory(() => MyInfoBloc(repository: sl(), authBloc: sl()));
  sl.registerFactory(() => LeaveRequestBloc(repository: sl(), authBloc: sl()));
  sl.registerFactory(() => NotificationBloc());
  sl.registerFactory(() => FilesBloc(dataSource: sl(), authBloc: sl()));
}

