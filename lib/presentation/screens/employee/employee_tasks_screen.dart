/// Employee Tasks Screen
/// 
/// Screen for Employee showing their assigned tasks and projects.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../config/routes/app_router.dart';
import '../../../domain/entities/project.dart';
import '../../../domain/entities/issue.dart';
import '../../../data/datasources/project_datasource.dart';
import '../../../data/datasources/issue_datasource.dart';
import '../../blocs/blocs.dart';

class EmployeeTasksScreen extends StatefulWidget {
  const EmployeeTasksScreen({super.key});

  @override
  State<EmployeeTasksScreen> createState() => _EmployeeTasksScreenState();
}

class _EmployeeTasksScreenState extends State<EmployeeTasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  // Projects state
  List<Project> _projects = [];
  bool _loadingProjects = true;
  
  // My Tasks state
  List<Issue> _myTasks = [];
  List<Issue> _filteredTasks = [];
  bool _loadingTasks = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _loadProjects();
    _loadMyTasks();
  }

  Future<void> _loadProjects() async {
    setState(() => _loadingProjects = true);
    
    try {
      final authState = context.read<AuthBloc>().state;
      final userId = authState.user?.id ?? '';
      
      if (userId.isEmpty) return;
      
      final datasource = ProjectDataSourceImpl();
      final projectModels = await datasource.getProjectsByUser(userId);
      if (mounted) {
        setState(() {
          _projects = projectModels.map((m) => m.toEntity()).toList();
          _loadingProjects = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingProjects = false);
      }
    }
  }

  Future<void> _loadMyTasks() async {
    setState(() => _loadingTasks = true);
    
    try {
      final authState = context.read<AuthBloc>().state;
      final userId = authState.user?.id ?? '';
      
      if (userId.isEmpty) return;
      
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
        setState(() => _loadingTasks = false);
      }
    }
  }

  void _onSearchChanged() {
    _filterTasks(_searchController.text);
  }

  void _filterTasks(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredTasks = _myTasks;
      } else {
        _filteredTasks = _myTasks
            .where((task) => task.title.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Công việc',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
        ),
      ),
      body: Column(
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyTasksTab() {
    return RefreshIndicator(
      onRefresh: _loadMyTasks,
      child: _loadingTasks
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                // Search Box
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm tác vụ...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                
                // Tasks List
                if (_filteredTasks.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        SizedBox(height: 40.h),
                        Icon(Icons.task_alt, size: 64.w, color: AppColors.textSecondary),
                        SizedBox(height: 16.h),
                        Text(
                          _searchQuery.isEmpty 
                              ? 'Chưa có công việc nào được giao'
                              : 'Không tìm thấy "$_searchQuery"',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
                        ),
                      ],
                    ),
                  )
                else
                  ..._filteredTasks.map((task) => _buildTaskItem(task)).toList(),
              ],
            ),
    );
  }

  Widget _buildTaskItem(Issue task) {
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
    }
    
    final dueDate = task.dueDate != null 
        ? DateFormat('dd/MM/yyyy').format(task.dueDate!)
        : 'Chưa có';

    return InkWell(
      onTap: () => context.push('/task/${task.id}'),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
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
                    task.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
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
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsTab() {
    return RefreshIndicator(
      onRefresh: _loadProjects,
      child: _loadingProjects
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_off, size: 64.w, color: AppColors.textSecondary),
                      SizedBox(height: 16.h),
                      Text(
                        'Bạn chưa tham gia dự án nào',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: _projects.length,
                  itemBuilder: (context, index) => _buildProjectItem(_projects[index]),
                ),
    );
  }

  Widget _buildProjectItem(Project project) {
    Color statusColor;
    String statusText;
    switch (project.status) {
      case ProjectStatus.planning:
        statusColor = AppColors.textSecondary;
        statusText = 'Đang lên kế hoạch';
        break;
      case ProjectStatus.active:
        statusColor = AppColors.success;
        statusText = 'Đang hoạt động';
        break;
      case ProjectStatus.onHold:
        statusColor = AppColors.warning;
        statusText = 'Tạm dừng';
        break;
      case ProjectStatus.completed:
        statusColor = AppColors.primary;
        statusText = 'Hoàn thành';
        break;
      case ProjectStatus.archived:
        statusColor = AppColors.error;
        statusText = 'Đã lưu trữ';
        break;
    }

    return InkWell(
      onTap: () => context.push('/projects/${project.id}'),
      borderRadius: BorderRadius.circular(12.r),
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
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(Icons.folder, color: AppColors.primary, size: 24.w),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(color: statusColor, fontSize: 10.sp),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
            if (project.description != null && project.description!.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                project.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
