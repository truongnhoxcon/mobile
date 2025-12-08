/// Profile Screen
/// 
/// User profile and settings.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../config/routes/app_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            // Profile Header
            _buildProfileHeader(),
            
            SizedBox(height: 24.h),
            
            // Stats Row
            _buildStatsRow(),
            
            SizedBox(height: 24.h),
            
            // Menu Items
            _buildMenuItem('Thông tin cá nhân', Icons.person_outline, () {}),
            _buildMenuItem('Cài đặt thông báo', Icons.notifications_outlined, () {}),
            _buildMenuItem('Đổi mật khẩu', Icons.lock_outline, () {}),
            _buildMenuItem('Ngôn ngữ', Icons.language, () {}),
            _buildMenuItem('Giao diện', Icons.palette_outlined, () {}),
            _buildMenuItem('Trợ giúp', Icons.help_outline, () {}),
            
            SizedBox(height: 16.h),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement logout
                  context.go(AppRoutes.login);
                },
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: const Text('Đăng xuất'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Version Info
            Text(
              'Phiên bản 1.0.0',
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 50.r,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(
                Icons.person,
                size: 50.w,
                color: AppColors.primary,
              ),
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
                child: Icon(
                  Icons.camera_alt,
                  size: 16.w,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Text(
          'Người dùng',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'user@example.com',
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            'Nhân viên',
            style: TextStyle(
              color: AppColors.success,
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
        _buildStatItem('Tasks hoàn thành', '28'),
        _buildStatItem('Ngày phép còn', '12'),
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
              style: TextStyle(
                fontSize: 11.sp,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 4.w),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border.withOpacity(0.5)),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 24.w),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textHint,
              size: 24.w,
            ),
          ],
        ),
      ),
    );
  }
}
