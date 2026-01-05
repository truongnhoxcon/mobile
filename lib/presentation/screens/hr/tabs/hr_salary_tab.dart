import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/salary.dart';
import '../../../blocs/blocs.dart';

/// HR Salary Tab - Quản lý bảng lương
class HRSalaryTab extends StatefulWidget {
  const HRSalaryTab({super.key});

  @override
  State<HRSalaryTab> createState() => _HRSalaryTabState();
}

class _HRSalaryTabState extends State<HRSalaryTab> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
  }

  void _loadSalaries() {
    context.read<HRBloc>().add(HRLoadSalaries(
      month: _selectedMonth,
      year: _selectedYear,
    ));
  }

  void _showGenerateSalariesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tạo bảng lương'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tạo bảng lương cho tháng $_selectedMonth/$_selectedYear?'),
            SizedBox(height: 12),
            Text(
              '• Lương sẽ được tính dựa trên lương cơ bản của nhân viên\n'
              '• Ngày nghỉ phép có lương sẽ được tính đủ lương\n'
              '• Ngày nghỉ không lương sẽ bị trừ\n'
              '• BHXH, BHYT, BHTN và thuế TNCN sẽ được khấu trừ tự động',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<HRBloc>().add(HRGenerateSalaries(
                month: _selectedMonth,
                year: _selectedYear,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Tạo bảng lương'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Month/Year Selector
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bảng lương',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedMonth == 1) {
                          _selectedMonth = 12;
                          _selectedYear--;
                        } else {
                          _selectedMonth--;
                        }
                      });
                      _loadSalaries();
                    },
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'Tháng $_selectedMonth/$_selectedYear',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedMonth == 12) {
                          _selectedMonth = 1;
                          _selectedYear++;
                        } else {
                          _selectedMonth++;
                        }
                      });
                      _loadSalaries();
                    },
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Salaries List
        Expanded(
          child: BlocBuilder<HRBloc, HRState>(
            builder: (context, state) {
              if (state.status == HRStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              final salaries = state.salaries;
              if (salaries.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.paid_outlined, size: 64.w, color: AppColors.textSecondary),
                      SizedBox(height: 16.h),
                      Text(
                        'Không có dữ liệu lương',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Tháng $_selectedMonth/$_selectedYear',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textHint,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      ElevatedButton.icon(
                        onPressed: () => _showGenerateSalariesDialog(context),
                        icon: const Icon(Icons.add_chart),
                        label: const Text('Tạo bảng lương tháng này'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Calculate totals
              double totalNet = salaries.fold(0, (sum, s) => sum + s.netSalary);
              int paidCount = salaries.where((s) => s.status == SalaryStatus.paid).length;

              return RefreshIndicator(
                onRefresh: () async => _loadSalaries(),
                child: ListView(
                  padding: EdgeInsets.all(16.w),
                  children: [
                    // Summary Card
                    _buildSummaryCard(totalNet, paidCount, salaries.length),
                    SizedBox(height: 16.h),
                    
                    // Salary List
                    ...salaries.map((salary) => _buildSalaryCard(salary)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(double totalNet, int paidCount, int totalCount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng lương tháng $_selectedMonth/$_selectedYear',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            formatter.format(totalNet),
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _buildMiniStat('Đã thanh toán', '$paidCount/$totalCount', Icons.check_circle),
              SizedBox(width: 24.w),
              _buildMiniStat('Tổng NV', '$totalCount', Icons.people),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16.w),
        SizedBox(width: 6.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white70, fontSize: 10.sp)),
            Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp)),
          ],
        ),
      ],
    );
  }

  Widget _buildSalaryCard(Salary salary) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: _getAvatarColor(salary.employeeName ?? 'U'),
                child: Text(
                  (salary.employeeName ?? 'U')[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      salary.employeeName ?? 'Nhân viên',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Kỳ lương: ${salary.periodString}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(salary.status),
            ],
          ),

          SizedBox(height: 12.h),

          // Salary Details
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              children: [
                _buildSalaryRow('Lương cơ bản', formatter.format(salary.baseSalary)),
                if (salary.totalBonus > 0)
                  _buildSalaryRow('Thưởng', '+${formatter.format(salary.totalBonus)}', isPositive: true),
                if (salary.totalDeductions > 0)
                  _buildSalaryRow('Khấu trừ', '-${formatter.format(salary.totalDeductions)}', isNegative: true),
                Divider(height: 16.h),
                _buildSalaryRow('Thực nhận', formatter.format(salary.netSalary), isBold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryRow(String label, String value, {bool isBold = false, bool isPositive = false, bool isNegative = false}) {
    Color valueColor = AppColors.textPrimary;
    if (isPositive) valueColor = AppColors.success;
    if (isNegative) valueColor = AppColors.error;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? AppColors.primary : valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(SalaryStatus status) {
    Color color;
    switch (status) {
      case SalaryStatus.paid:
        color = AppColors.success;
        break;
      case SalaryStatus.pending:
        color = AppColors.warning;
        break;
      case SalaryStatus.cancelled:
        color = AppColors.error;
        break;
      case SalaryStatus.draft:
        color = AppColors.info;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return HSLColor.fromAHSL(1.0, (hash % 360).toDouble(), 0.6, 0.5).toColor();
  }
}
