import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csv/csv.dart';
import '../../../domain/entities/employee.dart';
import '../../../domain/entities/evaluation.dart';
import '../../../domain/repositories/hr_repository.dart';
import 'hr_event.dart';
import 'hr_state.dart';

/// HR BLoC
class HRBloc extends Bloc<HREvent, HRState> {
  final HRRepository _repository;

  HRBloc({required HRRepository repository})
      : _repository = repository,
        super(const HRState()) {
    on<HRLoadDashboard>(_onLoadDashboard);
    on<HRLoadEmployees>(_onLoadEmployees);
    on<HRLoadLeaveRequests>(_onLoadLeaveRequests);
    on<HRApproveLeave>(_onApproveLeave);
    on<HRRejectLeave>(_onRejectLeave);
    on<HRLoadDepartments>(_onLoadDepartments);
    on<HRAddDepartment>(_onAddDepartment);
    on<HRUpdateDepartment>(_onUpdateDepartment);
    on<HRDeleteDepartment>(_onDeleteDepartment);
    on<HRLoadPositions>(_onLoadPositions);
    on<HRAddEmployee>(_onAddEmployee);
    on<HRDeleteEmployee>(_onDeleteEmployee);
    on<HRImportEmployeesFromCSV>(_onImportEmployeesFromCSV);
    // New handlers for Contracts, Salaries, Evaluations
    on<HRLoadContracts>(_onLoadContracts);
    on<HRLoadSalaries>(_onLoadSalaries);
    on<HRLoadEvaluations>(_onLoadEvaluations);
    on<HRApproveEvaluation>(_onApproveEvaluation);
    on<HRRejectEvaluation>(_onRejectEvaluation);
  }

  Future<void> _onLoadDashboard(
    HRLoadDashboard event,
    Emitter<HRState> emit,
  ) async {
    emit(state.copyWith(status: HRStatus.loading));

    final result = await _repository.getDashboardStats();

    result.fold(
      (failure) => emit(state.copyWith(
        status: HRStatus.error,
        errorMessage: failure.message,
      )),
      (stats) => emit(state.copyWith(
        status: HRStatus.loaded,
        dashboardStats: stats,
      )),
    );
  }

  Future<void> _onLoadEmployees(
    HRLoadEmployees event,
    Emitter<HRState> emit,
  ) async {
    emit(state.copyWith(status: HRStatus.loading));

    final result = await _repository.getEmployees();

    result.fold(
      (failure) => emit(state.copyWith(
        status: HRStatus.error,
        errorMessage: failure.message ?? 'Có lỗi xảy ra',
      )),
      (employees) {
        var filtered = employees;

        // Apply search filter
        if (event.searchQuery != null && event.searchQuery!.isNotEmpty) {
          final query = event.searchQuery!.toLowerCase();
          filtered = filtered.where((e) =>
              e.hoTen.toLowerCase().contains(query) ||
              (e.email?.toLowerCase().contains(query) ?? false) ||
              (e.maNhanVien?.toLowerCase().contains(query) ?? false)
          ).toList();
        }

        // Apply status filter
        if (event.statusFilter != null && event.statusFilter != 'ALL') {
          filtered = filtered.where((e) =>
              e.status.value == event.statusFilter
          ).toList();
        }

        // Apply department filter
        if (event.departmentFilter != null && event.departmentFilter != 'ALL') {
          filtered = filtered.where((e) =>
              e.phongBanId == event.departmentFilter
          ).toList();
        }

        emit(state.copyWith(
          status: HRStatus.loaded,
          employees: filtered,
        ));
      },
    );
  }

  Future<void> _onLoadLeaveRequests(
    HRLoadLeaveRequests event,
    Emitter<HRState> emit,
  ) async {
    emit(state.copyWith(status: HRStatus.loading));

    final result = event.pendingOnly
        ? await _repository.getPendingLeaveRequests()
        : await _repository.getAllLeaveRequests();

    result.fold(
      (failure) => emit(state.copyWith(
        status: HRStatus.error,
        errorMessage: failure.message,
      )),
      (requests) => emit(state.copyWith(
        status: HRStatus.loaded,
        leaveRequests: requests,
      )),
    );
  }

  Future<void> _onApproveLeave(
    HRApproveLeave event,
    Emitter<HRState> emit,
  ) async {
    emit(state.copyWith(status: HRStatus.approving));

    final result = await _repository.approveLeaveRequest(event.leaveId, event.note);

    result.fold(
      (failure) => emit(state.copyWith(
        status: HRStatus.error,
        errorMessage: failure.message,
      )),
      (_) {
        // Remove approved leave from list
        final updatedLeaves = state.leaveRequests
            .where((l) => l.id != event.leaveId)
            .toList();
        emit(state.copyWith(
          status: HRStatus.actionSuccess,
          leaveRequests: updatedLeaves,
          successMessage: 'Đã duyệt đơn nghỉ phép',
        ));
      },
    );
  }

  Future<void> _onRejectLeave(
    HRRejectLeave event,
    Emitter<HRState> emit,
  ) async {
    emit(state.copyWith(status: HRStatus.rejecting));

    final result = await _repository.rejectLeaveRequest(event.leaveId, event.reason);

    result.fold(
      (failure) => emit(state.copyWith(
        status: HRStatus.error,
        errorMessage: failure.message,
      )),
      (_) {
        // Remove rejected leave from list
        final updatedLeaves = state.leaveRequests
            .where((l) => l.id != event.leaveId)
            .toList();
        emit(state.copyWith(
          status: HRStatus.actionSuccess,
          leaveRequests: updatedLeaves,
          successMessage: 'Đã từ chối đơn nghỉ phép',
        ));
      },
    );
  }

  Future<void> _onLoadDepartments(
    HRLoadDepartments event,
    Emitter<HRState> emit,
  ) async {
    emit(state.copyWith(status: HRStatus.loading));
    final result = await _repository.getDepartments();

    result.fold(
      (failure) => emit(state.copyWith(
        status: HRStatus.error,
        errorMessage: failure.message,
      )),
      (departments) => emit(state.copyWith(
        status: HRStatus.loaded,
        departments: departments,
      )),
    );
  }

  Future<void> _onAddDepartment(
    HRAddDepartment event,
    Emitter<HRState> emit,
  ) async {
    emit(state.copyWith(status: HRStatus.loading));

    final result = await _repository.addDepartment(
      name: event.name,
      description: event.description,
      managerId: event.managerId,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: HRStatus.error,
        errorMessage: failure.message,
      )),
      (department) {
        final updatedDepartments = [...state.departments, department];
        emit(state.copyWith(
          status: HRStatus.actionSuccess,
          departments: updatedDepartments,
          successMessage: 'Tạo phòng ban thành công: ${department.tenPhongBan}',
        ));
      },
    );
  }

  Future<void> _onUpdateDepartment(
    HRUpdateDepartment event,
    Emitter<HRState> emit,
  ) async {
    emit(state.copyWith(status: HRStatus.loading));

    final result = await _repository.updateDepartment(
      id: event.id,
      name: event.name,
      description: event.description,
      managerId: event.managerId,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: HRStatus.error,
        errorMessage: failure.message,
      )),
      (department) {
        final updatedDepartments = state.departments.map((d) {
          if (d.id == event.id) return department;
          return d;
        }).toList();
        emit(state.copyWith(
          status: HRStatus.actionSuccess,
          departments: updatedDepartments,
          successMessage: 'Cập nhật phòng ban thành công',
        ));
      },
    );
  }

  Future<void> _onDeleteDepartment(
    HRDeleteDepartment event,
    Emitter<HRState> emit,
  ) async {
    emit(state.copyWith(status: HRStatus.loading));

    final result = await _repository.deleteDepartment(event.id);

    result.fold(
      (failure) => emit(state.copyWith(
        status: HRStatus.error,
        errorMessage: failure.message,
      )),
      (_) {
        final updatedDepartments = state.departments.where((d) => d.id != event.id).toList();
        emit(state.copyWith(
          status: HRStatus.actionSuccess,
          departments: updatedDepartments,
          successMessage: 'Đã xóa phòng ban',
        ));
      },
    );
  }

  Future<void> _onLoadPositions(
    HRLoadPositions event,
    Emitter<HRState> emit,
  ) async {
    final result = await _repository.getPositions();

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (positions) => emit(state.copyWith(positions: positions)),
    );
  }

  Future<void> _onAddEmployee(
    HRAddEmployee event,
    Emitter<HRState> emit,
  ) async {
    emit(state.copyWith(status: HRStatus.loading));

    final result = await _repository.addEmployee(
      hoTen: event.hoTen,
      email: event.email,
      password: event.password,
      soDienThoai: event.soDienThoai,
      gioiTinh: event.gioiTinh,
      phongBanId: event.phongBanId,
      chucVuId: event.chucVuId,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: HRStatus.error,
        errorMessage: failure.message,
      )),
      (employee) {
        // Add new employee to list
        final updatedEmployees = [...state.employees, employee];
        emit(state.copyWith(
          status: HRStatus.actionSuccess,
          employees: updatedEmployees,
          successMessage: 'Tạo nhân viên thành công: ${employee.hoTen}',
        ));
      },
    );
  }

  Future<void> _onDeleteEmployee(
    HRDeleteEmployee event,
    Emitter<HRState> emit,
  ) async {
    emit(state.copyWith(status: HRStatus.loading));

    final result = await _repository.deleteEmployee(event.employeeId);

    result.fold(
      (failure) => emit(state.copyWith(
        status: HRStatus.error,
        errorMessage: failure.message,
      )),
      (_) {
        // Remove employee from list
        final updatedEmployees = state.employees
            .where((e) => e.id != event.employeeId)
            .toList();
        emit(state.copyWith(
          status: HRStatus.actionSuccess,
          employees: updatedEmployees,
          successMessage: 'Đã xóa nhân viên thành công',
        ));
      },
    );
  }

  Future<void> _onImportEmployeesFromCSV(
    HRImportEmployeesFromCSV event,
    Emitter<HRState> emit,
  ) async {
    emit(state.copyWith(status: HRStatus.loading));

    try {
      // Parse CSV content
      final csvConverter = const CsvToListConverter();
      final rows = csvConverter.convert(event.csvContent);
      
      if (rows.isEmpty) {
        emit(state.copyWith(
          status: HRStatus.error,
          errorMessage: 'File CSV trống hoặc không hợp lệ',
        ));
        return;
      }

      // First row is headers
      final headers = rows.first.map((e) => e.toString().toLowerCase().trim()).toList();
      final dataRows = rows.skip(1).toList();

      if (dataRows.isEmpty) {
        emit(state.copyWith(
          status: HRStatus.error,
          errorMessage: 'Không có dữ liệu nhân viên trong file',
        ));
        return;
      }

      // Convert rows to maps
      final List<Map<String, dynamic>> employeesData = [];
      for (final row in dataRows) {
        final Map<String, dynamic> employeeMap = {};
        for (int i = 0; i < headers.length && i < row.length; i++) {
          employeeMap[headers[i]] = row[i]?.toString() ?? '';
        }
        // Only add if has hoTen or name (headers are lowercase)
        final hoTen = employeeMap['hoten'] ?? employeeMap['ho_ten'] ?? employeeMap['name'] ?? '';
        if (hoTen.toString().isNotEmpty) {
          employeesData.add(employeeMap);
        }
      }

      if (employeesData.isEmpty) {
        emit(state.copyWith(
          status: HRStatus.error,
          errorMessage: 'Không tìm thấy dữ liệu nhân viên hợp lệ. Hãy đảm bảo file có cột hoTen hoặc name.',
        ));
        return;
      }

      // Import employees with optional default department
      final result = await _repository.importEmployeesFromCSV(
        employeesData,
        defaultDepartmentId: event.defaultDepartmentId,
      );

      result.fold(
        (failure) => emit(state.copyWith(
          status: HRStatus.error,
          errorMessage: failure.message,
        )),
        (importedEmployees) {
          final updatedEmployees = [...state.employees, ...importedEmployees];
          emit(state.copyWith(
            status: HRStatus.actionSuccess,
            employees: updatedEmployees,
            successMessage: 'Đã import thành công ${importedEmployees.length} nhân viên',
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: HRStatus.error,
        errorMessage: 'Lỗi đọc file CSV: $e',
      ));
    }
  }

  // ==================== CONTRACT HANDLERS ====================

  Future<void> _onLoadContracts(
    HRLoadContracts event,
    Emitter<HRState> emit,
  ) async {
    emit(state.copyWith(status: HRStatus.loading));

    final result = await _repository.getContracts(statusFilter: event.statusFilter);

    result.fold(
      (failure) => emit(state.copyWith(
        status: HRStatus.error,
        errorMessage: failure.message ?? 'Không thể tải hợp đồng',
      )),
      (contracts) => emit(state.copyWith(
        status: HRStatus.loaded,
        contracts: contracts,
      )),
    );
  }

  // ==================== SALARY HANDLERS ====================

  Future<void> _onLoadSalaries(
    HRLoadSalaries event,
    Emitter<HRState> emit,
  ) async {
    emit(state.copyWith(status: HRStatus.loading));

    final result = await _repository.getSalaries(
      month: event.month,
      year: event.year,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: HRStatus.error,
        errorMessage: failure.message ?? 'Không thể tải bảng lương',
      )),
      (salaries) => emit(state.copyWith(
        status: HRStatus.loaded,
        salaries: salaries,
      )),
    );
  }

  // ==================== EVALUATION HANDLERS ====================

  Future<void> _onLoadEvaluations(
    HRLoadEvaluations event,
    Emitter<HRState> emit,
  ) async {
    emit(state.copyWith(status: HRStatus.loading));

    final result = await _repository.getEvaluations(pendingOnly: event.pendingOnly);

    result.fold(
      (failure) => emit(state.copyWith(
        status: HRStatus.error,
        errorMessage: failure.message ?? 'Không thể tải đánh giá',
      )),
      (evaluations) => emit(state.copyWith(
        status: HRStatus.loaded,
        evaluations: evaluations,
      )),
    );
  }

  Future<void> _onApproveEvaluation(
    HRApproveEvaluation event,
    Emitter<HRState> emit,
  ) async {
    emit(state.copyWith(status: HRStatus.approving));

    final result = await _repository.approveEvaluation(event.evaluationId, event.note);

    result.fold(
      (failure) => emit(state.copyWith(
        status: HRStatus.error,
        errorMessage: failure.message,
      )),
      (_) {
        // Update evaluation status in list
        final updatedEvaluations = state.evaluations.map((e) {
          if (e.id == event.evaluationId) {
            return e.copyWith(
              status: EvaluationStatus.approved,
              approvedAt: DateTime.now(),
            );
          }
          return e;
        }).toList();

        emit(state.copyWith(
          status: HRStatus.actionSuccess,
          evaluations: updatedEvaluations,
          successMessage: 'Đã duyệt đánh giá',
        ));
      },
    );
  }

  Future<void> _onRejectEvaluation(
    HRRejectEvaluation event,
    Emitter<HRState> emit,
  ) async {
    emit(state.copyWith(status: HRStatus.rejecting));

    final result = await _repository.rejectEvaluation(event.evaluationId, event.reason);

    result.fold(
      (failure) => emit(state.copyWith(
        status: HRStatus.error,
        errorMessage: failure.message,
      )),
      (_) {
        // Update evaluation status in list
        final updatedEvaluations = state.evaluations.map((e) {
          if (e.id == event.evaluationId) {
            return e.copyWith(
              status: EvaluationStatus.rejected,
              rejectReason: event.reason,
            );
          }
          return e;
        }).toList();

        emit(state.copyWith(
          status: HRStatus.actionSuccess,
          evaluations: updatedEvaluations,
          successMessage: 'Đã từ chối đánh giá',
        ));
      },
    );
  }
}


