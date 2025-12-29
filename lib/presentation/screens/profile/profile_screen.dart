import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../config/routes/app_router.dart';
import '../../blocs/blocs.dart';

import '../../widgets/common/pastel_background.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                'Cá nhân',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: Colors.white,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
              ),
            ),
            body: PastelBackground(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  _buildProfileHeader(user),
                  SizedBox(height: 32.h),
                  
                  // Feature Menu
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          'Thông tin cá nhân', 
                          Icons.person_outline, 
                          () => context.push(AppRoutes.myInfo),
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          'Bảng lương',
                          Icons.account_balance_wallet_outlined,
                          () => context.push(AppRoutes.salary),
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          'Nghỉ phép',
                          Icons.event_available_outlined,
                          () => context.push(AppRoutes.leave),
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          'Đánh giá hiệu suất', 
                          Icons.bar_chart, 
                          () => context.push(AppRoutes.myEvaluations),
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          'Danh bạ đồng nghiệp', 
                          Icons.people_outline, 
                          () => context.push(AppRoutes.team),
                        ),
                         _buildDivider(),
                        _buildMenuItem(
                          'Đổi mật khẩu', 
                          Icons.lock_reset, 
                          () => context.push(AppRoutes.changePassword),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32.h),
                  
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
                        backgroundColor: Colors.white,
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5), indent: 50.w, endIndent: 16.w);
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
          user?.displayName ?? 'Người dùng',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          user?.email ?? 'user@example.com',
          style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: (user?.isAdmin == true ? AppColors.warning : AppColors.success)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            user?.isAdmin == true ? 'Quản trị viên' : 'Nhân viên',
            style: TextStyle(
              color: user?.isAdmin == true ? AppColors.warning : AppColors.success,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildMenuItem(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20.w),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp, 
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textHint, size: 20.w),
          ],
        ),
      ),
    );
  }
}
