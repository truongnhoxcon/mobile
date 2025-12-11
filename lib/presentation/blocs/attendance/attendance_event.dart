import 'package:equatable/equatable.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

/// Load today's attendance
class AttendanceLoadToday extends AttendanceEvent {
  final String userId;
  const AttendanceLoadToday(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Check-in with GPS location
class AttendanceCheckIn extends AttendanceEvent {
  final String userId;
  const AttendanceCheckIn(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Check-out with GPS location
class AttendanceCheckOut extends AttendanceEvent {
  final String attendanceId;
  const AttendanceCheckOut(this.attendanceId);

  @override
  List<Object?> get props => [attendanceId];
}

/// Load monthly attendance history
class AttendanceLoadMonth extends AttendanceEvent {
  final String userId;
  final int year;
  final int month;

  const AttendanceLoadMonth({
    required this.userId,
    required this.year,
    required this.month,
  });

  @override
  List<Object?> get props => [userId, year, month];
}

/// Admin: Load all attendance by date
class AttendanceLoadAllByDate extends AttendanceEvent {
  final DateTime date;
  const AttendanceLoadAllByDate(this.date);

  @override
  List<Object?> get props => [date];
}
