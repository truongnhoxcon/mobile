import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource _dataSource;

  AuthRepositoryImpl({required AuthDataSource dataSource}) : _dataSource = dataSource;

  @override
  Stream<User?> get authStateChanges => _dataSource.authStateChanges.map((firebaseUser) {
    if (firebaseUser == null) return null;
    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
    );
  });

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final firebaseUser = _dataSource.currentUser;
      if (firebaseUser == null) return const Right(null);
      
      return Right(User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
      ));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await _dataSource.signInWithEmail(email, password);
      return Right(userModel.toEntity());
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final userModel = await _dataSource.signUpWithEmail(email, password, displayName);
      return Right(userModel.toEntity());
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      final userModel = await _dataSource.signInWithGoogle();
      return Right(userModel.toEntity());
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await _dataSource.resetPassword(email);
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword(String newPassword) async {
    try {
      await _dataSource.updatePassword(newPassword);
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
  }) async {
    return Left(ServerFailure(message: 'Use UserRepository for profile updates'));
  }
}
