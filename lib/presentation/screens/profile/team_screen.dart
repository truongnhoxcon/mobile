import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/employee.dart';
import '../../../config/dependencies/injection_container.dart' as di;
import '../../blocs/blocs.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/pastel_background.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<HRBloc>()..add(HRLoadEmployees()),
      child: const _TeamScreenContent(),
    );
  }
}

class _TeamScreenContent extends StatefulWidget {
  const _TeamScreenContent();

  @override
  State<_TeamScreenContent> createState() => _TeamScreenContentState();
}

class _TeamScreenContentState extends State<_TeamScreenContent> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Employee> _filterEmployees(List<Employee> employees) {
    if (_searchQuery.isEmpty) return employees;
    return employees.where((e) {
      final name = e.hoTen.toLowerCase();
      final email = e.email?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label: $text'),
        backgroundColor: AppColors.success,
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Danh bạ đồng nghiệp',
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
            Padding(
              padding: EdgeInsets.all(16.w),
              child: CustomTextField(
                label: 'Tìm kiếm',
                controller: _searchController,
                prefixIcon: Icons.search,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Expanded(
              child: BlocBuilder<HRBloc, HRState>(
                builder: (context, state) {
                  if (state.status == HRStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (state.status == HRStatus.error) {
                    return Center(child: Text('Lỗi tải dữ liệu: ${state.errorMessage}'));
                  }

                  final filteredList = _filterEmployees(state.employees);

                  if (filteredList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 60.w, color: AppColors.textHint),
                          SizedBox(height: 16.h),
                          Text(
                            'Không tìm thấy nhân viên nào',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 16.sp),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    itemCount: filteredList.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final employee = filteredList[index];
                      return _buildEmployeeCard(employee);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    return Container(
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 28.r,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: employee.avatarUrl != null ? NetworkImage(employee.avatarUrl!) : null,
            child: employee.avatarUrl == null
                ? Text(
                    employee.hoTen.isNotEmpty ? employee.hoTen[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20.sp,
                    ),
                  )
                : null,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.hoTen,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (employee.chucVuId != null) ...[
                   SizedBox(height: 4.h),
                   Text(
                     'Nhân viên', // Placeholder if position name not available directly
                     style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
                   ),
                ],
                SizedBox(height: 8.h),
                Row(
                  children: [
                    if (employee.soDienThoai != null && employee.soDienThoai!.isNotEmpty)
                      _buildContactButton(
                        Icons.phone, 
                        Color(0xFF3B82F6), 
                        () => _copyToClipboard(employee.soDienThoai!, 'Số điện thoại'),
                      ),
                    if ((employee.soDienThoai != null && employee.soDienThoai!.isNotEmpty) && 
                        (employee.email != null && employee.email!.isNotEmpty))
                      SizedBox(width: 12.w),
                    if (employee.email != null && employee.email!.isNotEmpty)
                      _buildContactButton(
                        Icons.email, 
                        Color(0xFFEF4444), 
                        () => _copyToClipboard(employee.email!, 'Email'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, size: 20.w, color: color),
      ),
    );
  }
}
