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
                      // Progress - calculated from issues
                      BlocBuilder<IssueBloc, IssueState>(
                        builder: (context, issueState) {
                          final issues = issueState.issues;
                          final totalTasks = issues.length;
                          final doneTasks = issues.where((i) => i.status == IssueStatus.done).length;
                          final progressPercent = totalTasks > 0 
                              ? (doneTasks / totalTasks * 100).round() 
                              : 0;
                          
                          return Row(
                            children: [
                              Text(
                                '$progressPercent%',
                                style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 8.w),
                              SizedBox(
                                width: 60.w,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4.r),
                                  child: LinearProgressIndicator(
                                    value: totalTasks > 0 ? doneTasks / totalTasks : 0,
                                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                    minHeight: 6.h,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
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
              switch (value) {
                case 'edit':
                  _showEditProjectDialog();
                  break;
                case 'member':
                  _showManageMembersSheet();
                  break;
                case 'delete':
                  _showDeleteConfirmation();
                  break;
              }
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
            
            // Horizontal Scroll Layout for wider columns
            SizedBox(
              height: 450.h,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 160.w,
                      child: _buildColumn(context, 'Chờ xử lý', state.todoIssues, IssueStatus.todo, Colors.grey),
                    ),
                    SizedBox(width: 12.w),
                    SizedBox(
                      width: 160.w,
                      child: _buildColumn(context, 'Đang làm', state.inProgressIssues, IssueStatus.inProgress, AppColors.info),
                    ),
                    SizedBox(width: 12.w),
                    SizedBox(
                      width: 160.w,
                      child: _buildColumn(context, 'Hoàn thành', state.doneIssues, IssueStatus.done, AppColors.success),
                    ),
                  ],
                ),
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
    // Get type color
    Color typeColor;
    IconData typeIcon;
    switch (issue.type) {
      case IssueType.bug:
        typeColor = Colors.red;
        typeIcon = Icons.bug_report;
        break;
      case IssueType.story:
        typeColor = Colors.purple;
        typeIcon = Icons.auto_stories;
        break;
      case IssueType.task:
        typeColor = AppColors.primary;
        typeIcon = Icons.task_alt;
        break;
    }
    
    // Get priority color
    Color priorityColor;
    switch (issue.priority) {
      case IssuePriority.critical: priorityColor = Colors.red;
      case IssuePriority.high: priorityColor = Colors.orange;
      case IssuePriority.medium: priorityColor = AppColors.info;
      case IssuePriority.low: priorityColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () => _showIssueOptionsSheet(context, issue, currentStatus),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type badge & Priority indicator
            Row(
              children: [
                Icon(typeIcon, size: 14.w, color: typeColor),
                SizedBox(width: 4.w),
                Container(
                  width: 3.w,
                  height: 14.h,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                const Spacer(),
                if (issue.assigneeId != null)
                  CircleAvatar(
                    radius: 10.r,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: Icon(Icons.person, size: 10.w, color: AppColors.primary),
                  ),
              ],
            ),
            SizedBox(height: 6.h),
            
            // Title
            Text(
              issue.title,
              style: TextStyle(
                fontWeight: FontWeight.w600, 
                fontSize: 12.sp,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Due date
            if (issue.dueDate != null) ...[
              SizedBox(height: 6.h),
              Row(
                children: [
                  Icon(Icons.schedule, size: 10.w, color: AppColors.textHint),
                  SizedBox(width: 3.w),
                  Text(
                    DateFormat('dd/MM').format(issue.dueDate!),
                    style: TextStyle(fontSize: 9.sp, color: AppColors.textHint),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Show issue options sheet
  void _showIssueOptionsSheet(BuildContext context, Issue issue, IssueStatus currentStatus) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.all(16.w),
        child: SingleChildScrollView(
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
              Text(
                issue.title,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (issue.description?.isNotEmpty == true) ...[
                SizedBox(height: 8.h),
                Text(
                  issue.description!,
                  style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: 16.h),
              Divider(color: AppColors.border),
              ListTile(
                leading: Icon(Icons.person_add, color: AppColors.primary),
                title: const Text('Giao việc'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAssignDialog(context, issue);
                },
              ),
              ...IssueStatus.values.where((s) => s != currentStatus).map((s) => ListTile(
                leading: Icon(
                  s == IssueStatus.done ? Icons.check_circle : Icons.arrow_forward,
                  color: s == IssueStatus.done ? AppColors.success : AppColors.textSecondary,
                ),
                title: Text('Chuyển sang: ${s.displayName}'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<IssueBloc>().add(IssueUpdateStatus(issue.id, s));
                },
              )),
              // Delete option - only for PM, Admin, or Owner
              Builder(
                builder: (context) {
                  final authState = this.context.read<AuthBloc>().state;
                  final isOwner = _project?.ownerId == authState.user?.id;
                  final canDelete = isOwner || 
                                   authState.user?.role == UserRole.projectManager ||
                                   authState.user?.role == UserRole.admin;
                  
                  if (!canDelete) return const SizedBox.shrink();
                  
                  return Column(
                    children: [
                      Divider(color: AppColors.border),
                      ListTile(
                        leading: Icon(Icons.delete, color: AppColors.error),
                        title: Text('Xóa công việc', style: TextStyle(color: AppColors.error)),
                        onTap: () {
                          Navigator.pop(ctx);
                          _showDeleteConfirmDialog(context, issue);
                        },
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  // Show delete confirmation dialog
  void _showDeleteConfirmDialog(BuildContext context, Issue issue) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            SizedBox(width: 8.w),
            const Text('Xác nhận xóa'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc muốn xóa công việc này?'),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Text(
                issue.title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Hành động này không thể hoàn tác.',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.error,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              this.context.read<IssueBloc>().add(IssueDelete(issue.id));
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text('Đã xóa công việc "${issue.title}"'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            icon: const Icon(Icons.delete),
            label: const Text('Xóa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
          ),
        ],
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
    DateTime? dueDate;

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
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
                
                // Title
                Text('Tạo tác vụ mới', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 24.h),
                
                // Task Title
                Text('Tiêu đề *', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                SizedBox(height: 8.h),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Nhập tiêu đề tác vụ',
                    prefixIcon: Icon(Icons.edit_note, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                
                // Description
                Text('Mô tả', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                SizedBox(height: 8.h),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Mô tả chi tiết (không bắt buộc)',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                
                // Type & Priority Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Loại', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                          SizedBox(height: 8.h),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: DropdownButtonFormField<IssueType>(
                              value: selectedType,
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  selectedType == IssueType.bug ? Icons.bug_report 
                                    : selectedType == IssueType.story ? Icons.auto_stories 
                                    : Icons.task_alt,
                                  color: selectedType == IssueType.bug ? Colors.red 
                                    : selectedType == IssueType.story ? Colors.purple 
                                    : AppColors.primary,
                                  size: 20.w,
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                                border: InputBorder.none,
                              ),
                              items: IssueType.values.map((t) => DropdownMenuItem(
                                value: t, 
                                child: Text(t.displayName, style: TextStyle(fontSize: 14.sp)),
                              )).toList(),
                              onChanged: (v) => setModalState(() => selectedType = v!),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Độ ưu tiên', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                          SizedBox(height: 8.h),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: DropdownButtonFormField<IssuePriority>(
                              value: selectedPriority,
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.flag,
                                  color: selectedPriority == IssuePriority.critical ? Colors.red 
                                    : selectedPriority == IssuePriority.high ? Colors.orange 
                                    : selectedPriority == IssuePriority.medium ? AppColors.info 
                                    : Colors.grey,
                                  size: 20.w,
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                                border: InputBorder.none,
                              ),
                              items: IssuePriority.values.map((p) => DropdownMenuItem(
                                value: p, 
                                child: Text(p.displayName, style: TextStyle(fontSize: 14.sp)),
                              )).toList(),
                              onChanged: (v) => setModalState(() => selectedPriority = v!),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                
                // Due Date
                Text('Hạn hoàn thành', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                SizedBox(height: 8.h),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: dueDate ?? DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setModalState(() => dueDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 20.w),
                        SizedBox(width: 12.w),
                        Text(
                          dueDate != null 
                            ? DateFormat('dd/MM/yyyy').format(dueDate!) 
                            : 'Chọn ngày (không bắt buộc)',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: dueDate != null ? AppColors.textPrimary : AppColors.textHint,
                          ),
                        ),
                        const Spacer(),
                        if (dueDate != null)
                          GestureDetector(
                            onTap: () => setModalState(() => dueDate = null),
                            child: Icon(Icons.close, size: 18.w, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                
                // Create Button
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text('Vui lòng nhập tiêu đề'), backgroundColor: AppColors.warning),
                        );
                        return;
                      }
                      final issue = Issue(
                        id: '',
                        projectId: widget.projectId,
                        title: titleController.text.trim(),
                        description: descController.text.trim(),
                        type: selectedType,
                        priority: selectedPriority,
                        reporterId: userId,
                        dueDate: dueDate,
                        createdAt: DateTime.now(),
                      );
                      context.read<IssueBloc>().add(IssueCreate(issue));
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      elevation: 0,
                    ),
                    child: Text('Tạo tác vụ', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
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

  // ========== EDIT PROJECT ==========
  void _showEditProjectDialog() {
    final project = _project;
    if (project == null) return;

    final nameController = TextEditingController(text: project.name);
    final descController = TextEditingController(text: project.description ?? '');
    ProjectStatus selectedStatus = project.status;
    DateTime? startDate = project.startDate;
    DateTime? endDate = project.endDate;
    bool isLoading = false;

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
          child: SingleChildScrollView(
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
                Text('Chỉnh sửa dự án', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 20.h),
                
                // Project Name
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên dự án *',
                    prefixIcon: const Icon(Icons.folder),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
                SizedBox(height: 14.h),
                
                // Description
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
                SizedBox(height: 14.h),
                
                // Status
                DropdownButtonFormField<ProjectStatus>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Trạng thái',
                    prefixIcon: const Icon(Icons.flag),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  items: ProjectStatus.values.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.displayName),
                  )).toList(),
                  onChanged: (v) => setModalState(() => selectedStatus = v!),
                ),
                SizedBox(height: 14.h),
                
                // Dates
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setModalState(() => startDate = picked);
                        },
                        child: Container(
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 18.w, color: AppColors.textSecondary),
                              SizedBox(width: 8.w),
                              Text(
                                startDate != null ? DateFormat('dd/MM/yyyy').format(startDate!) : 'Ngày bắt đầu',
                                style: TextStyle(
                                  color: startDate != null ? AppColors.textPrimary : AppColors.textHint,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: endDate ?? DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setModalState(() => endDate = picked);
                        },
                        child: Container(
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.event, size: 18.w, color: AppColors.textSecondary),
                              SizedBox(width: 8.w),
                              Text(
                                endDate != null ? DateFormat('dd/MM/yyyy').format(endDate!) : 'Ngày kết thúc',
                                style: TextStyle(
                                  color: endDate != null ? AppColors.textPrimary : AppColors.textHint,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                
                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text('Vui lòng nhập tên dự án'), backgroundColor: AppColors.error),
                        );
                        return;
                      }
                      
                      setModalState(() => isLoading = true);
                      
                      try {
                        final updatedProject = Project(
                          id: project.id,
                          name: nameController.text.trim(),
                          description: descController.text.trim(),
                          status: selectedStatus,
                          ownerId: project.ownerId,
                          memberIds: project.memberIds,
                          startDate: startDate,
                          endDate: endDate,
                          progress: project.progress,
                          createdAt: project.createdAt,
                        );
                        
                        await ProjectDataSourceImpl().updateProject(updatedProject);
                        
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Cập nhật dự án thành công!'), backgroundColor: AppColors.success),
                          );
                          _loadProject(); // Reload project data
                        }
                      } catch (e) {
                        setModalState(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Lưu thay đổi', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== MANAGE MEMBERS ==========
  void _showManageMembersSheet() {
    final project = _project;
    if (project == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ManageMembersSheet(
        projectId: project.id,
        memberIds: List<String>.from(project.memberIds),
        ownerId: project.ownerId,
        onMemberAdded: (userId) async {
          await ProjectDataSourceImpl().addMember(project.id, userId);
          _loadProject();
        },
        onMemberRemoved: (userId) async {
          await ProjectDataSourceImpl().removeMember(project.id, userId);
          _loadProject();
        },
      ),
    );
  }

  // ========== DELETE PROJECT ==========
  void _showDeleteConfirmation() {
    final project = _project;
    if (project == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28.w),
            SizedBox(width: 10.w),
            const Text('Xóa dự án'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc chắn muốn xóa dự án "${project.name}"?'),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red, size: 18.w),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Hành động này không thể hoàn tác. Tất cả tasks và dữ liệu liên quan sẽ bị xóa.',
                      style: TextStyle(fontSize: 12.sp, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              
              try {
                await ProjectDataSourceImpl().deleteProject(project.id);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('Đã xóa dự án!'), backgroundColor: AppColors.success),
                  );
                  Navigator.pop(context, true); // Return true to trigger refresh
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
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

// ========== MANAGE MEMBERS SHEET ==========
class _ManageMembersSheet extends StatefulWidget {
  final String projectId;
  final List<String> memberIds;
  final String ownerId;
  final Future<void> Function(String userId) onMemberAdded;
  final Future<void> Function(String userId) onMemberRemoved;

  const _ManageMembersSheet({
    required this.projectId,
    required this.memberIds,
    required this.ownerId,
    required this.onMemberAdded,
    required this.onMemberRemoved,
  });

  @override
  State<_ManageMembersSheet> createState() => _ManageMembersSheetState();
}

class _ManageMembersSheetState extends State<_ManageMembersSheet> {
  final _searchController = TextEditingController();
  List<User> _members = [];
  List<User> _searchResults = [];
  bool _loading = true;
  bool _searching = false;
  String? _actionUserId; // Track which user is being added/removed

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final datasource = UserDataSourceImpl();
      final List<User> members = [];
      
      for (final id in widget.memberIds) {
        try {
          final userModel = await datasource.getUserById(id);
          members.add(userModel.toEntity());
        } catch (_) {
          // User not found, skip
        }
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

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }

    setState(() => _searching = true);

    try {
      final datasource = UserDataSourceImpl();
      final results = await datasource.searchUsers(query);
      
      if (mounted) {
        setState(() {
          // Filter out already members
          _searchResults = results
              .map((m) => m.toEntity())
              .where((u) => !widget.memberIds.contains(u.id))
              .toList();
          _searching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _searching = false;
        });
      }
    }
  }

  Future<void> _addMember(User user) async {
    setState(() => _actionUserId = user.id);
    try {
      await widget.onMemberAdded(user.id);
      if (mounted) {
        setState(() {
          widget.memberIds.add(user.id);
          _members.add(user);
          _searchResults.removeWhere((u) => u.id == user.id);
          _searchController.clear();
          _actionUserId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã thêm ${user.displayName ?? user.email}'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _actionUserId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _removeMember(User user) async {
    // Can't remove owner
    if (user.id == widget.ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xóa chủ dự án'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _actionUserId = user.id);
    try {
      await widget.onMemberRemoved(user.id);
      if (mounted) {
        setState(() {
          widget.memberIds.remove(user.id);
          _members.removeWhere((m) => m.id == user.id);
          _actionUserId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa ${user.displayName ?? user.email}'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _actionUserId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: EdgeInsets.only(top: 12.h, bottom: 8.h),
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          
          // Title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Text('Quản lý thành viên', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text('${_members.length} thành viên', style: TextStyle(fontSize: 12.sp, color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          
          // Search field
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm để thêm thành viên...',
                prefixIcon: const Icon(Icons.person_add),
                suffixIcon: _searching
                    ? Padding(
                        padding: EdgeInsets.all(12.w),
                        child: SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              ),
              onChanged: _searchUsers,
            ),
          ),
          
          // Search results
          if (_searchResults.isNotEmpty)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              constraints: BoxConstraints(maxHeight: 150.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (ctx, idx) {
                  final user = _searchResults[idx];
                  final isAdding = _actionUserId == user.id;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        (user.displayName ?? user.email)[0].toUpperCase(),
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(user.displayName ?? 'No name'),
                    subtitle: Text(user.email, style: TextStyle(fontSize: 12.sp)),
                    trailing: isAdding
                        ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.add_circle, color: AppColors.primary),
                    onTap: isAdding ? null : () => _addMember(user),
                  );
                },
              ),
            ),
          
          SizedBox(height: 12.h),
          Divider(height: 1, color: AppColors.border),
          
          // Current members
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _members.isEmpty
                    ? Center(child: Text('Chưa có thành viên', style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        itemCount: _members.length,
                        itemBuilder: (ctx, idx) {
                          final member = _members[idx];
                          final isOwner = member.id == widget.ownerId;
                          final isRemoving = _actionUserId == member.id;
                          
                          return Container(
                            margin: EdgeInsets.only(bottom: 8.h),
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: isOwner ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: isOwner ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20.r,
                                  backgroundColor: isOwner ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
                                  child: Text(
                                    (member.displayName ?? member.email)[0].toUpperCase(),
                                    style: TextStyle(
                                      color: isOwner ? Colors.white : AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            member.displayName ?? 'No name',
                                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp),
                                          ),
                                          if (isOwner) ...[
                                            SizedBox(width: 6.w),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius: BorderRadius.circular(4.r),
                                              ),
                                              child: Text('Owner', style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ],
                                      ),
                                      Text(member.email, style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                if (!isOwner)
                                  isRemoving
                                      ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(strokeWidth: 2))
                                      : IconButton(
                                          onPressed: () => _removeMember(member),
                                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                          tooltip: 'Xóa thành viên',
                                        ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
