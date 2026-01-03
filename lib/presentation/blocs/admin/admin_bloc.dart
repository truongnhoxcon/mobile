/// Admin BLoC
/// 
/// Handles admin-related state management for user/account management.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/user.dart';
import '../../../data/datasources/user_datasource.dart';

part 'admin_event.dart';
part 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final UserDataSource _userDataSource;

  AdminBloc({UserDataSource? userDataSource})
      : _userDataSource = userDataSource ?? UserDataSourceImpl(),
        super(const AdminState()) {
    on<AdminLoadUsers>(_onLoadUsers);
    on<AdminUpdateUserRole>(_onUpdateUserRole);
    on<AdminToggleUserActive>(_onToggleUserActive);
    on<AdminResetUserPassword>(_onResetUserPassword);
    on<AdminDeleteUser>(_onDeleteUser);
  }

  Future<void> _onLoadUsers(
    AdminLoadUsers event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(
      isLoading: true,
      searchQuery: event.searchQuery,
      roleFilter: event.roleFilter,
    ));

    try {
      final users = await _userDataSource.getAllUsersForAdmin();
      emit(state.copyWith(
        users: users.map((m) => m.toEntity()).toList(),
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Lỗi khi tải danh sách người dùng: $e',
      ));
    }
  }

  Future<void> _onUpdateUserRole(
    AdminUpdateUserRole event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      final newRole = UserRoleExtension.fromString(event.newRole);
      await _userDataSource.updateUserRole(event.userId, newRole);
      
      // Refresh user list
      final users = await _userDataSource.getAllUsersForAdmin();
      emit(state.copyWith(
        users: users.map((m) => m.toEntity()).toList(),
        isLoading: false,
        successMessage: 'Đã cập nhật quyền người dùng thành công',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Lỗi khi cập nhật quyền: $e',
      ));
    }
  }

  Future<void> _onToggleUserActive(
    AdminToggleUserActive event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      await _userDataSource.toggleUserActive(event.userId, event.isActive);
      
      // Refresh user list
      final users = await _userDataSource.getAllUsersForAdmin();
      emit(state.copyWith(
        users: users.map((m) => m.toEntity()).toList(),
        isLoading: false,
        successMessage: event.isActive 
            ? 'Đã kích hoạt tài khoản' 
            : 'Đã vô hiệu hóa tài khoản',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Lỗi khi cập nhật trạng thái: $e',
      ));
    }
  }

  Future<void> _onResetUserPassword(
    AdminResetUserPassword event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      // Note: Password reset requires Firebase Admin SDK on server-side
      // For now, we'll just show a message indicating this limitation
      emit(state.copyWith(
        isLoading: false,
        successMessage: 'Tính năng đặt lại mật khẩu cần được thực hiện qua Firebase Console',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Lỗi khi đặt lại mật khẩu: $e',
      ));
    }
  }

  Future<void> _onDeleteUser(
    AdminDeleteUser event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      await _userDataSource.deleteUser(event.userId);
      
      // Refresh user list
      final users = await _userDataSource.getAllUsersForAdmin();
      emit(state.copyWith(
        users: users.map((m) => m.toEntity()).toList(),
        isLoading: false,
        successMessage: 'Đã xóa tài khoản thành công',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Lỗi khi xóa tài khoản: $e',
      ));
    }
  }
}
