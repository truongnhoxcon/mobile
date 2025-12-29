import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../config/dependencies/injection_container.dart' as di;
import '../../../domain/entities/evaluation.dart';
import '../../blocs/blocs.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/pastel_background.dart';

/// My Evaluations Screen - View personal performance evaluations
class MyEvaluationsScreen extends StatelessWidget {
  const MyEvaluationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<MyInfoBloc>()..add(const MyInfoLoadData()),
      child: const _MyEvaluationsScreenContent(),
    );
  }
}

class _MyEvaluationsScreenContent extends StatelessWidget {
  const _MyEvaluationsScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Đánh giá hiệu suất',
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

            final evaluations = state.myEvaluations;

            if (evaluations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assessment_outlined, size: 64.w, color: AppColors.textSecondary),
                    SizedBox(height: 16.h),
                    Text('Chưa có đánh giá nào',
                        style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary)),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => context.read<MyInfoBloc>().add(const MyInfoLoadData()),
              child: ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: evaluations.length,
                itemBuilder: (context, index) {
                  final evaluation = evaluations[index];
                  return _buildEvaluationCard(context, evaluation);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEvaluationCard(BuildContext context, Evaluation evaluation) {
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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with period and status
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.primary, size: 20.w),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        evaluation.period,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                      ),
                      if (evaluation.startDate != null && evaluation.endDate != null)
                        Text(
                          '${DateFormat('dd/MM/yyyy').format(evaluation.startDate!)} - ${DateFormat('dd/MM/yyyy').format(evaluation.endDate!)}',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
                        ),
                    ],
                  ),
                ),
                _buildStatusBadge(evaluation.status),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Scores comparison
                _buildScoresSection(evaluation),
                SizedBox(height: 16.h),

                // Final score with grade
                _buildFinalScoreSection(evaluation),
                SizedBox(height: 16.h),

                // Criteria breakdown (if any)
                if (evaluation.criteria.isNotEmpty) ...[
                  _buildCriteriaSection(evaluation),
                  SizedBox(height: 16.h),
                ],

                // Goals (if any)
                if (evaluation.currentGoals.isNotEmpty) ...[
                  _buildGoalsSection(evaluation),
                  SizedBox(height: 16.h),
                ],

                // Strengths and Improvements
                if (evaluation.strength != null && evaluation.strength!.isNotEmpty)
                  _buildFeedbackItem('Điểm mạnh', evaluation.strength!, AppColors.success),
                if (evaluation.improvement != null && evaluation.improvement!.isNotEmpty)
                  _buildFeedbackItem('Cần cải thiện', evaluation.improvement!, AppColors.warning),

                // Manager summary
                if (evaluation.managerSummary != null && evaluation.managerSummary!.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.comment, color: AppColors.info, size: 16.w),
                            SizedBox(width: 6.w),
                            Text('Nhận xét từ Manager',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.sp, color: AppColors.info)),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(evaluation.managerSummary!, style: TextStyle(fontSize: 13.sp)),
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

  Widget _buildScoresSection(Evaluation evaluation) {
    return Row(
      children: [
        Expanded(
          child: _buildScoreCard(
            'Tự đánh giá',
            evaluation.selfScore ?? 0,
            Colors.blue,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildScoreCard(
            'Manager đánh giá',
            evaluation.managerScore ?? 0,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCard(String label, double score, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 11.sp)),
          SizedBox(height: 4.h),
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalScoreSection(Evaluation evaluation) {
    final finalScore = evaluation.finalScore ?? 0;
    final grade = evaluation.grade;
    
    Color gradeColor;
    switch (grade) {
      case 'A':
      case 'A+':
        gradeColor = AppColors.success;
        break;
      case 'B':
      case 'B+':
        gradeColor = AppColors.info;
        break;
      case 'C':
      case 'C+':
        gradeColor = AppColors.warning;
        break;
      default:
        gradeColor = AppColors.error;
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradeColor.withValues(alpha: 0.2), gradeColor.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: gradeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: gradeColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                grade,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Điểm cuối cùng',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp)),
              Text(
                '${finalScore.toStringAsFixed(1)}/100',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: gradeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaSection(Evaluation evaluation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.checklist, color: AppColors.primary, size: 18.w),
            SizedBox(width: 6.w),
            Text('Tiêu chí đánh giá',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
          ],
        ),
        SizedBox(height: 12.h),
        ...evaluation.criteria.map((c) => _buildCriteriaItem(c)),
      ],
    );
  }

  Widget _buildCriteriaItem(EvaluationCriteria criteria) {
    final selfScore = criteria.selfScore ?? 0;
    final managerScore = criteria.managerScore ?? 0;
    final maxScore = criteria.maxScore;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(criteria.name,
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13.sp)),
              ),
              Text('${criteria.weight.toStringAsFixed(0)}%',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp)),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tự ĐG: ${selfScore.toStringAsFixed(1)}/$maxScore',
                        style: TextStyle(fontSize: 11.sp, color: Colors.blue)),
                    SizedBox(height: 4.h),
                    LinearProgressIndicator(
                      value: selfScore / maxScore,
                      backgroundColor: Colors.blue.withValues(alpha: 0.2),
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Manager: ${managerScore.toStringAsFixed(1)}/$maxScore',
                        style: TextStyle(fontSize: 11.sp, color: Colors.purple)),
                    SizedBox(height: 4.h),
                    LinearProgressIndicator(
                      value: managerScore / maxScore,
                      backgroundColor: Colors.purple.withValues(alpha: 0.2),
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsSection(Evaluation evaluation) {
    final completedGoals = evaluation.currentGoals.where((g) => g.isCompleted).length;
    final totalGoals = evaluation.currentGoals.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flag, color: AppColors.warning, size: 18.w),
            SizedBox(width: 6.w),
            Text('Mục tiêu',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
            const Spacer(),
            Text('$completedGoals/$totalGoals hoàn thành',
                style: TextStyle(color: AppColors.success, fontSize: 12.sp)),
          ],
        ),
        SizedBox(height: 12.h),
        ...evaluation.currentGoals.map((goal) => _buildGoalItem(goal)),
      ],
    );
  }

  Widget _buildGoalItem(EvaluationGoal goal) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: goal.isCompleted
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.background,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: goal.isCompleted
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            goal.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: goal.isCompleted ? AppColors.success : AppColors.textSecondary,
            size: 20.w,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13.sp,
                      decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
                    )),
                if (goal.description != null && goal.description!.isNotEmpty)
                  Text(goal.description!,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackItem(String label, String content, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            label.contains('mạnh') ? Icons.thumb_up : Icons.lightbulb,
            color: color,
            size: 18.w,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.sp, color: color)),
                SizedBox(height: 4.h),
                Text(content, style: TextStyle(fontSize: 13.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(EvaluationStatus status) {
    Color color;
    switch (status) {
      case EvaluationStatus.draft:
        color = AppColors.textSecondary;
        break;
      case EvaluationStatus.submitted:
        color = AppColors.info;
        break;
      case EvaluationStatus.reviewed:
        color = AppColors.warning;
        break;
      case EvaluationStatus.approved:
        color = AppColors.success;
        break;
      case EvaluationStatus.rejected:
        color = AppColors.error;
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
}
