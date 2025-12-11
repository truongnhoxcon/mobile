import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../config/dependencies/injection_container.dart' as di;
import '../../../domain/entities/issue.dart';
import '../../../domain/entities/project.dart';
import '../../blocs/blocs.dart';

class ProjectDetailScreen extends StatelessWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<ProjectBloc>()),
        BlocProvider(create: (_) => di.sl<IssueBloc>()..add(IssueLoadByProject(projectId))),
      ],
      child: _ProjectDetailContent(projectId: projectId),
    );
  }
}

class _ProjectDetailContent extends StatefulWidget {
  final String projectId;
  const _ProjectDetailContent({required this.projectId});

  @override
  State<_ProjectDetailContent> createState() => _ProjectDetailContentState();
}

class _ProjectDetailContentState extends State<_ProjectDetailContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết dự án', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Kanban Board', icon: Icon(Icons.view_kanban)),
            Tab(text: 'Thông tin', icon: Icon(Icons.info_outline)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _KanbanBoard(projectId: widget.projectId),
          _ProjectInfo(projectId: widget.projectId),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateIssueDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateIssueDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final authState = context.read<AuthBloc>().state;
    final userId = authState.user?.id ?? '';
    IssueType selectedType = IssueType.task;
    IssuePriority selectedPriority = IssuePriority.medium;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, MediaQuery.of(ctx).viewInsets.bottom + 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tạo Issue mới', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 20.h),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Tiêu đề *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<IssueType>(
                      value: selectedType,
                      decoration: InputDecoration(
                        labelText: 'Loại',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      items: IssueType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(),
                      onChanged: (v) => setModalState(() => selectedType = v!),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: DropdownButtonFormField<IssuePriority>(
                      value: selectedPriority,
                      decoration: InputDecoration(
                        labelText: 'Độ ưu tiên',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      items: IssuePriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.displayName))).toList(),
                      onChanged: (v) => setModalState(() => selectedPriority = v!),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) return;
                    final issue = Issue(
                      id: '',
                      projectId: widget.projectId,
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      type: selectedType,
                      priority: selectedPriority,
                      reporterId: userId,
                      createdAt: DateTime.now(),
                    );
                    context.read<IssueBloc>().add(IssueCreate(issue));
                    Navigator.pop(ctx);
                  },
                  child: const Text('Tạo Issue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Kanban Board
// ============================================================================
class _KanbanBoard extends StatelessWidget {
  final String projectId;
  const _KanbanBoard({required this.projectId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IssueBloc, IssueState>(
      builder: (context, state) {
        if (state.status == IssueBlocStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<IssueBloc>().add(IssueLoadByProject(projectId));
          },
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.all(12.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildColumn(context, 'Chờ xử lý', state.todoIssues, IssueStatus.todo, AppColors.textSecondary),
                SizedBox(width: 12.w),
                _buildColumn(context, 'Đang làm', state.inProgressIssues, IssueStatus.inProgress, AppColors.info),
                SizedBox(width: 12.w),
                _buildColumn(context, 'Hoàn thành', state.doneIssues, IssueStatus.done, AppColors.success),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildColumn(BuildContext context, String title, List<Issue> issues, IssueStatus status, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;
    final columnWidth = (screenWidth - 60.w) / 1.2; // Show partial next column

    return Container(
      width: columnWidth,
      constraints: BoxConstraints(minHeight: 500.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8.w, height: 8.w,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                SizedBox(width: 8.w),
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text('${issues.length}', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: color)),
                ),
              ],
            ),
          ),
          Expanded(
            child: issues.isEmpty
                ? Center(child: Text('Không có issue', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp)))
                : ListView.builder(
                    padding: EdgeInsets.all(8.w),
                    shrinkWrap: true,
                    itemCount: issues.length,
                    itemBuilder: (ctx, idx) => _buildIssueCard(context, issues[idx], status),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueCard(BuildContext context, Issue issue, IssueStatus currentStatus) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildTypeChip(issue.type),
                const Spacer(),
                _buildPriorityIcon(issue.priority),
              ],
            ),
            SizedBox(height: 8.h),
            Text(issue.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
            if (issue.description?.isNotEmpty == true) ...[
              SizedBox(height: 4.h),
              Text(issue.description!, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp), maxLines: 2),
            ],
            SizedBox(height: 8.h),
            Row(
              children: [
                if (issue.dueDate != null) ...[
                  Icon(Icons.calendar_today, size: 14.w, color: AppColors.textSecondary),
                  SizedBox(width: 4.w),
                  Text(DateFormat('dd/MM').format(issue.dueDate!), style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary)),
                ],
                const Spacer(),
                PopupMenuButton<IssueStatus>(
                  child: Icon(Icons.more_horiz, size: 20.w),
                  onSelected: (newStatus) {
                    context.read<IssueBloc>().add(IssueUpdateStatus(issue.id, newStatus));
                  },
                  itemBuilder: (ctx) => IssueStatus.values
                      .where((s) => s != currentStatus)
                      .map((s) => PopupMenuItem(value: s, child: Text('Chuyển sang: ${s.displayName}')))
                      .toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(IssueType type) {
    Color color;
    IconData icon;
    switch (type) {
      case IssueType.bug:
        color = Colors.red;
        icon = Icons.bug_report;
        break;
      case IssueType.story:
        color = Colors.purple;
        icon = Icons.auto_stories;
        break;
      case IssueType.task:
        color = Colors.blue;
        icon = Icons.task_alt;
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.w, color: color),
          SizedBox(width: 4.w),
          Text(type.displayName, style: TextStyle(fontSize: 10.sp, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPriorityIcon(IssuePriority priority) {
    Color color;
    switch (priority) {
      case IssuePriority.critical: color = Colors.red;
      case IssuePriority.high: color = Colors.orange;
      case IssuePriority.medium: color = Colors.blue;
      case IssuePriority.low: color = Colors.grey;
    }
    return Icon(Icons.flag, size: 16.w, color: color);
  }
}

// ============================================================================
// Project Info Tab
// ============================================================================
class _ProjectInfo extends StatelessWidget {
  final String projectId;
  const _ProjectInfo({required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Thông tin dự án (ID: $projectId)', style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}
