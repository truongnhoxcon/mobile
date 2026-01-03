part of 'admin_bloc.dart';

class AdminState extends Equatable {
  final List<User> users;
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final String? searchQuery;
  final String? roleFilter;

  const AdminState({
    this.users = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.searchQuery,
    this.roleFilter,
  });

  /// Get users filtered by search and role
  List<User> get filteredUsers {
    var result = users;
    
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      result = result.where((user) {
        return user.email.toLowerCase().contains(query) ||
            (user.displayName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    if (roleFilter != null && roleFilter!.isNotEmpty) {
      result = result.where((user) => user.role.value == roleFilter).toList();
    }
    
    return result;
  }

  /// Get user counts by role
  int get adminCount => users.where((u) => u.role == UserRole.admin).length;
  int get hrManagerCount => users.where((u) => u.role == UserRole.hrManager).length;
  int get pmCount => users.where((u) => u.role == UserRole.projectManager).length;
  int get employeeCount => users.where((u) => u.role == UserRole.employee).length;
  int get activeCount => users.where((u) => u.isActive).length;
  int get inactiveCount => users.where((u) => !u.isActive).length;

  AdminState copyWith({
    List<User>? users,
    bool? isLoading,
    String? error,
    String? successMessage,
    String? searchQuery,
    String? roleFilter,
  }) {
    return AdminState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      roleFilter: roleFilter ?? this.roleFilter,
    );
  }

  @override
  List<Object?> get props => [users, isLoading, error, successMessage, searchQuery, roleFilter];
}
