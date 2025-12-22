import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/department.dart';
import '../../domain/entities/position.dart';
import '../../domain/entities/hr_dashboard_stats.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/repositories/hr_repository.dart';
import '../datasources/hr_datasource.dart';

/// HR Repository Implementation
class HRRepositoryImpl implements HRRepository {
  final HRDataSource _dataSource;

  HRRepositoryImpl({required HRDataSource dataSource}) : _dataSource = dataSource;

  @override
  Future<Either<Failure, List<Employee>>> getEmployees() async {
    try {
      final employees = await _dataSource.getEmployees();
      return Right(employees);
    } catch (e) {
      return Left(ServerFailure(message: 'Không thể tải danh sách nhân viên: $e'));
    }
  }

  @override
  Future<Either<Failure, Employee?>> getEmployee(String id) async {
    try {
      final employee = await _dataSource.getEmployee(id);
      return Right(employee);
    } catch (e) {
      return Left(ServerFailure(message: 'Không thể tải thông tin nhân viên: $e'));
    }
  }

  @override
  Future<Either<Failure, HRDashboardStats>> getDashboardStats() async {
    try {
      final stats = await _dataSource.getDashboardStats();
      return Right(stats);
    } catch (e) {
      return Left(ServerFailure(message: 'Không thể tải thống kê: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Department>>> getDepartments() async {
    try {
      final departments = await _dataSource.getDepartments();
      return Right(departments);
    } catch (e) {
      return Left(ServerFailure(message: 'Không thể tải phòng ban: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Position>>> getPositions() async {
    try {
      final positions = await _dataSource.getPositions();
      return Right(positions);
    } catch (e) {
      return Left(ServerFailure(message: 'Không thể tải chức vụ: $e'));
    }
  }

  @override
  Future<Either<Failure, List<LeaveRequest>>> getPendingLeaveRequests() async {
    try {
      final requests = await _dataSource.getPendingLeaveRequests();
      return Right(requests);
    } catch (e) {
      return Left(ServerFailure(message: 'Không thể tải đơn nghỉ phép: $e'));
    }
  }

  @override
  Future<Either<Failure, List<LeaveRequest>>> getAllLeaveRequests() async {
    try {
      final requests = await _dataSource.getAllLeaveRequests();
      return Right(requests);
    } catch (e) {
      return Left(ServerFailure(message: 'Không thể tải đơn nghỉ phép: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> approveLeaveRequest(String id, String note) async {
    try {
      await _dataSource.approveLeaveRequest(id, note);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Không thể duyệt đơn: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> rejectLeaveRequest(String id, String reason) async {
    try {
      await _dataSource.rejectLeaveRequest(id, reason);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Không thể từ chối đơn: $e'));
    }
  }

  @override
  Future<Either<Failure, Employee>> addEmployee({
    required String hoTen,
    required String email,
    required String password,
    String? soDienThoai,
    String gioiTinh = 'Nam',
    String? phongBanId,
    String? chucVuId,
  }) async {
    try {
      final employee = await _dataSource.addEmployee(
        hoTen: hoTen,
        email: email,
        password: password,
        soDienThoai: soDienThoai,
        gioiTinh: gioiTinh,
        phongBanId: phongBanId,
        chucVuId: chucVuId,
      );
      return Right(employee);
    } catch (e) {
      return Left(ServerFailure(message: 'Không thể tạo nhân viên: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Employee>>> importEmployeesFromCSV(List<Map<String, dynamic>> employeesData) async {
    try {
      final employees = await _dataSource.importEmployeesFromCSV(employeesData);
      return Right(employees);
    } catch (e) {
      return Left(ServerFailure(message: 'Không thể import nhân viên: $e'));
    }
  }
}
