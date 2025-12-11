import 'package:equatable/equatable.dart';

/// Leave Request status
enum LeaveStatus {
  pending,
  approved,
  rejected,
}

extension LeaveStatusExtension on LeaveStatus {
  String get value {
    switch (this) {
      case LeaveStatus.pending:
        return 'PENDING';
      case LeaveStatus.approved:
        return 'APPROVED';
      case LeaveStatus.rejected:
        return 'REJECTED';
    }
  }

  String get displayName {
    switch (this) {
      case LeaveStatus.pending:
        return 'Chờ duyệt';
      case LeaveStatus.approved:
        return 'Đã duyệt';
      case LeaveStatus.rejected:
        return 'Từ chối';
    }
  }

  static LeaveStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'APPROVED':
        return LeaveStatus.approved;
      case 'REJECTED':
        return LeaveStatus.rejected;
      case 'PENDING':
      default:
        return LeaveStatus.pending;
    }
  }
}

/// Leave Type
enum LeaveType {
  annual,     // Nghỉ phép năm
  sick,       // Nghỉ ốm
  personal,   // Nghỉ việc riêng
  unpaid,     // Nghỉ không lương
}

extension LeaveTypeExtension on LeaveType {
  String get value {
    switch (this) {
      case LeaveType.annual:
        return 'ANNUAL';
      case LeaveType.sick:
        return 'SICK';
      case LeaveType.personal:
        return 'PERSONAL';
      case LeaveType.unpaid:
        return 'UNPAID';
    }
  }

  String get displayName {
    switch (this) {
      case LeaveType.annual:
        return 'Nghỉ phép năm';
      case LeaveType.sick:
        return 'Nghỉ ốm';
      case LeaveType.personal:
        return 'Việc riêng';
      case LeaveType.unpaid:
        return 'Không lương';
    }
  }

  static LeaveType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'SICK':
        return LeaveType.sick;
      case 'PERSONAL':
        return LeaveType.personal;
      case 'UNPAID':
        return LeaveType.unpaid;
      case 'ANNUAL':
      default:
        return LeaveType.annual;
    }
  }
}

/// Leave Request entity
class LeaveRequest extends Equatable {
  final String id;
  final String userId;
  final String? userName;
  final LeaveType type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final LeaveStatus status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectReason;
  final DateTime createdAt;

  const LeaveRequest({
    required this.id,
    required this.userId,
    this.userName,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.status = LeaveStatus.pending,
    this.approvedBy,
    this.approvedAt,
    this.rejectReason,
    required this.createdAt,
  });

  int get totalDays => endDate.difference(startDate).inDays + 1;

  LeaveRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    LeaveType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    LeaveStatus? status,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectReason,
    DateTime? createdAt,
  }) {
    return LeaveRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectReason: rejectReason ?? this.rejectReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id, userId, userName, type, startDate, endDate,
        reason, status, approvedBy, approvedAt, rejectReason, createdAt,
      ];
}
