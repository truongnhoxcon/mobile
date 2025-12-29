/// Attendance Entity
/// 
/// Domain entity representing attendance records.

import 'package:equatable/equatable.dart';

/// Attendance status enum
enum AttendanceStatus {
  present,
  late,
  earlyLeave,
  absent,
  leave,
  holiday,    // Ngày lễ
  weekend,    // Cuối tuần
}

extension AttendanceStatusExtension on AttendanceStatus {
  String get value {
    switch (this) {
      case AttendanceStatus.present:
        return 'PRESENT';
      case AttendanceStatus.late:
        return 'LATE';
      case AttendanceStatus.earlyLeave:
        return 'EARLY_LEAVE';
      case AttendanceStatus.absent:
        return 'ABSENT';
      case AttendanceStatus.leave:
        return 'LEAVE';
      case AttendanceStatus.holiday:
        return 'HOLIDAY';
      case AttendanceStatus.weekend:
        return 'WEEKEND';
    }
  }

  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'Đúng giờ';
      case AttendanceStatus.late:
        return 'Đi trễ';
      case AttendanceStatus.earlyLeave:
        return 'Về sớm';
      case AttendanceStatus.absent:
        return 'Vắng mặt';
      case AttendanceStatus.leave:
        return 'Nghỉ phép';
      case AttendanceStatus.holiday:
        return 'Ngày lễ';
      case AttendanceStatus.weekend:
        return 'Cuối tuần';
    }
  }

  /// Có được tính công không
  bool get isPaidDay {
    switch (this) {
      case AttendanceStatus.present:
      case AttendanceStatus.late:
      case AttendanceStatus.earlyLeave:
      case AttendanceStatus.leave:
      case AttendanceStatus.holiday:
        return true;
      case AttendanceStatus.absent:
      case AttendanceStatus.weekend:
        return false;
    }
  }

  static AttendanceStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'LATE':
        return AttendanceStatus.late;
      case 'EARLY_LEAVE':
        return AttendanceStatus.earlyLeave;
      case 'ABSENT':
        return AttendanceStatus.absent;
      case 'LEAVE':
        return AttendanceStatus.leave;
      case 'HOLIDAY':
        return AttendanceStatus.holiday;
      case 'WEEKEND':
        return AttendanceStatus.weekend;
      case 'PRESENT':
      default:
        return AttendanceStatus.present;
    }
  }
}

/// Shift Type - Loại ca làm việc
enum ShiftType {
  normal,   // Ca hành chính (8:00-17:00)
  morning,  // Ca sáng (6:00-14:00)
  evening,  // Ca chiều (14:00-22:00)
  night,    // Ca đêm (22:00-6:00)
  flexible, // Giờ linh hoạt
}

extension ShiftTypeExtension on ShiftType {
  String get displayName {
    switch (this) {
      case ShiftType.normal:
        return 'Hành chính';
      case ShiftType.morning:
        return 'Ca sáng';
      case ShiftType.evening:
        return 'Ca chiều';
      case ShiftType.night:
        return 'Ca đêm';
      case ShiftType.flexible:
        return 'Linh hoạt';
    }
  }

  /// Giờ bắt đầu chuẩn
  int get startHour {
    switch (this) {
      case ShiftType.normal:
        return 8;
      case ShiftType.morning:
        return 6;
      case ShiftType.evening:
        return 14;
      case ShiftType.night:
        return 22;
      case ShiftType.flexible:
        return 9;
    }
  }

  /// Giờ kết thúc chuẩn
  int get endHour {
    switch (this) {
      case ShiftType.normal:
        return 17;
      case ShiftType.morning:
        return 14;
      case ShiftType.evening:
        return 22;
      case ShiftType.night:
        return 6;
      case ShiftType.flexible:
        return 18;
    }
  }
}

/// GPS Location
class GeoLocation extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;

  const GeoLocation({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  @override
  List<Object?> get props => [latitude, longitude, address];
}

/// Attendance entity
class Attendance extends Equatable {
  final String id;
  final String userId;
  final String? userName;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final GeoLocation? checkInLocation;
  final GeoLocation? checkOutLocation;
  final AttendanceStatus status;
  final double? workingHours;
  final String? note;
  
  // Working standards
  final ShiftType shiftType;
  final double standardHours;   // Số giờ chuẩn (default: 8)
  final int lateThresholdMinutes; // Số phút trễ cho phép (default: 15)
  
  // Overtime
  final double overtimeHours;   // Số giờ OT
  final bool isOvertimeApproved; // OT được duyệt chưa
  
  // Remote work
  final bool isRemote;          // Làm việc từ xa
  final String? remoteReason;   // Lý do WFH
  
  // Late/Early metrics
  final int? lateMinutes;       // Số phút đi trễ
  final int? earlyLeaveMinutes; // Số phút về sớm

  const Attendance({
    required this.id,
    required this.userId,
    this.userName,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.checkInLocation,
    this.checkOutLocation,
    this.status = AttendanceStatus.present,
    this.workingHours,
    this.note,
    this.shiftType = ShiftType.normal,
    this.standardHours = 8.0,
    this.lateThresholdMinutes = 15,
    this.overtimeHours = 0,
    this.isOvertimeApproved = false,
    this.isRemote = false,
    this.remoteReason,
    this.lateMinutes,
    this.earlyLeaveMinutes,
  });

  bool get hasCheckedIn => checkInTime != null;
  bool get hasCheckedOut => checkOutTime != null;
  
  /// Số giờ làm việc thực tế (tính từ check-in/out)
  double get actualWorkingHours {
    if (checkInTime == null || checkOutTime == null) return 0;
    final diff = checkOutTime!.difference(checkInTime!);
    // Trừ 1 giờ nghỉ trưa
    return (diff.inMinutes / 60.0) - 1;
  }
  
  /// Có đi trễ không (vượt ngưỡng cho phép)
  bool get isLate {
    if (checkInTime == null) return false;
    final standardStart = DateTime(date.year, date.month, date.day, shiftType.startHour);
    final threshold = standardStart.add(Duration(minutes: lateThresholdMinutes));
    return checkInTime!.isAfter(threshold);
  }
  
  /// Có về sớm không
  bool get isEarlyLeave {
    if (checkOutTime == null) return false;
    final standardEnd = DateTime(date.year, date.month, date.day, shiftType.endHour);
    return checkOutTime!.isBefore(standardEnd);
  }
  
  /// Có làm OT không
  bool get hasOvertime => overtimeHours > 0;
  
  /// Lương OT rate (150%, 200%, 300%)
  double get overtimeRate {
    // Ngày thường: 150%, Cuối tuần: 200%, Lễ: 300%
    if (status == AttendanceStatus.holiday) return 3.0;
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      return 2.0;
    }
    return 1.5;
  }

  Attendance copyWith({
    String? id,
    String? userId,
    String? userName,
    DateTime? date,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    GeoLocation? checkInLocation,
    GeoLocation? checkOutLocation,
    AttendanceStatus? status,
    double? workingHours,
    String? note,
    ShiftType? shiftType,
    double? standardHours,
    int? lateThresholdMinutes,
    double? overtimeHours,
    bool? isOvertimeApproved,
    bool? isRemote,
    String? remoteReason,
    int? lateMinutes,
    int? earlyLeaveMinutes,
  }) {
    return Attendance(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInLocation: checkInLocation ?? this.checkInLocation,
      checkOutLocation: checkOutLocation ?? this.checkOutLocation,
      status: status ?? this.status,
      workingHours: workingHours ?? this.workingHours,
      note: note ?? this.note,
      shiftType: shiftType ?? this.shiftType,
      standardHours: standardHours ?? this.standardHours,
      lateThresholdMinutes: lateThresholdMinutes ?? this.lateThresholdMinutes,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      isOvertimeApproved: isOvertimeApproved ?? this.isOvertimeApproved,
      isRemote: isRemote ?? this.isRemote,
      remoteReason: remoteReason ?? this.remoteReason,
      lateMinutes: lateMinutes ?? this.lateMinutes,
      earlyLeaveMinutes: earlyLeaveMinutes ?? this.earlyLeaveMinutes,
    );
  }

  @override
  List<Object?> get props => [
        id, userId, userName, date, checkInTime, checkOutTime,
        checkInLocation, checkOutLocation, status, workingHours, note,
        shiftType, standardHours, lateThresholdMinutes,
        overtimeHours, isOvertimeApproved, isRemote, remoteReason,
        lateMinutes, earlyLeaveMinutes,
      ];
}
