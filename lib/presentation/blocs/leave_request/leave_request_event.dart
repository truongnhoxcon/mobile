import 'package:equatable/equatable.dart';
import '../../../domain/entities/leave_request.dart';

/// Leave Request Events
abstract class LeaveRequestEvent extends Equatable {
  const LeaveRequestEvent();

  @override
  List<Object?> get props => [];
}

/// Load user's own leave requests
class LeaveRequestLoadMy extends LeaveRequestEvent {
  const LeaveRequestLoadMy();
}

/// Submit new leave request
class LeaveRequestSubmit extends LeaveRequestEvent {
  final LeaveType type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;

  const LeaveRequestSubmit({
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
  });

  @override
  List<Object?> get props => [type, startDate, endDate, reason];
}

/// Cancel leave request
class LeaveRequestCancel extends LeaveRequestEvent {
  final String requestId;

  const LeaveRequestCancel(this.requestId);

  @override
  List<Object?> get props => [requestId];
}
