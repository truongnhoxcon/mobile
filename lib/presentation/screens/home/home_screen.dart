/// Home Screen
/// 
/// Main dashboard with navigation to all modules.
/// Redesigned based on DACN Mobile UI with gradient header and KPI cards.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../config/routes/app_router.dart';
import '../../blocs/blocs.dart';
import '../../widgets/common/gradient_header.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/common/gradient_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  // Dashboard data
  int _leaveDaysRemaining = 12;
  int _lateDays = 4;
  double _totalHours = 97;
  
  // Attendance
  bool _hasCheckedIn = false;
  bool _hasCheckedOut = false;
  String? _checkInTime;
  String? _checkOutTime;
  bool _isCheckingIn = false;
  
  // Time
  String _currentTime = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final displayName = authState.user?.displayName ?? 'Nhân viên';
    final avatarUrl = authState.user?.photoUrl;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Reload data
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Gradient Header
              GradientHeader(
                displayName: displayName,
                avatarUrl: avatarUrl,
                notificationCount: 2,
                onNotificationTap: () {
                  // TODO: Navigate to notifications
                },
              ),
              
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Row
                    _buildStatsRow(),
                    SizedBox(height: 16.h),
                    
                    // Attendance Card
                    _buildAttendanceCard(),
                    SizedBox(height: 16.h),
                    
                    // Quick Actions
                    _buildQuickActions(),
                    SizedBox(height: 16.h),
                    
                    // Task Summary
                    _buildTaskSummary(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        StatCard(
          value: '$_leaveDaysRemaining',
          label: 'Ngày phép',
          icon: Icons.calendar_today,
          color: const Color(0xFF3B82F6),
        ),
        SizedBox(width: 12.w),
        StatCard(
          value: '$_lateDays',
          label: 'Đi muộn',
          icon: Icons.access_time,
          color: const Color(0xFFF59E0B),
        ),
        SizedBox(width: 12.w),
        StatCard(
          value: '${_totalHours.toInt()}h',
          label: 'Giờ làm',
          icon: Icons.timer_outlined,
          color: const Color(0xFF8B5CF6),
        ),
      ],
    );
  }

  Widget _buildAttendanceCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
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
          // Title
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.access_time_filled, color: AppColors.primary, size: 22.w),
              ),
              SizedBox(width: 12.w),
              Text(
                'Chấm công hôm nay',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                DateFormat('dd/MM/yyyy').format(DateTime.now()),
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
              ),
            ],
          ),
          
          SizedBox(height: 20.h),
          
          // Current time
          Text(
            _currentTime,
            style: TextStyle(
              fontSize: 42.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 2,
            ),
          ),
          
          SizedBox(height: 20.h),
          
          // Check in/out times
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimeColumn('Giờ vào', _checkInTime ?? '--:--', AppColors.success),
              Container(width: 1, height: 40.h, color: Colors.grey.shade200),
              _buildTimeColumn('Giờ ra', _checkOutTime ?? '--:--', AppColors.error),
            ],
          ),
          
          SizedBox(height: 20.h),
          
          // Check in/out button
          _buildCheckButton(),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(String label, String time, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
        SizedBox(height: 6.h),
        Text(
          time,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: time == '--:--' ? AppColors.textHint : color,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckButton() {
    String buttonText;
    GradientType gradientType;
    IconData buttonIcon;
    
    if (_hasCheckedOut) {
      buttonText = 'ĐÃ HOÀN THÀNH';
      gradientType = GradientType.disabled;
      buttonIcon = Icons.check_circle;
    } else if (_hasCheckedIn) {
      buttonText = 'CHECK-OUT';
      gradientType = GradientType.checkOut;
      buttonIcon = Icons.logout;
    } else {
      buttonText = 'CHECK-IN';
      gradientType = GradientType.accent;
      buttonIcon = Icons.login;
    }

    return GradientButton(
      text: buttonText,
      icon: buttonIcon,
      gradientType: gradientType,
      isLoading: _isCheckingIn,
      isDisabled: _hasCheckedOut,
      onPressed: _handleCheckInOut,
    );
  }

  void _handleCheckInOut() {
    // TODO: Implement actual check-in/out with API
    setState(() {
      _isCheckingIn = true;
    });
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isCheckingIn = false;
          if (!_hasCheckedIn) {
            _hasCheckedIn = true;
            _checkInTime = DateFormat('HH:mm').format(DateTime.now());
          } else {
            _hasCheckedOut = true;
            _checkOutTime = DateFormat('HH:mm').format(DateTime.now());
          }
        });
      }
    });
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⚡ Truy cập nhanh',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            QuickActionCard(
              label: 'Chấm công',
              icon: Icons.access_time,
              color: const Color(0xFF3B82F6),
              onTap: () => context.push(AppRoutes.hr),
            ),
            SizedBox(width: 12.w),
            QuickActionCard(
              label: 'Nghỉ phép',
              icon: Icons.event_available,
              color: const Color(0xFF10B981),
              onTap: () {
                // TODO: Navigate to leave request
              },
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            QuickActionCard(
              label: 'Dự án',
              icon: Icons.folder_special,
              color: const Color(0xFF8B5CF6),
              onTap: () => context.push(AppRoutes.projects),
            ),
            SizedBox(width: 12.w),
            QuickActionCard(
              label: 'Tin nhắn',
              icon: Icons.chat_bubble,
              color: const Color(0xFFFF6B00),
              onTap: () => context.push(AppRoutes.chat),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskSummary() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push(AppRoutes.projects),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.assignment, color: AppColors.primary, size: 24.w),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Công việc của tôi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '5 việc cần hoàn thành',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                '5',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final authState = context.read<AuthBloc>().state;
    final isHRManager = authState.user?.isHRManager ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Trang chủ'),
              _buildNavItem(1, Icons.work_history_rounded, Icons.work_history_outlined, 'Công việc'),
              _buildNavItem(2, Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Chat'),
              _buildNavItem(3, Icons.notifications_rounded, Icons.notifications_outlined, 'Thông báo'),
              _buildNavItem(4, Icons.person_rounded, Icons.person_outline_rounded, 'Hồ sơ'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label, {int badge = 0}) {
    final isActive = _selectedIndex == index;
    
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : inactiveIcon,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                  size: 26.w,
                ),
                if (badge > 0)
                  Positioned(
                    right: -8.w,
                    top: -4.h,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex && index == 0) return;
    
    switch (index) {
      case 0:
        setState(() => _selectedIndex = 0);
        break;
      case 1: // Công việc
        context.push(AppRoutes.hr);
        break;
      case 2: // Chat
        context.push(AppRoutes.chat);
        break;
      case 3: // Notifications
        // TODO: Navigate to notifications
        break;
      case 4: // Profile
        context.push(AppRoutes.profile);
        break;
    }
  }
}
