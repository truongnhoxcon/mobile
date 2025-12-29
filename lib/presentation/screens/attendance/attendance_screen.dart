import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/attendance.dart';
import '../../../config/dependencies/injection_container.dart' as di;
import '../../blocs/blocs.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/pastel_background.dart';

/// Attendance Screen - Check-in/out and history
class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final authBloc = di.sl<AuthBloc>();
        final userId = authBloc.state.user?.id ?? '';
        return di.sl<AttendanceBloc>()
          ..add(AttendanceLoadToday(userId))
          ..add(AttendanceLoadMonth(
            userId: userId,
            year: DateTime.now().year,
            month: DateTime.now().month,
          ));
      },
      child: const _AttendanceScreenContent(),
    );
  }
}

class _AttendanceScreenContent extends StatefulWidget {
  const _AttendanceScreenContent();

  @override
  State<_AttendanceScreenContent> createState() => _AttendanceScreenContentState();
}

class _AttendanceScreenContentState extends State<_AttendanceScreenContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chấm công',
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Hôm nay', icon: Icon(Icons.today)),
            Tab(text: 'Lịch sử', icon: Icon(Icons.calendar_month)),
          ],
        ),
      ),
      body: PastelBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            _TodayTab(),
            _HistoryTab(
              selectedMonth: _selectedMonth,
              onMonthChanged: (month) => setState(() => _selectedMonth = month),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Today Tab - Check-in/out and today's status
// ============================================================================
class _TodayTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AttendanceBloc, AttendanceState>(
      listenWhen: (previous, current) => 
        (previous.status == AttendanceBlocStatus.checkingIn && current.status == AttendanceBlocStatus.loaded) ||
        (previous.status == AttendanceBlocStatus.checkingOut && current.status == AttendanceBlocStatus.loaded) ||
        current.status == AttendanceBlocStatus.error,
      listener: (context, state) {
        if (state.status == AttendanceBlocStatus.error && state.errorMessage != null) {
          if (state.errorMessage!.contains('cách văn phòng')) {
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
                 content: Text(state.errorMessage!, style: TextStyle(fontSize: 14.sp)),
                 actions: [
                   TextButton(
                     onPressed: () => Navigator.pop(context),
                     child: Text('Đóng', style: TextStyle(color: AppColors.primary)),
                   ),
                 ],
               ),
             );
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
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            final userId = di.sl<AuthBloc>().state.user?.id ?? '';
            context.read<AttendanceBloc>().add(AttendanceLoadToday(userId));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Date Header
                _buildDateHeader(),
                SizedBox(height: 24.h),
                
                // Check-in/out Card
                _buildCheckInOutCard(context, state),
                SizedBox(height: 20.h),
                
                // Today's Summary
                if (state.todayAttendance != null)
                  _buildTodaySummary(state.todayAttendance!),
                
                SizedBox(height: 20.h),
                
                // Location Info
                if (state.todayAttendance?.checkInLocation != null)
                  _buildLocationCard(state.todayAttendance!),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateHeader() {
    final now = DateTime.now();
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('dd').format(now),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(now).toUpperCase(),
                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE', 'vi').format(now),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                DateFormat('yyyy').format(now),
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              ),
            ],
          ),
          const Spacer(),
          Text(
            DateFormat('HH:mm').format(now),
            style: TextStyle(
              color: Colors.white,
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInOutCard(BuildContext context, AttendanceState state) {
    final hasCheckedIn = state.todayAttendance?.hasCheckedIn ?? false;
    final hasCheckedOut = state.todayAttendance?.hasCheckedOut ?? false;
    final isLoading = state.status == AttendanceBlocStatus.checkingIn ||
        state.status == AttendanceBlocStatus.checkingOut;

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
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
          // Status Icon
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: _getStatusColor(hasCheckedIn, hasCheckedOut).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(hasCheckedIn, hasCheckedOut),
              color: _getStatusColor(hasCheckedIn, hasCheckedOut),
              size: 40.w,
            ),
          ),
          SizedBox(height: 16.h),
          
          // Status Text
          Text(
            _getStatusText(hasCheckedIn, hasCheckedOut),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: _getStatusColor(hasCheckedIn, hasCheckedOut),
            ),
          ),
          SizedBox(height: 24.h),
          
          // Check-in/out Button
          if (!hasCheckedOut)
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: isLoading ? null : () => _handleCheckInOut(context, state),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasCheckedIn ? AppColors.warning : AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 24.w,
                        height: 24.w,
                        child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(hasCheckedIn ? Icons.logout : Icons.login, size: 24.w),
                          SizedBox(width: 8.w),
                          Text(
                            hasCheckedIn ? 'CHECK OUT' : 'CHECK IN',
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
          
          // Completed message
          if (hasCheckedOut)
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 24.w),
                  SizedBox(width: 8.w),
                  Text(
                    'Đã hoàn thành chấm công hôm nay!',
                    style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          
          // Error message
          if (state.status == AttendanceBlocStatus.error && state.errorMessage != null) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 20.w),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: TextStyle(color: AppColors.error, fontSize: 13.sp),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodaySummary(Attendance attendance) {
    final timeFormat = DateFormat('HH:mm');
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chi tiết hôm nay',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildTimeCard(
                  icon: Icons.login,
                  label: 'Giờ vào',
                  time: attendance.checkInTime != null
                      ? timeFormat.format(attendance.checkInTime!)
                      : '--:--',
                  color: AppColors.success,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildTimeCard(
                  icon: Icons.logout,
                  label: 'Giờ ra',
                  time: attendance.checkOutTime != null
                      ? timeFormat.format(attendance.checkOutTime!)
                      : '--:--',
                  color: AppColors.warning,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildTimeCard(
                  icon: Icons.timer,
                  label: 'Tổng giờ',
                  time: attendance.workingHours != null
                      ? '${attendance.workingHours!.toStringAsFixed(1)}h'
                      : '--',
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Text('Trạng thái: ', style: TextStyle(color: AppColors.textSecondary)),
              _buildStatusBadge(attendance.status),
            ],
          ),
          SizedBox(height: 12.h),
          
          // Additional badges row
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              // Shift Type badge
              _buildInfoBadge(
                icon: Icons.access_time,
                label: attendance.shiftType.displayName,
                color: AppColors.info,
              ),
              
              // OT hours badge (if any)
              if (attendance.overtimeHours > 0)
                _buildInfoBadge(
                  icon: Icons.more_time,
                  label: 'OT ${attendance.overtimeHours.toStringAsFixed(1)}h',
                  color: AppColors.warning,
                ),
              
              // Remote work badge
              if (attendance.isRemote)
                _buildInfoBadge(
                  icon: Icons.home_work,
                  label: 'WFH',
                  color: AppColors.primary,
                ),
              
              // Late badge
              if (attendance.lateMinutes != null && attendance.lateMinutes! > 0)
                _buildInfoBadge(
                  icon: Icons.schedule,
                  label: 'Trễ ${attendance.lateMinutes}p',
                  color: AppColors.error,
                ),
              
              // Early leave badge
              if (attendance.earlyLeaveMinutes != null && attendance.earlyLeaveMinutes! > 0)
                _buildInfoBadge(
                  icon: Icons.exit_to_app,
                  label: 'Về sớm ${attendance.earlyLeaveMinutes}p',
                  color: AppColors.warning,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.w, color: color),
          SizedBox(width: 4.w),
          Text(label, style: TextStyle(fontSize: 12.sp, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTimeCard({
    required IconData icon,
    required String label,
    required String time,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.w),
          SizedBox(height: 8.h),
          Text(time, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
          SizedBox(height: 2.h),
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp)),
        ],
      ),
    );
  }

  Widget _buildLocationCard(Attendance attendance) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: AppColors.primary, size: 20.w),
              SizedBox(width: 8.w),
              Text('Vị trí chấm công', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
            ],
          ),
          SizedBox(height: 12.h),
          if (attendance.checkInLocation != null)
            _buildLocationRow('Check-in', attendance.checkInLocation!),
          if (attendance.checkOutLocation != null) ...[
            SizedBox(height: 8.h),
            _buildLocationRow('Check-out', attendance.checkOutLocation!),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationRow(String label, GeoLocation location) {
    return Row(
      children: [
        Text('$label: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
        Expanded(
          child: Text(
            location.address ?? '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
            style: TextStyle(fontSize: 13.sp),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(AttendanceStatus status) {
    Color color;
    switch (status) {
      case AttendanceStatus.present:
        color = AppColors.success;
      case AttendanceStatus.late:
        color = AppColors.warning;
      case AttendanceStatus.earlyLeave:
        color = AppColors.info;
      case AttendanceStatus.absent:
        color = AppColors.error;
      case AttendanceStatus.leave:
        color = AppColors.primary;
      case AttendanceStatus.holiday:
        color = AppColors.warning;
      case AttendanceStatus.weekend:
        color = AppColors.textSecondary;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: color, fontSize: 12.sp, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _handleCheckInOut(BuildContext context, AttendanceState state) {
    final userId = di.sl<AuthBloc>().state.user?.id ?? '';
    
    if (state.todayAttendance?.hasCheckedIn ?? false) {
      // Check out
      context.read<AttendanceBloc>().add(
        AttendanceCheckOut(state.todayAttendance!.id),
      );
    } else {
      // Check in
      context.read<AttendanceBloc>().add(AttendanceCheckIn(userId));
    }
  }

  Color _getStatusColor(bool hasCheckedIn, bool hasCheckedOut) {
    if (hasCheckedOut) return AppColors.success;
    if (hasCheckedIn) return AppColors.warning;
    return AppColors.textSecondary;
  }

  IconData _getStatusIcon(bool hasCheckedIn, bool hasCheckedOut) {
    if (hasCheckedOut) return Icons.check_circle;
    if (hasCheckedIn) return Icons.schedule;
    return Icons.radio_button_unchecked;
  }

  String _getStatusText(bool hasCheckedIn, bool hasCheckedOut) {
    if (hasCheckedOut) return 'Đã hoàn thành';
    if (hasCheckedIn) return 'Đang làm việc';
    return 'Chưa chấm công';
  }
}

// ============================================================================
// History Tab - Monthly calendar and stats
// ============================================================================
class _HistoryTab extends StatelessWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;

  const _HistoryTab({
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            final userId = di.sl<AuthBloc>().state.user?.id ?? '';
            context.read<AttendanceBloc>().add(AttendanceLoadMonth(
              userId: userId,
              year: selectedMonth.year,
              month: selectedMonth.month,
            ));
          },
          child: ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              // Month Selector
              _buildMonthSelector(context),
              SizedBox(height: 16.h),
              
              // Stats Summary
              _buildStatsSummary(state.monthlyAttendance),
              SizedBox(height: 16.h),
              
              // Calendar Grid
              _buildCalendarGrid(state.monthlyAttendance),
              SizedBox(height: 16.h),
              
              // Legend
              _buildLegend(),
              SizedBox(height: 16.h),
              
              // Attendance List
              _buildAttendanceList(state.monthlyAttendance),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              final newMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
              onMonthChanged(newMonth);
              _loadMonth(context, newMonth);
            },
          ),
          Text(
            DateFormat('MMMM yyyy', 'vi').format(selectedMonth),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final newMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
              onMonthChanged(newMonth);
              _loadMonth(context, newMonth);
            },
          ),
        ],
      ),
    );
  }

  void _loadMonth(BuildContext context, DateTime month) {
    final userId = di.sl<AuthBloc>().state.user?.id ?? '';
    context.read<AttendanceBloc>().add(AttendanceLoadMonth(
      userId: userId,
      year: month.year,
      month: month.month,
    ));
  }

  Widget _buildStatsSummary(List<Attendance> attendances) {
    final present = attendances.where((a) => a.status == AttendanceStatus.present).length;
    final late = attendances.where((a) => a.status == AttendanceStatus.late).length;
    final absent = attendances.where((a) => a.status == AttendanceStatus.absent).length;
    final leave = attendances.where((a) => a.status == AttendanceStatus.leave).length;
    final totalHours = attendances.fold<double>(0, (sum, a) => sum + (a.workingHours ?? 0));

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF10B981), const Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Text(
            '${totalHours.toStringAsFixed(1)}h',
            style: TextStyle(color: Colors.white, fontSize: 32.sp, fontWeight: FontWeight.bold),
          ),
          Text('Tổng giờ làm việc', style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(present.toString(), 'Đúng giờ', Colors.white),
              _buildStatItem(late.toString(), 'Đi trễ', Colors.amber),
              _buildStatItem(absent.toString(), 'Vắng', Colors.red.shade300),
              _buildStatItem(leave.toString(), 'Nghỉ phép', Colors.blue.shade300),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 20.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 2.h),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 11.sp)),
      ],
    );
  }

  Widget _buildCalendarGrid(List<Attendance> attendances) {
    final firstDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday;

    // Create attendance map by date
    final attendanceMap = <int, Attendance>{};
    for (final a in attendances) {
      attendanceMap[a.date.day] = a;
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
                .map((d) => SizedBox(
                      width: 36.w,
                      child: Text(d, textAlign: TextAlign.center, 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp, color: AppColors.textSecondary)),
                    ))
                .toList(),
          ),
          SizedBox(height: 8.h),
          // Calendar days
          Wrap(
            children: List.generate(42, (index) {
              final dayIndex = index - (startWeekday - 1);
              if (dayIndex < 1 || dayIndex > daysInMonth) {
                return SizedBox(width: 36.w, height: 36.w);
              }
              
              final attendance = attendanceMap[dayIndex];
              return _buildCalendarDay(dayIndex, attendance);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDay(int day, Attendance? attendance) {
    final today = DateTime.now();
    final isToday = day == today.day && 
        selectedMonth.month == today.month && 
        selectedMonth.year == today.year;

    Color bgColor = Colors.transparent;
    Color textColor = AppColors.textPrimary;

    if (attendance != null) {
      switch (attendance.status) {
        case AttendanceStatus.present:
          bgColor = AppColors.success.withValues(alpha: 0.2);
          textColor = AppColors.success;
        case AttendanceStatus.late:
          bgColor = AppColors.warning.withValues(alpha: 0.2);
          textColor = AppColors.warning;
        case AttendanceStatus.absent:
          bgColor = AppColors.error.withValues(alpha: 0.2);
          textColor = AppColors.error;
        case AttendanceStatus.leave:
          bgColor = AppColors.primary.withValues(alpha: 0.2);
          textColor = AppColors.primary;
        case AttendanceStatus.earlyLeave:
          bgColor = AppColors.info.withValues(alpha: 0.2);
          textColor = AppColors.info;
        case AttendanceStatus.holiday:
          bgColor = AppColors.warning.withValues(alpha: 0.2);
          textColor = AppColors.warning;
        case AttendanceStatus.weekend:
          bgColor = AppColors.textSecondary.withValues(alpha: 0.1);
          textColor = AppColors.textSecondary;
      }
    }

    return Container(
      width: 36.w,
      height: 36.w,
      margin: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: isToday ? Border.all(color: AppColors.primary, width: 2) : null,
      ),
      child: Center(
        child: Text(
          '$day',
          style: TextStyle(
            color: textColor,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            fontSize: 13.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem(AppColors.success, 'Đúng giờ'),
        _buildLegendItem(AppColors.warning, 'Đi trễ'),
        _buildLegendItem(AppColors.error, 'Vắng'),
        _buildLegendItem(AppColors.primary, 'Nghỉ phép'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4.w),
        Text(label, style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildAttendanceList(List<Attendance> attendances) {
    if (attendances.isEmpty) {
      return Center(
        child: Text('Không có dữ liệu', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    // Sort by date descending
    final sorted = List<Attendance>.from(attendances)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chi tiết', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
        SizedBox(height: 12.h),
        ...sorted.take(10).map((a) => _AttendanceListItem(attendance: a)),
      ],
    );
  }
}

class _AttendanceListItem extends StatelessWidget {
  final Attendance attendance;

  const _AttendanceListItem({required this.attendance});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: _getStatusColor(attendance.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('dd').format(attendance.date),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                ),
                Text(
                  DateFormat('E', 'vi').format(attendance.date),
                  style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.login, size: 14.w, color: AppColors.success),
                    SizedBox(width: 4.w),
                    Text(
                      attendance.checkInTime != null
                          ? timeFormat.format(attendance.checkInTime!)
                          : '--:--',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                    SizedBox(width: 16.w),
                    Icon(Icons.logout, size: 14.w, color: AppColors.warning),
                    SizedBox(width: 4.w),
                    Text(
                      attendance.checkOutTime != null
                          ? timeFormat.format(attendance.checkOutTime!)
                          : '--:--',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  attendance.workingHours != null
                      ? '${attendance.workingHours!.toStringAsFixed(1)} giờ làm việc'
                      : 'Chưa hoàn thành',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          _buildStatusBadge(attendance.status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AttendanceStatus status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present: return AppColors.success;
      case AttendanceStatus.late: return AppColors.warning;
      case AttendanceStatus.absent: return AppColors.error;
      case AttendanceStatus.leave: return AppColors.primary;
      case AttendanceStatus.earlyLeave: return AppColors.info;
      case AttendanceStatus.holiday: return AppColors.warning;
      case AttendanceStatus.weekend: return AppColors.textSecondary;
    }
  }
}
