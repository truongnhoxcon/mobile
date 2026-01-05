/// PM Home Screen
/// 
/// Main dashboard for Project Manager with PM-specific navigation.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../config/routes/app_router.dart';
import '../../../config/dependencies/injection_container.dart' as di;
import '../../../domain/entities/user.dart';
import '../../blocs/blocs.dart';
import '../employee/employee_tasks_screen.dart';
import '../chat/chat_list_screen.dart';

/// Project Manager Home Screen - Different layout from Employee
class PMHomeScreen extends StatefulWidget {
  const PMHomeScreen({super.key});

  @override
  State<PMHomeScreen> createState() => _PMHomeScreenState();
}

class _PMHomeScreenState extends State<PMHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0 || _currentIndex == 1 || _currentIndex == 2 ? null : _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.aiChat),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.smart_toy, color: Colors.white),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    String title;
    switch (_currentIndex) {
      case 0:
        title = 'Quản lý Dự án';
        break;
      case 1:
        title = 'Tin nhắn';
        break;
      case 2:
        title = 'Hồ sơ';
        break;
      default:
        title = 'Project Manager';
    }

    return AppBar(
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
      ),
      actions: [
        IconButton(
          icon: Badge(
            label: const Text('2'),
            child: Icon(Icons.notifications_outlined, size: 26.w),
          ),
          onPressed: () {
            // TODO: Navigate to notifications
          },
        ),
        SizedBox(width: 8.w),
      ],
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const EmployeeTasksScreen();
      case 1:
        return const ChatListScreen();
      case 2:
        return const _PMProfileTab();
      default:
        return const EmployeeTasksScreen();
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
          icon: Icon(Icons.folder_open_rounded),
          label: 'Dự án',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_rounded),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Hồ sơ',
        ),
      ],
    );
  }
}

/// PM Profile Tab - Profile content without separate AppBar
class _PMProfileTab extends StatelessWidget {
  const _PMProfileTab();

  String _getRoleDisplayName(UserRole? role) {
    if (role == null) return 'Project Manager';
    switch (role) {
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(AuthSignOutRequested());
            },
            child: Text('Đăng xuất', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.unauthenticated) {
          context.go(AppRoutes.login);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;
          
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Hồ sơ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.settings, size: 26.w),
                  onPressed: () {},
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  _buildProfileHeader(user),
                  SizedBox(height: 24.h),
                  _buildStatsRow(),
                  SizedBox(height: 24.h),
                  _buildMenuItem(context, 'Thông tin cá nhân', Icons.person_outline, () {}),
                  _buildMenuItem(context, 'Cài đặt thông báo', Icons.notifications_outlined, () {}),
                  _buildMenuItem(context, 'Đổi mật khẩu', Icons.lock_outline, () {}),
                  _buildMenuItem(context, 'Giao diện', Icons.palette_outlined, () {}),
                  _buildMenuItem(context, 'Trợ giúp', Icons.help_outline, () {}),
                  SizedBox(height: 16.h),
                  
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showLogoutDialog(context),
                      icon: const Icon(Icons.logout, color: AppColors.error),
                      label: const Text('Đăng xuất'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24.h),
                  Text(
                    'Phiên bản 1.0.0',
                    style: TextStyle(color: AppColors.textHint, fontSize: 12.sp),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(user) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 50.r,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: user?.photoUrl != null 
                  ? NetworkImage(user!.photoUrl!) 
                  : null,
              child: user?.photoUrl == null
                  ? Icon(Icons.person, size: 50.w, color: AppColors.primary)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Icon(Icons.camera_alt, size: 16.w, color: Colors.white),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Text(
          user?.displayName ?? 'Project Manager',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          user?.email ?? 'pm@example.com',
          style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            _getRoleDisplayName(user?.role),
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatItem('Dự án', '5'),
        _buildStatItem('Tasks', '28'),
        _buildStatItem('Thành viên', '12'),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 4.w),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 24.w),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 16.sp, color: AppColors.textPrimary),
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textHint, size: 24.w),
          ],
        ),
      ),
    );
  }
}

