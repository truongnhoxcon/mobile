/// Attendance Model
/// 
/// Data model for Attendance entity with Firestore serialization.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/attendance.dart';

class AttendanceModel extends Attendance {
  const AttendanceModel({
    required super.id,
    required super.userId,
    required super.date,
    super.checkInTime,
    super.checkOutTime,
    super.checkInLocation,
    super.checkOutLocation,
    super.status,
    super.workingHours,
    super.note,
  });

  /// Create from Firestore document
  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      checkInTime: (data['checkInTime'] as Timestamp?)?.toDate(),
      checkOutTime: (data['checkOutTime'] as Timestamp?)?.toDate(),
      checkInLocation: data['checkInLocation'] != null
          ? GeoLocation(
              latitude: data['checkInLocation']['latitude'],
              longitude: data['checkInLocation']['longitude'],
              address: data['checkInLocation']['address'],
            )
          : null,
      checkOutLocation: data['checkOutLocation'] != null
          ? GeoLocation(
              latitude: data['checkOutLocation']['latitude'],
              longitude: data['checkOutLocation']['longitude'],
              address: data['checkOutLocation']['address'],
            )
          : null,
      status: AttendanceStatusExtension.fromString(data['status'] ?? 'PRESENT'),
      workingHours: (data['workingHours'] as num?)?.toDouble(),
      note: data['note'],
    );
  }

  /// Create from entity
  factory AttendanceModel.fromEntity(Attendance attendance) {
    return AttendanceModel(
      id: attendance.id,
      userId: attendance.userId,
      date: attendance.date,
      checkInTime: attendance.checkInTime,
      checkOutTime: attendance.checkOutTime,
      checkInLocation: attendance.checkInLocation,
      checkOutLocation: attendance.checkOutLocation,
      status: attendance.status,
      workingHours: attendance.workingHours,
      note: attendance.note,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'checkInTime': checkInTime != null ? Timestamp.fromDate(checkInTime!) : null,
      'checkOutTime': checkOutTime != null ? Timestamp.fromDate(checkOutTime!) : null,
      'checkInLocation': checkInLocation != null
          ? {
              'latitude': checkInLocation!.latitude,
              'longitude': checkInLocation!.longitude,
              'address': checkInLocation!.address,
            }
          : null,
      'checkOutLocation': checkOutLocation != null
          ? {
              'latitude': checkOutLocation!.latitude,
              'longitude': checkOutLocation!.longitude,
              'address': checkOutLocation!.address,
            }
          : null,
      'status': status.value,
      'workingHours': workingHours,
      'note': note,
    };
  }

  /// Convert to entity
  Attendance toEntity() {
    return Attendance(
      id: id,
      userId: userId,
      date: date,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
      checkInLocation: checkInLocation,
      checkOutLocation: checkOutLocation,
      status: status,
      workingHours: workingHours,
      note: note,
    );
  }
}
