/// User Repository Interface
/// 
/// Defines the contract for user data operations.

import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class UserRepository {
  /// Get user by ID
  Future<Either<Failure, User>> getUserById(String userId);

  /// Get all users
  Future<Either<Failure, List<User>>> getAllUsers();

  /// Get users by role
  Future<Either<Failure, List<User>>> getUsersByRole(UserRole role);

  /// Create user profile in Firestore
  Future<Either<Failure, User>> createUserProfile(User user);

  /// Update user profile
  Future<Either<Failure, User>> updateUserProfile(User user);

  /// Update user role (admin only)
  Future<Either<Failure, void>> updateUserRole(String userId, UserRole role);

  /// Search users by name or email
  Future<Either<Failure, List<User>>> searchUsers(String query);

  /// Stream of user changes
  Stream<User?> userStream(String userId);
}
