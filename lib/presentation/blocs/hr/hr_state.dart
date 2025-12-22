import 'package:equatable/equatable.dart';
import '../../../domain/entities/employee.dart';
import '../../../domain/entities/department.dart';
import '../../../domain/entities/position.dart';
import '../../../domain/entities/hr_dashboard_stats.dart';
import '../../../domain/entities/leave_request.dart';

/// HR BLoC Status
enum HRStatus {
  initial,
  loading,
  loaded,
  error,
  approving,
  rejecting,
  actionSuccess,
}

/// HR BLoC State
class HRState extends Equatable {
  final HRStatus status;
  final HRDashboardStats? dashboardStats;
  final List<Employee> employees;
  final List<LeaveRequest> leaveRequests;
  final List<Department> departments;
  final List<Position> positions;
  final String? errorMessage;
  final String? successMessage;

  const HRState({
    this.status = HRStatus.initial,
    this.dashboardStats,
    this.employees = const [],
    this.leaveRequests = const [],
    this.departments = const [],
    this.positions = const [],
    this.errorMessage,
    this.successMessage,
  });

  HRState copyWith({
    HRStatus? status,
    HRDashboardStats? dashboardStats,
    List<Employee>? employees,
    List<LeaveRequest>? leaveRequests,
    List<Department>? departments,
    List<Position>? positions,
    String? errorMessage,
    String? successMessage,
  }) {
    return HRState(
      status: status ?? this.status,
      dashboardStats: dashboardStats ?? this.dashboardStats,
      employees: employees ?? this.employees,
      leaveRequests: leaveRequests ?? this.leaveRequests,
      departments: departments ?? this.departments,
      positions: positions ?? this.positions,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        dashboardStats,
        employees,
        leaveRequests,
        departments,
        positions,
        errorMessage,
        successMessage,
      ];
}
