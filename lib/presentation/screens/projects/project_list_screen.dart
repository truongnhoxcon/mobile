import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../config/dependencies/injection_container.dart' as di;
import '../../../domain/entities/project.dart';
import '../../blocs/blocs.dart';

class ProjectListScreen extends StatelessWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get current user from AuthBloc
    final authState = context.read<AuthBloc>().state;
    final userId = authState.user?.id ?? '';
    
    return BlocProvider(
      create: (_) => di.sl<ProjectBloc>()..add(ProjectLoadByUser(userId)),
      child: _ProjectListContent(userId: userId),
    );
  }
}

class _ProjectListContent extends StatefulWidget {
  final String userId;
  const _ProjectListContent({required this.userId});

  @override
  State<_ProjectListContent> createState() => _ProjectListContentState();
}

class _ProjectListContentState extends State<_ProjectListContent> {
  ProjectStatus? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dự án', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp)),
        actions: [
          PopupMenuButton<ProjectStatus?>(
            icon: Icon(Icons.filter_list, color: _selectedFilter != null ? AppColors.primary : null),
            tooltip: 'Lọc theo trạng thái',
            onSelected: (status) {
              setState(() => _selectedFilter = status);
              // Load user's projects, will filter by status in UI
              context.read<ProjectBloc>().add(ProjectLoadByUser(widget.userId));
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('Tất cả')),
              ...ProjectStatus.values.map((s) => PopupMenuItem(
                value: s,
                child: Row(
                  children: [
                    Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: _getStatusColor(s),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(s.displayName),
                  ],
                ),
              )),
            ],
          ),
        ],
      ),
      body: BlocBuilder<ProjectBloc, ProjectState>(
        builder: (context, state) {
          if (state.status == ProjectBlocStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter by status in UI if selected
          final filteredProjects = _selectedFilter == null
              ? state.projects
              : state.projects.where((p) => p.status == _selectedFilter).toList();

          if (filteredProjects.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ProjectBloc>().add(ProjectLoadByUser(widget.userId));
            },
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: filteredProjects.length,
              itemBuilder: (context, index) => _buildProjectCard(context, filteredProjects[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateProjectDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Tạo dự án'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80.w, color: AppColors.textSecondary),
          SizedBox(height: 16.h),
          Text('Chưa có dự án nào', style: TextStyle(fontSize: 18.sp, color: AppColors.textSecondary)),
          SizedBox(height: 8.h),
          Text('Nhấn + để tạo dự án mới', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, Project project) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () => context.push('/projects/${project.id}'),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.name,
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: _getStatusColor(project.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        project.status.displayName,
                        style: TextStyle(
                          color: _getStatusColor(project.status),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (project.description != null && project.description!.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Text(
                    project.description!,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: 12.h),
                // Progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tiến độ', style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
                        Text('${project.progress}%', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    LinearProgressIndicator(
                      value: project.progress / 100,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation(_getProgressColor(project.progress)),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Icon(Icons.people, size: 16.w, color: AppColors.textSecondary),
                    SizedBox(width: 4.w),
                    Text('${project.memberIds.length} thành viên', style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
                    const Spacer(),
                    if (project.endDate != null) ...[
                      Icon(Icons.calendar_today, size: 16.w, color: AppColors.textSecondary),
                      SizedBox(width: 4.w),
                      Text(DateFormat('dd/MM/yyyy').format(project.endDate!), style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.planning: return AppColors.info;
      case ProjectStatus.active: return AppColors.success;
      case ProjectStatus.onHold: return AppColors.warning;
      case ProjectStatus.completed: return AppColors.primary;
      case ProjectStatus.archived: return AppColors.textSecondary;
    }
  }

  Color _getProgressColor(int progress) {
    if (progress >= 80) return AppColors.success;
    if (progress >= 50) return AppColors.info;
    if (progress >= 25) return AppColors.warning;
    return AppColors.error;
  }

  void _showCreateProjectDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final authState = context.read<AuthBloc>().state;
    final userId = authState.user?.id ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, MediaQuery.of(ctx).viewInsets.bottom + 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tạo dự án mới', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 20.h),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Tên dự án *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
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
                  if (nameController.text.trim().isEmpty) return;
                  final project = Project(
                    id: '',
                    name: nameController.text.trim(),
                    description: descController.text.trim(),
                    ownerId: userId,
                    memberIds: [userId],
                    createdAt: DateTime.now(),
                  );
                  context.read<ProjectBloc>().add(ProjectCreate(project));
                  Navigator.pop(ctx);
                },
                child: const Text('Tạo dự án'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
