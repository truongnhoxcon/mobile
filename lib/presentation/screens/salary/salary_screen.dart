import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/salary.dart';
import '../../../config/dependencies/injection_container.dart' as di;
import '../../blocs/blocs.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/pastel_background.dart';

/// Salary Screen - View personal salary with charts and details
class SalaryScreen extends StatelessWidget {
  const SalaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<MyInfoBloc>()..add(const MyInfoLoadData()),
      child: const _SalaryScreenContent(),
    );
  }
}

class _SalaryScreenContent extends StatefulWidget {
  const _SalaryScreenContent();

  @override
  State<_SalaryScreenContent> createState() => _SalaryScreenContentState();
}

class _SalaryScreenContentState extends State<_SalaryScreenContent> {
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bảng lương',
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
        actions: [
          // Year selector
          PopupMenuButton<int>(
            icon: Row(
              children: [
                Text('$_selectedYear', style: TextStyle(fontSize: 14.sp)),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
            onSelected: (year) => setState(() => _selectedYear = year),
            itemBuilder: (_) => List.generate(5, (i) {
              final year = DateTime.now().year - i;
              return PopupMenuItem(value: year, child: Text('$year'));
            }),
          ),
        ],
      ),
      body: PastelBackground(
        child: BlocBuilder<MyInfoBloc, MyInfoState>(
          builder: (context, state) {
            if (state.status == MyInfoStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == MyInfoStatus.error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64.w, color: AppColors.error),
                    SizedBox(height: 16.h),
                    Text(state.errorMessage ?? 'Có lỗi xảy ra'),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () => context.read<MyInfoBloc>().add(const MyInfoLoadData()),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }

            // Filter salaries by selected year
            final yearSalaries = state.mySalaries
                .where((s) => s.year == _selectedYear)
                .toList()
              ..sort((a, b) => b.month.compareTo(a.month));

            if (yearSalaries.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.paid_outlined, size: 64.w, color: AppColors.textSecondary),
                    SizedBox(height: 16.h),
                    Text('Chưa có bảng lương năm $_selectedYear',
                        style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary)),
                  ],
                ),
              );
            }

            final latestSalary = yearSalaries.first;
            final previousSalary = yearSalaries.length > 1 ? yearSalaries[1] : null;

            return RefreshIndicator(
              onRefresh: () async => context.read<MyInfoBloc>().add(const MyInfoLoadData()),
              child: ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  // Summary Card
                  _buildSummaryCard(yearSalaries, latestSalary, previousSalary),
                  SizedBox(height: 20.h),

                  // Salary Chart
                  _buildSalaryChart(yearSalaries),
                  SizedBox(height: 20.h),

                  // Latest Salary Details
                  _buildLatestSalaryDetails(latestSalary, previousSalary),
                  SizedBox(height: 20.h),

                  // Working Days Breakdown (Ngày công)
                  _buildWorkingDaysBreakdown(latestSalary),
                  SizedBox(height: 20.h),

                  // Allowances Breakdown (Phụ cấp)
                  if (latestSalary.totalAllowances > 0)
                    _buildAllowancesBreakdown(latestSalary),
                  if (latestSalary.totalAllowances > 0)
                    SizedBox(height: 20.h),

                  // OT Pay Breakdown (Tăng ca)
                  if (latestSalary.overtimeHours > 0)
                    _buildOvertimeBreakdown(latestSalary),
                  if (latestSalary.overtimeHours > 0)
                    SizedBox(height: 20.h),

                  // Bonus Breakdown (Thưởng)
                  if (latestSalary.totalBonus > 0)
                    _buildBonusBreakdown(latestSalary),
                  if (latestSalary.totalBonus > 0)
                    SizedBox(height: 20.h),

                  // Deductions Breakdown
                  _buildDeductionsBreakdown(latestSalary),
                  SizedBox(height: 20.h),

                  // Salary History
                  _buildSalaryHistory(yearSalaries),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(List<Salary> salaries, Salary latest, Salary? previous) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final totalNet = salaries.fold<double>(0, (sum, s) => sum + s.netSalary);
    final avgNet = totalNet / salaries.length;

    // Calculate trend
    double trendPercent = 0;
    if (previous != null && previous.netSalary > 0) {
      trendPercent = ((latest.netSalary - previous.netSalary) / previous.netSalary) * 100;
    }

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF10B981), const Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.white, size: 24.w),
              SizedBox(width: 8.w),
              Text('Lương tháng ${latest.month}/$_selectedYear',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14.sp)),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  formatter.format(latest.netSalary),
                  style: TextStyle(color: Colors.white, fontSize: 28.sp, fontWeight: FontWeight.bold),
                ),
              ),
              if (trendPercent != 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendPercent > 0 ? Icons.trending_up : Icons.trending_down,
                        color: trendPercent > 0 ? Colors.greenAccent : Colors.redAccent,
                        size: 16.w,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${trendPercent > 0 ? '+' : ''}${trendPercent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          Divider(color: Colors.white.withValues(alpha: 0.3)),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Tổng năm', formatter.format(totalNet)),
              _buildStatItem('Trung bình', formatter.format(avgNet)),
              _buildStatItem('Số tháng', '${salaries.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 11.sp)),
        SizedBox(height: 2.h),
        Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12.sp)),
      ],
    );
  }

  Widget _buildSalaryChart(List<Salary> salaries) {
    // Sort by month ascending for chart
    final chartData = List<Salary>.from(salaries)..sort((a, b) => a.month.compareTo(b.month));
    
    if (chartData.isEmpty) return const SizedBox();

    final maxSalary = chartData.map((s) => s.netSalary).reduce((a, b) => a > b ? a : b);
    final minSalary = chartData.map((s) => s.netSalary).reduce((a, b) => a < b ? a : b);
    final range = maxSalary - minSalary;

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
          Text('Biểu đồ lương $_selectedYear',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
          SizedBox(height: 20.h),
          SizedBox(
            height: 180.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: chartData.map((salary) {
                final height = range > 0
                    ? ((salary.netSalary - minSalary) / range * 120 + 40).h
                    : 100.h;
                final isLatest = salary.month == chartData.last.month;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${(salary.netSalary / 1000000).toStringAsFixed(1)}M',
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
                            color: isLatest ? AppColors.success : AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Container(
                          height: height,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isLatest
                                  ? [AppColors.success, AppColors.success.withValues(alpha: 0.7)]
                                  : [AppColors.primary.withValues(alpha: 0.6), AppColors.primary.withValues(alpha: 0.3)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text('T${salary.month}',
                            style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestSalaryDetails(Salary salary, Salary? previous) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

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
              Text('Chi tiết lương tháng ${salary.month}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
              const Spacer(),
              _buildStatusBadge(salary.status),
            ],
          ),
          SizedBox(height: 16.h),
          // Gross salary from contract
          _buildSalaryRow('Lương hợp đồng (Gross)', formatter.format(salary.grossSalary),
              comparison: previous != null ? salary.grossSalary - previous.grossSalary : null),
          _buildSalaryRow('Lương cơ bản', formatter.format(salary.baseSalary),
              comparison: previous != null ? salary.baseSalary - previous.baseSalary : null),
          _buildSalaryRow('Thưởng', '+${formatter.format(salary.totalBonus)}',
              isPositive: true,
              comparison: previous != null ? salary.totalBonus - previous.totalBonus : null),
          _buildSalaryRow('Khấu trừ', '-${formatter.format(salary.totalDeductions)}',
              isNegative: true,
              comparison: previous != null ? salary.totalDeductions - previous.totalDeductions : null,
              compareInvert: true),
          Divider(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Thực nhận', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
              Text(
                formatter.format(salary.netSalary),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          // Payment date if paid
          if (salary.status == SalaryStatus.paid && salary.paidAt != null) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 16.w),
                SizedBox(width: 6.w),
                Text(
                  'Đã thanh toán: ${DateFormat('dd/MM/yyyy').format(salary.paidAt!)}',
                  style: TextStyle(color: AppColors.success, fontSize: 12.sp),
                ),
              ],
            ),
          ],
          // Note if any
          if (salary.note != null && salary.note!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.notes, color: AppColors.warning, size: 16.w),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(salary.note!, style: TextStyle(fontSize: 12.sp)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSalaryRow(String label, String value,
      {bool isPositive = false, bool isNegative = false, double? comparison, bool compareInvert = false}) {
    Color valueColor = AppColors.textPrimary;
    if (isPositive) valueColor = AppColors.success;
    if (isNegative) valueColor = AppColors.error;

    Widget? comparisonWidget;
    if (comparison != null && comparison != 0) {
      final displayComparison = compareInvert ? -comparison : comparison;
      final isUp = displayComparison > 0;
      comparisonWidget = Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: (isUp ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward,
                size: 10.w, color: isUp ? AppColors.success : AppColors.error),
            Text(
              '${(comparison.abs() / 1000000).toStringAsFixed(1)}M',
              style: TextStyle(
                fontSize: 9.sp,
                color: isUp ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp))),
          if (comparisonWidget != null) ...[comparisonWidget, SizedBox(width: 8.w)],
          Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.w500, fontSize: 14.sp)),
        ],
      ),
    );
  }

  Widget _buildWorkingDaysBreakdown(Salary salary) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    
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
              Icon(Icons.calendar_today, color: AppColors.primary, size: 20.w),
              SizedBox(width: 8.w),
              Text('Ngày công tháng ${salary.month}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
            ],
          ),
          SizedBox(height: 16.h),
          
          // Working days progress
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tỷ lệ công',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp)),
                      SizedBox(height: 4.h),
                      Text(
                        '${salary.workingRatio.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24.sp,
                          color: salary.workingRatio >= 100 ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 60.w,
                  height: 60.w,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: (salary.workingRatio / 100).clamp(0.0, 1.0),
                        strokeWidth: 6,
                        backgroundColor: AppColors.border,
                        color: salary.workingRatio >= 100 ? AppColors.success : AppColors.warning,
                      ),
                      Center(
                        child: Text(
                          '${salary.totalPaidDays}/${salary.standardWorkingDays}',
                          style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          
          // Days breakdown
          _buildDaysRow(Icons.work, 'Ngày công chuẩn', salary.standardWorkingDays, AppColors.textSecondary),
          _buildDaysRow(Icons.check_circle, 'Ngày làm thực tế', salary.actualWorkingDays, AppColors.success),
          _buildDaysRow(Icons.beach_access, 'Nghỉ phép có lương', salary.paidLeaveDays, AppColors.primary,
              highlight: salary.paidLeaveDays > 0),
          if (salary.unpaidLeaveDays > 0)
            _buildDaysRow(Icons.event_busy, 'Nghỉ không lương', salary.unpaidLeaveDays, AppColors.warning),
          if (salary.sickLeaveDays > 0)
            _buildDaysRow(Icons.local_hospital, 'Nghỉ ốm (75% BHXH)', salary.sickLeaveDays, AppColors.info),
          if (salary.lateDays > 0)
            _buildDaysRow(Icons.schedule, 'Ngày đi trễ', salary.lateDays, AppColors.warning),
          if (salary.absentDays > 0)
            _buildDaysRow(Icons.cancel, 'Vắng không phép', salary.absentDays, AppColors.error),
          
          Divider(height: 20.h),
          
          Row(
            children: [
              Icon(Icons.paid, color: AppColors.success, size: 20.w),
              SizedBox(width: 8.w),
              Expanded(
                child: Text('Tổng ngày được tính lương',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${salary.totalPaidDays} ngày',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),
          
          if (salary.paidLeaveDays > 0) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 18.w),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Bạn có ${salary.paidLeaveDays} ngày nghỉ phép được tính lương (≈ ${formatter.format(salary.dailySalary * salary.paidLeaveDays)})',
                      style: TextStyle(color: AppColors.info, fontSize: 12.sp),
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

  Widget _buildDaysRow(IconData icon, String label, int days, Color color, {bool highlight = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Icon(icon, size: 18.w, color: color),
          SizedBox(width: 10.w),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14.sp))),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: highlight ? color.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              '$days ngày',
              style: TextStyle(
                fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                color: highlight ? color : AppColors.textPrimary,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeductionsBreakdown(Salary salary) {
    // Use actual values from Salary entity
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

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
          Text('Chi tiết khấu trừ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
          SizedBox(height: 16.h),
          _buildDeductionItem('BHXH (8%)', salary.bhxh, formatter, const Color(0xFF3B82F6)),
          _buildDeductionItem('BHYT (1.5%)', salary.bhyt, formatter, const Color(0xFF10B981)),
          _buildDeductionItem('BHTN (1%)', salary.bhtn, formatter, const Color(0xFF8B5CF6)),
          _buildDeductionItem('Thuế TNCN', salary.personalTax, formatter, const Color(0xFFEF4444)),
          if (salary.otherDeductions > 0)
            _buildDeductionItem('Khác', salary.otherDeductions, formatter, const Color(0xFF6B7280)),
          Divider(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng khấu trừ', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                formatter.format(salary.totalDeductions),
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeductionItem(String label, double amount, NumberFormat formatter, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3.r)),
          ),
          SizedBox(width: 8.w),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14.sp))),
          Text(formatter.format(amount), style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildAllowancesBreakdown(Salary salary) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

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
              Icon(Icons.wallet_giftcard, color: AppColors.success, size: 20.w),
              SizedBox(width: 8.w),
              Text('Chi tiết phụ cấp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
            ],
          ),
          SizedBox(height: 16.h),
          if (salary.mealAllowance > 0)
            _buildAllowanceItem('Phụ cấp ăn trưa', salary.mealAllowance, formatter, const Color(0xFF10B981)),
          if (salary.transportAllowance > 0)
            _buildAllowanceItem('Phụ cấp xăng xe', salary.transportAllowance, formatter, const Color(0xFF3B82F6)),
          if (salary.phoneAllowance > 0)
            _buildAllowanceItem('Phụ cấp điện thoại', salary.phoneAllowance, formatter, const Color(0xFF8B5CF6)),
          if (salary.housingAllowance > 0)
            _buildAllowanceItem('Phụ cấp nhà ở', salary.housingAllowance, formatter, const Color(0xFFF59E0B)),
          if (salary.otherAllowance > 0)
            _buildAllowanceItem('Phụ cấp khác', salary.otherAllowance, formatter, const Color(0xFF6B7280)),
          Divider(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng phụ cấp', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                formatter.format(salary.totalAllowances),
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllowanceItem(String label, double amount, NumberFormat formatter, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3.r)),
          ),
          SizedBox(width: 8.w),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14.sp))),
          Text('+${formatter.format(amount)}', style: TextStyle(fontSize: 14.sp, color: AppColors.success)),
        ],
      ),
    );
  }

  Widget _buildOvertimeBreakdown(Salary salary) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final hourlyRate = salary.hourlyRate;

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
              Icon(Icons.access_time_filled, color: AppColors.warning, size: 20.w),
              SizedBox(width: 8.w),
              Text('Chi tiết tăng ca', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
            ],
          ),
          SizedBox(height: 16.h),
          _buildOvertimeRow('Tổng giờ OT', '${salary.overtimeHours.toStringAsFixed(1)} giờ'),
          _buildOvertimeRow('Mức lương/giờ', formatter.format(hourlyRate)),
          _buildOvertimeRow('Hệ số ngày thường', 'x${salary.overtimeNormalRate.toStringAsFixed(1)} (150%)'),
          _buildOvertimeRow('Hệ số cuối tuần', 'x${salary.overtimeWeekendRate.toStringAsFixed(1)} (200%)'),
          _buildOvertimeRow('Hệ số ngày lễ', 'x${salary.overtimeHolidayRate.toStringAsFixed(1)} (300%)'),
          Divider(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tiền tăng ca', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '+${formatter.format(salary.overtimePay)}',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOvertimeRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14.sp)),
        ],
      ),
    );
  }

  Widget _buildBonusBreakdown(Salary salary) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

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
              Icon(Icons.emoji_events, color: AppColors.primary, size: 20.w),
              SizedBox(width: 8.w),
              Text('Chi tiết thưởng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
            ],
          ),
          SizedBox(height: 16.h),
          if (salary.performanceBonus > 0)
            _buildBonusItem('Thưởng hiệu suất', salary.performanceBonus, formatter, const Color(0xFF10B981)),
          if (salary.projectBonus > 0)
            _buildBonusItem('Thưởng dự án', salary.projectBonus, formatter, const Color(0xFF3B82F6)),
          if (salary.holidayBonus > 0)
            _buildBonusItem('Thưởng lễ/Tết', salary.holidayBonus, formatter, const Color(0xFFEF4444)),
          if (salary.otherBonus > 0)
            _buildBonusItem('Thưởng khác', salary.otherBonus, formatter, const Color(0xFF8B5CF6)),
          Divider(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng thưởng', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '+${formatter.format(salary.totalBonus)}',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBonusItem(String label, double amount, NumberFormat formatter, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3.r)),
          ),
          SizedBox(width: 8.w),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14.sp))),
          Text('+${formatter.format(amount)}', style: TextStyle(fontSize: 14.sp, color: AppColors.success)),
        ],
      ),
    );
  }

  Widget _buildSalaryHistory(List<Salary> salaries) {
    if (salaries.length <= 1) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Lịch sử lương $_selectedYear', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text('${salaries.length} tháng',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12.sp)),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        ...salaries.skip(1).map((s) => _SalaryHistoryItem(salary: s)),
      ],
    );
  }

  Widget _buildStatusBadge(SalaryStatus status) {
    Color color;
    switch (status) {
      case SalaryStatus.paid:
        color = AppColors.success;
      case SalaryStatus.pending:
        color = AppColors.warning;
      case SalaryStatus.cancelled:
        color = AppColors.textSecondary;
      case SalaryStatus.draft:
        color = AppColors.info;
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
}

class _SalaryHistoryItem extends StatefulWidget {
  final Salary salary;

  const _SalaryHistoryItem({required this.salary});

  @override
  State<_SalaryHistoryItem> createState() => _SalaryHistoryItemState();
}

class _SalaryHistoryItemState extends State<_SalaryHistoryItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final salary = widget.salary;
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _isExpanded ? AppColors.success : AppColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12.r),
            child: Padding(
              padding: EdgeInsets.all(14.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      'T${salary.month}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tháng ${salary.month}/${salary.year}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                        SizedBox(height: 2.h),
                        Text(formatter.format(salary.netSalary),
                            style: TextStyle(color: AppColors.success, fontSize: 14.sp)),
                      ],
                    ),
                  ),
                  _buildStatusBadge(salary.status),
                  SizedBox(width: 8.w),
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.w),
              child: Column(
                children: [
                  const Divider(height: 1),
                  SizedBox(height: 12.h),
                  _buildDetailRow('Lương cơ bản', formatter.format(salary.baseSalary)),
                  _buildDetailRow('Thưởng', '+${formatter.format(salary.totalBonus)}', isPositive: true),
                  _buildDetailRow('Khấu trừ', '-${formatter.format(salary.totalDeductions)}', isNegative: true),
                  Divider(height: 16.h),
                  _buildDetailRow('Thực nhận', formatter.format(salary.netSalary), isBold: true),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isPositive = false, bool isNegative = false, bool isBold = false}) {
    Color valueColor = AppColors.textPrimary;
    if (isPositive) valueColor = AppColors.success;
    if (isNegative) valueColor = AppColors.error;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
          Text(
            value,
            style: TextStyle(
              color: isBold ? AppColors.success : valueColor,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 15.sp : 13.sp,
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
      case SalaryStatus.pending:
        color = AppColors.warning;
      case SalaryStatus.cancelled:
        color = AppColors.textSecondary;
      case SalaryStatus.draft:
        color = AppColors.info;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: color, fontSize: 10.sp, fontWeight: FontWeight.bold),
      ),
    );
  }
}
