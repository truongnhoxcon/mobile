import 'package:equatable/equatable.dart';
import '../../../domain/entities/attendance.dart';

enum AttendanceBlocStatus { initial, loading, loaded, checkingIn, checkingOut, error }

class AttendanceState extends Equatable {
  final AttendanceBlocStatus status;
  final Attendance? todayAttendance;
  final List<Attendance> monthlyAttendance;
  final List<Attendance> allAttendanceByDate;
  final String? errorMessage;
  final GeoLocation? currentLocation;

  const AttendanceState({
    this.status = AttendanceBlocStatus.initial,
    this.todayAttendance,
    this.monthlyAttendance = const [],
    this.allAttendanceByDate = const [],
    this.errorMessage,
    this.currentLocation,
  });

  bool get isCheckedIn => todayAttendance?.checkInTime != null;
  bool get isCheckedOut => todayAttendance?.checkOutTime != null;
  bool get canCheckIn => !isCheckedIn;
  bool get canCheckOut => isCheckedIn && !isCheckedOut;

  AttendanceState copyWith({
    AttendanceBlocStatus? status,
    Attendance? todayAttendance,
    List<Attendance>? monthlyAttendance,
    List<Attendance>? allAttendanceByDate,
    String? errorMessage,
    GeoLocation? currentLocation,
    bool clearTodayAttendance = false,
  }) {
    return AttendanceState(
      status: status ?? this.status,
      todayAttendance: clearTodayAttendance ? null : (todayAttendance ?? this.todayAttendance),
      monthlyAttendance: monthlyAttendance ?? this.monthlyAttendance,
      allAttendanceByDate: allAttendanceByDate ?? this.allAttendanceByDate,
      errorMessage: errorMessage ?? this.errorMessage,
      currentLocation: currentLocation ?? this.currentLocation,
    );
  }

  @override
  List<Object?> get props => [
        status,
        todayAttendance,
        monthlyAttendance,
        allAttendanceByDate,
        errorMessage,
        currentLocation,
      ];
}
