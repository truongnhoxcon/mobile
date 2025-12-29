import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../config/dependencies/injection_container.dart' as di;
import '../../../domain/entities/issue.dart';
import '../../../domain/entities/project.dart';
import '../../../domain/entities/user.dart';
import '../../../data/datasources/project_datasource.dart';
import '../../../data/datasources/user_datasource.dart';
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

class _ProjectDetailContentState extends State<_ProjectDetailContent> {
  Project? _project;
  bool _loadingProject = true;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    try {
      final datasource = ProjectDataSourceImpl();
      final projectModel = await datasource.getProject(widget.projectId);
      if (mounted && projectModel != null) {
        setState(() {
          _project = projectModel.toEntity();
          _loadingProject = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingProject = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    // Strict check: Must be Owner OR Project Manager role to create tasks
    final isOwner = _project?.ownerId != null && _project?.ownerId == authState.user?.id;
    final canManage = isOwner || 
                      authState.user?.role == UserRole.projectManager ||
                      authState.user?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loadingProject
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                _loadProject();
                context.read<IssueBloc>().add(IssueLoadByProject(widget.projectId));
              },
              child: CustomScrollView(
                slivers: [
                  // Custom AppBar with Project Info
                  _buildSliverAppBar(canManage),
                  
                  // KPI Stats
                  SliverToBoxAdapter(child: _buildKPISection()),
                  
                  // Kanban Board
                  SliverToBoxAdapter(child: _buildKanbanSection()),
                ],
              ),
            ),
      floatingActionButton: canManage 
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateIssueDialog(context),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Tạo Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildSliverAppBar(bool canManage) {
    final project = _project;
    final statusColor = _getStatusColor(project?.status ?? ProjectStatus.planning);
    
    return SliverAppBar(
      expandedHeight: 240.h,
      pinned: true,
      backgroundColor: AppColors.primary,
      title: Text(
        project?.name ?? 'Chi tiết dự án',
        style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 60.h, 20.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                   // ... (Header content same as before)
                   Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(Icons.folder, color: Colors.white, size: 28.w),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project?.name ?? 'Đang tải...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (project?.description?.isNotEmpty == true)
                              Text(
                                project!.description!,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13.sp,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          project?.status.displayName ?? 'Unknown',
                          style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Icon(Icons.people, color: Colors.white.withValues(alpha: 0.9), size: 16.w),
                      SizedBox(width: 4.w),
                      Text(
                        '${project?.memberIds.length ?? 0} thành viên',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12.sp),
                      ),
                      const Spacer(),
                      // Progress
                      Row(
                        children: [
                          Text(
                            '${project?.progress ?? 0}%',
                            style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 8.w),
                          SizedBox(
                            width: 60.w,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4.r),
                              child: LinearProgressIndicator(
                                value: (project?.progress ?? 0) / 100,
                                backgroundColor: Colors.white.withValues(alpha: 0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                minHeight: 6.h,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        if (canManage)
          PopupMenuButton<String>(
            icon: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: const Icon(Icons.more_vert, color: Colors.white),
            ),
            onSelected: (value) {
              // Handle menu actions
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tính năng $value đang phát triển')),
              );
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Chỉnh sửa dự án'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'member',
                child: Row(
                  children: [
                    Icon(Icons.person_add, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Quản lý thành viên'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Xóa dự án', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          )
        else
           SizedBox(width: 16.w),
      ],
    );
  }

  Widget _buildKPISection() {
    return BlocBuilder<IssueBloc, IssueState>(
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              _buildKPICard('Chờ xử lý', '${state.todoIssues.length}', Icons.pending_actions, Colors.grey),
              SizedBox(width: 12.w),
              _buildKPICard('Đang làm', '${state.inProgressIssues.length}', Icons.timelapse, AppColors.info),
              SizedBox(width: 12.w),
              _buildKPICard('Hoàn thành', '${state.doneIssues.length}', Icons.check_circle, AppColors.success),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKPICard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: color, size: 22.w),
            ),
            SizedBox(height: 10.h),
            Text(
              value,
              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: color),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKanbanSection() {
    return BlocBuilder<IssueBloc, IssueState>(
      builder: (context, state) {
        if (state.status == IssueBlocStatus.loading) {
          return SizedBox(
            height: 400.h,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Icon(Icons.view_kanban, color: AppColors.primary, size: 20.w),
                  SizedBox(width: 8.w),
                  Text(
                    'Kanban Board',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            
            // Fit-to-screen Layout (No Horizontal Scroll)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              height: 450.h, // Slightly taller to accommodate content
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildColumn(context, 'Chờ xử lý', state.todoIssues, IssueStatus.todo, Colors.grey)),
                  SizedBox(width: 8.w), // Smaller spacing
                  Expanded(child: _buildColumn(context, 'Đang làm', state.inProgressIssues, IssueStatus.inProgress, AppColors.info)),
                  SizedBox(width: 8.w),
                  Expanded(child: _buildColumn(context, 'Hoàn thành', state.doneIssues, IssueStatus.done, AppColors.success)),
                ],
              ),
            ),
            SizedBox(height: 80.h),
          ],
        );
      },
    );
  }

  Widget _buildColumn(BuildContext context, String title, List<Issue> issues, IssueStatus status, Color color) {
    // Removed fixed width calculation logic
    
    return DragTarget<Issue>(
      onWillAcceptWithDetails: (details) {
        return details.data.status != status;
      },
      onAcceptWithDetails: (details) {
        context.read<IssueBloc>().add(IssueUpdateStatus(details.data.id, status));
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        
        return Container(
          // width: columnWidth, // REMOVED fixed width
          height: double.infinity, // Fill parent height
          decoration: BoxDecoration(
            color: isHovering ? color.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: isHovering 
                ? Border.all(color: color, width: 2)
                : null,
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
              // Header
              Container(
                padding: EdgeInsets.all(10.w), // Compact padding
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8.w, height: 8.w, // Smaller dot
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        title, 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp, color: AppColors.textPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text('${issues.length}', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: color)),
                    ),
                  ],
                ),
              ),
              // Issues
              Expanded(
                child: issues.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isHovering ? Icons.add_circle_outline : Icons.inbox_outlined, 
                              size: 32.w, 
                              color: isHovering ? color : Colors.grey.shade300,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(8.w),
                        shrinkWrap: true,
                        itemCount: issues.length,
                        itemBuilder: (ctx, idx) => _buildDraggableIssueCard(context, issues[idx], status),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDraggableIssueCard(BuildContext context, Issue issue, IssueStatus currentStatus) {
    return LongPressDraggable<Issue>(
      data: issue,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.6,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeChip(issue.type),
              SizedBox(height: 8.h),
              Text(
                issue.title,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _buildIssueCard(context, issue, currentStatus),
      ),
      child: _buildIssueCard(context, issue, currentStatus),
    );
  }

  Widget _buildIssueCard(BuildContext context, Issue issue, IssueStatus currentStatus) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
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
            SizedBox(height: 10.h),
            Text(
              issue.title,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (issue.description?.isNotEmpty == true) ...[
              SizedBox(height: 6.h),
              Text(
                issue.description!,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: 10.h),
            Row(
              children: [
                if (issue.dueDate != null) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, size: 12.w, color: AppColors.warning),
                        SizedBox(width: 4.w),
                        Text(
                          DateFormat('dd/MM').format(issue.dueDate!),
                          style: TextStyle(fontSize: 11.sp, color: AppColors.warning, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                ],
                // Assignee avatar or assign button
                GestureDetector(
                  onTap: () => _showAssignDialog(context, issue),
                  child: issue.assigneeId != null
                      ? Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 10.r,
                                backgroundColor: AppColors.primary,
                                child: Icon(Icons.person, size: 12.w, color: Colors.white),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Đã giao',
                                style: TextStyle(fontSize: 10.sp, color: AppColors.primary, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.3), style: BorderStyle.solid),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_add_alt_1, size: 12.w, color: AppColors.textSecondary),
                              SizedBox(width: 4.w),
                              Text(
                                'Giao việc',
                                style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: AppColors.border.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Icon(Icons.more_horiz, size: 16.w, color: AppColors.textSecondary),
                  ),
                  onSelected: (value) {
                    if (value == 'assign') {
                      _showAssignDialog(context, issue);
                    } else {
                      final newStatus = IssueStatus.values.firstWhere((s) => s.value == value);
                      context.read<IssueBloc>().add(IssueUpdateStatus(issue.id, newStatus));
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'assign',
                      child: Row(
                        children: [
                          Icon(Icons.person_add, size: 18.w, color: AppColors.primary),
                          SizedBox(width: 8.w),
                          const Text('Giao việc'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    ...IssueStatus.values
                        .where((s) => s != currentStatus)
                        .map((s) => PopupMenuItem(value: s.value, child: Text('→ ${s.displayName}'))),
                  ],
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
        color = AppColors.primary;
        icon = Icons.task_alt;
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.w, color: color),
          SizedBox(width: 4.w),
          Text(type.displayName, style: TextStyle(fontSize: 11.sp, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPriorityIcon(IssuePriority priority) {
    Color color;
    switch (priority) {
      case IssuePriority.critical: color = Colors.red;
      case IssuePriority.high: color = Colors.orange;
      case IssuePriority.medium: color = AppColors.info;
      case IssuePriority.low: color = Colors.grey;
    }
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Icon(Icons.flag, size: 14.w, color: color),
    );
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.planning: return AppColors.warning;
      case ProjectStatus.active: return AppColors.primary;
      case ProjectStatus.onHold: return Colors.orange;
      case ProjectStatus.completed: return AppColors.success;
      case ProjectStatus.archived: return AppColors.textSecondary;
    }
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
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, MediaQuery.of(ctx).viewInsets.bottom + 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text('Tạo Task mới', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 20.h),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Tiêu đề *',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
              SizedBox(height: 14.h),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<IssueType>(
                      value: selectedType,
                      decoration: InputDecoration(
                        labelText: 'Loại',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
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
                        labelText: 'Ưu tiên',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      items: IssuePriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.displayName))).toList(),
                      onChanged: (v) => setModalState(() => selectedPriority = v!),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 52.h,
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: Text('Tạo Task', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignDialog(BuildContext context, Issue issue) async {
    // Get project members
    final project = _project;
    if (project == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AssignMemberSheet(
        issue: issue,
        memberIds: project.memberIds,
        onAssign: (userId) {
          context.read<IssueBloc>().add(IssueAssign(issue.id, userId));
          Navigator.pop(ctx);
        },
        onUnassign: () {
          context.read<IssueBloc>().add(IssueAssign(issue.id, null));
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

// Separate widget for the assign sheet to manage its own state
class _AssignMemberSheet extends StatefulWidget {
  final Issue issue;
  final List<String> memberIds;
  final Function(String) onAssign;
  final VoidCallback onUnassign;

  const _AssignMemberSheet({
    required this.issue,
    required this.memberIds,
    required this.onAssign,
    required this.onUnassign,
  });

  @override
  State<_AssignMemberSheet> createState() => _AssignMemberSheetState();
}

class _AssignMemberSheetState extends State<_AssignMemberSheet> {
  List<User> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final datasource = UserDataSourceImpl();
      final List<User> members = [];
      for (final id in widget.memberIds) {
        try {
          final user = await datasource.getUserById(id);
          members.add(user.toEntity());
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _members = members;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text('Giao việc', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          Text(
            widget.issue.title,
            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 16.h),
          
          if (widget.issue.assigneeId != null)
            Container(
              margin: EdgeInsets.only(bottom: 12.h),
              child: OutlinedButton.icon(
                onPressed: widget.onUnassign,
                icon: const Icon(Icons.person_remove, color: Colors.red),
                label: const Text('Hủy giao việc', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  minimumSize: Size(double.infinity, 44.h),
                ),
              ),
            ),
          
          Text('Chọn thành viên:', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
          SizedBox(height: 12.h),
          
          if (_loading)
            SizedBox(
              height: 100.h,
              child: const Center(child: CircularProgressIndicator()),
            )
          else if (_members.isEmpty)
            SizedBox(
              height: 100.h,
              child: Center(
                child: Text('Không có thành viên', style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 300.h),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _members.length,
                itemBuilder: (ctx, idx) {
                  final member = _members[idx];
                  final isAssigned = widget.issue.assigneeId == member.id;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isAssigned ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        (member.displayName ?? member.email)[0].toUpperCase(),
                        style: TextStyle(
                          color: isAssigned ? Colors.white : AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(member.displayName ?? 'No name'),
                    subtitle: Text(member.email, style: TextStyle(fontSize: 12.sp)),
                    trailing: isAssigned
                        ? Icon(Icons.check_circle, color: AppColors.primary)
                        : null,
                    onTap: () => widget.onAssign(member.id),
                  );
                },
              ),
            ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
