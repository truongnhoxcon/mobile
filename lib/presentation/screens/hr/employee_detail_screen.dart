import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/employee.dart';
import '../../blocs/blocs.dart';

/// Employee Detail Screen - Chi tiết thông tin nhân viên
class EmployeeDetailScreen extends StatelessWidget {
  final Employee employee;

  const EmployeeDetailScreen({super.key, required this.employee});

  Color _getStatusColor(EmployeeStatus status) {
    switch (status) {
      case EmployeeStatus.working:
        return AppColors.success;
      case EmployeeStatus.tempOff:
        return AppColors.warning;
      case EmployeeStatus.terminated:
        return AppColors.error;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            SizedBox(width: 8.w),
            const Text('Xác nhận xóa'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc chắn muốn xóa nhân viên này?'),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20.r,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      employee.hoTen[0].toUpperCase(),
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(employee.hoTen, style: TextStyle(fontWeight: FontWeight.bold)),
                        if (employee.email != null)
                          Text(employee.email!, style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              '⚠️ Hành động này không thể hoàn tác!',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w500, fontSize: 12.sp),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<HRBloc>().add(HRDeleteEmployee(employeeId: employee.id));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đang xóa nhân viên ${employee.hoTen}...'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(employee.status);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Avatar
          SliverAppBar(
            expandedHeight: 220.h,
            pinned: true,
            actions: [
              IconButton(
                onPressed: () => _showDeleteConfirmation(context),
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Xóa nhân viên',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 30.h),
                      // Avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 40.r,
                          backgroundColor: Colors.white,
                          backgroundImage: employee.avatarUrl != null 
                              ? NetworkImage(employee.avatarUrl!) 
                              : null,
                          child: employee.avatarUrl == null
                              ? Text(
                                  employee.hoTen[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 32.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        employee.hoTen,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          employee.status.displayName,
                          style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  // Quick Info Cards
                  Row(
                    children: [
                      Expanded(child: _QuickInfoCard(icon: Icons.badge, label: 'Mã NV', value: employee.maNhanVien ?? 'N/A')),
                      SizedBox(width: 12.w),
                      Expanded(child: _QuickInfoCard(icon: Icons.business, label: 'Phòng ban', value: employee.tenPhongBan ?? 'Chưa có')),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(child: _QuickInfoCard(icon: Icons.work, label: 'Chức vụ', value: employee.tenChucVu ?? 'Chưa có')),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _QuickInfoCard(
                          icon: Icons.calendar_today,
                          label: 'Vào làm',
                          value: employee.ngayVaoLam != null ? dateFormat.format(employee.ngayVaoLam!) : 'N/A',
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Personal Info Section
                  _SectionHeader(title: 'Thông tin cá nhân', icon: Icons.person),
                  SizedBox(height: 12.h),
                  _InfoCard(
                    children: [
                      _InfoRow(icon: Icons.email, label: 'Email', value: employee.email ?? 'Chưa có'),
                      _InfoRow(icon: Icons.phone, label: 'Số điện thoại', value: employee.soDienThoai ?? 'Chưa có'),
                      _InfoRow(icon: Icons.credit_card, label: 'CCCD', value: employee.cccd ?? 'Chưa có'),
                      _InfoRow(
                        icon: Icons.cake,
                        label: 'Ngày sinh',
                        value: employee.ngaySinh != null ? dateFormat.format(employee.ngaySinh!) : 'Chưa có',
                      ),
                      _InfoRow(
                        icon: employee.gioiTinh == 'Nam' ? Icons.male : Icons.female,
                        label: 'Giới tính',
                        value: employee.gioiTinh,
                      ),
                      _InfoRow(icon: Icons.location_on, label: 'Địa chỉ', value: employee.diaChi ?? 'Chưa có'),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Work Info Section
                  _SectionHeader(title: 'Thông tin công việc', icon: Icons.work_outline),
                  SizedBox(height: 12.h),
                  _InfoCard(
                    children: [
                      _InfoRow(icon: Icons.business, label: 'Phòng ban', value: employee.tenPhongBan ?? 'Chưa phân bổ'),
                      _InfoRow(icon: Icons.workspace_premium, label: 'Chức vụ', value: employee.tenChucVu ?? 'Chưa có chức vụ'),
                      _InfoRow(
                        icon: Icons.calendar_month,
                        label: 'Ngày vào làm',
                        value: employee.ngayVaoLam != null ? dateFormat.format(employee.ngayVaoLam!) : 'Chưa có',
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Salary Info Section
                  _SectionHeader(title: 'Thông tin lương', icon: Icons.attach_money),
                  SizedBox(height: 12.h),
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.money,
                        label: 'Lương cơ bản',
                        value: employee.luongCoBan != null
                            ? NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(employee.luongCoBan)
                            : 'Chưa có',
                        valueColor: AppColors.success,
                      ),
                      _InfoRow(
                        icon: Icons.add_circle,
                        label: 'Phụ cấp',
                        value: employee.phuCap != null
                            ? NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(employee.phuCap)
                            : 'Chưa có',
                        valueColor: AppColors.info,
                      ),
                      if (employee.luongCoBan != null)
                        _InfoRow(
                          icon: Icons.account_balance_wallet,
                          label: 'Tổng thu nhập',
                          value: NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                              .format((employee.luongCoBan ?? 0) + (employee.phuCap ?? 0)),
                          valueColor: AppColors.primary,
                          isBold: true,
                        ),
                    ],
                  ),

                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _QuickInfoCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, size: 16.w, color: AppColors.primary),
              ),
              SizedBox(width: 8.w),
              Text(label, style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
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
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          Icon(icon, size: 20.w, color: AppColors.textSecondary),
          SizedBox(width: 12.w),
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: valueColor ?? AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
