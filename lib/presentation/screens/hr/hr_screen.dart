import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import '../../../core/theme/app_colors.dart';
import '../../../config/dependencies/injection_container.dart' as di;
import '../../../domain/entities/attendance.dart' as entity;
import '../../blocs/blocs.dart';
import 'hr_main_screen.dart';

/// HR Screen - Role-based routing
/// HR Manager: Shows management dashboard
/// Employee: Shows check-in/check-out
class HRScreen extends StatelessWidget {
  const HRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final user = authState.user;
    
    // HR Manager gets management screen
    if (user?.isHRManager == true) {
      return const HRMainScreen();
    }
    
    // Regular employee gets attendance screen
    return BlocProvider(
      create: (_) {
        final userId = user?.id ?? '';
        return di.sl<AttendanceBloc>()..add(AttendanceLoadToday(userId));
      },
      child: const _HRScreenContent(),
    );
  }
}

class _HRScreenContent extends StatefulWidget {
  const _HRScreenContent();

  @override
  State<_HRScreenContent> createState() => _HRScreenContentState();
}

class _HRScreenContentState extends State<_HRScreenContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nhân sự', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Chấm công', icon: Icon(Icons.fingerprint)),
            Tab(text: 'Lịch sử', icon: Icon(Icons.history)),
            Tab(text: 'Nghỉ phép', icon: Icon(Icons.event_busy)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CheckInTab(),
          _HistoryTab(),
          _LeaveRequestTab(),
        ],
      ),
    );
  }
}

// ============================================================================
// Check-in Tab with GPS
// ============================================================================
class _CheckInTab extends StatefulWidget {
  const _CheckInTab();

  @override
  State<_CheckInTab> createState() => _CheckInTabState();
}

class _CheckInTabState extends State<_CheckInTab> {
  // Company Location Config (HUTECH Campus)
  static const double _companyLat = 10.802532;
  static const double _companyLng = 106.713989;
  static const double _allowedRadius = 500.0; // meters

  Timer? _timer;
  String _currentTime = '';
  String _currentDate = '';
  String _currentAddress = 'Đang lấy địa chỉ...';
  Position? _currentPosition;
  double? _distanceToCompany;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(now);
      _currentDate = DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(now);
    });
  }

  Future<void> _getCurrentLocation() async {
    if (_isGettingLocation) return;
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentAddress = 'Vui lòng bật GPS';
          _isGettingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentAddress = 'Quyền vị trí bị từ chối';
            _isGettingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentAddress = 'Quyền vị trí bị từ chối vĩnh viễn';
          _isGettingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      _currentPosition = position;

      double distance = Geolocator.distanceBetween(
        position.latitude, position.longitude,
        _companyLat, _companyLng,
      );
      
      setState(() => _distanceToCompany = distance);

      // Get address from coordinates
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude,
        );

        if (placemarks.isNotEmpty && mounted) {
          Placemark place = placemarks[0];
          final street = place.street ?? '';
          final subAdmin = place.subAdministrativeArea ?? '';
          final admin = place.administrativeArea ?? '';
          
          setState(() {
            final parts = [street, subAdmin, admin].where((s) => s.isNotEmpty);
            _currentAddress = parts.isNotEmpty ? parts.join(', ') : 'Vị trí đã xác định';
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _currentAddress = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}');
        }
      }
    } catch (e) {
      debugPrint('Location error: $e');
      if (mounted) {
        setState(() => _currentAddress = 'Không thể lấy vị trí');
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle, color: Colors.white),
            SizedBox(width: 10.w),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  Future<void> _handleCheckIn() async {
    final authState = context.read<AuthBloc>().state;
    final userId = authState.user?.id ?? '';

    if (_currentPosition == null) {
      _showMessage('Đang lấy vị trí GPS, vui lòng đợi...', isError: true);
      await _getCurrentLocation();
      return;
    }

    // Check distance to company
    if (_distanceToCompany != null && _distanceToCompany! > _allowedRadius) {
      _showMessage(
        'Bạn đang ở quá xa công ty (${_distanceToCompany!.toStringAsFixed(0)}m). Phải trong bán kính ${_allowedRadius.toInt()}m để check-in.',
        isError: true,
      );
      return;
    }

    context.read<AttendanceBloc>().add(AttendanceCheckIn(userId));
    _showMessage('Check-in thành công! Chúc bạn làm việc vui vẻ.');
  }

  Future<void> _handleCheckOut(String attendanceId) async {
    if (_currentPosition == null) {
      _showMessage('Đang lấy vị trí GPS, vui lòng đợi...', isError: true);
      await _getCurrentLocation();
      return;
    }

    context.read<AttendanceBloc>().add(AttendanceCheckOut(attendanceId));
    _showMessage('Check-out thành công! Hẹn gặp lại.');
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState.user?.id ?? '';

    return BlocConsumer<AttendanceBloc, AttendanceState>(
      listener: (context, state) {
        if (state.status == AttendanceBlocStatus.error && state.errorMessage != null) {
          _showMessage(state.errorMessage!, isError: true);
        }
      },
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            await _getCurrentLocation();
            context.read<AttendanceBloc>().add(AttendanceLoadToday(userId));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                _buildTodayCard(state),
                SizedBox(height: 20.h),
                _buildLocationCard(),
                SizedBox(height: 20.h),
                _buildActionButton(context, state, userId),
                SizedBox(height: 20.h),
                if (state.todayAttendance != null)
                  _buildTodayRecord(state.todayAttendance!),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodayCard(AttendanceState state) {
    String statusText;
    Color statusColor;

    if (state.isCheckedOut) {
      statusText = 'Đã hoàn thành';
      statusColor = AppColors.success;
    } else if (state.isCheckedIn) {
      statusText = 'Đang làm việc';
      statusColor = AppColors.info;
    } else {
      statusText = 'Chưa vào ca';
      statusColor = AppColors.textSecondary;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentTime,
                      style: TextStyle(fontSize: 42.sp, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(_currentDate, style: TextStyle(color: Colors.white70, fontSize: 13.sp)),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.sp),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Divider(color: Colors.white30),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTimeColumn('Giờ vào', state.todayAttendance?.checkInTime, true),
              Container(width: 1, height: 60.h, color: Colors.white30),
              _buildTimeColumn('Giờ ra', state.todayAttendance?.checkOutTime, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(String label, DateTime? time, bool isCheckIn) {
    final timeStr = time != null ? DateFormat('HH:mm').format(time) : '--:--';
    String status = '';
    Color statusColor = Colors.green;

    if (time != null) {
      if (isCheckIn) {
        // Late if after 8:00 AM
        if (time.hour > 8 || (time.hour == 8 && time.minute > 0)) {
          final lateMinutes = (time.hour - 8) * 60 + time.minute;
          status = 'Trễ ${lateMinutes}p';
          statusColor = Colors.orange;
        } else {
          status = 'Đúng giờ';
        }
      } else {
        // Early if before 5:00 PM
        if (time.hour < 17) {
          final earlyMinutes = (17 - time.hour) * 60 - time.minute;
          status = 'Sớm ${earlyMinutes}p';
          statusColor = Colors.orange;
        } else {
          status = 'Đúng giờ';
        }
      }
    }

    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
        SizedBox(height: 6.h),
        Text(timeStr, style: TextStyle(color: Colors.white, fontSize: 28.sp, fontWeight: FontWeight.bold)),
        if (status.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 6.h),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              status,
              style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationCard() {
    final isInRange = _distanceToCompany != null && _distanceToCompany! <= _allowedRadius;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: AppColors.primary, size: 24.w),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentAddress,
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_distanceToCompany != null) ...[
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            isInRange ? Icons.check_circle : Icons.warning,
                            size: 16.w,
                            color: isInRange ? AppColors.success : AppColors.warning,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Cách công ty: ${_distanceToCompany! > 1000 ? '${(_distanceToCompany! / 1000).toStringAsFixed(1)} km' : '${_distanceToCompany!.toStringAsFixed(0)} m'}',
                            style: TextStyle(
                              color: isInRange ? AppColors.success : AppColors.warning,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: _isGettingLocation ? null : _getCurrentLocation,
                icon: _isGettingLocation
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.refresh, color: AppColors.primary),
                tooltip: 'Cập nhật vị trí',
              ),
            ],
          ),
          if (!isInRange && _distanceToCompany != null)
            Container(
              margin: EdgeInsets.only(top: 12.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 20.w),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Bạn phải ở trong bán kính ${_allowedRadius.toInt()}m từ công ty để check-in',
                      style: TextStyle(color: AppColors.warning, fontSize: 12.sp),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, AttendanceState state, String userId) {
    final isLoading = state.status == AttendanceBlocStatus.checkingIn ||
        state.status == AttendanceBlocStatus.checkingOut;
    final isInRange = _distanceToCompany == null || _distanceToCompany! <= _allowedRadius;

    if (state.isCheckedOut) {
      return SizedBox(
        width: double.infinity,
        height: 60.h,
        child: ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_circle),
          label: Text('ĐÃ HOÀN THÀNH HÔM NAY', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          ),
        ),
      );
    }

    if (state.canCheckOut && state.todayAttendance != null) {
      return SizedBox(
        width: double.infinity,
        height: 60.h,
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : () => _handleCheckOut(state.todayAttendance!.id),
          icon: isLoading
              ? SizedBox(width: 24.w, height: 24.w, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.logout),
          label: Text(isLoading ? 'ĐANG CHECK-OUT...' : 'CHECK-OUT', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            elevation: 6,
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 60.h,
      child: ElevatedButton.icon(
        onPressed: (isLoading || !isInRange) ? null : _handleCheckIn,
        icon: isLoading
            ? SizedBox(width: 24.w, height: 24.w, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.login),
        label: Text(isLoading ? 'ĐANG CHECK-IN...' : 'CHECK-IN', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          elevation: 6,
        ),
      ),
    );
  }

  Widget _buildTodayRecord(entity.Attendance attendance) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chi tiết hôm nay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
          SizedBox(height: 16.h),
          _buildRecordRow(Icons.login, 'Check-in', 
            attendance.checkInTime != null ? DateFormat('HH:mm:ss').format(attendance.checkInTime!) : '--:--:--',
            AppColors.success),
          SizedBox(height: 12.h),
          _buildRecordRow(Icons.logout, 'Check-out',
            attendance.checkOutTime != null ? DateFormat('HH:mm:ss').format(attendance.checkOutTime!) : '--:--:--',
            AppColors.warning),
          if (attendance.workingHours != null) ...[
            SizedBox(height: 12.h),
            _buildRecordRow(Icons.timer, 'Thời gian làm việc', '${attendance.workingHours!.toStringAsFixed(1)} giờ', AppColors.info),
          ],
          SizedBox(height: 12.h),
          _buildRecordRow(Icons.info_outline, 'Trạng thái', attendance.status.displayName, _getStatusColor(attendance.status)),
          if (attendance.checkInLocation != null) ...[
            SizedBox(height: 12.h),
            _buildRecordRow(Icons.my_location, 'Vị trí check-in', attendance.checkInLocation!.address ?? 'N/A', AppColors.primary),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20.w, color: color),
        SizedBox(width: 12.w),
        Expanded(
          flex: 2,
          child: Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp)),
        ),
        Expanded(
          flex: 2,
          child: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(entity.AttendanceStatus status) {
    switch (status) {
      case entity.AttendanceStatus.present:
        return AppColors.success;
      case entity.AttendanceStatus.late:
        return AppColors.warning;
      case entity.AttendanceStatus.earlyLeave:
        return AppColors.info;
      case entity.AttendanceStatus.absent:
        return AppColors.error;
      case entity.AttendanceStatus.leave:
        return AppColors.primary;
    }
  }
}

// ============================================================================
// History Tab
// ============================================================================
class _HistoryTab extends StatefulWidget {
  const _HistoryTab();

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMonthlyAttendance());
  }

  void _loadMonthlyAttendance() {
    final authState = context.read<AuthBloc>().state;
    final userId = authState.user?.id ?? '';
    context.read<AttendanceBloc>().add(AttendanceLoadMonth(
          userId: userId,
          year: _selectedYear,
          month: _selectedMonth,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    if (_selectedMonth == 1) {
                      _selectedMonth = 12;
                      _selectedYear--;
                    } else {
                      _selectedMonth--;
                    }
                  });
                  _loadMonthlyAttendance();
                },
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                'Tháng $_selectedMonth/$_selectedYear',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    if (_selectedMonth == 12) {
                      _selectedMonth = 1;
                      _selectedYear++;
                    } else {
                      _selectedMonth++;
                    }
                  });
                  _loadMonthlyAttendance();
                },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<AttendanceBloc, AttendanceState>(
            builder: (context, state) {
              if (state.status == AttendanceBlocStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.monthlyAttendance.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 64.w, color: AppColors.textSecondary),
                      SizedBox(height: 16.h),
                      Text('Không có dữ liệu chấm công', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: state.monthlyAttendance.length,
                itemBuilder: (context, index) {
                  final attendance = state.monthlyAttendance[index];
                  return _buildAttendanceItem(attendance);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceItem(entity.Attendance attendance) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(DateFormat('dd').format(attendance.date), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp)),
                Text(DateFormat('E', 'vi_VN').format(attendance.date), style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary)),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${attendance.checkInTime != null ? DateFormat('HH:mm').format(attendance.checkInTime!) : '--:--'} - ${attendance.checkOutTime != null ? DateFormat('HH:mm').format(attendance.checkOutTime!) : '--:--'}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4.h),
                Text(
                  attendance.workingHours != null ? '${attendance.workingHours!.toStringAsFixed(1)} giờ' : 'Đang làm việc',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: _getStatusColor(attendance.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              attendance.status.displayName,
              style: TextStyle(color: _getStatusColor(attendance.status), fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(entity.AttendanceStatus status) {
    switch (status) {
      case entity.AttendanceStatus.present: return AppColors.success;
      case entity.AttendanceStatus.late: return AppColors.warning;
      case entity.AttendanceStatus.earlyLeave: return AppColors.info;
      case entity.AttendanceStatus.absent: return AppColors.error;
      case entity.AttendanceStatus.leave: return AppColors.primary;
    }
  }
}

// ============================================================================
// Leave Request Tab
// ============================================================================
class _LeaveRequestTab extends StatelessWidget {
  const _LeaveRequestTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80.w, color: AppColors.textSecondary),
          SizedBox(height: 16.h),
          Text('Đơn xin nghỉ phép', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          Text('Tính năng đang phát triển', style: TextStyle(color: AppColors.textSecondary)),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Tạo đơn nghỉ phép'),
          ),
        ],
      ),
    );
  }
}
