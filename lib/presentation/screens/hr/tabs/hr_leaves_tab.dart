import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/leave_request.dart';
import '../../../blocs/blocs.dart';

/// HR Leaves Tab - Quản lý đơn nghỉ phép
class HRLeavesTab extends StatefulWidget {
  const HRLeavesTab({super.key});

  @override
  State<HRLeavesTab> createState() => _HRLeavesTabState();
}

class _HRLeavesTabState extends State<HRLeavesTab> {
  bool _showPendingOnly = true;

  void _loadLeaves() {
    context.read<HRBloc>().add(HRLoadLeaveRequests(pendingOnly: _showPendingOnly));
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
                  'Đơn nghỉ phép',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              FilterChip(
                label: Text(_showPendingOnly ? 'Chờ duyệt' : 'Tất cả'),
                selected: _showPendingOnly,
                onSelected: (selected) {
                  setState(() => _showPendingOnly = selected);
                  _loadLeaves();
                },
                selectedColor: AppColors.warning.withValues(alpha: 0.2),
                checkmarkColor: AppColors.warning,
              ),
            ],
          ),
        ),

        // Leaves List
        Expanded(
          child: BlocConsumer<HRBloc, HRState>(
            listener: (context, state) {
              if (state.status == HRStatus.actionSuccess && state.successMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.successMessage!),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
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
                      Text(state.errorMessage ?? 'Có lỗi xảy ra'),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: _loadLeaves,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                );
              }

              final leaves = state.leaveRequests;
              if (leaves.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_available, size: 64.w, color: AppColors.textSecondary),
                      SizedBox(height: 16.h),
                      Text(
                        _showPendingOnly 
                            ? 'Không có đơn chờ duyệt'
                            : 'Không có đơn nghỉ phép',
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
                onRefresh: () async => _loadLeaves(),
                child: ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: leaves.length,
                  itemBuilder: (context, index) {
                    return _buildLeaveCard(context, leaves[index], state);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveCard(BuildContext context, LeaveRequest leave, HRState state) {
    final isProcessing = (state.status == HRStatus.approving || 
                          state.status == HRStatus.rejecting);
    
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
                backgroundColor: _getAvatarColor(leave.userName ?? 'U'),
                child: Text(
                  (leave.userName ?? 'U')[0].toUpperCase(),
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
                      leave.userName ?? 'Nhân viên',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      leave.type.displayName,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: _getLeaveTypeColor(leave.type),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(leave.status),
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
                      'Từ ngày',
                      style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(leave.startDate),
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
                      'Đến ngày',
                      style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(leave.endDate),
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
                    '${leave.totalDays} ngày',
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
          
          SizedBox(height: 12.h),
          
          // Reason
          Text(
            'Lý do:',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            leave.reason.isNotEmpty ? leave.reason : 'Không có lý do',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Action Buttons (only for pending)
          if (leave.status == LeaveStatus.pending) ...[
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isProcessing ? null : () => _showRejectDialog(context, leave),
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
                    onPressed: isProcessing ? null : () {
                      context.read<HRBloc>().add(HRApproveLeave(leaveId: leave.id));
                    },
                    icon: isProcessing 
                        ? SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Duyệt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, LeaveRequest leave) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Từ chối đơn nghỉ phép'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Từ chối đơn của ${leave.userName}?'),
            SizedBox(height: 16.h),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do từ chối *',
                hintText: 'Nhập lý do...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do từ chối')),
                );
                return;
              }
              context.read<HRBloc>().add(HRRejectLeave(
                leaveId: leave.id,
                reason: reasonController.text.trim(),
              ));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(LeaveStatus status) {
    Color color;
    String label;
    
    switch (status) {
      case LeaveStatus.pending:
        color = AppColors.warning;
        label = 'Chờ duyệt';
        break;
      case LeaveStatus.approved:
        color = AppColors.success;
        label = 'Đã duyệt';
        break;
      case LeaveStatus.rejected:
        color = AppColors.error;
        label = 'Từ chối';
        break;
      case LeaveStatus.cancelled:
        color = AppColors.textSecondary;
        label = 'Đã hủy';
        break;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _getLeaveTypeColor(LeaveType type) {
    switch (type) {
      case LeaveType.annual:
        return Colors.blue;
      case LeaveType.sickPaid:
      case LeaveType.sickUnpaid:
        return Colors.red;
      case LeaveType.maternity:
      case LeaveType.paternity:
        return Colors.pink;
      case LeaveType.wedding:
      case LeaveType.bereavement:
        return Colors.purple;
      case LeaveType.compensatory:
        return Colors.green;
      case LeaveType.personal:
        return Colors.orange;
      case LeaveType.unpaid:
        return Colors.grey;
    }
  }

  Color _getAvatarColor(String name) {
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return HSLColor.fromAHSL(1.0, (hash % 360).toDouble(), 0.6, 0.5).toColor();
  }
}
