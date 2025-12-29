import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/evaluation.dart';
import '../../../blocs/blocs.dart';

/// HR Evaluations Tab - Quản lý đánh giá nhân viên
class HREvaluationsTab extends StatefulWidget {
  const HREvaluationsTab({super.key});

  @override
  State<HREvaluationsTab> createState() => _HREvaluationsTabState();
}

class _HREvaluationsTabState extends State<HREvaluationsTab> {
  bool _showPendingOnly = true;

  void _loadEvaluations() {
    context.read<HRBloc>().add(HRLoadEvaluations(pendingOnly: _showPendingOnly));
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
                  'Đánh giá nhân viên',
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
                  _loadEvaluations();
                },
                selectedColor: AppColors.warning.withValues(alpha: 0.2),
                checkmarkColor: AppColors.warning,
              ),
            ],
          ),
        ),

        // Evaluations List
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
                        onPressed: _loadEvaluations,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                );
              }

              final evaluations = state.evaluations;
              if (evaluations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review_outlined, size: 64.w, color: AppColors.textSecondary),
                      SizedBox(height: 16.h),
                      Text(
                        _showPendingOnly 
                            ? 'Không có đánh giá chờ duyệt'
                            : 'Không có đánh giá nào',
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
                onRefresh: () async => _loadEvaluations(),
                child: ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: evaluations.length,
                  itemBuilder: (context, index) {
                    return _buildEvaluationCard(context, evaluations[index], state);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEvaluationCard(BuildContext context, Evaluation evaluation, HRState state) {
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
                backgroundColor: _getAvatarColor(evaluation.employeeName ?? 'U'),
                child: Text(
                  (evaluation.employeeName ?? 'U')[0].toUpperCase(),
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
                      evaluation.employeeName ?? 'Nhân viên',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Kỳ đánh giá: ${evaluation.period}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(evaluation.status),
            ],
          ),

          SizedBox(height: 12.h),

          // Score Card
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
                      'Điểm đánh giá',
                      style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Text(
                          (evaluation.finalScore ?? 0).toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(evaluation.finalScore ?? 0),
                          ),
                        ),
                        Text(
                          '/100',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: _getScoreColor(evaluation.finalScore ?? 0).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    evaluation.grade,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(evaluation.finalScore ?? 0),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Comments
          if (evaluation.managerSummary != null && evaluation.managerSummary!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              'Nhận xét:',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              evaluation.managerSummary!,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Evaluator Info
          if (evaluation.evaluatorName != null) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14.w, color: AppColors.textSecondary),
                SizedBox(width: 4.w),
                Text(
                  'Người đánh giá: ${evaluation.evaluatorName}',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],

          // Action Buttons (only for submitted)
          if (evaluation.status == EvaluationStatus.submitted) ...[
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isProcessing ? null : () => _showRejectDialog(context, evaluation),
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
                      context.read<HRBloc>().add(HRApproveEvaluation(evaluationId: evaluation.id));
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

  void _showRejectDialog(BuildContext context, Evaluation evaluation) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Từ chối đánh giá'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Từ chối đánh giá của ${evaluation.employeeName}?'),
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
              context.read<HRBloc>().add(HRRejectEvaluation(
                evaluationId: evaluation.id,
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

  Widget _buildStatusBadge(EvaluationStatus status) {
    Color color;
    switch (status) {
      case EvaluationStatus.approved:
        color = AppColors.success;
        break;
      case EvaluationStatus.submitted:
        color = AppColors.warning;
        break;
      case EvaluationStatus.reviewed:
        color = AppColors.info;
        break;
      case EvaluationStatus.rejected:
        color = AppColors.error;
        break;
      case EvaluationStatus.draft:
        color = AppColors.textSecondary;
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

  Color _getScoreColor(double score) {
    if (score >= 90) return AppColors.success;
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 70) return AppColors.info;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  Color _getAvatarColor(String name) {
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return HSLColor.fromAHSL(1.0, (hash % 360).toDouble(), 0.6, 0.5).toColor();
  }
}
