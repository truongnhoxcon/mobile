import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/leave_request.dart';
import '../../../domain/repositories/hr_repository.dart';
import '../auth/auth_bloc.dart';
import 'leave_request_event.dart';
import 'leave_request_state.dart';

/// Leave Request BLoC
/// Handles personal leave request operations
class LeaveRequestBloc extends Bloc<LeaveRequestEvent, LeaveRequestState> {
  final HRRepository _repository;
  final AuthBloc _authBloc;

  LeaveRequestBloc({
    required HRRepository repository,
    required AuthBloc authBloc,
  })  : _repository = repository,
        _authBloc = authBloc,
        super(const LeaveRequestState()) {
    on<LeaveRequestLoadMy>(_onLoadMy);
    on<LeaveRequestSubmit>(_onSubmit);
    on<LeaveRequestCancel>(_onCancel);
  }

  String get _currentUserId => _authBloc.state.user?.id ?? '';
  String get _currentUserName => _authBloc.state.user?.displayName ?? '';

  Future<void> _onLoadMy(
    LeaveRequestLoadMy event,
    Emitter<LeaveRequestState> emit,
  ) async {
    emit(state.copyWith(status: LeaveRequestStatus.loading));

    final result = await _repository.getAllLeaveRequests();

    result.fold(
      (failure) => emit(state.copyWith(
        status: LeaveRequestStatus.error,
        errorMessage: failure.message ?? 'Không thể tải đơn nghỉ phép',
      )),
      (requests) {
        // Filter for current user's requests only
        final myRequests = requests.where((r) => r.userId == _currentUserId).toList();
        emit(state.copyWith(
          status: LeaveRequestStatus.loaded,
          myRequests: myRequests,
        ));
      },
    );
  }

  Future<void> _onSubmit(
    LeaveRequestSubmit event,
    Emitter<LeaveRequestState> emit,
  ) async {
    emit(state.copyWith(status: LeaveRequestStatus.submitting));

    // Create new leave request
    final newRequest = LeaveRequest(
      id: '', // Will be assigned by backend
      userId: _currentUserId,
      userName: _currentUserName,
      type: event.type,
      startDate: event.startDate,
      endDate: event.endDate,
      reason: event.reason,
      status: LeaveStatus.pending,
      createdAt: DateTime.now(),
    );

    // Submit to Firebase via repository
    final result = await _repository.submitLeaveRequest(newRequest);

    result.fold(
      (failure) => emit(state.copyWith(
        status: LeaveRequestStatus.error,
        errorMessage: failure.message ?? 'Không thể gửi đơn nghỉ phép',
      )),
      (savedRequest) {
        final updatedRequests = [savedRequest, ...state.myRequests];
        emit(state.copyWith(
          status: LeaveRequestStatus.submitted,
          myRequests: updatedRequests,
          successMessage: 'Đã gửi đơn nghỉ phép thành công',
        ));
      },
    );
  }

  Future<void> _onCancel(
    LeaveRequestCancel event,
    Emitter<LeaveRequestState> emit,
  ) async {
    // TODO: Implement cancel logic when backend supports it
    final updatedRequests = state.myRequests.where((r) => r.id != event.requestId).toList();
    emit(state.copyWith(myRequests: updatedRequests));
  }
}
