/// User Entity
/// 
/// Domain entity representing a user in the system.

import 'package:equatable/equatable.dart';

/// User roles in the system
enum UserRole {
  admin,
  employee,
  hrManager,
  projectManager,
}

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.employee:
        return 'EMPLOYEE';
      case UserRole.hrManager:
        return 'HR_MANAGER';
      case UserRole.projectManager:
        return 'PROJECT_MANAGER';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Quản trị viên';
      case UserRole.employee:
        return 'Nhân viên';
      case UserRole.hrManager:
        return 'HR Manager';
      case UserRole.projectManager:
        return 'Project Manager';
    }
  }

  static UserRole fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'HR_MANAGER':
        return UserRole.hrManager;
      case 'PROJECT_MANAGER':
      case 'MANAGER_PROJECT':
        return UserRole.projectManager;
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

  /// Check if user is HR Manager
  bool get isHRManager => role == UserRole.hrManager;

  /// Check if user is Project Manager
  bool get isProjectManager => role == UserRole.projectManager;

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
