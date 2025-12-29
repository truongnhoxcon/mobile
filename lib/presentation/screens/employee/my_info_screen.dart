import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../config/dependencies/injection_container.dart' as di;
import '../../../domain/entities/contract.dart';
import '../../../domain/entities/salary.dart';
import '../../../domain/entities/evaluation.dart';
import '../../blocs/blocs.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/pastel_background.dart';

/// My Info Screen - View personal info with enhanced details
class MyInfoScreen extends StatefulWidget {
  const MyInfoScreen({super.key});

  @override
  State<MyInfoScreen> createState() => _MyInfoScreenState();
}

class _MyInfoScreenState extends State<MyInfoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<MyInfoBloc>()..add(const MyInfoLoadData()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Thông tin của tôi',
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
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'Hợp đồng', icon: Icon(Icons.description)),
              Tab(text: 'Lương', icon: Icon(Icons.paid)),
              Tab(text: 'Đánh giá', icon: Icon(Icons.rate_review)),
            ],
          ),
        ),
        body: PastelBackground(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _MyContractsTab(),
              _MySalaryTab(),
              _MyEvaluationsTab(),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// My Contracts Tab - Enhanced with expandable details
// ============================================================================
class _MyContractsTab extends StatelessWidget {
  const _MyContractsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyInfoBloc, MyInfoState>(
      builder: (context, state) {
        if (state.status == MyInfoStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == MyInfoStatus.error) {
          return _buildErrorView(context, state.errorMessage);
        }

        final contracts = state.myContracts;
        if (contracts.isEmpty) {
          return _buildEmptyView(Icons.description_outlined, 'Chưa có hợp đồng');
        }

        // Find active contract
        final activeContract = contracts.where((c) => c.status == ContractStatus.active).toList();
        
        return RefreshIndicator(
          onRefresh: () async => context.read<MyInfoBloc>().add(const MyInfoLoadData()),
          child: ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              // Summary Card
              if (activeContract.isNotEmpty)
                _buildContractSummary(activeContract.first),
              
              SizedBox(height: 16.h),
              
              // Section Header
              _buildSectionHeader('Tất cả hợp đồng', contracts.length),
              SizedBox(height: 12.h),
              
              // Contract List
              ...contracts.map((c) => _ContractCard(contract: c)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContractSummary(Contract contract) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: Colors.white, size: 24.w),
              SizedBox(width: 8.w),
              Text(
                'Hợp đồng hiện tại',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            contract.type.displayName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              _buildSummaryItem(Icons.calendar_today, 
                '${contract.daysUntilExpiry != null && contract.daysUntilExpiry! > 0 ? contract.daysUntilExpiry : 0} ngày còn lại'),
              SizedBox(width: 24.w),
              _buildSummaryItem(Icons.timer, 
                '${contract.durationMonths ?? 0} tháng'),
            ],
          ),
          if (contract.isExpiringSoon) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber, color: Colors.black87, size: 16.w),
                  SizedBox(width: 6.w),
                  Text(
                    'Sắp hết hạn!',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
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

  Widget _buildSummaryItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16.w),
        SizedBox(width: 4.w),
        Text(
          text,
          style: TextStyle(color: Colors.white, fontSize: 13.sp),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text(
            '$count',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12.sp),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context, String? message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.w, color: AppColors.error),
          SizedBox(height: 16.h),
          Text(message ?? 'Có lỗi xảy ra'),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () => context.read<MyInfoBloc>().add(const MyInfoLoadData()),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64.w, color: AppColors.textSecondary),
          SizedBox(height: 16.h),
          Text(message, style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// Expandable Contract Card
class _ContractCard extends StatefulWidget {
  final Contract contract;
  const _ContractCard({required this.contract});

  @override
  State<_ContractCard> createState() => _ContractCardState();
}

class _ContractCardState extends State<_ContractCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final contract = widget.contract;
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _isExpanded ? AppColors.primary : AppColors.border),
      ),
      child: Column(
        children: [
          // Header (always visible)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12.r),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contract.type.displayName,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${DateFormat('dd/MM/yyyy').format(contract.startDate)} - ${contract.endDate != null ? DateFormat('dd/MM/yyyy').format(contract.endDate!) : 'Không xác định'}',
                          style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(contract.status),
                  SizedBox(width: 8.w),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded Details
          if (_isExpanded)
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.w),
              child: Column(
                children: [
                  Divider(height: 1),
                  SizedBox(height: 16.h),
                  _buildDetailRow('Loại hợp đồng', contract.type.displayName),
                  _buildDetailRow('Ngày bắt đầu', DateFormat('dd/MM/yyyy').format(contract.startDate)),
                  _buildDetailRow('Ngày kết thúc', contract.endDate != null ? DateFormat('dd/MM/yyyy').format(contract.endDate!) : 'Không xác định'),
                  _buildDetailRow('Thời hạn', '${contract.durationMonths ?? "Không xác định"} tháng'),
                  if (contract.grossSalary > 0)
                    _buildDetailRow('Mức lương', formatter.format(contract.grossSalary)),
                  _buildDetailRow('Trạng thái', contract.status.displayName),
                  if (contract.note != null && contract.note!.isNotEmpty)
                    _buildDetailRow('Ghi chú', contract.note!),
                  if (contract.isExpiringSoon) ...[
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: AppColors.warning, size: 20.w),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'Hợp đồng còn ${contract.daysUntilExpiry} ngày. Vui lòng liên hệ HR để gia hạn.',
                              style: TextStyle(color: AppColors.warning, fontSize: 13.sp),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13.sp)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ContractStatus status) {
    Color color;
    switch (status) {
      case ContractStatus.active:
        color = AppColors.success;
      case ContractStatus.pending:
        color = AppColors.warning;
      case ContractStatus.expired:
        color = AppColors.error;
      case ContractStatus.terminated:
        color = AppColors.error;
      case ContractStatus.draft:
        color = AppColors.textSecondary;
      case ContractStatus.renewed:
        color = AppColors.primary;
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

// ============================================================================
// My Salary Tab - Enhanced with summary and trend
// ============================================================================
class _MySalaryTab extends StatelessWidget {
  const _MySalaryTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyInfoBloc, MyInfoState>(
      builder: (context, state) {
        if (state.status == MyInfoStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final salaries = state.mySalaries;
        if (salaries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.paid_outlined, size: 64.w, color: AppColors.textSecondary),
                SizedBox(height: 16.h),
                Text('Chưa có bảng lương', 
                  style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        // Sort by date desc
        final sortedSalaries = List<Salary>.from(salaries)
          ..sort((a, b) {
            final dateA = DateTime(a.year, a.month);
            final dateB = DateTime(b.year, b.month);
            return dateB.compareTo(dateA);
          });

        // Calculate stats
        final totalNetSalary = salaries.fold<double>(0, (sum, s) => sum + s.netSalary);
        final avgSalary = salaries.isNotEmpty ? (totalNetSalary / salaries.length).toDouble() : 0.0;
        final latestSalary = sortedSalaries.isNotEmpty ? sortedSalaries.first : null;
        final previousSalary = sortedSalaries.length > 1 ? sortedSalaries[1] : null;
        
        // Calculate trend
        double trendPercent = 0;
        if (latestSalary != null && previousSalary != null && previousSalary.netSalary > 0) {
          trendPercent = ((latestSalary.netSalary - previousSalary.netSalary) / previousSalary.netSalary) * 100;
        }

        final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

        return RefreshIndicator(
          onRefresh: () async => context.read<MyInfoBloc>().add(const MyInfoLoadData()),
          child: ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              // Summary Card
              _buildSalarySummary(
                latestSalary: latestSalary,
                avgSalary: avgSalary,
                trendPercent: trendPercent,
                formatter: formatter,
              ),
              
              SizedBox(height: 20.h),
              
              // Section Header
              Row(
                children: [
                  Text('Lịch sử lương', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      '${salaries.length} tháng',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12.sp),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              
              // Salary List
              ...sortedSalaries.map((s) => _SalaryCard(salary: s)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSalarySummary({
    required Salary? latestSalary,
    required double avgSalary,
    required double trendPercent,
    required NumberFormat formatter,
  }) {
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
              Text(
                'Lương gần nhất',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14.sp),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  latestSalary != null ? formatter.format(latestSalary.netSalary) : '--',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                  ),
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
                        color: Colors.white,
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
              _buildStatItem('Trung bình', formatter.format(avgSalary)),
              if (latestSalary != null)
                _buildStatItem('Kỳ', 'T${latestSalary.month}/${latestSalary.year}'),
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
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
        SizedBox(height: 2.h),
        Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14.sp)),
      ],
    );
  }
}

/// Expandable Salary Card
class _SalaryCard extends StatefulWidget {
  final Salary salary;
  const _SalaryCard({required this.salary});

  @override
  State<_SalaryCard> createState() => _SalaryCardState();
}

class _SalaryCardState extends State<_SalaryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final salary = widget.salary;
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
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
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.receipt_long, color: AppColors.success, size: 24.w),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tháng ${salary.month}/${salary.year}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          formatter.format(salary.netSalary),
                          style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 14.sp),
                        ),
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
                  Divider(height: 1),
                  SizedBox(height: 16.h),
                  _buildSalaryRow('Lương cơ bản', formatter.format(salary.baseSalary)),
                  if (salary.totalBonus > 0)
                    _buildSalaryRow('Thưởng', '+${formatter.format(salary.totalBonus)}', isPositive: true),
                  if (salary.totalDeductions > 0)
                    _buildSalaryRow('Khấu trừ', '-${formatter.format(salary.totalDeductions)}', isNegative: true),
                  Divider(height: 20.h),
                  _buildSalaryRow('Thực nhận', formatter.format(salary.netSalary), isBold: true),
                  if (salary.note != null && salary.note!.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'Ghi chú: ${salary.note}',
                        style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSalaryRow(String label, String value, {bool isPositive = false, bool isNegative = false, bool isBold = false}) {
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
              color: valueColor,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 16.sp : 13.sp,
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

// ============================================================================
// My Evaluations Tab - Enhanced with score comparison
// ============================================================================
class _MyEvaluationsTab extends StatelessWidget {
  const _MyEvaluationsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyInfoBloc, MyInfoState>(
      builder: (context, state) {
        if (state.status == MyInfoStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final evaluations = state.myEvaluations;
        if (evaluations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rate_review_outlined, size: 64.w, color: AppColors.textSecondary),
                SizedBox(height: 16.h),
                Text('Chưa có đánh giá', 
                  style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        // Sort by date desc
        final sortedEvaluations = List<Evaluation>.from(evaluations)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Calculate stats
        final avgScore = evaluations.fold<double>(0, (sum, e) => sum + (e.finalScore ?? 0)) / evaluations.length;
        final latestEval = sortedEvaluations.first;

        return RefreshIndicator(
          onRefresh: () async => context.read<MyInfoBloc>().add(const MyInfoLoadData()),
          child: ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              // Summary Card
              _buildEvaluationSummary(latestEval, avgScore, evaluations.length),
              
              SizedBox(height: 20.h),
              
              // Section Header
              Row(
                children: [
                  Text('Lịch sử đánh giá', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      '${evaluations.length} kỳ',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12.sp),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              
              // Evaluation List
              ...sortedEvaluations.map((e) => _EvaluationCard(evaluation: e)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEvaluationSummary(Evaluation latest, double avgScore, int totalCount) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
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
              Icon(Icons.emoji_events, color: Colors.white, size: 24.w),
              SizedBox(width: 8.w),
              Text(
                'Đánh giá gần nhất',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14.sp),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(latest.finalScore ?? 0).toStringAsFixed(0)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8.w),
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Text(
                  'điểm',
                  style: TextStyle(color: Colors.white70, fontSize: 16.sp),
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  latest.grade,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trung bình', style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
                  SizedBox(height: 2.h),
                  Text('${avgScore.toStringAsFixed(1)} điểm', 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14.sp)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Kỳ', style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
                  SizedBox(height: 2.h),
                  Text(latest.period, 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14.sp)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Expandable Evaluation Card
class _EvaluationCard extends StatefulWidget {
  final Evaluation evaluation;
  const _EvaluationCard({required this.evaluation});

  @override
  State<_EvaluationCard> createState() => _EvaluationCardState();
}

class _EvaluationCardState extends State<_EvaluationCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final evaluation = widget.evaluation;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _isExpanded ? _getScoreColor(evaluation.finalScore ?? 0) : AppColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12.r),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Container(
                    width: 50.w,
                    height: 50.w,
                    decoration: BoxDecoration(
                      color: _getScoreColor(evaluation.finalScore ?? 0).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                    child: Center(
                      child: Text(
                        evaluation.grade,
                        style: TextStyle(
                          color: _getScoreColor(evaluation.finalScore ?? 0),
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          evaluation.period,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '${(evaluation.finalScore ?? 0).toStringAsFixed(0)} điểm',
                          style: TextStyle(color: _getScoreColor(evaluation.finalScore ?? 0), fontSize: 14.sp),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(evaluation.status),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(height: 1),
                  SizedBox(height: 16.h),
                  _buildDetailRow('Kỳ đánh giá', evaluation.period),
                  _buildDetailRow('Điểm số', '${(evaluation.finalScore ?? 0).toStringAsFixed(0)}/100'),
                  _buildDetailRow('Xếp loại', evaluation.grade),
                  _buildDetailRow('Trạng thái', evaluation.status.displayName),
                  if (evaluation.evaluatorName != null)
                    _buildDetailRow('Người đánh giá', evaluation.evaluatorName!),
                  if (evaluation.managerSummary != null && evaluation.managerSummary!.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Text('Nhận xét:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp)),
                    SizedBox(height: 8.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        evaluation.managerSummary!,
                        style: TextStyle(fontSize: 13.sp, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13.sp)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(EvaluationStatus status) {
    Color color;
    switch (status) {
      case EvaluationStatus.approved:
        color = AppColors.success;
      case EvaluationStatus.submitted:
        color = AppColors.warning;
      case EvaluationStatus.reviewed:
        color = AppColors.info;
      case EvaluationStatus.rejected:
        color = AppColors.error;
      case EvaluationStatus.draft:
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

  Color _getScoreColor(double score) {
    if (score >= 90) return AppColors.success;
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 70) return AppColors.info;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }
}
