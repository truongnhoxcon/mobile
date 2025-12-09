/// Auth Repository Interface
/// 
/// Defines the contract for authentication operations.

import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  /// Get current user
  Future<Either<Failure, User?>> getCurrentUser();

  /// Sign in with email and password
  Future<Either<Failure, User>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  Future<Either<Failure, User>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  /// Sign in with Google
  Future<Either<Failure, User>> signInWithGoogle();

  /// Sign out
  Future<Either<Failure, void>> signOut();

  /// Reset password
  Future<Either<Failure, void>> resetPassword(String email);

  /// Update user profile
  Future<Either<Failure, User>> updateProfile({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
  });

  /// Stream of auth state changes
  Stream<User?> get authStateChanges;
}
