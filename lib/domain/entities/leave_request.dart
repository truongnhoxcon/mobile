import 'package:equatable/equatable.dart';

/// Leave Request status
enum LeaveStatus {
  pending,
  approved,
  rejected,
  cancelled, // Nhân viên tự hủy
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
      case LeaveStatus.cancelled:
        return 'CANCELLED';
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
      case LeaveStatus.cancelled:
        return 'Đã hủy';
    }
  }

  static LeaveStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'APPROVED':
        return LeaveStatus.approved;
      case 'REJECTED':
        return LeaveStatus.rejected;
      case 'CANCELLED':
        return LeaveStatus.cancelled;
      case 'PENDING':
      default:
        return LeaveStatus.pending;
    }
  }
}

/// Leave Type - Theo luật lao động Việt Nam
enum LeaveType {
  annual,       // Nghỉ phép năm (12 ngày, 100% lương)
  sickPaid,     // Nghỉ ốm có BHXH (75% lương BHXH, tối đa 30-60 ngày/năm)
  sickUnpaid,   // Nghỉ ốm vượt quota
  maternity,    // Thai sản (6 tháng, 100% BHXH)
  paternity,    // Nghỉ cha khi vợ sinh (5-7 ngày có lương)
  wedding,      // Nghỉ cưới (3 ngày có lương)
  bereavement,  // Nghỉ tang (1-3 ngày có lương tùy quan hệ)
  unpaid,       // Nghỉ không lương
  compensatory, // Nghỉ bù (do làm OT)
  personal,     // Việc riêng (trừ phép năm)
}

extension LeaveTypeExtension on LeaveType {
  String get value {
    switch (this) {
      case LeaveType.annual:
        return 'ANNUAL';
      case LeaveType.sickPaid:
        return 'SICK_PAID';
      case LeaveType.sickUnpaid:
        return 'SICK_UNPAID';
      case LeaveType.maternity:
        return 'MATERNITY';
      case LeaveType.paternity:
        return 'PATERNITY';
      case LeaveType.wedding:
        return 'WEDDING';
      case LeaveType.bereavement:
        return 'BEREAVEMENT';
      case LeaveType.unpaid:
        return 'UNPAID';
      case LeaveType.compensatory:
        return 'COMPENSATORY';
      case LeaveType.personal:
        return 'PERSONAL';
    }
  }

  String get displayName {
    switch (this) {
      case LeaveType.annual:
        return 'Phép năm';
      case LeaveType.sickPaid:
        return 'Nghỉ ốm (BHXH)';
      case LeaveType.sickUnpaid:
        return 'Nghỉ ốm (không lương)';
      case LeaveType.maternity:
        return 'Thai sản';
      case LeaveType.paternity:
        return 'Nghỉ cha';
      case LeaveType.wedding:
        return 'Nghỉ cưới';
      case LeaveType.bereavement:
        return 'Nghỉ tang';
      case LeaveType.unpaid:
        return 'Không lương';
      case LeaveType.compensatory:
        return 'Nghỉ bù';
      case LeaveType.personal:
        return 'Việc riêng';
    }
  }

  /// Loại nghỉ phép được trả lương
  bool get isPaid {
    switch (this) {
      case LeaveType.annual:
      case LeaveType.sickPaid:
      case LeaveType.maternity:
      case LeaveType.paternity:
      case LeaveType.wedding:
      case LeaveType.bereavement:
      case LeaveType.compensatory:
        return true;
      case LeaveType.sickUnpaid:
      case LeaveType.unpaid:
      case LeaveType.personal:
        return false;
    }
  }

  /// Phần trăm lương được hưởng
  double get salaryPercent {
    switch (this) {
      case LeaveType.annual:
      case LeaveType.paternity:
      case LeaveType.wedding:
      case LeaveType.bereavement:
      case LeaveType.compensatory:
        return 100;
      case LeaveType.sickPaid:
      case LeaveType.maternity:
        return 75; // BHXH chi trả
      case LeaveType.sickUnpaid:
      case LeaveType.unpaid:
      case LeaveType.personal:
        return 0;
    }
  }

  /// Màu sắc hiển thị
  String get colorHex {
    switch (this) {
      case LeaveType.annual:
        return '#10B981'; // Green
      case LeaveType.sickPaid:
      case LeaveType.sickUnpaid:
        return '#EF4444'; // Red
      case LeaveType.maternity:
      case LeaveType.paternity:
        return '#EC4899'; // Pink
      case LeaveType.wedding:
        return '#F59E0B'; // Amber
      case LeaveType.bereavement:
        return '#6B7280'; // Gray
      case LeaveType.unpaid:
        return '#9CA3AF'; // Light gray
      case LeaveType.compensatory:
        return '#3B82F6'; // Blue
      case LeaveType.personal:
        return '#8B5CF6'; // Purple
    }
  }

  static LeaveType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'SICK_PAID':
        return LeaveType.sickPaid;
      case 'SICK_UNPAID':
        return LeaveType.sickUnpaid;
      case 'MATERNITY':
        return LeaveType.maternity;
      case 'PATERNITY':
        return LeaveType.paternity;
      case 'WEDDING':
        return LeaveType.wedding;
      case 'BEREAVEMENT':
        return LeaveType.bereavement;
      case 'UNPAID':
        return LeaveType.unpaid;
      case 'COMPENSATORY':
        return LeaveType.compensatory;
      case 'PERSONAL':
        return LeaveType.personal;
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
  final String? approverName;
  final DateTime? approvedAt;
  final String? rejectReason;
  final DateTime createdAt;
  
  // Nghỉ nửa ngày
  final bool isHalfDay;
  final bool? isMorningSession; // true = sáng, false = chiều
  
  // Metadata
  final String? attachmentUrl; // Giấy khám bệnh, giấy kết hôn...

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
    this.approverName,
    this.approvedAt,
    this.rejectReason,
    required this.createdAt,
    this.isHalfDay = false,
    this.isMorningSession,
    this.attachmentUrl,
  });

  /// Tổng số ngày nghỉ (tính cả nửa ngày)
  double get totalDays {
    if (isHalfDay) return 0.5;
    return (endDate.difference(startDate).inDays + 1).toDouble();
  }

  /// Có được trả lương không
  bool get isPaidLeave => type.isPaid && status == LeaveStatus.approved;

  /// Số tiền lương (tính theo %)
  double get salaryPercent => type.salaryPercent;

  /// Có thể hủy được không (chỉ pending và chưa tới ngày bắt đầu)
  bool get canCancel => 
      status == LeaveStatus.pending && 
      startDate.isAfter(DateTime.now());

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
    String? approverName,
    DateTime? approvedAt,
    String? rejectReason,
    DateTime? createdAt,
    bool? isHalfDay,
    bool? isMorningSession,
    String? attachmentUrl,
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
      approverName: approverName ?? this.approverName,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectReason: rejectReason ?? this.rejectReason,
      createdAt: createdAt ?? this.createdAt,
      isHalfDay: isHalfDay ?? this.isHalfDay,
      isMorningSession: isMorningSession ?? this.isMorningSession,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
    );
  }

  @override
  List<Object?> get props => [
        id, userId, userName, type, startDate, endDate,
        reason, status, approvedBy, approverName, approvedAt, 
        rejectReason, createdAt, isHalfDay, isMorningSession, attachmentUrl,
      ];
}

/// Leave Quota - Quota nghỉ phép theo từng loại
class LeaveQuota extends Equatable {
  final String userId;
  final int year;
  final LeaveType type;
  final double totalDays;     // Tổng quota
  final double usedDays;      // Đã sử dụng
  final double pendingDays;   // Đang chờ duyệt

  const LeaveQuota({
    required this.userId,
    required this.year,
    required this.type,
    required this.totalDays,
    this.usedDays = 0,
    this.pendingDays = 0,
  });

  double get remainingDays => totalDays - usedDays - pendingDays;
  double get availableDays => totalDays - usedDays;
  bool get isExhausted => remainingDays <= 0;

  @override
  List<Object?> get props => [userId, year, type, totalDays, usedDays, pendingDays];
}
