import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../config/dependencies/injection_container.dart' as di;
import '../../../domain/entities/leave_request.dart';
import '../../blocs/blocs.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/pastel_background.dart';

/// Leave Request Screen - Enhanced with quota, cancel, filter, expandable
class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<LeaveRequestBloc>()..add(const LeaveRequestLoadMy()),
      child: Scaffold(
        body: PastelBackground(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Custom Glassmorphism Header
                Container(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8E44AD).withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Bar: Back Button & Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Back Button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                              color: AppColors.textPrimary,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          // Title
                          Text(
                            'Nghỉ phép',
                            style: TextStyle(
                              fontSize: 20.sp, 
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          // Placeholder for balance (invisible)
                          SizedBox(width: 40.w), 
                        ],
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Tab Bar
                      Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.textSecondary,
                          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 14.sp),
                          dividerColor: Colors.transparent,
                          indicatorSize: TabBarIndicatorSize.tab,
                          tabs: const [
                            Tab(text: 'Tạo đơn', icon: Icon(Icons.add_circle_outline, size: 20)),
                            Tab(text: 'Đơn của tôi', icon: Icon(Icons.list_alt, size: 20)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Tab View Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _CreateRequestTab(onCreated: () => _tabController.animateTo(1)),
                      const _MyRequestsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Create Request Tab - Enhanced with quota display
// ============================================================================
class _CreateRequestTab extends StatefulWidget {
  final VoidCallback onCreated;
  
  const _CreateRequestTab({required this.onCreated});

  @override
  State<_CreateRequestTab> createState() => _CreateRequestTabState();
}

class _CreateRequestTabState extends State<_CreateRequestTab> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  LeaveType _selectedType = LeaveType.annual;
  bool _isSubmitting = false;
  bool _isHalfDay = false;
  bool _isMorningSession = true; // true = Sáng, false = Chiều

  // Mock quota data - replace with real data from API
  final int _annualQuota = 12;
  final int _usedDays = 5;

  int get _remainingDays => _annualQuota - _usedDays;
  double get _requestedDays => _isHalfDay 
      ? 0.5 
      : (_endDate.difference(_startDate).inDays + 1).toDouble();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _submitRequest() {
    if (!_formKey.currentState!.validate()) return;
    
    // Check quota for annual leave
    if (_selectedType == LeaveType.annual && _requestedDays > _remainingDays) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bạn chỉ còn $_remainingDays ngày phép năm!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    setState(() => _isSubmitting = true);
    
    context.read<LeaveRequestBloc>().add(LeaveRequestSubmit(
      type: _selectedType,
      startDate: _startDate,
      endDate: _endDate,
      reason: _reasonController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeaveRequestBloc, LeaveRequestState>(
      listener: (context, state) {
        if (state.status == LeaveRequestStatus.submitted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Đã gửi đơn nghỉ phép thành công!'),
              backgroundColor: AppColors.success,
            ),
          );
          _reasonController.clear();
          widget.onCreated();
        } else if (state.status == LeaveRequestStatus.error) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Có lỗi xảy ra'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quota Summary Card
              _buildQuotaSummary(),
              
              SizedBox(height: 24.h),
              
              // Leave Type
              Text('Loại nghỉ phép', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: AppColors.textPrimary)),
              SizedBox(height: 12.h),
              Container(
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
                child: DropdownButtonFormField<LeaveType>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                  ),
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                  items: LeaveType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: _getLeaveTypeColor(type).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_getLeaveTypeIcon(type), size: 18.w, color: _getLeaveTypeColor(type)),
                          ),
                          SizedBox(width: 12.w),
                          Text(type.displayName, style: TextStyle(fontSize: 14.sp)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedType = value);
                  },
                ),
              ),
              
              SizedBox(height: 24.h),
              
              // Date Range
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Từ ngày', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: AppColors.textPrimary)),
                        SizedBox(height: 8.h),
                        _buildDateButton(_startDate, _selectStartDate),
                      ],
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Đến ngày', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: AppColors.textPrimary)),
                        SizedBox(height: 8.h),
                        _buildDateButton(_endDate, _selectEndDate),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16.h),
              
              // Duration info with warning
              _buildDurationInfo(),
              
              SizedBox(height: 16.h),
              
              // Half-day option
              Container(
                padding: EdgeInsets.all(12.w),
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
                        Checkbox(
                          value: _isHalfDay,
                          onChanged: (value) => setState(() => _isHalfDay = value ?? false),
                          activeColor: AppColors.primary,
                        ),
                        Text('Nghỉ nửa ngày', style: TextStyle(fontSize: 14.sp)),
                        const Spacer(),
                        if (_isHalfDay)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text('0.5 ngày', style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                            )),
                          ),
                      ],
                    ),
                    if (_isHalfDay) ...[
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isMorningSession = true),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: _isMorningSession 
                                      ? AppColors.primary 
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: _isMorningSession 
                                        ? AppColors.primary 
                                        : AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.wb_sunny_outlined, 
                                      color: _isMorningSession ? Colors.white : AppColors.textSecondary,
                                      size: 18.w,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text('Buổi sáng',
                                      style: TextStyle(
                                        color: _isMorningSession ? Colors.white : AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isMorningSession = false),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: !_isMorningSession 
                                      ? AppColors.primary 
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: !_isMorningSession 
                                        ? AppColors.primary 
                                        : AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.nightlight_outlined, 
                                      color: !_isMorningSession ? Colors.white : AppColors.textSecondary,
                                      size: 18.w,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text('Buổi chiều',
                                      style: TextStyle(
                                        color: !_isMorningSession ? Colors.white : AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 20.h),
              
              // Reason
              Text('Lý do', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _reasonController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Nhập lý do xin nghỉ phép...',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập lý do';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 32.h),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Gửi đơn', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuotaSummary() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.event_available, color: Colors.white, size: 20.w),
              ),
              SizedBox(width: 12.w),
              Text(
                'Ngày phép năm ${DateTime.now().year}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuotaItem('Tổng', '$_annualQuota', 'ngày'),
              Container(width: 1, height: 40.h, color: Colors.white.withValues(alpha: 0.2)),
              _buildQuotaItem('Đã dùng', '$_usedDays', 'ngày'),
              Container(width: 1, height: 40.h, color: Colors.white.withValues(alpha: 0.2)),
              _buildQuotaItem('Còn lại', '$_remainingDays', 'ngày', highlight: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaItem(String label, String value, String unit, {bool highlight = false}) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                color: highlight ? const Color(0xFFFFD700) : Colors.white, // Gold for highlight
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 4.w),
            Text(
              unit,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          label, 
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 13.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildDurationInfo() {
    final isOverQuota = _selectedType == LeaveType.annual && _requestedDays > _remainingDays;
    
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isOverQuota 
          ? AppColors.error.withValues(alpha: 0.1) 
          : AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isOverQuota ? AppColors.error.withValues(alpha: 0.3) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOverQuota ? Icons.warning_amber : Icons.info_outline,
            color: isOverQuota ? AppColors.error : AppColors.info,
            size: 20.w,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng: $_requestedDays ngày',
                  style: TextStyle(
                    color: isOverQuota ? AppColors.error : AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isOverQuota)
                  Text(
                    'Vượt quá số ngày phép còn lại ($_remainingDays ngày)',
                    style: TextStyle(color: AppColors.error, fontSize: 12.sp),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('dd/MM/yyyy').format(date), style: TextStyle(fontSize: 15.sp)),
            Icon(Icons.calendar_today, size: 18.w, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  IconData _getLeaveTypeIcon(LeaveType type) {
    switch (type) {
      case LeaveType.annual: return Icons.beach_access;
      case LeaveType.sickPaid:
      case LeaveType.sickUnpaid: return Icons.local_hospital;
      case LeaveType.maternity:
      case LeaveType.paternity: return Icons.child_care;
      case LeaveType.wedding: return Icons.favorite;
      case LeaveType.bereavement: return Icons.sentiment_very_dissatisfied;
      case LeaveType.compensatory: return Icons.schedule;
      case LeaveType.personal: return Icons.person;
      case LeaveType.unpaid: return Icons.money_off;
    }
  }

  Color _getLeaveTypeColor(LeaveType type) {
    switch (type) {
      case LeaveType.annual: return const Color(0xFF3B82F6);
      case LeaveType.sickPaid:
      case LeaveType.sickUnpaid: return const Color(0xFFEF4444);
      case LeaveType.maternity:
      case LeaveType.paternity: return const Color(0xFFEC4899);
      case LeaveType.wedding:
      case LeaveType.bereavement: return const Color(0xFF8B5CF6);
      case LeaveType.compensatory: return const Color(0xFF10B981);
      case LeaveType.personal: return const Color(0xFFF59E0B);
      case LeaveType.unpaid: return const Color(0xFF6B7280);
    }
  }
}

// ============================================================================
// My Requests Tab - Enhanced with filter, cancel, expandable
// ============================================================================
class _MyRequestsTab extends StatefulWidget {
  const _MyRequestsTab();

  @override
  State<_MyRequestsTab> createState() => _MyRequestsTabState();
}

class _MyRequestsTabState extends State<_MyRequestsTab> {
  LeaveStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeaveRequestBloc, LeaveRequestState>(
      builder: (context, state) {
        if (state.status == LeaveRequestStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final allRequests = state.myRequests;
        
        // Apply filter
        final requests = _filterStatus == null
          ? allRequests
          : allRequests.where((r) => r.status == _filterStatus).toList();

        // Sort by date desc
        final sortedRequests = List<LeaveRequest>.from(requests)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Calculate stats
        final pendingCount = allRequests.where((r) => r.status == LeaveStatus.pending).length;
        final approvedCount = allRequests.where((r) => r.status == LeaveStatus.approved).length;
        final rejectedCount = allRequests.where((r) => r.status == LeaveStatus.rejected).length;
        final totalApprovedDays = allRequests
          .where((r) => r.status == LeaveStatus.approved)
          .fold<double>(0, (sum, r) => sum + r.totalDays).toInt();

        return RefreshIndicator(
          onRefresh: () async => context.read<LeaveRequestBloc>().add(const LeaveRequestLoadMy()),
          child: ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              // Stats Summary
              _buildStatsSummary(pendingCount, approvedCount, rejectedCount, totalApprovedDays),
              
              SizedBox(height: 24.h),
              
              // Filter Chips
              _buildFilterChips(pendingCount, approvedCount, rejectedCount),
              
              SizedBox(height: 24.h),
              
              // Section Header
              Row(
                children: [
                  Text(
                    _filterStatus == null ? 'Tất cả đơn' : _filterStatus!.displayName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: AppColors.textPrimary),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      '${sortedRequests.length}',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13.sp),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16.h),
              
              // Empty state
              if (sortedRequests.isEmpty)
                Center(
                  child: Column(
                    children: [
                      SizedBox(height: 60.h),
                      Container(
                        padding: EdgeInsets.all(24.w),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.event_note_outlined, size: 64.w, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Không có đơn nghỉ phép',
                        style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              
              // Request List
              ...sortedRequests.map((r) => Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: GlassCard(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(
                              color: _getLeaveTypeColor(r.type).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(_getLeaveTypeIcon(r.type), color: _getLeaveTypeColor(r.type), size: 24.w),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      r.type.displayName,
                                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    ),
                                    _buildStatusBadge(r.status),
                                  ],
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  '${DateFormat('dd/MM').format(r.startDate)} - ${DateFormat('dd/MM').format(r.endDate)} (${r.totalDays} ngày)',
                                  style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Container(padding: EdgeInsets.zero, width: double.infinity, height: 1.h, color: AppColors.border.withOpacity(0.5)),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.reason,
                              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (r.status == LeaveStatus.pending)
                            TextButton(
                              onPressed: () => _showCancelDialog(context, r),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                                padding: EdgeInsets.symmetric(horizontal: 12.w),
                                backgroundColor: AppColors.error.withValues(alpha: 0.05),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                              ),
                              child: const Text('Hủy'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              )).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(LeaveStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case LeaveStatus.pending:
        color = AppColors.warning;
        label = 'Chờ duyệt';
        icon = Icons.hourglass_empty_rounded;
        break;
      case LeaveStatus.approved:
        color = AppColors.success;
        label = 'Đã duyệt';
        icon = Icons.check_circle_rounded;
        break;
      case LeaveStatus.rejected:
        color = AppColors.error;
        label = 'Từ chối';
        icon = Icons.cancel_rounded;
        break;
      case LeaveStatus.cancelled:
        color = AppColors.textSecondary;
        label = 'Đã hủy';
        icon = Icons.remove_circle_outline_rounded;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.w, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary(int pending, int approved, int rejected, int totalDays) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.hourglass_top_rounded, '$pending', 'Chờ duyệt', AppColors.warning),
          _buildStatItem(Icons.check_circle_rounded, '$approved', 'Đã duyệt', AppColors.success),
          _buildStatItem(Icons.cancel_outlined, '$rejected', 'Từ chối', AppColors.error),
          _buildStatItem(Icons.calendar_month_rounded, '$totalDays', 'Ngày nghỉ', AppColors.info),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20.w),
        ),
        SizedBox(height: 8.h),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: AppColors.textPrimary)),
        SizedBox(height: 2.h),
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp)),
      ],
    );
  }

  Widget _buildFilterChips(int pending, int approved, int rejected) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(null, 'Tất cả'),
          SizedBox(width: 12.w),
          _buildFilterChip(LeaveStatus.pending, 'Chờ duyệt ($pending)'),
          SizedBox(width: 12.w),
          _buildFilterChip(LeaveStatus.approved, 'Đã duyệt ($approved)'),
          SizedBox(width: 12.w),
          _buildFilterChip(LeaveStatus.rejected, 'Từ chối ($rejected)'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(LeaveStatus? status, String label) {
    final isSelected = _filterStatus == status;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterStatus = status),
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
        side: BorderSide(
          color: isSelected ? Colors.transparent : AppColors.border,
        ),
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13.sp,
      ),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
    );
  }

  void _showCancelDialog(BuildContext context, LeaveRequest request) {
    // ... existing implementation
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hủy đơn nghỉ phép?'),
        content: Text('Bạn có chắc muốn hủy đơn nghỉ ${request.type.displayName} '
          'từ ${DateFormat('dd/MM').format(request.startDate)} đến ${DateFormat('dd/MM').format(request.endDate)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<LeaveRequestBloc>().add(LeaveRequestCancel(request.id));
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã hủy đơn nghỉ phép')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hủy đơn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Helper methods moved inside state or kept as class members
IconData _getLeaveTypeIcon(LeaveType type) {
    switch (type) {
      case LeaveType.annual: return Icons.beach_access_rounded;
      case LeaveType.sickPaid:
      case LeaveType.sickUnpaid: return Icons.medical_services_rounded;
      case LeaveType.maternity:
      case LeaveType.paternity: return Icons.child_care_rounded;
      case LeaveType.wedding: return Icons.favorite_rounded;
      case LeaveType.bereavement: return Icons.sentiment_dissatisfied_rounded;
      case LeaveType.compensatory: return Icons.history_toggle_off_rounded;
      case LeaveType.personal: return Icons.person_rounded;
      case LeaveType.unpaid: return Icons.money_off_rounded;
    }
}

Color _getLeaveTypeColor(LeaveType type) {
    switch (type) {
      case LeaveType.annual: return const Color(0xFF3B82F6);
      case LeaveType.sickPaid:
      case LeaveType.sickUnpaid: return const Color(0xFFEF4444);
      case LeaveType.maternity:
      case LeaveType.paternity: return const Color(0xFFEC4899);
      case LeaveType.wedding:
      case LeaveType.bereavement: return const Color(0xFF8B5CF6);
      case LeaveType.compensatory: return const Color(0xFF10B981);
      case LeaveType.personal: return const Color(0xFFF59E0B);
      case LeaveType.unpaid: return const Color(0xFF6B7280);
    }
}




