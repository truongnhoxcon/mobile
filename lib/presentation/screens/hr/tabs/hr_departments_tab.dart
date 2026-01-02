import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/department.dart';
import '../../../blocs/blocs.dart';
import '../department_detail_screen.dart';

/// HR Departments Tab - Quản lý phòng ban
class HRDepartmentsTab extends StatefulWidget {
  const HRDepartmentsTab({super.key});

  @override
  State<HRDepartmentsTab> createState() => _HRDepartmentsTabState();
}

class _HRDepartmentsTabState extends State<HRDepartmentsTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadDepartments() {
    context.read<HRBloc>().add(const HRLoadDepartments());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Add Bar
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              // Search Box
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm phòng ban...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  ),
                  onChanged: (value) => _loadDepartments(),
                ),
              ),
              SizedBox(width: 12.w),
              // Add Department Button
              ElevatedButton.icon(
                onPressed: () => _showAddDepartmentDialog(context),
                icon: Icon(Icons.add, size: 18.w),
                label: const Text('Thêm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                ),
              ),
            ],
          ),
        ),

        // Department List
        Expanded(
          child: BlocConsumer<HRBloc, HRState>(
            listener: (context, state) {
              if (state.status == HRStatus.actionSuccess && state.successMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.successMessage!),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state.status == HRStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.status == HRStatus.error) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64.w, color: AppColors.error),
                      SizedBox(height: 16.h),
                      Text(state.errorMessage ?? 'Có lỗi xảy ra'),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: _loadDepartments,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                );
              }

              final departments = state.departments;
              if (departments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business_outlined, size: 64.w, color: AppColors.textSecondary),
                      SizedBox(height: 16.h),
                      Text(
                        'Chưa có phòng ban nào',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      ElevatedButton.icon(
                        onPressed: () => _showAddDepartmentDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm phòng ban'),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _loadDepartments(),
                child: ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: departments.length,
                  itemBuilder: (context, index) {
                    return _buildDepartmentCard(departments[index]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddDepartmentDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String? selectedManagerId;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.business, color: AppColors.primary),
              SizedBox(width: 8.w),
              const Text('Thêm phòng ban'),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên phòng ban *',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập tên' : null,
                  ),
                  SizedBox(height: 12.h),
                  TextFormField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  this.context.read<HRBloc>().add(HRAddDepartment(
                    name: nameController.text.trim(),
                    description: descController.text.trim().isNotEmpty 
                        ? descController.text.trim() 
                        : null,
                    managerId: selectedManagerId,
                  ));
                  Navigator.pop(dialogContext);
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Tạo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentCard(Department department) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => BlocProvider.value(
            value: context.read<HRBloc>(),
            child: DepartmentDetailScreen(departmentId: department.id),
          ),
        ),
      ),
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
            // Icon
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.business, color: AppColors.primary, size: 28.w),
            ),
          SizedBox(width: 16.w),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  department.tenPhongBan,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (department.moTa != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    department.moTa!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(Icons.people, size: 14.w, color: AppColors.textSecondary),
                    SizedBox(width: 4.w),
                    Text(
                      '${department.soNhanVien ?? 0} nhân viên',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Actions
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _showEditDepartmentDialog(context, department);
                  break;
                case 'delete':
                  _showDeleteConfirmation(context, department);
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
                    Text('Chỉnh sửa'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Xóa', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      ),  // Close Container
    );    // Close InkWell
  }

  void _showEditDepartmentDialog(BuildContext context, Department department) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: department.tenPhongBan);
    final descController = TextEditingController(text: department.moTa ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: AppColors.primary),
            SizedBox(width: 8.w),
            const Text('Sửa phòng ban'),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên phòng ban *',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập tên' : null,
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                this.context.read<HRBloc>().add(HRUpdateDepartment(
                  id: department.id,
                  name: nameController.text.trim(),
                  description: descController.text.trim().isNotEmpty 
                      ? descController.text.trim() 
                      : null,
                ));
                Navigator.pop(dialogContext);
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Lưu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Department department) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.warning),
            SizedBox(width: 8.w),
            const Text('Xác nhận xóa'),
          ],
        ),
        content: Text('Bạn có chắc muốn xóa phòng ban "${department.tenPhongBan}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              this.context.read<HRBloc>().add(HRDeleteDepartment(department.id));
              Navigator.pop(dialogContext);
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
}
