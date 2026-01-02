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
import '../../../../domain/entities/issue.dart';
import '../../../../data/datasources/project_datasource.dart';
import '../../../../data/datasources/issue_datasource.dart';
import '../../../blocs/blocs.dart';
import '../../files/files_screen.dart';

/// PM Dashboard Tab - Dashboard + Tasks + Projects
class PMDashboardTab extends StatefulWidget {
  const PMDashboardTab({super.key});

  @override
  State<PMDashboardTab> createState() => _PMDashboardTabState();
}

class _PMDashboardTabState extends State<PMDashboardTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  // Projects state
  List<Project> _projects = [];
  bool _loadingProjects = true;
  String? _projectsError;
  
  // My Tasks state
  List<Issue> _myTasks = [];
  List<Issue> _filteredTasks = [];
  bool _loadingTasks = true;
  String? _tasksError;
  String _searchQuery = '';
  String? _selectedProjectId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _loadProjects();
    _loadMyTasks();
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

  Future<void> _loadMyTasks() async {
    setState(() {
      _loadingTasks = true;
      _tasksError = null;
    });
    
    try {
      final authState = context.read<AuthBloc>().state;
      final userId = authState.user?.id ?? '';
      
      if (userId.isEmpty) {
        throw Exception('User not authenticated');
      }
      
      final datasource = IssueDataSourceImpl();
      final issueModels = await datasource.getIssuesByAssignee(userId);
      if (mounted) {
        setState(() {
          _myTasks = issueModels.map((m) => m.toEntity()).toList();
          _filteredTasks = _myTasks;
          _loadingTasks = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _tasksError = e.toString();
          _loadingTasks = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    _filterTasks();
  }

  void _filterTasks() {
    setState(() {
      _searchQuery = _searchController.text;
      
      _filteredTasks = _myTasks.where((task) {
        final matchesSearch = _searchQuery.isEmpty || 
            task.title.toLowerCase().contains(_searchQuery.toLowerCase());
        
        final matchesProject = _selectedProjectId == null || 
            task.projectId == _selectedProjectId;
            
        return matchesSearch && matchesProject;
      }).toList();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
              Tab(text: 'Tài liệu', icon: Icon(Icons.description_outlined)),
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
              const FilesScreen(isEmbedded: true),
            ],
          ),
        ),
      ],
    );
  }



  Widget _buildMyTasksTab() {
    return RefreshIndicator(
      onRefresh: _loadMyTasks,
      child: _loadingTasks
          ? const Center(child: CircularProgressIndicator())
          : _tasksError != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48.w, color: AppColors.error),
                      SizedBox(height: 16.h),
                      Text('Lỗi: $_tasksError', style: TextStyle(color: AppColors.error)),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: _loadMyTasks,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: EdgeInsets.all(16.w),
                  children: [
                    // Toolbar - Filter and Search Row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Tìm kiếm...',
                              prefixIcon: const Icon(Icons.search),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedProjectId,
                                hint: Text('Tất cả DA', style: TextStyle(fontSize: 12.sp)),
                                isExpanded: true,
                                items: [
                                  DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('Tất cả dự án', style: TextStyle(fontSize: 12.sp)),
                                  ),
                                  ..._projects.map((p) => DropdownMenuItem<String>(
                                    value: p.id,
                                    child: Text(p.name, style: TextStyle(fontSize: 12.sp), overflow: TextOverflow.ellipsis),
                                  )),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedProjectId = value;
                                    _filterTasks();
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        // Add button - circular + icon
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: IconButton(
                            onPressed: () => context.push(AppRoutes.pmCreateTask),
                            icon: const Icon(Icons.add, color: Colors.white),
                            constraints: BoxConstraints(minWidth: 44.w, minHeight: 44.h),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    
                    // Tasks List
                    if (_filteredTasks.isEmpty && _searchQuery.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            SizedBox(height: 40.h),
                            Icon(Icons.task_alt, size: 64.w, color: AppColors.textSecondary),
                            SizedBox(height: 16.h),
                            Text(
                              'Chưa có công việc nào được giao',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
                            ),
                          ],
                        ),
                      )
                    else if (_filteredTasks.isEmpty && _searchQuery.isNotEmpty)
                      Center(
                        child: Column(
                          children: [
                            SizedBox(height: 40.h),
                            Icon(Icons.search_off, size: 64.w, color: AppColors.textSecondary),
                            SizedBox(height: 16.h),
                            Text(
                              'Không tìm thấy "$_searchQuery"',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._filteredTasks.map((task) => _buildRealTaskItem(task)).toList(),
                  ],
                ),
    );
  }

  Widget _buildRealTaskItem(Issue task) {
    Color statusColor;
    String statusText;
    switch (task.status) {
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
    
    final dueDate = task.dueDate != null 
        ? DateFormat('dd/MM').format(task.dueDate!)
        : '--/--';

    // Find Project Name
    final project = _projects.where((p) => p.id == task.projectId).firstOrNull;
    final projectName = project?.name ?? 'Unknown Project';

    return InkWell(
      onTap: () => context.pushNamed('taskDetail', pathParameters: {'id': task.id}),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Name Tag
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_outlined, size: 12.w, color: AppColors.primary),
                  SizedBox(width: 4.w),
                  Flexible(
                    child: Text(
                      projectName,
                      style: TextStyle(fontSize: 11.sp, color: AppColors.primary, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 12.w, color: AppColors.textSecondary),
                          SizedBox(width: 4.w),
                          Text(dueDate, style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
                          SizedBox(width: 12.w),
                          Icon(Icons.flag, size: 12.w, color: _getPriorityColor(task.priority)),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(IssuePriority priority) {
    switch (priority) {
      case IssuePriority.critical: return Colors.red;
      case IssuePriority.high: return Colors.orange;
      case IssuePriority.medium: return Colors.blue;
      case IssuePriority.low: return Colors.grey;
    }
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
      onTap: () async {
        final result = await context.push('/projects/${project.id}');
        if (result == true) {
          _loadProjects(); // Reload after delete or update
        }
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
