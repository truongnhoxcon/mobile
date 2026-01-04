import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../blocs/blocs.dart';

/// HR Dashboard Tab - Premium thống kê tổng quan cho HR Manager
class HRDashboardTab extends StatelessWidget {
  const HRDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HRBloc, HRState>(
      builder: (context, state) {
        if (state.status == HRStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == HRStatus.error) {
          return _buildErrorState(context, state);
        }

        final stats = state.dashboardStats;
        if (stats == null) {
          return const Center(child: Text('Không có dữ liệu'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<HRBloc>().add(const HRLoadDashboard());
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Header with Gradient
                _buildWelcomeHeader(stats),
                
                // Quick Stats Row
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _buildQuickStatsRow(stats),
                ),
                
                SizedBox(height: 20.h),
                
                // KPI Cards Section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _buildSectionHeader('Thống kê chi tiết', Icons.analytics),
                ),
                SizedBox(height: 12.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _buildKPIGrid(stats),
                ),
                
                SizedBox(height: 24.h),
                
                // Gender Distribution Section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _buildSectionHeader('Phân bố nhân sự', Icons.pie_chart),
                ),
                SizedBox(height: 12.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _buildGenderCard(stats),
                ),
                
                SizedBox(height: 24.h),
                
                // Recent Activities
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _buildSectionHeader('Hoạt động gần đây', Icons.history),
                ),
                SizedBox(height: 12.h),
                _buildRecentActivities(),
                
                SizedBox(height: 100.h),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, HRState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, size: 48.w, color: AppColors.error),
          ),
          SizedBox(height: 16.h),
          Text(
            state.errorMessage ?? 'Có lỗi xảy ra',
            style: TextStyle(color: AppColors.error, fontSize: 16.sp),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.h),
          ElevatedButton.icon(
            onPressed: () => context.read<HRBloc>().add(const HRLoadDashboard()),
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(dynamic stats) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.info, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.info.withOpacity(0.3),
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
            child: Icon(Icons.people_alt, color: Colors.white, size: 32.w),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quản lý Nhân sự',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${stats.tongNhanVien} nhân viên • ${stats.donChoPheDuyet} đơn chờ duyệt',
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

  Widget _buildQuickStatsRow(dynamic stats) {
    return SizedBox(
      height: 100.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _QuickStatCard(icon: Icons.people, label: 'Tổng NV', value: '${stats.tongNhanVien}', color: AppColors.primary),
          _QuickStatCard(icon: Icons.person_add, label: 'NV mới', value: '${stats.nhanVienMoi}', color: AppColors.success),
          _QuickStatCard(icon: Icons.pending_actions, label: 'Chờ duyệt', value: '${stats.donChoPheDuyet}', color: AppColors.warning),
          _QuickStatCard(icon: Icons.person_off, label: 'Nghỉ việc', value: '${stats.nghiViec}', color: AppColors.error),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20.w),
        ),
        SizedBox(width: 12.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildKPIGrid(dynamic stats) {
    return Row(
      children: [
        Expanded(
          child: _KPICard(
            icon: Icons.trending_up,
            label: 'Tăng trưởng',
            value: '+${stats.nhanVienMoi}',
            subtitle: 'Tháng này',
            color: AppColors.success,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _KPICard(
            icon: Icons.access_time,
            label: 'Chấm công',
            value: '${stats.tongNhanVien}',
            subtitle: 'Hôm nay',
            color: AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildGenderCard(dynamic stats) {
    final genderStats = stats.nhanVienTheoGioiTinh;
    if (genderStats == null) return const SizedBox.shrink();
    
    final male = genderStats['nam'] ?? 0;
    final female = genderStats['nu'] ?? 0;
    final total = male + female;
    final malePercent = total > 0 ? (male / total * 100) : 0.0;
    final femalePercent = total > 0 ? (female / total * 100) : 0.0;
    
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _GenderStat(icon: Icons.male, label: 'Nam', count: male, percent: malePercent, color: Colors.blue)),
              Container(width: 1, height: 80.h, color: AppColors.border),
              Expanded(child: _GenderStat(icon: Icons.female, label: 'Nữ', count: female, percent: femalePercent, color: Colors.pink)),
            ],
          ),
          SizedBox(height: 16.h),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Row(
              children: [
                Expanded(
                  flex: male,
                  child: Container(height: 8.h, color: Colors.blue),
                ),
                Expanded(
                  flex: female,
                  child: Container(height: 8.h, color: Colors.pink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    final activities = [
      {'icon': Icons.person_add, 'text': 'Nhân viên mới được thêm', 'time': '2 giờ trước', 'color': AppColors.success},
      {'icon': Icons.event_busy, 'text': 'Đơn xin nghỉ phép mới', 'time': '5 giờ trước', 'color': AppColors.warning},
      {'icon': Icons.check_circle, 'text': 'Đơn nghỉ phép đã duyệt', 'time': 'Hôm qua', 'color': AppColors.info},
    ];
    
    return Column(
      children: activities.map((activity) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: (activity['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(activity['icon'] as IconData, color: activity['color'] as Color, size: 20.w),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['text'] as String,
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      activity['time'] as String,
                      style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 85.w,
      margin: EdgeInsets.only(right: 10.w),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22.w),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: color)),
            ),
          ),
          Text(label, style: TextStyle(fontSize: 10.sp, color: color), overflow: TextOverflow.ellipsis, maxLines: 1),
        ],
      ),
    );
  }
}

class _KPICard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _KPICard({required this.icon, required this.label, required this.value, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: color, size: 20.w),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(subtitle, style: TextStyle(fontSize: 10.sp, color: color, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(value, style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _GenderStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final double percent;
  final Color color;

  const _GenderStat({required this.icon, required this.label, required this.count, required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32.w, color: color),
        ),
        SizedBox(height: 8.h),
        Text('$count', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: color)),
        Text('$label (${percent.toStringAsFixed(1)}%)', style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary)),
      ],
    );
  }
}
