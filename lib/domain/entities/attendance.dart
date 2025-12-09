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
      case 'PRESENT':
      default:
        return AttendanceStatus.present;
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
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final GeoLocation? checkInLocation;
  final GeoLocation? checkOutLocation;
  final AttendanceStatus status;
  final double? workingHours;
  final String? note;

  const Attendance({
    required this.id,
    required this.userId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.checkInLocation,
    this.checkOutLocation,
    this.status = AttendanceStatus.present,
    this.workingHours,
    this.note,
  });

  bool get hasCheckedIn => checkInTime != null;
  bool get hasCheckedOut => checkOutTime != null;

  Attendance copyWith({
    String? id,
    String? userId,
    DateTime? date,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    GeoLocation? checkInLocation,
    GeoLocation? checkOutLocation,
    AttendanceStatus? status,
    double? workingHours,
    String? note,
  }) {
    return Attendance(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInLocation: checkInLocation ?? this.checkInLocation,
      checkOutLocation: checkOutLocation ?? this.checkOutLocation,
      status: status ?? this.status,
      workingHours: workingHours ?? this.workingHours,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [
        id, userId, date, checkInTime, checkOutTime,
        checkInLocation, checkOutLocation, status, workingHours, note,
      ];
}
