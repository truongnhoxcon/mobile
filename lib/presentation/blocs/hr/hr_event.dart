import 'package:equatable/equatable.dart';

/// HR BLoC Events
abstract class HREvent extends Equatable {
  const HREvent();

  @override
  List<Object?> get props => [];
}

/// Load HR Dashboard
class HRLoadDashboard extends HREvent {
  const HRLoadDashboard();
}

/// Load Employees List
class HRLoadEmployees extends HREvent {
  final String? searchQuery;
  final String? statusFilter;
  final String? departmentFilter;

  const HRLoadEmployees({
    this.searchQuery,
    this.statusFilter,
    this.departmentFilter,
  });

  @override
  List<Object?> get props => [searchQuery, statusFilter, departmentFilter];
}

/// Load Pending Leave Requests
class HRLoadLeaveRequests extends HREvent {
  final bool pendingOnly;

  const HRLoadLeaveRequests({this.pendingOnly = true});

  @override
  List<Object?> get props => [pendingOnly];
}

/// Approve Leave Request
class HRApproveLeave extends HREvent {
  final String leaveId;
  final String note;

  const HRApproveLeave({required this.leaveId, this.note = ''});

  @override
  List<Object?> get props => [leaveId, note];
}

/// Reject Leave Request
class HRRejectLeave extends HREvent {
  final String leaveId;
  final String reason;

  const HRRejectLeave({required this.leaveId, required this.reason});

  @override
  List<Object?> get props => [leaveId, reason];
}

/// Load Departments
class HRLoadDepartments extends HREvent {
  const HRLoadDepartments();
}

/// Load Positions
class HRLoadPositions extends HREvent {
  const HRLoadPositions();
}

/// Add new Employee
class HRAddEmployee extends HREvent {
  final String hoTen;
  final String email;
  final String password;
  final String? soDienThoai;
  final String gioiTinh;
  final String? phongBanId;
  final String? chucVuId;

  const HRAddEmployee({
    required this.hoTen,
    required this.email,
    required this.password,
    this.soDienThoai,
    this.gioiTinh = 'Nam',
    this.phongBanId,
    this.chucVuId,
  });

  @override
  List<Object?> get props => [hoTen, email, password, soDienThoai, gioiTinh, phongBanId, chucVuId];
}

/// Import employees from CSV file
class HRImportEmployeesFromCSV extends HREvent {
  final String csvContent;

  const HRImportEmployeesFromCSV({required this.csvContent});

  @override
  List<Object?> get props => [csvContent];
}
