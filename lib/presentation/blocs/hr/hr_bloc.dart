import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csv/csv.dart';
import '../../../domain/entities/employee.dart';
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
    on<HRLoadPositions>(_onLoadPositions);
    on<HRAddEmployee>(_onAddEmployee);
    on<HRImportEmployeesFromCSV>(_onImportEmployeesFromCSV);
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
        errorMessage: failure.message ?? 'Có lỗi xảy ra',
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
    final result = await _repository.getDepartments();

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (departments) => emit(state.copyWith(departments: departments)),
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

      // Import employees
      final result = await _repository.importEmployeesFromCSV(employeesData);

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
}
