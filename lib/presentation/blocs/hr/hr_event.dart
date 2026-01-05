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

/// Add new Department
class HRAddDepartment extends HREvent {
  final String name;
  final String? description;
  final String? managerId;

  const HRAddDepartment({
    required this.name,
    this.description,
    this.managerId,
  });

  @override
  List<Object?> get props => [name, description, managerId];
}

/// Update Department
class HRUpdateDepartment extends HREvent {
  final String id;
  final String name;
  final String? description;
  final String? managerId;

  const HRUpdateDepartment({
    required this.id,
    required this.name,
    this.description,
    this.managerId,
  });

  @override
  List<Object?> get props => [id, name, description, managerId];
}

/// Delete Department
class HRDeleteDepartment extends HREvent {
  final String id;

  const HRDeleteDepartment(this.id);

  @override
  List<Object?> get props => [id];
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

/// Delete Employee
class HRDeleteEmployee extends HREvent {
  final String employeeId;

  const HRDeleteEmployee({required this.employeeId});

  @override
  List<Object?> get props => [employeeId];
}

/// Import employees from CSV file
class HRImportEmployeesFromCSV extends HREvent {
  final String csvContent;
  final String? defaultDepartmentId;

  const HRImportEmployeesFromCSV({
    required this.csvContent,
    this.defaultDepartmentId,
  });

  @override
  List<Object?> get props => [csvContent, defaultDepartmentId];
}

// ==================== CONTRACT EVENTS ====================

/// Load Contracts List
class HRLoadContracts extends HREvent {
  final String? statusFilter;

  const HRLoadContracts({this.statusFilter});

  @override
  List<Object?> get props => [statusFilter];
}

// ==================== SALARY EVENTS ====================

/// Load Salaries List
class HRLoadSalaries extends HREvent {
  final int? month;
  final int? year;

  const HRLoadSalaries({this.month, this.year});

  @override
  List<Object?> get props => [month, year];
}

/// Generate Monthly Salaries
class HRGenerateSalaries extends HREvent {
  final int month;
  final int year;

  const HRGenerateSalaries({required this.month, required this.year});

  @override
  List<Object?> get props => [month, year];
}

// ==================== EVALUATION EVENTS ====================

/// Load Evaluations List
class HRLoadEvaluations extends HREvent {
  final bool pendingOnly;

  const HRLoadEvaluations({this.pendingOnly = false});

  @override
  List<Object?> get props => [pendingOnly];
}

/// Approve Evaluation
class HRApproveEvaluation extends HREvent {
  final String evaluationId;
  final String note;

  const HRApproveEvaluation({required this.evaluationId, this.note = ''});

  @override
  List<Object?> get props => [evaluationId, note];
}

/// Reject Evaluation
class HRRejectEvaluation extends HREvent {
  final String evaluationId;
  final String reason;

  const HRRejectEvaluation({required this.evaluationId, required this.reason});

  @override
  List<Object?> get props => [evaluationId, reason];
}
