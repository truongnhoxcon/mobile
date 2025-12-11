import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../domain/entities/attendance.dart';
import '../../../data/datasources/attendance_datasource.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceDataSource _dataSource;

  AttendanceBloc({required AttendanceDataSource dataSource})
      : _dataSource = dataSource,
        super(const AttendanceState()) {
    on<AttendanceLoadToday>(_onLoadToday);
    on<AttendanceCheckIn>(_onCheckIn);
    on<AttendanceCheckOut>(_onCheckOut);
    on<AttendanceLoadMonth>(_onLoadMonth);
    on<AttendanceLoadAllByDate>(_onLoadAllByDate);
  }

  Future<GeoLocation?> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return GeoLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        address: 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}',
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _onLoadToday(
    AttendanceLoadToday event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(status: AttendanceBlocStatus.loading));

    try {
      final attendance = await _dataSource.getTodayAttendance(event.userId);
      emit(state.copyWith(
        status: AttendanceBlocStatus.loaded,
        todayAttendance: attendance?.toEntity(),
        clearTodayAttendance: attendance == null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AttendanceBlocStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCheckIn(
    AttendanceCheckIn event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(status: AttendanceBlocStatus.checkingIn));

    try {
      final location = await _getCurrentLocation();
      if (location == null) {
        emit(state.copyWith(
          status: AttendanceBlocStatus.error,
          errorMessage: 'Không thể lấy vị trí GPS. Vui lòng bật định vị.',
        ));
        return;
      }

      final attendance = await _dataSource.checkIn(event.userId, location);
      emit(state.copyWith(
        status: AttendanceBlocStatus.loaded,
        todayAttendance: attendance.toEntity(),
        currentLocation: location,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AttendanceBlocStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCheckOut(
    AttendanceCheckOut event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(status: AttendanceBlocStatus.checkingOut));

    try {
      final location = await _getCurrentLocation();
      if (location == null) {
        emit(state.copyWith(
          status: AttendanceBlocStatus.error,
          errorMessage: 'Không thể lấy vị trí GPS. Vui lòng bật định vị.',
        ));
        return;
      }

      final attendance = await _dataSource.checkOut(event.attendanceId, location);
      emit(state.copyWith(
        status: AttendanceBlocStatus.loaded,
        todayAttendance: attendance.toEntity(),
        currentLocation: location,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AttendanceBlocStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMonth(
    AttendanceLoadMonth event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(status: AttendanceBlocStatus.loading));

    try {
      final attendances = await _dataSource.getMonthlyAttendance(
        event.userId,
        event.year,
        event.month,
      );
      emit(state.copyWith(
        status: AttendanceBlocStatus.loaded,
        monthlyAttendance: attendances.map((m) => m.toEntity()).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AttendanceBlocStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadAllByDate(
    AttendanceLoadAllByDate event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(status: AttendanceBlocStatus.loading));

    try {
      final attendances = await _dataSource.getAllAttendanceByDate(event.date);
      emit(state.copyWith(
        status: AttendanceBlocStatus.loaded,
        allAttendanceByDate: attendances.map((m) => m.toEntity()).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AttendanceBlocStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
