import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/department.dart';
import '../../../domain/entities/employee.dart';
import '../../blocs/blocs.dart';

/// Department Detail Screen - Shows department info and employees list
class DepartmentDetailScreen extends StatefulWidget {
  final String departmentId;

  const DepartmentDetailScreen({
    super.key,
    required this.departmentId,
  });

  @override
  State<DepartmentDetailScreen> createState() => _DepartmentDetailScreenState();
}

class _DepartmentDetailScreenState extends State<DepartmentDetailScreen> {
  Department? _department;
  List<Employee> _employees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDepartmentData();
  }

  void _loadDepartmentData() {
    final hrState = context.read<HRBloc>().state;
    
    // Find department from state
    final dept = hrState.departments.firstWhere(
      (d) => d.id == widget.departmentId,
      orElse: () => Department(id: '', tenPhongBan: 'Không tìm thấy'),
    );
    
    // Filter employees by department
    final employees = hrState.employees.where(
      (e) => e.phongBanId == widget.departmentId
    ).toList();
    
    setState(() {
      _department = dept;
      _employees = employees;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_department?.tenPhongBan ?? 'Chi tiết phòng ban'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDepartmentDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_department == null || _department!.id.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.w, color: AppColors.error),
            SizedBox(height: 16.h),
            Text(
              'Không tìm thấy phòng ban',
              style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadDepartmentData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Department Info Header
            _buildDepartmentHeader(),
            
            // Statistics
            _buildStatistics(),
            
            // Employees List
            _buildEmployeesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  Icons.business,
                  size: 40.w,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _department!.tenPhongBan,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_department!.moTa != null && _department!.moTa!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Text(
                          _department!.moTa!,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.people,
              label: 'Nhân viên',
              value: '${_employees.length}',
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildStatCard(
              icon: Icons.check_circle,
              label: 'Đang làm việc',
              value: '${_employees.where((e) => e.status == EmployeeStatus.working).length}',
              color: AppColors.success,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildStatCard(
              icon: Icons.pause_circle,
              label: 'Tạm nghỉ',
              value: '${_employees.where((e) => e.status == EmployeeStatus.tempOff).length}',
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
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
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Icon(Icons.people, color: AppColors.primary, size: 20.w),
              SizedBox(width: 8.w),
              Text(
                'Danh sách nhân viên',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${_employees.length} người',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        
        if (_employees.isEmpty)
          Padding(
            padding: EdgeInsets.all(32.w),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.people_outline, size: 48.w, color: AppColors.textSecondary),
                  SizedBox(height: 12.h),
                  Text(
                    'Chưa có nhân viên nào trong phòng ban này',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: _employees.length,
            itemBuilder: (context, index) {
              return _buildEmployeeCard(_employees[index]);
            },
          ),
        
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    final statusColor = employee.status == EmployeeStatus.working
        ? AppColors.success
        : employee.status == EmployeeStatus.tempOff
            ? AppColors.warning
            : AppColors.error;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24.r,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: employee.avatarUrl != null
                ? NetworkImage(employee.avatarUrl!)
                : null,
            child: employee.avatarUrl == null
                ? Text(
                    employee.hoTen.isNotEmpty ? employee.hoTen[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          SizedBox(width: 12.w),
          
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
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        employee.status.displayName,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                if (employee.tenChucVu != null)
                  Text(
                    employee.tenChucVu!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  Text(
                    'Chưa có chức vụ',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    if (employee.email != null && employee.email!.isNotEmpty) ...[
                      Icon(Icons.email_outlined, size: 12.w, color: AppColors.textSecondary),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          employee.email!,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                if (employee.ngayVaoLam != null) ...[
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12.w, color: AppColors.textSecondary),
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

  void _showEditDepartmentDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: _department?.tenPhongBan ?? '');
    final descController = TextEditingController(text: _department?.moTa ?? '');

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
                context.read<HRBloc>().add(HRUpdateDepartment(
                  id: _department!.id,
                  name: nameController.text.trim(),
                  description: descController.text.trim().isNotEmpty 
                      ? descController.text.trim() 
                      : null,
                ));
                Navigator.pop(dialogContext);
                // Reload data after update
                Future.delayed(const Duration(milliseconds: 500), () {
                  _loadDepartmentData();
                });
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
}
