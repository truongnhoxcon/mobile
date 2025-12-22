/// Attendance Data Source
/// 
/// Firebase Firestore operations for attendance.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/attendance.dart';
import '../models/attendance_model.dart';

abstract class AttendanceDataSource {
  /// Get today's attendance
  Future<AttendanceModel?> getTodayAttendance(String userId);

  /// Check-in
  Future<AttendanceModel> checkIn(String userId, GeoLocation location);

  /// Check-out
  Future<AttendanceModel> checkOut(String attendanceId, GeoLocation location);

  /// Get monthly attendance
  Future<List<AttendanceModel>> getMonthlyAttendance(String userId, int year, int month);

  /// Get attendance by date
  Future<AttendanceModel?> getAttendanceByDate(String userId, DateTime date);

  /// Get all attendance by date (for admin)
  Future<List<AttendanceModel>> getAllAttendanceByDate(DateTime date);

  /// Stream of today's attendance
  Stream<AttendanceModel?> todayAttendanceStream(String userId);
}

class AttendanceDataSourceImpl implements AttendanceDataSource {
  final FirebaseFirestore _firestore;

  AttendanceDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _attendanceRef =>
      _firestore.collection('attendance');

  String _getDateId(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  @override
  Future<AttendanceModel?> getTodayAttendance(String userId) async {
    final today = _getDateId(DateTime.now());
    final doc = await _attendanceRef.doc('${userId}_$today').get();
    if (!doc.exists) return null;
    return AttendanceModel.fromFirestore(doc);
  }

  @override
  Future<AttendanceModel> checkIn(String userId, GeoLocation location) async {
    final now = DateTime.now();
    final today = _getDateId(now);
    final docId = '${userId}_$today';

    // Determine status based on check-in time
    AttendanceStatus status = AttendanceStatus.present;
    final checkInHour = now.hour;
    final checkInMinute = now.minute;
    
    // Late if after 8:00 AM
    if (checkInHour > 8 || (checkInHour == 8 && checkInMinute > 0)) {
      status = AttendanceStatus.late;
    }

    final attendance = AttendanceModel(
      id: docId,
      userId: userId,
      date: DateTime(now.year, now.month, now.day),
      checkInTime: now,
      checkInLocation: location,
      status: status,
    );

    await _attendanceRef.doc(docId).set(attendance.toFirestore());
    return attendance;
  }

  @override
  Future<AttendanceModel> checkOut(String attendanceId, GeoLocation location) async {
    final now = DateTime.now();
    final doc = await _attendanceRef.doc(attendanceId).get();
    
    if (!doc.exists) {
      throw Exception('Attendance record not found');
    }

    final existing = AttendanceModel.fromFirestore(doc);
    
    // Calculate working hours
    double? workingHours;
    if (existing.checkInTime != null) {
      workingHours = now.difference(existing.checkInTime!).inMinutes / 60.0;
    }

    // Check for early leave (before 5:00 PM)
    AttendanceStatus status = existing.status;
    if (now.hour < 17) {
      status = AttendanceStatus.earlyLeave;
    }

    await _attendanceRef.doc(attendanceId).update({
      'checkOutTime': Timestamp.fromDate(now),
      'checkOutLocation': {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'address': location.address,
      },
      'workingHours': workingHours,
      'status': status.value,
    });

    // Fetch updated document to ensure fresh data
    final updatedDoc = await _attendanceRef.doc(attendanceId).get();
    return AttendanceModel.fromFirestore(updatedDoc);
  }

  @override
  Future<List<AttendanceModel>> getMonthlyAttendance(String userId, int year, int month) async {
    // Query by userId only, then filter by date in memory
    // This avoids needing a composite index
    final snapshot = await _attendanceRef
        .where('userId', isEqualTo: userId)
        .get();

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final filtered = snapshot.docs
        .map((doc) => AttendanceModel.fromFirestore(doc))
        .where((a) => a.date.isAfter(startDate.subtract(const Duration(days: 1))) && 
                      a.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList();

    // Sort by date descending
    filtered.sort((a, b) => b.date.compareTo(a.date));
    
    return filtered;
  }

  @override
  Future<AttendanceModel?> getAttendanceByDate(String userId, DateTime date) async {
    final dateId = _getDateId(date);
    final doc = await _attendanceRef.doc('${userId}_$dateId').get();
    if (!doc.exists) return null;
    return AttendanceModel.fromFirestore(doc);
  }

  @override
  Future<List<AttendanceModel>> getAllAttendanceByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final snapshot = await _attendanceRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    return snapshot.docs.map((doc) => AttendanceModel.fromFirestore(doc)).toList();
  }

  @override
  Stream<AttendanceModel?> todayAttendanceStream(String userId) {
    final today = _getDateId(DateTime.now());
    return _attendanceRef.doc('${userId}_$today').snapshots().map((doc) {
      if (!doc.exists) return null;
      return AttendanceModel.fromFirestore(doc);
    });
  }
}
