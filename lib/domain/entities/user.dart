/// User Entity
/// 
/// Domain entity representing a user in the system.

import 'package:equatable/equatable.dart';

/// User roles in the system (2 roles only)
enum UserRole {
  admin,
  employee,
}

/// Extension to convert UserRole to/from string
extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.employee:
        return 'EMPLOYEE';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Quản trị viên';
      case UserRole.employee:
        return 'Nhân viên';
    }
  }

  static UserRole fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'EMPLOYEE':
      default:
        return UserRole.employee;
    }
  }
}

/// User entity
class User extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final UserRole role;
  final String? departmentId;
  final String? position;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.role = UserRole.employee,
    this.departmentId,
    this.position,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  /// Check if user is admin
  bool get isAdmin => role == UserRole.admin;

  /// Creates a copy of the user with updated fields
  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    UserRole? role,
    String? departmentId,
    String? position,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      departmentId: departmentId ?? this.departmentId,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        photoUrl,
        phoneNumber,
        role,
        departmentId,
        position,
        createdAt,
        updatedAt,
        isActive,
      ];
}
