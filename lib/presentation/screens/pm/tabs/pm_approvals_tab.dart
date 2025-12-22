/// PM Approvals Tab
/// 
/// Approval tab for Project Manager to approve/reject team leave requests.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/leave_request.dart';
import '../../../blocs/blocs.dart';

/// PM Approvals Tab - Duyệt đơn nghỉ phép team
class PMApprovalsTab extends StatefulWidget {
  const PMApprovalsTab({super.key});

  @override
  State<PMApprovalsTab> createState() => _PMApprovalsTabState();
}

class _PMApprovalsTabState extends State<PMApprovalsTab> {
  String _filterStatus = 'pending';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter Tabs
        Container(
          padding: EdgeInsets.all(16.w),
          color: AppColors.surface,
          child: Row(
            children: [
              _buildFilterChip('Chờ duyệt', 'pending'),
              SizedBox(width: 8.w),
              _buildFilterChip('Đã duyệt', 'approved'),
              SizedBox(width: 8.w),
              _buildFilterChip('Từ chối', 'rejected'),
            ],
          ),
        ),
        
        // Approvals List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              // TODO: Load from actual API
            },
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                // Placeholder data - in production, this would come from API
                if (_filterStatus == 'pending') ...[
                  _buildApprovalCard(
                    id: '1',
                    employeeName: 'Nguyễn Văn A',
                    leaveType: 'Nghỉ phép năm',
                    fromDate: '25/12/2024',
                    toDate: '27/12/2024',
                    days: 3,
                    reason: 'Về quê ăn Tết cùng gia đình',
                    status: 'pending',
                  ),
                  _buildApprovalCard(
                    id: '2',
                    employeeName: 'Trần Thị B',
                    leaveType: 'Nghỉ ốm',
                    fromDate: '23/12/2024',
                    toDate: '24/12/2024',
                    days: 2,
                    reason: 'Bị cảm sốt, cần nghỉ ngơi',
                    status: 'pending',
                  ),
                ] else if (_filterStatus == 'approved') ...[
                  _buildApprovalCard(
                    id: '3',
                    employeeName: 'Lê Văn C',
                    leaveType: 'Nghỉ việc riêng',
                    fromDate: '20/12/2024',
                    toDate: '20/12/2024',
                    days: 1,
                    reason: 'Đi đám cưới bạn',
                    status: 'approved',
                  ),
                ] else ...[
                  _buildApprovalCard(
                    id: '4',
                    employeeName: 'Phạm Văn D',
                    leaveType: 'Nghỉ phép năm',
                    fromDate: '15/12/2024',
                    toDate: '20/12/2024',
                    days: 6,
                    reason: 'Đi du lịch',
                    status: 'rejected',
                    rejectReason: 'Đang trong giai đoạn bận, cần hoàn thành dự án',
                  ),
                ],
                
                // Empty state
                if ((_filterStatus == 'pending' && false) || 
                    (_filterStatus != 'pending' && false))
                  Center(
                    child: Column(
                      children: [
                        SizedBox(height: 60.h),
                        Icon(
                          Icons.inbox_outlined,
                          size: 64.w,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Không có đơn nào',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalCard({
    required String id,
    required String employeeName,
    required String leaveType,
    required String fromDate,
    required String toDate,
    required int days,
    required String reason,
    required String status,
    String? rejectReason,
  }) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    
    switch (status) {
      case 'approved':
        statusColor = AppColors.success;
        statusLabel = 'Đã duyệt';
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = AppColors.error;
        statusLabel = 'Từ chối';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppColors.warning;
        statusLabel = 'Chờ duyệt';
        statusIcon = Icons.pending;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    employeeName[0].toUpperCase(),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employeeName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        leaveType,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16.w, color: statusColor),
                      SizedBox(width: 4.w),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Body
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date info
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem('Từ ngày', fromDate, Icons.event),
                    ),
                    Expanded(
                      child: _buildInfoItem('Đến ngày', toDate, Icons.event),
                    ),
                    Expanded(
                      child: _buildInfoItem('Số ngày', '$days ngày', Icons.schedule),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                
                // Reason
                Text(
                  'Lý do',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    reason,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                
                // Reject reason if any
                if (rejectReason != null) ...[
                  SizedBox(height: 12.h),
                  Text(
                    'Lý do từ chối',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      rejectReason,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Actions (only for pending)
          if (status == 'pending')
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16.r),
                  bottomRight: Radius.circular(16.r),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(id, employeeName),
                      icon: const Icon(Icons.close),
                      label: const Text('Từ chối'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleApprove(id, employeeName),
                      icon: const Icon(Icons.check),
                      label: const Text('Phê duyệt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 4.h),
        Row(
          children: [
            Icon(icon, size: 14.w, color: AppColors.primary),
            SizedBox(width: 4.w),
            Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleApprove(String id, String employeeName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã phê duyệt đơn của $employeeName'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    // TODO: Call actual API
  }

  void _showRejectDialog(String id, String employeeName) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Từ chối đơn của $employeeName'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Lý do từ chối',
            border: OutlineInputBorder(),
            hintText: 'Nhập lý do từ chối...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã từ chối đơn của $employeeName'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              // TODO: Call actual API
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }
}
