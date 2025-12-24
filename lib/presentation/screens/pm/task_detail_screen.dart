/// Task Detail Screen
/// 
/// Screen to display detailed information about a task/issue.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/issue.dart';
import '../../../domain/entities/user.dart';
import '../../../data/datasources/issue_datasource.dart';
import '../../../data/datasources/user_datasource.dart';
import '../../blocs/blocs.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  Issue? _task;
  User? _assignee;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final datasource = IssueDataSourceImpl();
      final issue = await datasource.getIssue(widget.taskId);
      
      if (issue != null) {
        User? assignee;
        if (issue.assigneeId != null && issue.assigneeId!.isNotEmpty) {
          final userDatasource = UserDataSourceImpl();
          final userModel = await userDatasource.getUserById(issue.assigneeId!);
          if (userModel != null) {
            assignee = userModel.toEntity();
          }
        }
        
        if (mounted) {
          setState(() {
            _task = issue.toEntity();
            _assignee = assignee;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Không tìm thấy task';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _updateStatus(IssueStatus newStatus) async {
    if (_task == null) return;
    
    try {
      final datasource = IssueDataSourceImpl();
      await datasource.updateIssueStatus(_task!.id, newStatus);
      await _loadTask();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật trạng thái'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chi tiết tác vụ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
        ),
        actions: [
          if (_task != null)
            PopupMenuButton<IssueStatus>(
              icon: const Icon(Icons.more_vert),
              onSelected: _updateStatus,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: IssueStatus.todo,
                  child: Row(
                    children: [
                      Icon(Icons.radio_button_unchecked, color: AppColors.warning, size: 20.w),
                      SizedBox(width: 8.w),
                      const Text('Chờ xử lý'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: IssueStatus.inProgress,
                  child: Row(
                    children: [
                      Icon(Icons.timelapse, color: AppColors.primary, size: 20.w),
                      SizedBox(width: 8.w),
                      const Text('Đang làm'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: IssueStatus.done,
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success, size: 20.w),
                      SizedBox(width: 8.w),
                      const Text('Hoàn thành'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48.w, color: AppColors.error),
                      SizedBox(height: 16.h),
                      Text(_error!, style: TextStyle(color: AppColors.error)),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: _loadTask,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _task == null
                  ? const Center(child: Text('Không tìm thấy task'))
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title & Status
                          _buildHeader(),
                          SizedBox(height: 24.h),
                          
                          // Details Grid
                          _buildDetailsGrid(),
                          SizedBox(height: 24.h),
                          
                          // Description
                          if (_task!.description != null && _task!.description!.isNotEmpty)
                            _buildDescriptionSection(),
                          
                          SizedBox(height: 24.h),
                          
                          // Assignee
                          _buildAssigneeSection(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildHeader() {
    Color statusColor;
    String statusText;
    switch (_task!.status) {
      case IssueStatus.todo:
        statusColor = AppColors.warning;
        statusText = 'Chờ xử lý';
        break;
      case IssueStatus.inProgress:
        statusColor = AppColors.primary;
        statusText = 'Đang làm';
        break;
      case IssueStatus.done:
        statusColor = AppColors.success;
        statusText = 'Hoàn thành';
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusText = 'Không xác định';
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _task!.title,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              _buildPriorityBadge(),
              SizedBox(width: 8.w),
              _buildTypeBadge(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge() {
    Color color;
    String text;
    switch (_task!.priority) {
      case IssuePriority.low:
        color = AppColors.success;
        text = 'Thấp';
        break;
      case IssuePriority.medium:
        color = AppColors.warning;
        text = 'Trung bình';
        break;
      case IssuePriority.high:
        color = AppColors.error;
        text = 'Cao';
        break;
      case IssuePriority.critical:
        color = Colors.purple;
        text = 'Khẩn cấp';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, color: color, size: 14.w),
          SizedBox(width: 4.w),
          Text(text, style: TextStyle(color: color, fontSize: 12.sp)),
        ],
      ),
    );
  }

  Widget _buildTypeBadge() {
    IconData icon;
    String text;
    switch (_task!.type) {
      case IssueType.task:
        icon = Icons.check_box;
        text = 'Task';
        break;
      case IssueType.bug:
        icon = Icons.bug_report;
        text = 'Bug';
        break;
      case IssueType.story:
        icon = Icons.bookmark;
        text = 'Story';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 14.w),
          SizedBox(width: 4.w),
          Text(text, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp)),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            Icons.calendar_today,
            'Ngày tạo',
            _task!.createdAt != null 
                ? DateFormat('dd/MM/yyyy HH:mm').format(_task!.createdAt!)
                : 'Không xác định',
          ),
          Divider(height: 24.h),
          _buildDetailRow(
            Icons.schedule,
            'Hạn hoàn thành',
            _task!.dueDate != null 
                ? DateFormat('dd/MM/yyyy').format(_task!.dueDate!)
                : 'Chưa đặt',
          ),
          Divider(height: 24.h),
          _buildDetailRow(
            Icons.update,
            'Cập nhật lần cuối',
            _task!.updatedAt != null
                ? DateFormat('dd/MM/yyyy HH:mm').format(_task!.updatedAt!)
                : 'Không xác định',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20.w),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mô tả',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            _task!.description ?? '',
            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildAssigneeSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Người được giao',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              CircleAvatar(
                radius: 24.r,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: _assignee?.photoUrl != null
                    ? ClipOval(
                        child: Image.network(
                          _assignee!.photoUrl!,
                          width: 48.w,
                          height: 48.w,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(Icons.person, color: AppColors.primary, size: 24.w),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _assignee?.displayName ?? 'Chưa được giao',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_assignee?.email != null)
                      Text(
                        _assignee!.email,
                        style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
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
}
