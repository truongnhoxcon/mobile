/// Attendance Repository Interface
/// 
/// Defines the contract for attendance data operations.

import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/attendance.dart';

abstract class AttendanceRepository {
  /// Get today's attendance for current user
  Future<Either<Failure, Attendance?>> getTodayAttendance();

  /// Check-in with GPS location
  Future<Either<Failure, Attendance>> checkIn(GeoLocation location);

  /// Check-out with GPS location
  Future<Either<Failure, Attendance>> checkOut(GeoLocation location);

  /// Get attendance history for a month
  Future<Either<Failure, List<Attendance>>> getMonthlyAttendance({
    required int year,
    required int month,
  });

  /// Get attendance by date
  Future<Either<Failure, Attendance?>> getAttendanceByDate(DateTime date);

  /// Get all employees attendance for admin
  Future<Either<Failure, List<Attendance>>> getAllAttendanceByDate(DateTime date);

  /// Stream of today's attendance
  Stream<Attendance?> todayAttendanceStream();
}
