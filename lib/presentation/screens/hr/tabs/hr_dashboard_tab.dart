import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../blocs/blocs.dart';

/// HR Dashboard Tab - Thống kê tổng quan cho HR Manager
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64.w, color: AppColors.error),
                SizedBox(height: 16.h),
                Text(
                  state.errorMessage ?? 'Có lỗi xảy ra',
                  style: TextStyle(color: AppColors.error, fontSize: 16.sp),
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () {
                    context.read<HRBloc>().add(const HRLoadDashboard());
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
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
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📊 Thống kê nhân sự',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 16.h),
                
                // KPI Cards Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  childAspectRatio: 1.0,
                  children: [
                    _buildKPICard(
                      icon: Icons.people,
                      label: 'Tổng nhân viên',
                      value: '${stats.tongNhanVien}',
                      color: AppColors.primary,
                    ),
                    _buildKPICard(
                      icon: Icons.person_add,
                      label: 'Nhân viên mới',
                      value: '${stats.nhanVienMoi}',
                      color: AppColors.success,
                      subtitle: 'Tháng này',
                    ),
                    _buildKPICard(
                      icon: Icons.person_off,
                      label: 'Nghỉ việc',
                      value: '${stats.nghiViec}',
                      color: AppColors.error,
                    ),
                    _buildKPICard(
                      icon: Icons.pending_actions,
                      label: 'Đơn chờ duyệt',
                      value: '${stats.donChoPheDuyet}',
                      color: AppColors.warning,
                    ),
                  ],
                ),
                
                SizedBox(height: 24.h),
                
                // Gender Distribution
                _buildSectionTitle('Phân bố giới tính'),
                SizedBox(height: 12.h),
                _buildGenderCard(stats),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKPICard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 22.w),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10.sp,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildGenderCard(dynamic stats) {
    final genderStats = stats.nhanVienTheoGioiTinh;
    if (genderStats == null) return const SizedBox.shrink();
    
    final male = genderStats['nam'] ?? 0;
    final female = genderStats['nu'] ?? 0;
    final total = male + female;
    
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildGenderItem(
            icon: Icons.male,
            label: 'Nam',
            count: male,
            total: total,
            color: Colors.blue,
          ),
          Container(
            width: 1,
            height: 80.h,
            color: AppColors.border,
          ),
          _buildGenderItem(
            icon: Icons.female,
            label: 'Nữ',
            count: female,
            total: total,
            color: Colors.pink,
          ),
        ],
      ),
    );
  }

  Widget _buildGenderItem({
    required IconData icon,
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0';
    
    return Column(
      children: [
        Icon(icon, size: 48.w, color: color),
        SizedBox(height: 8.h),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          '$label ($percentage%)',
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
