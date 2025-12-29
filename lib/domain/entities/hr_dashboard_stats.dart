import 'package:equatable/equatable.dart';

/// HR Dashboard Stats entity
class HRDashboardStats extends Equatable {
  final int tongNhanVien;
  final int dangLamViec;  // Active employees
  final int nhanVienMoi;
  final int nghiViec;
  final int donChoPheDuyet;
  final Map<String, dynamic>? chamCongPhongBan;
  final Map<String, dynamic>? nhanVienTheoTuoi;
  final Map<String, dynamic>? nhanVienTheoGioiTinh;

  const HRDashboardStats({
    this.tongNhanVien = 0,
    this.dangLamViec = 0,
    this.nhanVienMoi = 0,
    this.nghiViec = 0,
    this.donChoPheDuyet = 0,
    this.chamCongPhongBan,
    this.nhanVienTheoTuoi,
    this.nhanVienTheoGioiTinh,
  });

  HRDashboardStats copyWith({
    int? tongNhanVien,
    int? dangLamViec,
    int? nhanVienMoi,
    int? nghiViec,
    int? donChoPheDuyet,
    Map<String, dynamic>? chamCongPhongBan,
    Map<String, dynamic>? nhanVienTheoTuoi,
    Map<String, dynamic>? nhanVienTheoGioiTinh,
  }) {
    return HRDashboardStats(
      tongNhanVien: tongNhanVien ?? this.tongNhanVien,
      dangLamViec: dangLamViec ?? this.dangLamViec,
      nhanVienMoi: nhanVienMoi ?? this.nhanVienMoi,
      nghiViec: nghiViec ?? this.nghiViec,
      donChoPheDuyet: donChoPheDuyet ?? this.donChoPheDuyet,
      chamCongPhongBan: chamCongPhongBan ?? this.chamCongPhongBan,
      nhanVienTheoTuoi: nhanVienTheoTuoi ?? this.nhanVienTheoTuoi,
      nhanVienTheoGioiTinh: nhanVienTheoGioiTinh ?? this.nhanVienTheoGioiTinh,
    );
  }

  @override
  List<Object?> get props => [
        tongNhanVien, dangLamViec, nhanVienMoi, nghiViec, donChoPheDuyet,
        chamCongPhongBan, nhanVienTheoTuoi, nhanVienTheoGioiTinh,
      ];
}
