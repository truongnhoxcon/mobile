/// Account Management Screen
/// 
/// Admin screen for managing user accounts.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/user.dart';
import '../../blocs/admin/admin_bloc.dart';

class AccountManagementScreen extends StatelessWidget {
  const AccountManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminBloc()..add(const AdminLoadUsers()),
      child: const _AccountManagementContent(),
    );
  }
}

class _AccountManagementContent extends StatefulWidget {
  const _AccountManagementContent();

  @override
  State<_AccountManagementContent> createState() => _AccountManagementContentState();
}

class _AccountManagementContentState extends State<_AccountManagementContent> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedRoleFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý tài khoản'),
      ),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: AppColors.error,
              ),
            );
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Search and filter bar
              _SearchFilterBar(
                searchController: _searchController,
                selectedRole: _selectedRoleFilter,
                onSearchChanged: (query) {
                  context.read<AdminBloc>().add(AdminLoadUsers(
                    searchQuery: query,
                    roleFilter: _selectedRoleFilter,
                  ));
                },
                onRoleFilterChanged: (role) {
                  setState(() => _selectedRoleFilter = role);
                  context.read<AdminBloc>().add(AdminLoadUsers(
                    searchQuery: _searchController.text,
                    roleFilter: role,
                  ));
                },
              ),
              
              // User list
              Expanded(
                child: state.isLoading && state.users.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _UserList(users: state.filteredUsers),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SearchFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String? selectedRole;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onRoleFilterChanged;

  const _SearchFilterBar({
    required this.searchController,
    required this.selectedRole,
    required this.onSearchChanged,
    required this.onRoleFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo email hoặc tên...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 12),
          
          // Role filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tất cả',
                  isSelected: selectedRole == null,
                  onTap: () => onRoleFilterChanged(null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Admin',
                  isSelected: selectedRole == 'ADMIN',
                  color: AppColors.warning,
                  onTap: () => onRoleFilterChanged('ADMIN'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'HR Manager',
                  isSelected: selectedRole == 'HR_MANAGER',
                  color: AppColors.info,
                  onTap: () => onRoleFilterChanged('HR_MANAGER'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'PM',
                  isSelected: selectedRole == 'PROJECT_MANAGER',
                  color: AppColors.secondary,
                  onTap: () => onRoleFilterChanged('PROJECT_MANAGER'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Nhân viên',
                  isSelected: selectedRole == 'EMPLOYEE',
                  color: AppColors.textSecondary,
                  onTap: () => onRoleFilterChanged('EMPLOYEE'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : chipColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: chipColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : chipColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final List<User> users;

  const _UserList({required this.users});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy người dùng',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<AdminBloc>().add(const AdminLoadUsers());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return _UserCard(user: user);
        },
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final User user;

  const _UserCard({required this.user});

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppColors.warning;
      case UserRole.hrManager:
        return AppColors.info;
      case UserRole.projectManager:
        return AppColors.secondary;
      case UserRole.employee:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor(user.role);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: user.isActive ? Colors.transparent : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: roleColor.withOpacity(0.2),
              backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
              child: user.photoUrl == null
                  ? Text(
                      (user.displayName ?? user.email)[0].toUpperCase(),
                      style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.displayName ?? 'Chưa đặt tên',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (!user.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Đã vô hiệu hóa',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.role.displayName,
                      style: TextStyle(
                        color: roleColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Actions menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => _handleAction(context, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit_role',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Đổi quyền'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_active',
                  child: Row(
                    children: [
                      Icon(
                        user.isActive ? Icons.block : Icons.check_circle,
                        size: 20,
                        color: user.isActive ? AppColors.error : AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Text(user.isActive ? 'Vô hiệu hóa' : 'Kích hoạt'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reset_password',
                  child: Row(
                    children: [
                      Icon(Icons.lock_reset, size: 20),
                      SizedBox(width: 8),
                      Text('Đặt lại mật khẩu'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'edit_role':
        _showEditRoleDialog(context);
        break;
      case 'toggle_active':
        context.read<AdminBloc>().add(AdminToggleUserActive(
          userId: user.id,
          isActive: !user.isActive,
        ));
        break;
      case 'reset_password':
        _showResetPasswordDialog(context);
        break;
    }
  }

  void _showEditRoleDialog(BuildContext context) {
    String? selectedRole = user.role.value;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đổi quyền người dùng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Email: ${user.email}'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(
                labelText: 'Quyền',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'ADMIN', child: Text('Quản trị viên')),
                DropdownMenuItem(value: 'HR_MANAGER', child: Text('HR Manager')),
                DropdownMenuItem(value: 'PROJECT_MANAGER', child: Text('Project Manager')),
                DropdownMenuItem(value: 'EMPLOYEE', child: Text('Nhân viên')),
              ],
              onChanged: (value) => selectedRole = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedRole != null && selectedRole != user.role.value) {
                context.read<AdminBloc>().add(AdminUpdateUserRole(
                  userId: user.id,
                  newRole: selectedRole!,
                ));
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đặt lại mật khẩu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber, size: 48, color: AppColors.warning),
            const SizedBox(height: 16),
            Text('Đặt lại mật khẩu cho:\n${user.email}'),
            const SizedBox(height: 8),
            const Text(
              'Mật khẩu mới: Employee@123',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            onPressed: () {
              context.read<AdminBloc>().add(AdminResetUserPassword(
                userId: user.id,
              ));
              Navigator.pop(dialogContext);
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}
