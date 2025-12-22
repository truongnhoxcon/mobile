/// PM Home Screen
/// 
/// Main dashboard for Project Manager with PM-specific navigation.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../config/routes/app_router.dart';
import '../../blocs/blocs.dart';
import '../pm/tabs/pm_dashboard_tab.dart';
import '../pm/tabs/pm_approvals_tab.dart';

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
      appBar: _buildAppBar(),
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
        title = 'Duyệt đơn';
        break;
      case 2:
        title = 'Tin nhắn';
        break;
      case 3:
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
        return const PMDashboardTab();
      case 1:
        return const PMApprovalsTab();
      case 2:
        return _buildChatPlaceholder();
      case 3:
        return _buildProfilePlaceholder();
      default:
        return const PMDashboardTab();
    }
  }

  Widget _buildChatPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64.w, color: AppColors.textSecondary),
          SizedBox(height: 16.h),
          Text(
            'Tin nhắn nội bộ',
            style: TextStyle(fontSize: 18.sp, color: AppColors.textSecondary),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () => context.push(AppRoutes.chat),
            child: const Text('Mở Chat'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 64.w, color: AppColors.textSecondary),
          SizedBox(height: 16.h),
          Text(
            'Hồ sơ cá nhân',
            style: TextStyle(fontSize: 18.sp, color: AppColors.textSecondary),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () => context.push(AppRoutes.profile),
            child: const Text('Xem Hồ sơ'),
          ),
        ],
      ),
    );
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
          icon: Icon(Icons.approval_rounded),
          label: 'Duyệt đơn',
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
