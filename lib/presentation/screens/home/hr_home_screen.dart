/// HR Home Screen
/// 
/// Main dashboard for HR Manager with HR-specific navigation.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../config/routes/app_router.dart';
import '../../../config/dependencies/injection_container.dart' as di;
import '../../blocs/blocs.dart';
import '../hr/tabs/hr_dashboard_tab.dart';
import '../hr/tabs/hr_employees_tab.dart';
import '../hr/tabs/hr_departments_tab.dart';
import '../hr/tabs/hr_leaves_tab.dart';
import '../chat/chat_list_screen.dart';
import '../profile/profile_screen.dart';

/// HR Manager Home Screen - Completely different layout from Employee
class HRHomeScreen extends StatefulWidget {
  const HRHomeScreen({super.key});

  @override
  State<HRHomeScreen> createState() => _HRHomeScreenState();
}

class _HRHomeScreenState extends State<HRHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<HRBloc>()
        ..add(const HRLoadDashboard())
        ..add(const HRLoadEmployees())
        ..add(const HRLoadLeaveRequests())
        ..add(const HRLoadDepartments()),
      child: Scaffold(
        // Hide AppBar for Chat(2) and Profile(3) since they have their own AppBars
        appBar: (_currentIndex == 2 || _currentIndex == 3) ? null : _buildAppBar(),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push(AppRoutes.aiChat),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.smart_toy, color: Colors.white),
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    String title;
    switch (_currentIndex) {
      case 0:
        title = 'Quản lý Nhân sự';
        break;
      case 1:
        title = 'Chấm công Nhân viên';
        break;
      case 2:
        title = 'Tin nhắn';
        break;
      case 3:
        title = 'Hồ sơ';
        break;
      default:
        title = 'HR Manager';
    }

    return AppBar(
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
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
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHRDashboard();
      case 1:
        return _buildAttendanceManagement();
      case 2:
        return _buildChatScreen();
      case 3:
        return _buildProfileScreen();
      default:
        return _buildHRDashboard();
    }
  }

  Widget _buildHRDashboard() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              isScrollable: false,
              tabs: const [
                Tab(text: 'Tổng quan', icon: Icon(Icons.dashboard)),
                Tab(text: 'Nhân viên', icon: Icon(Icons.people)),
                Tab(text: 'Phòng ban', icon: Icon(Icons.business)),
                Tab(text: 'Nghỉ phép', icon: Icon(Icons.event_busy)),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                HRDashboardTab(),
                HREmployeesTab(),
                HRDepartmentsTab(),
                HRLeavesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceManagement() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards
          Row(
            children: [
              Expanded(child: _buildStatCard('Đang làm', '45', AppColors.success, Icons.check_circle)),
              SizedBox(width: 12.w),
              Expanded(child: _buildStatCard('Vắng mặt', '3', AppColors.error, Icons.cancel)),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(child: _buildStatCard('Đi muộn', '5', AppColors.warning, Icons.schedule)),
              SizedBox(width: 12.w),
              Expanded(child: _buildStatCard('Nghỉ phép', '2', AppColors.accent, Icons.beach_access)),
            ],
          ),
          
          SizedBox(height: 24.h),
          
          Text(
            'Chấm công hôm nay',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          
          // Attendance list placeholder
          ...List.generate(5, (index) => _buildAttendanceItem(
            'Nhân viên ${index + 1}',
            index % 2 == 0 ? '08:00' : '08:${15 + index * 5}',
            index % 2 == 0,
          )),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32.w),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceItem(String name, String time, bool onTime) {
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
          CircleAvatar(
            radius: 24.r,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              name[0],
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Check-in: $time',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: onTime ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              onTime ? 'Đúng giờ' : 'Đi muộn',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: onTime ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatScreen() {
    return const ChatListScreen();
  }

  Widget _buildProfileScreen() {
    return const ProfileScreen();
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
          icon: Icon(Icons.dashboard_rounded),
          label: 'Quản lý',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.access_time_rounded),
          label: 'Chấm công',
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
