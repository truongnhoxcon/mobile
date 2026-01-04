/// Admin Home Screen
/// 
/// Premium admin screen with account management functionality.
/// Designed to be consistent with HR and PM home screens.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/user.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/admin/admin_bloc.dart';
import '../profile/profile_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminBloc()..add(const AdminLoadUsers()),
      child: Scaffold(
        appBar: _currentIndex == 1 ? null : _buildAppBar(),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Quản trị hệ thống',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, size: 24.w),
          onPressed: () => context.read<AdminBloc>().add(const AdminLoadUsers()),
        ),
        SizedBox(width: 8.w),
      ],
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const _AccountManagementTab();
      case 1:
        return const ProfileScreen();
      default:
        return const _AccountManagementTab();
    }
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.manage_accounts_rounded),
          label: 'Quản lý TK',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Hồ sơ',
        ),
      ],
    );
  }
}

/// Account Management Tab - Main admin functionality
class _AccountManagementTab extends StatefulWidget {
  const _AccountManagementTab();

  @override
  State<_AccountManagementTab> createState() => _AccountManagementTabState();
}

class _AccountManagementTabState extends State<_AccountManagementTab> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedRoleFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!), backgroundColor: AppColors.error),
          );
        }
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage!), backgroundColor: AppColors.success),
          );
        }
      },
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            context.read<AdminBloc>().add(const AdminLoadUsers());
          },
          child: CustomScrollView(
            slivers: [
              // Welcome Header with Gradient
              SliverToBoxAdapter(
                child: _buildWelcomeHeader(context, state),
              ),
              
              // Statistics Row
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _buildStatisticsRow(state),
                ),
              ),
              
              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: _buildSearchBar(context),
                ),
              ),
              
              // Filter Chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _buildFilterChips(context),
                ),
              ),
              
              SliverToBoxAdapter(child: SizedBox(height: 12.h)),
              
              // User List
              state.isLoading && state.users.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : state.filteredUsers.isEmpty
                      ? SliverFillRemaining(child: _buildEmptyState())
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final user = state.filteredUsers[index];
                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                                child: _UserCard(user: user),
                              );
                            },
                            childCount: state.filteredUsers.length,
                          ),
                        ),
              
              SliverToBoxAdapter(child: SizedBox(height: 100.h)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, AdminState state) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 32.w,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quản lý tài khoản',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${state.users.length} người dùng • ${state.activeCount} hoạt động',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsRow(AdminState state) {
    return SizedBox(
      height: 100.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _StatCard(icon: Icons.shield, label: 'Admin', value: '${state.adminCount}', color: AppColors.warning),
          _StatCard(icon: Icons.people_alt, label: 'HR', value: '${state.hrManagerCount}', color: AppColors.info),
          _StatCard(icon: Icons.folder_shared, label: 'PM', value: '${state.pmCount}', color: AppColors.secondary),
          _StatCard(icon: Icons.person, label: 'Nhân viên', value: '${state.employeeCount}', color: AppColors.textSecondary),
          _StatCard(icon: Icons.block, label: 'Đã khóa', value: '${state.inactiveCount}', color: AppColors.error),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm người dùng...',
          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppColors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    context.read<AdminBloc>().add(AdminLoadUsers(roleFilter: _selectedRoleFilter));
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        ),
        onChanged: (query) {
          context.read<AdminBloc>().add(AdminLoadUsers(
            searchQuery: query,
            roleFilter: _selectedRoleFilter,
          ));
        },
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(label: 'Tất cả', isSelected: _selectedRoleFilter == null, onTap: () => _setFilter(null)),
          _FilterChip(label: 'Admin', isSelected: _selectedRoleFilter == 'ADMIN', color: AppColors.warning, onTap: () => _setFilter('ADMIN')),
          _FilterChip(label: 'HR Manager', isSelected: _selectedRoleFilter == 'HR_MANAGER', color: AppColors.info, onTap: () => _setFilter('HR_MANAGER')),
          _FilterChip(label: 'PM', isSelected: _selectedRoleFilter == 'PROJECT_MANAGER', color: AppColors.secondary, onTap: () => _setFilter('PROJECT_MANAGER')),
          _FilterChip(label: 'Nhân viên', isSelected: _selectedRoleFilter == 'EMPLOYEE', color: AppColors.textSecondary, onTap: () => _setFilter('EMPLOYEE')),
        ],
      ),
    );
  }

  void _setFilter(String? role) {
    setState(() => _selectedRoleFilter = role);
    context.read<AdminBloc>().add(AdminLoadUsers(
      searchQuery: _searchController.text,
      roleFilter: role,
    ));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 80.w, color: AppColors.textSecondary.withOpacity(0.5)),
          SizedBox(height: 16.h),
          Text(
            'Không tìm thấy người dùng',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm',
            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 85.w,
      margin: EdgeInsets.only(right: 10.w),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20.w),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: color)),
            ),
          ),
          Text(label, style: TextStyle(fontSize: 9.sp, color: color), overflow: TextOverflow.ellipsis, maxLines: 1),
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

  const _FilterChip({required this.label, required this.isSelected, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected ? chipColor : chipColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: chipColor.withOpacity(isSelected ? 1 : 0.3)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : chipColor,
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
            ),
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final User user;

  const _UserCard({required this.user});

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin: return AppColors.warning;
      case UserRole.hrManager: return AppColors.info;
      case UserRole.projectManager: return AppColors.secondary;
      case UserRole.employee: return AppColors.textSecondary;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin: return Icons.shield;
      case UserRole.hrManager: return Icons.people_alt;
      case UserRole.projectManager: return Icons.folder_shared;
      case UserRole.employee: return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor(user.role);
    final roleIcon = _getRoleIcon(user.role);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: user.isActive ? AppColors.border : AppColors.error.withOpacity(0.3),
          width: user.isActive ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () => _showUserDetails(context),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // Avatar with role icon
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28.r,
                      backgroundColor: roleColor.withOpacity(0.15),
                      child: Text(
                        (user.displayName ?? user.email)[0].toUpperCase(),
                        style: TextStyle(
                          color: roleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20.sp,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: roleColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(roleIcon, size: 12.w, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 14.w),
                
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
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!user.isActive)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock, size: 12.w, color: AppColors.error),
                                  SizedBox(width: 4.w),
                                  Text('Đã khóa', style: TextStyle(color: AppColors.error, fontSize: 11.sp, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        user.email,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          user.role.displayName,
                          style: TextStyle(color: roleColor, fontSize: 12.sp, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Action menu
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  onSelected: (value) => _handleAction(context, value),
                  itemBuilder: (context) => [
                    _buildMenuItem(Icons.edit, 'Đổi quyền', 'edit_role'),
                    _buildMenuItem(
                      user.isActive ? Icons.lock : Icons.lock_open,
                      user.isActive ? 'Khóa tài khoản' : 'Mở khóa',
                      'toggle_active',
                      color: user.isActive ? AppColors.error : AppColors.success,
                    ),
                    _buildMenuItem(Icons.lock_reset, 'Đặt lại MK', 'reset_password', color: AppColors.warning),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(IconData icon, String text, String value, {Color? color}) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20.w, color: color ?? AppColors.textPrimary),
          SizedBox(width: 12.w),
          Text(text, style: TextStyle(fontSize: 14.sp)),
        ],
      ),
    );
  }

  void _showUserDetails(BuildContext context) {
    // Could show a detailed user view here
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'edit_role':
        _showEditRoleDialog(context);
        break;
      case 'toggle_active':
        context.read<AdminBloc>().add(AdminToggleUserActive(userId: user.id, isActive: !user.isActive));
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Icon(Icons.edit, color: AppColors.primary),
            SizedBox(width: 12.w),
            const Text('Đổi quyền'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(user.email, style: TextStyle(color: AppColors.textSecondary)),
            SizedBox(height: 20.h),
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: InputDecoration(
                labelText: 'Chọn quyền',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                prefixIcon: Icon(Icons.security),
              ),
              items: [
                DropdownMenuItem(value: 'ADMIN', child: Row(children: [Icon(Icons.shield, color: AppColors.warning, size: 20.w), SizedBox(width: 8.w), const Text('Quản trị viên')])),
                DropdownMenuItem(value: 'HR_MANAGER', child: Row(children: [Icon(Icons.people_alt, color: AppColors.info, size: 20.w), SizedBox(width: 8.w), const Text('HR Manager')])),
                DropdownMenuItem(value: 'PROJECT_MANAGER', child: Row(children: [Icon(Icons.folder_shared, color: AppColors.secondary, size: 20.w), SizedBox(width: 8.w), const Text('Project Manager')])),
                DropdownMenuItem(value: 'EMPLOYEE', child: Row(children: [Icon(Icons.person, color: AppColors.textSecondary, size: 20.w), SizedBox(width: 8.w), const Text('Nhân viên')])),
              ],
              onChanged: (value) => selectedRole = value,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            onPressed: () {
              if (selectedRole != null && selectedRole != user.role.value) {
                context.read<AdminBloc>().add(AdminUpdateUserRole(userId: user.id, newRole: selectedRole!));
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Lưu thay đổi'),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Icon(Icons.lock_reset, color: AppColors.warning),
            SizedBox(width: 12.w),
            const Text('Đặt lại mật khẩu'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Icon(Icons.warning_amber, size: 40.w, color: AppColors.warning),
                  SizedBox(height: 12.h),
                  Text(user.email, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.key, size: 20.w, color: AppColors.info),
                  SizedBox(width: 8.w),
                  Text('Mật khẩu mới: 123456', style: TextStyle(color: AppColors.info, fontWeight: FontWeight.bold, fontSize: 16.sp)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            onPressed: () {
              context.read<AdminBloc>().add(AdminResetUserPassword(userId: user.id, newPassword: '123456'));
              Navigator.pop(dialogContext);
            },
            child: const Text('Xác nhận đặt lại'),
          ),
        ],
      ),
    );
  }
}
