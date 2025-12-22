import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/employee.dart';
import '../../../blocs/blocs.dart';

/// HR Employees Tab - Danh sách nhân viên
class HREmployeesTab extends StatefulWidget {
  const HREmployeesTab({super.key});

  @override
  State<HREmployeesTab> createState() => _HREmployeesTabState();
}

class _HREmployeesTabState extends State<HREmployeesTab> {
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'ALL';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadEmployees() {
    context.read<HRBloc>().add(HRLoadEmployees(
      searchQuery: _searchController.text,
      statusFilter: _statusFilter,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filter Bar
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            children: [
              // Search Box
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm nhân viên...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                ),
                onChanged: (value) => _loadEmployees(),
              ),
              SizedBox(height: 12.h),
              
              // Status Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Tất cả', 'ALL'),
                    SizedBox(width: 8.w),
                    _buildFilterChip('Đang làm', 'DANG_LAM_VIEC'),
                    SizedBox(width: 8.w),
                    _buildFilterChip('Tạm nghỉ', 'TAM_NGHI'),
                    SizedBox(width: 8.w),
                    _buildFilterChip('Nghỉ việc', 'NGHI_VIEC'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Employee List
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
                        onPressed: _loadEmployees,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                );
              }

              final employees = state.employees;
              if (employees.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64.w, color: AppColors.textSecondary),
                      SizedBox(height: 16.h),
                      Text(
                        'Không có nhân viên',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      ElevatedButton.icon(
                        onPressed: () => _showAddEmployeeDialog(context),
                        icon: const Icon(Icons.person_add),
                        label: const Text('Thêm nhân viên'),
                      ),
                    ],
                  ),
                );
              }

              return Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () async => _loadEmployees(),
                    child: ListView.builder(
                      padding: EdgeInsets.all(16.w),
                      itemCount: employees.length,
                      itemBuilder: (context, index) {
                        return _buildEmployeeCard(employees[index]);
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 16.h,
                    right: 16.w,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Import CSV Button
                        FloatingActionButton.small(
                          heroTag: 'import',
                          onPressed: () => _pickAndImportCSV(context),
                          backgroundColor: AppColors.success,
                          child: const Icon(Icons.upload_file, color: Colors.white),
                        ),
                        SizedBox(height: 12.h),
                        // Add Employee Button
                        FloatingActionButton.extended(
                          heroTag: 'add',
                          onPressed: () => _showAddEmployeeDialog(context),
                          backgroundColor: AppColors.primary,
                          icon: const Icon(Icons.person_add, color: Colors.white),
                          label: const Text('Thêm', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _pickAndImportCSV(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      String csvContent;

      if (file.bytes != null) {
        csvContent = utf8.decode(file.bytes!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể đọc file')),
        );
        return;
      }

      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.upload_file, color: AppColors.success),
              SizedBox(width: 8.w),
              const Text('Import CSV'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('File: ${file.name}'),
              SizedBox(height: 8.h),
              Text(
                'Format file CSV cần có các cột:\n• hoTen hoặc name (bắt buộc)\n• email\n• soDienThoai hoặc phone\n• gioiTinh hoặc gender',
                style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
              ),
              SizedBox(height: 16.h),
              const Text('Bạn có muốn import file này?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.upload),
              label: const Text('Import'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );

      if (confirm == true) {
        // ignore: use_build_context_synchronously
        this.context.read<HRBloc>().add(HRImportEmployeesFromCSV(csvContent: csvContent));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showAddEmployeeDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final hoTenController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    String gioiTinh = 'Nam';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.person_add, color: AppColors.primary),
              SizedBox(width: 8.w),
              const Text('Thêm nhân viên'),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: hoTenController,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên *',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập họ tên' : null,
                  ),
                  SizedBox(height: 12.h),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Vui lòng nhập email';
                      if (!v.contains('@')) return 'Email không hợp lệ';
                      return null;
                    },
                  ),
                  SizedBox(height: 12.h),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu *',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                      if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                      return null;
                    },
                  ),
                  SizedBox(height: 12.h),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Text('Giới tính:', style: TextStyle(fontSize: 14.sp)),
                      SizedBox(width: 16.w),
                      ChoiceChip(
                        label: const Text('Nam'),
                        selected: gioiTinh == 'Nam',
                        onSelected: (_) => setDialogState(() => gioiTinh = 'Nam'),
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      SizedBox(width: 8.w),
                      ChoiceChip(
                        label: const Text('Nữ'),
                        selected: gioiTinh == 'Nữ',
                        onSelected: (_) => setDialogState(() => gioiTinh = 'Nữ'),
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ],
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
                  this.context.read<HRBloc>().add(HRAddEmployee(
                    hoTen: hoTenController.text.trim(),
                    email: emailController.text.trim(),
                    password: passwordController.text,
                    soDienThoai: phoneController.text.trim().isNotEmpty 
                        ? phoneController.text.trim() 
                        : null,
                    gioiTinh: gioiTinh,
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

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _statusFilter = value);
        _loadEmployees();
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
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
          // Avatar
          CircleAvatar(
            radius: 28.r,
            backgroundColor: _getAvatarColor(employee.hoTen),
            backgroundImage: employee.avatarUrl != null
                ? NetworkImage(employee.avatarUrl!)
                : null,
            child: employee.avatarUrl == null
                ? Text(
                    employee.hoTen.isNotEmpty ? employee.hoTen[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          SizedBox(width: 16.w),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        employee.hoTen,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _buildStatusBadge(employee.status),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  employee.tenChucVu ?? 'Chưa có chức vụ',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.business, size: 14.w, color: AppColors.textSecondary),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        employee.tenPhongBan ?? 'Chưa phân phòng ban',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (employee.ngayVaoLam != null) ...[
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14.w, color: AppColors.textSecondary),
                      SizedBox(width: 4.w),
                      Text(
                        'Vào làm: ${DateFormat('dd/MM/yyyy').format(employee.ngayVaoLam!)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(EmployeeStatus status) {
    Color color;
    String label;
    
    switch (status) {
      case EmployeeStatus.working:
        color = AppColors.success;
        label = 'Đang làm';
        break;
      case EmployeeStatus.tempOff:
        color = AppColors.warning;
        label = 'Tạm nghỉ';
        break;
      case EmployeeStatus.terminated:
        color = AppColors.error;
        label: 'Nghỉ việc';
        label = 'Nghỉ việc';
        break;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return HSLColor.fromAHSL(1.0, (hash % 360).toDouble(), 0.6, 0.5).toColor();
  }
}
