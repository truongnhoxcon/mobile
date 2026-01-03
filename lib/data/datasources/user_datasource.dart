/// User Data Source
/// 
/// Firebase Firestore operations for users.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';

abstract class UserDataSource {
  /// Get user by ID
  Future<UserModel> getUserById(String userId);

  /// Get all active users
  Future<List<UserModel>> getAllUsers();

  /// Get all users including inactive (for admin)
  Future<List<UserModel>> getAllUsersForAdmin();

  /// Get users by role
  Future<List<UserModel>> getUsersByRole(UserRole role);

  /// Create user profile
  Future<UserModel> createUser(UserModel user);

  /// Update user profile
  Future<UserModel> updateUser(UserModel user);

  /// Update user role
  Future<void> updateUserRole(String userId, UserRole role);

  /// Toggle user active status
  Future<void> toggleUserActive(String userId, bool isActive);

  /// Delete user (soft delete - set isActive to false)
  Future<void> deleteUser(String userId);

  /// Search users
  Future<List<UserModel>> searchUsers(String query);

  /// Stream of user changes
  Stream<UserModel?> userStream(String userId);
}

class UserDataSourceImpl implements UserDataSource {
  final FirebaseFirestore _firestore;

  UserDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef => _firestore.collection('users');

  @override
  Future<UserModel> getUserById(String userId) async {
    final doc = await _usersRef.doc(userId).get();
    if (!doc.exists) {
      throw Exception('User not found');
    }
    return UserModel.fromFirestore(doc);
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _usersRef.where('isActive', isEqualTo: true).get();
    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<UserModel>> getAllUsersForAdmin() async {
    final snapshot = await _usersRef.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<UserModel>> getUsersByRole(UserRole role) async {
    final snapshot = await _usersRef
        .where('role', isEqualTo: role.value)
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  @override
  Future<UserModel> createUser(UserModel user) async {
    await _usersRef.doc(user.id).set(user.toFirestore());
    return user;
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    await _usersRef.doc(user.id).update(user.toFirestore());
    return user;
  }

  @override
  Future<void> updateUserRole(String userId, UserRole role) async {
    await _usersRef.doc(userId).update({
      'role': role.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> toggleUserActive(String userId, bool isActive) async {
    await _usersRef.doc(userId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteUser(String userId) async {
    // Soft delete - just mark as inactive
    await _usersRef.doc(userId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    final lowerQuery = query.toLowerCase();
    final snapshot = await _usersRef.where('isActive', isEqualTo: true).get();
    
    return snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .where((user) =>
            (user.displayName?.toLowerCase().contains(lowerQuery) ?? false) ||
            user.email.toLowerCase().contains(lowerQuery))
        .toList();
  }

  @override
  Stream<UserModel?> userStream(String userId) {
    return _usersRef.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }
}
