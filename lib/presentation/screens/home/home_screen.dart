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
import '../../../data/datasources/issue_datasource.dart';
import '../../../domain/entities/issue.dart';
import '../../widgets/common/gradient_header.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/pastel_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  
  // Dashboard data
  int _leaveDaysRemaining = 12;
  int _lateDays = 4;
  double _totalHours = 97;
  
  // Time
  String _currentTime = '';
  Timer? _timer;

  // Priority Tasks
  late Future<List<Issue>> _priorityTasksFuture;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _loadTodayAttendance();
    _priorityTasksFuture = _fetchTopTasks();
  }

  void _loadTodayAttendance() {
    final authState = context.read<AuthBloc>().state;
    final userId = authState.user?.id ?? '';
    if (userId.isNotEmpty) {
      context.read<AttendanceBloc>().add(AttendanceLoadToday(userId));
    }
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

    return BlocListener<AttendanceBloc, AttendanceState>(
      listenWhen: (previous, current) => 
        (previous.status == AttendanceBlocStatus.checkingIn && current.status == AttendanceBlocStatus.loaded) ||
        (previous.status == AttendanceBlocStatus.checkingOut && current.status == AttendanceBlocStatus.loaded) ||
        current.status == AttendanceBlocStatus.error,
      listener: (context, state) {
        if (state.status == AttendanceBlocStatus.error && state.errorMessage != null) {
          if (state.errorMessage!.contains('cách văn phòng')) {
             _showLocationErrorDialog(state.errorMessage!, null);
          } else {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text(state.errorMessage!), backgroundColor: AppColors.error),
             );
          }
        } else if (state.status == AttendanceBlocStatus.loaded) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('Chấm công thành công!'),
               backgroundColor: AppColors.success,
             ),
           );
        }
      },
      child: PastelBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push(AppRoutes.aiChat),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.smart_toy, color: Colors.white),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              _loadTodayAttendance();
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
                       context.push(AppRoutes.notifications);
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
                        
                        // Priority Tasks
                        _buildPriorityTasks(),
                      ],
                    ),
                  ),
                  SizedBox(height: 80.h), // Space for bottom nav
                ],
              ),
            ),
          ),
        ),
      ),
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
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, attendanceState) {
        final attendance = attendanceState.todayAttendance;
        final hasCheckedIn = attendance?.checkInTime != null;
        final hasCheckedOut = attendance?.checkOutTime != null;
        
        String checkInTime = '--:--';
        String checkOutTime = '--:--';
        
        if (attendance != null) {
          if (attendance.checkInTime != null) {
            checkInTime = DateFormat('HH:mm').format(attendance.checkInTime!);
          }
          if (attendance.checkOutTime != null) {
            checkOutTime = DateFormat('HH:mm').format(attendance.checkOutTime!);
          }
        }

        return GlassCard(
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
                  _buildTimeColumn('Giờ vào', checkInTime, AppColors.success),
                  Container(width: 1, height: 40.h, color: Colors.grey.shade200),
                  _buildTimeColumn('Giờ ra', checkOutTime, AppColors.error),
                ],
              ),
              
              SizedBox(height: 20.h),
              
              // Check in/out button
              _buildCheckButton(attendanceState, hasCheckedIn, hasCheckedOut),
            ],
          ),
        );
      },
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

  Widget _buildCheckButton(AttendanceState state, bool hasCheckedIn, bool hasCheckedOut) {
    String buttonText;
    GradientType gradientType;
    IconData buttonIcon;
    bool isLoading = state.status == AttendanceBlocStatus.checkingIn || 
                     state.status == AttendanceBlocStatus.checkingOut;
    
    if (hasCheckedOut) {
      buttonText = 'ĐÃ HOÀN THÀNH';
      gradientType = GradientType.disabled;
      buttonIcon = Icons.check_circle;
    } else if (hasCheckedIn) {
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
      isLoading: isLoading,
      isDisabled: hasCheckedOut,
      onPressed: () => _handleCheckInOut(hasCheckedIn, state.todayAttendance?.id),
    );
  }

  void _handleCheckInOut(bool hasCheckedIn, String? attendanceId) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState.user?.id ?? '';
    
    if (userId.isEmpty) return;
    
    // BLoC handles GPS and geofence validation - just dispatch the event
    if (!hasCheckedIn) {
      context.read<AttendanceBloc>().add(AttendanceCheckIn(userId));
    } else if (attendanceId != null) {
      context.read<AttendanceBloc>().add(AttendanceCheckOut(attendanceId));
    }
  }

  Widget _buildPriorityTasks() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Công việc ưu tiên',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.employeeTasks),
              child: const Text('Xem tất cả'),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        FutureBuilder<List<Issue>>(
          future: _priorityTasksFuture, 
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final tasks = snapshot.data ?? [];
            if (tasks.isEmpty) {
              return Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 48.w, color: AppColors.success),
                      SizedBox(height: 12.h),
                      Text(
                        'Bạn đã hoàn thành hết công việc!',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: tasks.map((task) => _buildTaskItem(task)).toList(),
            );
          },
        ),
      ],
    );
  }

  Future<List<Issue>> _fetchTopTasks() async {
    try {
      final authState = context.read<AuthBloc>().state;
      final userId = authState.user?.id ?? '';
      if (userId.isEmpty) return [];

      final issues = await IssueDataSourceImpl().getIssuesByAssignee(userId);
      // Filter for active tasks (not done)
      final activeIssues = issues
          .where((i) => i.status != IssueStatus.done)
          .map((m) => m.toEntity()) // Convert model to entity
          .toList();
          
      // Take top 3
      return activeIssues.take(3).toList();
    } catch (_) {
      return [];
    }
  }

  Widget _buildTaskItem(Issue task) {
    Color statusColor;
    String statusText;
    switch (task.status) {
      case IssueStatus.todo:
        statusColor = AppColors.warning;
        statusText = 'Chờ xử lý';
        break;
      case IssueStatus.inProgress:
        statusColor = AppColors.primary;
        statusText = 'Đang làm';
        break;
      case IssueStatus.done:
        statusColor = AppColors.success;
        statusText = 'Hoàn thành';
        break;
    }

    return InkWell(
      onTap: () => context.pushNamed('taskDetail', pathParameters: {'id': task.id}),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.assignment_outlined, color: statusColor, size: 20.w),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Hạn: ${task.dueDate != null ? DateFormat('dd/MM').format(task.dueDate!) : 'N/A'}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  void _showLocationErrorDialog(String message, double? distance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Icon(Icons.location_off, color: AppColors.error, size: 28.w),
            SizedBox(width: 10.w),
            Text('Không thể chấm công', style: TextStyle(fontSize: 18.sp)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: TextStyle(fontSize: 14.sp)),
            if (distance != null) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.directions_walk, color: AppColors.warning, size: 20.w),
                    SizedBox(width: 8.w),
                    Text(
                      'Khoảng cách: ${_formatDistance(distance)}',
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
  
  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toInt()} m';
  }
}
