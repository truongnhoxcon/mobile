/// Home Screen
/// 
/// Main dashboard with navigation to all modules.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../config/routes/app_router.dart';
import '../../blocs/blocs.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Enterprise Mobile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
        actions: [
          IconButton(
            icon: Badge(
              label: const Text('3'),
              child: Icon(Icons.notifications_outlined, size: 26.w),
            ),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              _buildWelcomeCard(),
              
              SizedBox(height: 24.h),
              
              // Quick Actions Grid
              Text(
                'Truy cập nhanh',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),
              _buildQuickActionsGrid(),
              
              SizedBox(height: 24.h),
              
              // Recent Activities
              Text(
                'Hoạt động gần đây',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),
              _buildRecentActivities(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.aiChat),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.smart_toy, color: Colors.white),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào! 👋',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Người dùng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '5 task đang chờ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 35.r,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              size: 35.w,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    // Get user role from AuthBloc
    final authState = context.read<AuthBloc>().state;
    final isHRManager = authState.user?.isHRManager ?? false;

    final actions = [
      _QuickAction('Dự án', Icons.folder_open_rounded, AppColors.primary, AppRoutes.projects),
      // HR Manager sees "Quản lý HR", Employee sees "Chấm công"
      isHRManager 
          ? _QuickAction('Quản lý HR', Icons.admin_panel_settings_rounded, AppColors.success, AppRoutes.hr)
          : _QuickAction('Chấm công', Icons.access_time_rounded, AppColors.success, AppRoutes.hr),
      _QuickAction('Tin nhắn', Icons.chat_bubble_rounded, AppColors.accent, AppRoutes.chat),
      _QuickAction('Hồ sơ', Icons.person_rounded, AppColors.secondary, AppRoutes.profile),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 1.4,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildQuickActionCard(action);
      },
    );
  }

  Widget _buildQuickActionCard(_QuickAction action) {
    return GestureDetector(
      onTap: () => context.push(action.route),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: action.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: action.color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: action.color,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                action.icon,
                color: Colors.white,
                size: 24.w,
              ),
            ),
            Text(
              action.title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Column(
      children: [
        _buildActivityItem(
          'Task "Setup Firebase" đã hoàn thành',
          'Dự án Mobile App',
          Icons.check_circle,
          AppColors.success,
          '5 phút trước',
        ),
        _buildActivityItem(
          'Bạn được giao task mới',
          'Dự án Web Dashboard',
          Icons.assignment,
          AppColors.primary,
          '1 giờ trước',
        ),
        _buildActivityItem(
          'Check-in thành công',
          'Văn phòng HQ',
          Icons.location_on,
          AppColors.accent,
          '8:30 AM',
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String time,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color, size: 22.w),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    // Get user role from AuthBloc
    final authState = context.read<AuthBloc>().state;
    final isHRManager = authState.user?.isHRManager ?? false;

    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() => _currentIndex = index);
        switch (index) {
          case 0:
            context.go(AppRoutes.home);
            break;
          case 1:
            context.push(AppRoutes.projects);
            break;
          case 2:
            context.push(AppRoutes.hr);
            break;
          case 3:
            context.push(AppRoutes.chat);
            break;
          case 4:
            context.push(AppRoutes.profile);
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Trang chủ'),
        const BottomNavigationBarItem(icon: Icon(Icons.folder_rounded), label: 'Dự án'),
        BottomNavigationBarItem(
          icon: Icon(isHRManager ? Icons.admin_panel_settings_rounded : Icons.access_time_rounded), 
          label: isHRManager ? 'Quản lý HR' : 'Chấm công',
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.chat_rounded), label: 'Chat'),
        const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Hồ sơ'),
      ],
    );
  }
}

class _QuickAction {
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  _QuickAction(this.title, this.icon, this.color, this.route);
}
