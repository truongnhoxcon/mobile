/// PM Dashboard Tab
/// 
/// Dashboard for Project Manager showing KPIs, tasks, and projects.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../config/routes/app_router.dart';
import '../../../../domain/entities/project.dart';
import '../../../../data/datasources/project_datasource.dart';
import '../../../blocs/blocs.dart';

/// PM Dashboard Tab - Dashboard + Tasks + Projects
class PMDashboardTab extends StatefulWidget {
  const PMDashboardTab({super.key});

  @override
  State<PMDashboardTab> createState() => _PMDashboardTabState();
}

class _PMDashboardTabState extends State<PMDashboardTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Projects state
  List<Project> _projects = [];
  bool _loadingProjects = true;
  String? _projectsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _loadingProjects = true;
      _projectsError = null;
    });
    
    try {
      final authState = context.read<AuthBloc>().state;
      final userId = authState.user?.id ?? '';
      
      if (userId.isEmpty) {
        throw Exception('User not authenticated');
      }
      
      final datasource = ProjectDataSourceImpl();
      // Only get projects where user is a member
      final projectModels = await datasource.getProjectsByUser(userId);
      if (mounted) {
        setState(() {
          _projects = projectModels.map((m) => m.toEntity()).toList();
          _loadingProjects = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _projectsError = e.toString();
          _loadingProjects = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // KPI Summary Cards
        _buildKPICards(),
        
        // Tab Bar
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Tác vụ của tôi', icon: Icon(Icons.list_alt)),
              Tab(text: 'Dự án', icon: Icon(Icons.folder_open)),
              Tab(text: 'Hiệu suất', icon: Icon(Icons.analytics)),
            ],
          ),
        ),
        
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMyTasksTab(),
              _buildProjectsTab(),
              _buildPerformanceTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKPICards() {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(child: _buildKPICard('Dự án', '5', Icons.folder, AppColors.primary)),
          SizedBox(width: 12.w),
          Expanded(child: _buildKPICard('Hoàn thành', '12', Icons.check_circle, AppColors.success)),
          SizedBox(width: 12.w),
          Expanded(child: _buildKPICard('Quá hạn', '3', Icons.warning, AppColors.error)),
        ],
      ),
    );
  }

  Widget _buildKPICard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.w),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyTasksTab() {
    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Reload tasks
      },
      child: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // Toolbar
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm tác vụ...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              ElevatedButton.icon(
                onPressed: () {
                  context.push(AppRoutes.pmCreateTask);
                },
                icon: const Icon(Icons.add),
                label: const Text('Tạo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          // Tasks List - Placeholder
          _buildTaskItem(
            'Thiết kế UI Dashboard',
            'Dự án A',
            'Đang thực hiện',
            AppColors.primary,
            '25/12/2024',
          ),
          _buildTaskItem(
            'Tích hợp API Backend',
            'Dự án B',
            'Chờ xử lý',
            AppColors.warning,
            '28/12/2024',
          ),
          _buildTaskItem(
            'Review code PR #123',
            'Dự án A',
            'Hoàn thành',
            AppColors.success,
            '20/12/2024',
          ),
          
          // Empty state if no tasks
          Center(
            child: Column(
              children: [
                SizedBox(height: 40.h),
                Icon(Icons.task_alt, size: 64.w, color: AppColors.textSecondary),
                SizedBox(height: 16.h),
                Text(
                  'Đây là demo, dữ liệu thực từ API',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(String title, String project, String status, Color statusColor, String dueDate) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.folder_outlined, size: 14.w, color: AppColors.textSecondary),
                    SizedBox(width: 4.w),
                    Text(project, style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
                    SizedBox(width: 16.w),
                    Icon(Icons.schedule, size: 14.w, color: AppColors.textSecondary),
                    SizedBox(width: 4.w),
                    Text(dueDate, style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
                  ],
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
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsTab() {
    return RefreshIndicator(
      onRefresh: _loadProjects,
      child: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // Toolbar
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await context.push(AppRoutes.pmCreateProject);
                  if (result == true) {
                    _loadProjects(); // Reload after creating
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Tạo dự án'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadProjects,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          // Loading state
          if (_loadingProjects)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )),
          
          // Error state
          if (_projectsError != null)
            Center(
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48.w, color: AppColors.error),
                  SizedBox(height: 8.h),
                  Text('Lỗi: $_projectsError', style: TextStyle(color: AppColors.error)),
                  TextButton(onPressed: _loadProjects, child: const Text('Thử lại')),
                ],
              ),
            ),
          
          // Empty state
          if (!_loadingProjects && _projectsError == null && _projects.isEmpty)
            Center(
              child: Column(
                children: [
                  SizedBox(height: 32.h),
                  Icon(Icons.folder_off, size: 64.w, color: AppColors.textSecondary),
                  SizedBox(height: 16.h),
                  Text('Chưa có dự án nào', style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary)),
                  SizedBox(height: 8.h),
                  TextButton.icon(
                    onPressed: () => context.push(AppRoutes.pmCreateProject),
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo dự án đầu tiên'),
                  ),
                ],
              ),
            ),
          
          // Projects List
          if (!_loadingProjects && _projectsError == null)
            ..._projects.map((project) => _buildProjectCardFromEntity(project)).toList(),
        ],
      ),
    );
  }

  Widget _buildProjectCardFromEntity(Project project) {
    final statusColor = _getStatusColor(project.status);
    final progress = project.progress / 100.0;
    
    return GestureDetector(
      onTap: () {
        context.push('/projects/${project.id}');
      },
      child: Container(
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
            Row(
              children: [
                Icon(Icons.folder, color: Colors.amber, size: 24.w),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    project.name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    project.status.displayName,
                    style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            if (project.description != null && project.description!.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                project.description!,
                style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 6.h,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  '${project.progress}%',
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.planning:
        return AppColors.warning;
      case ProjectStatus.active:
        return AppColors.primary;
      case ProjectStatus.onHold:
        return Colors.orange;
      case ProjectStatus.completed:
        return AppColors.success;
      case ProjectStatus.archived:
        return AppColors.textSecondary;
    }
  }

  Widget _buildProjectCard(String name, String description, String status, Color statusColor, double progress) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to project detail
      },
      child: Container(
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
            Row(
              children: [
                Icon(Icons.folder, color: Colors.amber, size: 24.w),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              description,
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 6.h,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Stats
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng quan hiệu suất',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPerformanceStat('Tổng dự án', '5', Icons.folder),
                    _buildPerformanceStat('Tasks hoàn thành', '45', Icons.check_circle),
                    _buildPerformanceStat('Tỷ lệ', '78%', Icons.trending_up),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24.h),
          
          Text(
            'Chi tiết theo dự án',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          
          // Project performance table - placeholder
          _buildPerformanceRow('Dự án Mobile App', 20, 13, 2, 65),
          _buildPerformanceRow('Dự án Web Dashboard', 15, 15, 0, 100),
          _buildPerformanceRow('Dự án API Backend', 10, 2, 1, 20),
        ],
      ),
    );
  }

  Widget _buildPerformanceStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28.w),
        SizedBox(height: 8.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceRow(String projectName, int total, int completed, int overdue, int percent) {
    Color progressColor = percent >= 80 ? AppColors.success : percent >= 50 ? AppColors.warning : AppColors.error;
    
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
          Text(
            projectName,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _buildStatChip('Tổng: $total', AppColors.primary),
              SizedBox(width: 8.w),
              _buildStatChip('Xong: $completed', AppColors.success),
              SizedBox(width: 8.w),
              _buildStatChip('Quá hạn: $overdue', AppColors.error),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 8.h,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: progressColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
