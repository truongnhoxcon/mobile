part of 'admin_bloc.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

/// Load all users
class AdminLoadUsers extends AdminEvent {
  final String? searchQuery;
  final String? roleFilter;

  const AdminLoadUsers({this.searchQuery, this.roleFilter});

  @override
  List<Object?> get props => [searchQuery, roleFilter];
}

/// Update user role
class AdminUpdateUserRole extends AdminEvent {
  final String userId;
  final String newRole;

  const AdminUpdateUserRole({
    required this.userId,
    required this.newRole,
  });

  @override
  List<Object?> get props => [userId, newRole];
}

/// Toggle user active status
class AdminToggleUserActive extends AdminEvent {
  final String userId;
  final bool isActive;

  const AdminToggleUserActive({
    required this.userId,
    required this.isActive,
  });

  @override
  List<Object?> get props => [userId, isActive];
}

/// Reset user password
class AdminResetUserPassword extends AdminEvent {
  final String userId;
  final String newPassword;

  const AdminResetUserPassword({
    required this.userId,
    this.newPassword = 'Employee@123',
  });

  @override
  List<Object?> get props => [userId, newPassword];
}

/// Delete user account
class AdminDeleteUser extends AdminEvent {
  final String userId;

  const AdminDeleteUser({required this.userId});

  @override
  List<Object?> get props => [userId];
}
