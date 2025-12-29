import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/contract.dart';
import '../../../blocs/blocs.dart';

/// HR Contracts Tab - Quản lý hợp đồng lao động
class HRContractsTab extends StatefulWidget {
  const HRContractsTab({super.key});

  @override
  State<HRContractsTab> createState() => _HRContractsTabState();
}

class _HRContractsTabState extends State<HRContractsTab> {
  String _statusFilter = 'all';

  void _loadContracts() {
    context.read<HRBloc>().add(HRLoadContracts(
      statusFilter: _statusFilter == 'all' ? null : _statusFilter,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter Bar
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Hợp đồng lao động',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                initialValue: _statusFilter,
                onSelected: (value) {
                  setState(() => _statusFilter = value);
                  _loadContracts();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'all', child: Text('Tất cả')),
                  const PopupMenuItem(value: 'active', child: Text('Đang hiệu lực')),
                  const PopupMenuItem(value: 'expired', child: Text('Hết hạn')),
                  const PopupMenuItem(value: 'pending', child: Text('Chờ duyệt')),
                ],
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getFilterLabel(_statusFilter),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 20.w),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Contracts List
        Expanded(
          child: BlocBuilder<HRBloc, HRState>(
            builder: (context, state) {
              if (state.status == HRStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              final contracts = state.contracts;
              if (contracts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined, size: 64.w, color: AppColors.textSecondary),
                      SizedBox(height: 16.h),
                      Text(
                        'Không có hợp đồng nào',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _loadContracts(),
                child: ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: contracts.length,
                  itemBuilder: (context, index) {
                    return _buildContractCard(contracts[index]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'active':
        return 'Đang hiệu lực';
      case 'expired':
        return 'Hết hạn';
      case 'pending':
        return 'Chờ duyệt';
      default:
        return 'Tất cả';
    }
  }

  Widget _buildContractCard(Contract contract) {
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
                backgroundColor: _getContractTypeColor(contract.type),
                child: Icon(
                  Icons.description,
                  color: Colors.white,
                  size: 20.w,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contract.employeeName ?? 'Nhân viên',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      contract.type.displayName,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: _getContractTypeColor(contract.type),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(contract.status),
            ],
          ),

          SizedBox(height: 12.h),

          // Date Range
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bắt đầu',
                      style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(contract.startDate),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.arrow_forward, color: AppColors.textSecondary, size: 20.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Kết thúc',
                      style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary),
                    ),
                    Text(
                      contract.endDate != null 
                          ? DateFormat('dd/MM/yyyy').format(contract.endDate!) 
                          : 'Không xác định',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    contract.durationMonths != null 
                        ? '${contract.durationMonths} tháng' 
                        : 'Vô thời hạn',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Expiry Warning
          if (contract.isExpiringSoon && contract.status == ContractStatus.active) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: AppColors.warning, size: 18.w),
                  SizedBox(width: 8.w),
                  Text(
                    'Còn ${contract.daysUntilExpiry} ngày hết hạn',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
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

  Widget _buildStatusBadge(ContractStatus status) {
    Color color;
    switch (status) {
      case ContractStatus.active:
        color = AppColors.success;
        break;
      case ContractStatus.expired:
        color = AppColors.error;
        break;
      case ContractStatus.terminated:
        color = AppColors.error;
        break;
      case ContractStatus.pending:
        color = AppColors.warning;
        break;
      case ContractStatus.draft:
        color = AppColors.textSecondary;
        break;
      case ContractStatus.renewed:
        color = AppColors.primary;
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

  Color _getContractTypeColor(ContractType type) {
    switch (type) {
      case ContractType.indefinite:
        return AppColors.success;
      case ContractType.definite12:
      case ContractType.definite24:
      case ContractType.definite36:
        return AppColors.primary;
      case ContractType.seasonal:
        return AppColors.info;
      case ContractType.partTime:
        return AppColors.warning;
      case ContractType.freelance:
        return AppColors.textSecondary;
    }
  }
}
