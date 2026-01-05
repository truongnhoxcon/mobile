/// Location Service for GPS Geofencing
/// 
/// Validates user location before allowing attendance check-in.
/// Office: Khu Phố 3, Biên Hòa, Đồng Nai

import 'package:geolocator/geolocator.dart';

class LocationService {
  // Office coordinates - Khu Phố 3, Biên Hòa, Đồng Nai
  static const double officeLatitude = 10.9745;
  static const double officeLongitude = 106.8918;
  static const double geofenceRadius = 200.0; // meters

  /// Check if location services are enabled and permissions granted
  Future<LocationPermissionResult> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionResult.serviceDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationPermissionResult.denied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionResult.deniedForever;
    }

    return LocationPermissionResult.granted;
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Calculate distance from current position to office
  double calculateDistanceToOffice(Position position) {
    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      officeLatitude,
      officeLongitude,
    );
  }

  /// Check if position is within geofence radius
  bool isWithinGeofence(Position position) {
    final distance = calculateDistanceToOffice(position);
    return distance <= geofenceRadius;
  }

  /// Full validation - returns result with distance info
  Future<GeofenceValidationResult> validateForCheckIn() async {
    // 1. Check permission
    final permissionResult = await checkPermission();
    if (permissionResult != LocationPermissionResult.granted) {
      return GeofenceValidationResult(
        isValid: false,
        error: _getPermissionErrorMessage(permissionResult),
        permissionResult: permissionResult,
      );
    }

    // 2. Get current position
    final position = await getCurrentPosition();
    if (position == null) {
      return GeofenceValidationResult(
        isValid: false,
        error: 'Không thể lấy vị trí. Vui lòng thử lại.',
      );
    }

    // 3. Calculate distance and validate
    final distance = calculateDistanceToOffice(position);
    final isWithin = distance <= geofenceRadius;

    return GeofenceValidationResult(
      isValid: isWithin,
      distanceToOffice: distance,
      currentPosition: position,
      error: isWithin ? null : 'Bạn đang ở cách văn phòng ${_formatDistance(distance)}. Vui lòng đến văn phòng để chấm công.',
    );
  }

  String _getPermissionErrorMessage(LocationPermissionResult result) {
    switch (result) {
      case LocationPermissionResult.serviceDisabled:
        return 'Vui lòng bật định vị GPS trên thiết bị.';
      case LocationPermissionResult.denied:
        return 'Cần cấp quyền truy cập vị trí để chấm công.';
      case LocationPermissionResult.deniedForever:
        return 'Quyền vị trí bị từ chối vĩnh viễn. Vui lòng vào Cài đặt để cấp quyền.';
      default:
        return 'Lỗi không xác định.';
    }
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toInt()} m';
  }
}

enum LocationPermissionResult {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

class GeofenceValidationResult {
  final bool isValid;
  final double? distanceToOffice;
  final Position? currentPosition;
  final String? error;
  final LocationPermissionResult? permissionResult;

  GeofenceValidationResult({
    required this.isValid,
    this.distanceToOffice,
    this.currentPosition,
    this.error,
    this.permissionResult,
  });
}
