import 'package:equatable/equatable.dart';
import '../../../domain/entities/leave_request.dart';

/// Leave Request Status
enum LeaveRequestStatus {
  initial,
  loading,
  loaded,
  submitting,
  submitted,
  error,
  pending,
  approved,
  rejected,
}

extension LeaveRequestStatusExtension on LeaveRequestStatus {
  String get displayName {
    switch (this) {
      case LeaveRequestStatus.pending:
        return 'Chờ duyệt';
      case LeaveRequestStatus.approved:
        return 'Đã duyệt';
      case LeaveRequestStatus.rejected:
        return 'Từ chối';
      default:
        return '';
    }
  }
}

/// Leave Request State
class LeaveRequestState extends Equatable {
  final LeaveRequestStatus status;
  final List<LeaveRequest> myRequests;
  final String? errorMessage;
  final String? successMessage;

  const LeaveRequestState({
    this.status = LeaveRequestStatus.initial,
    this.myRequests = const [],
    this.errorMessage,
    this.successMessage,
  });

  LeaveRequestState copyWith({
    LeaveRequestStatus? status,
    List<LeaveRequest>? myRequests,
    String? errorMessage,
    String? successMessage,
  }) {
    return LeaveRequestState(
      status: status ?? this.status,
      myRequests: myRequests ?? this.myRequests,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [status, myRequests, errorMessage, successMessage];
}
