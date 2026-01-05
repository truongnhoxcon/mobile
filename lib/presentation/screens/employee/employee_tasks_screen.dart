/// Employee Tasks Screen
/// 
/// Screen for Employee showing their assigned tasks and projects.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../../core/theme/app_colors.dart';
import '../../../config/routes/app_router.dart';
import '../../../domain/entities/project.dart';
import '../../../domain/entities/issue.dart';
import '../../../domain/entities/chat_room.dart';
import '../../../data/datasources/project_datasource.dart';
import '../../../data/datasources/issue_datasource.dart';
import '../../../data/datasources/chat_datasource.dart';
import '../../blocs/blocs.dart';

import '../files/files_screen.dart';

import '../../widgets/common/pastel_background.dart';

class EmployeeTasksScreen extends StatefulWidget {
  const EmployeeTasksScreen({super.key});

  @override
  State<EmployeeTasksScreen> createState() => _EmployeeTasksScreenState();
}

class _EmployeeTasksScreenState extends State<EmployeeTasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _projectSearchController = TextEditingController();
  
  // Projects state
  List<Project> _projects = [];
  List<Project> _filteredProjects = [];
  bool _loadingProjects = true;
  ProjectStatus? _selectedProjectStatus;
  
  // My Tasks state
  List<Issue> _myTasks = [];
  List<Issue> _filteredTasks = [];
  bool _loadingTasks = true;
  String _searchQuery = '';
  String? _selectedProjectId;
  StreamSubscription? _tasksSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _loadProjects();
    _subscribeToTasks();
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
          _filteredProjects = _projects; // Initialize filtered list
          _loadingProjects = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingProjects = false);
      }
    }
  }

  void _subscribeToTasks() {
    final authState = context.read<AuthBloc>().state;
    final userId = authState.user?.id ?? '';
    
    if (userId.isEmpty) return;
    
    setState(() => _loadingTasks = true);
    
    final datasource = IssueDataSourceImpl();
    _tasksSubscription = datasource.issuesStreamByAssignee(userId).listen(
      (issueModels) {
        if (mounted) {
          setState(() {
            _myTasks = issueModels.map((m) => m.toEntity()).toList();
            _filteredTasks = _myTasks;
            _loadingTasks = false;
          });
          _filterTasks();
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() => _loadingTasks = false);
        }
      },
    );
  }

  Future<void> _loadMyTasks() async {
    // For pull-to-refresh, just wait a bit for the stream to update
    await Future.delayed(const Duration(milliseconds: 500));
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
    _tasksSubscription?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final isPM = authState.user?.isProjectManager == true;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Công việc',
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
        child: Column(
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
      ),
      ),
    );
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
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) return;
                  final projectName = nameController.text.trim();
                  final project = Project(
                    id: '',
                    name: projectName,
                    description: descController.text.trim(),
                    ownerId: userId,
                    memberIds: [userId],
                    createdAt: DateTime.now(),
                  );
                  // Create project (chat room is auto-created in ProjectDataSourceImpl.createProject)
                  final projectDatasource = ProjectDataSourceImpl();
                  await projectDatasource.createProject(project);
                  
                  Navigator.pop(ctx);
                  // Reload projects
                  _loadProjects();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã tạo dự án và phòng chat mới')),
                  );
                },
                child: const Text('Tạo dự án'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyTasksTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([_loadMyTasks(), _loadProjects()]);
      },
      child: _loadingTasks
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                // Filter and Search Row
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
                    SizedBox(width: 12.w),
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
                  ],
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
                              ? 'Không có công việc nào'
                              : 'Không tìm thấy kết quả',
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
        padding: EdgeInsets.all(12.w), // Compact padding
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: Offset(0, 2)),
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
                          // Priority Flag?
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

  Widget _buildProjectsTab() {
    final authState = context.read<AuthBloc>().state;
    final isPM = authState.user?.isProjectManager == true;
    
    // Use filtered projects if searching/filtering, otherwise use all projects
    final displayProjects = (_projectSearchController.text.isNotEmpty || _selectedProjectStatus != null)
        ? _filteredProjects
        : _projects;
    
    return RefreshIndicator(
      onRefresh: _loadProjects,
      child: _loadingProjects
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                // Search, Filter and Create button row
                Row(
                  children: [
                    // Search field
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _projectSearchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm dự án...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) => _filterProjects(),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // Status filter dropdown
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ProjectStatus?>(
                          value: _selectedProjectStatus,
                          hint: Text('Lọc', style: TextStyle(fontSize: 12.sp)),
                          icon: Icon(Icons.filter_list, size: 18.w),
                          items: [
                            DropdownMenuItem<ProjectStatus?>(
                              value: null,
                              child: Text('Tất cả', style: TextStyle(fontSize: 12.sp)),
                            ),
                            ...ProjectStatus.values.map((s) => DropdownMenuItem<ProjectStatus?>(
                              value: s,
                              child: Text(s.displayName, style: TextStyle(fontSize: 11.sp)),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedProjectStatus = value;
                              _filterProjects();
                            });
                          },
                        ),
                      ),
                    ),
                    // Create button for PM
                    if (isPM) ...[
                      SizedBox(width: 8.w),
                      IconButton(
                        onPressed: () => _showCreateProjectDialog(context),
                        icon: Icon(Icons.add_circle, color: AppColors.primary, size: 32.w),
                        tooltip: 'Tạo dự án mới',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 16.h),
                // Projects list
                if (displayProjects.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40.h),
                      child: Column(
                        children: [
                          Icon(Icons.folder_open, size: 64.w, color: AppColors.textSecondary),
                          SizedBox(height: 16.h),
                          Text(
                            _projects.isEmpty ? 'Chưa có dự án nào' : 'Không tìm thấy dự án',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...displayProjects.map((project) => _buildProjectItem(project)),
              ],
            ),
    );
  }

  void _filterProjects() {
    final query = _projectSearchController.text.toLowerCase();
    setState(() {
      _filteredProjects = _projects.where((project) {
        final matchesSearch = query.isEmpty || 
            project.name.toLowerCase().contains(query) ||
            (project.description?.toLowerCase().contains(query) ?? false);
        final matchesStatus = _selectedProjectStatus == null || 
            project.status == _selectedProjectStatus;
        return matchesSearch && matchesStatus;
      }).toList();
    });
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
      onTap: () {
        context.push('/projects/${project.id}').then((_) {
          // Reload projects when returning (in case of deletion/update)
          _loadProjects();
        });
      },
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
