import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/employee.dart';
import '../entities/department.dart';
import '../entities/position.dart';
import '../entities/hr_dashboard_stats.dart';
import '../entities/leave_request.dart';

/// HR Repository interface
abstract class HRRepository {
  /// Get all employees
  Future<Either<Failure, List<Employee>>> getEmployees();

  /// Get employee by ID
  Future<Either<Failure, Employee?>> getEmployee(String id);

  /// Get HR Dashboard stats
  Future<Either<Failure, HRDashboardStats>> getDashboardStats();

  /// Get all departments
  Future<Either<Failure, List<Department>>> getDepartments();

  /// Get all positions
  Future<Either<Failure, List<Position>>> getPositions();

  /// Get pending leave requests
  Future<Either<Failure, List<LeaveRequest>>> getPendingLeaveRequests();

  /// Get all leave requests
  Future<Either<Failure, List<LeaveRequest>>> getAllLeaveRequests();

  /// Approve leave request
  Future<Either<Failure, void>> approveLeaveRequest(String id, String note);

  /// Reject leave request
  Future<Either<Failure, void>> rejectLeaveRequest(String id, String reason);

  /// Add new employee
  Future<Either<Failure, Employee>> addEmployee({
    required String hoTen,
    required String email,
    required String password,
    String? soDienThoai,
    String gioiTinh,
    String? phongBanId,
    String? chucVuId,
  });

  /// Import employees from CSV
  Future<Either<Failure, List<Employee>>> importEmployeesFromCSV(List<Map<String, dynamic>> employeesData);
}
