import 'package:equatable/equatable.dart';

/// Employee Status
enum EmployeeStatus {
  working,    // DANG_LAM_VIEC
  tempOff,    // TAM_NGHI
  terminated, // NGHI_VIEC
}

extension EmployeeStatusExtension on EmployeeStatus {
  String get value {
    switch (this) {
      case EmployeeStatus.working:
        return 'DANG_LAM_VIEC';
      case EmployeeStatus.tempOff:
        return 'TAM_NGHI';
      case EmployeeStatus.terminated:
        return 'NGHI_VIEC';
    }
  }

  String get displayName {
    switch (this) {
      case EmployeeStatus.working:
        return 'Đang làm việc';
      case EmployeeStatus.tempOff:
        return 'Tạm nghỉ';
      case EmployeeStatus.terminated:
        return 'Nghỉ việc';
    }
  }

  static EmployeeStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'TAM_NGHI':
        return EmployeeStatus.tempOff;
      case 'NGHI_VIEC':
        return EmployeeStatus.terminated;
      case 'DANG_LAM_VIEC':
      default:
        return EmployeeStatus.working;
    }
  }
}

/// Employee entity for HR management
class Employee extends Equatable {
  final String id;
  final String? maNhanVien;
  final String? userId;
  final String hoTen;
  final String? email;
  final String? soDienThoai;
  final String? cccd;
  final DateTime? ngaySinh;
  final String gioiTinh;
  final String? diaChi;
  final DateTime? ngayVaoLam;
  final String? phongBanId;
  final String? tenPhongBan;
  final String? chucVuId;
  final String? tenChucVu;
  final double? luongCoBan;
  final double? phuCap;
  final EmployeeStatus status;
  final String? avatarUrl;

  const Employee({
    required this.id,
    this.maNhanVien,
    this.userId,
    required this.hoTen,
    this.email,
    this.soDienThoai,
    this.cccd,
    this.ngaySinh,
    this.gioiTinh = 'Nam',
    this.diaChi,
    this.ngayVaoLam,
    this.phongBanId,
    this.tenPhongBan,
    this.chucVuId,
    this.tenChucVu,
    this.luongCoBan,
    this.phuCap,
    this.status = EmployeeStatus.working,
    this.avatarUrl,
  });

  Employee copyWith({
    String? id,
    String? maNhanVien,
    String? userId,
    String? hoTen,
    String? email,
    String? soDienThoai,
    String? cccd,
    DateTime? ngaySinh,
    String? gioiTinh,
    String? diaChi,
    DateTime? ngayVaoLam,
    String? phongBanId,
    String? tenPhongBan,
    String? chucVuId,
    String? tenChucVu,
    double? luongCoBan,
    double? phuCap,
    EmployeeStatus? status,
    String? avatarUrl,
  }) {
    return Employee(
      id: id ?? this.id,
      maNhanVien: maNhanVien ?? this.maNhanVien,
      userId: userId ?? this.userId,
      hoTen: hoTen ?? this.hoTen,
      email: email ?? this.email,
      soDienThoai: soDienThoai ?? this.soDienThoai,
      cccd: cccd ?? this.cccd,
      ngaySinh: ngaySinh ?? this.ngaySinh,
      gioiTinh: gioiTinh ?? this.gioiTinh,
      diaChi: diaChi ?? this.diaChi,
      ngayVaoLam: ngayVaoLam ?? this.ngayVaoLam,
      phongBanId: phongBanId ?? this.phongBanId,
      tenPhongBan: tenPhongBan ?? this.tenPhongBan,
      chucVuId: chucVuId ?? this.chucVuId,
      tenChucVu: tenChucVu ?? this.tenChucVu,
      luongCoBan: luongCoBan ?? this.luongCoBan,
      phuCap: phuCap ?? this.phuCap,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  List<Object?> get props => [
        id, maNhanVien, userId, hoTen, email, soDienThoai, cccd,
        ngaySinh, gioiTinh, diaChi, ngayVaoLam, phongBanId, tenPhongBan,
        chucVuId, tenChucVu, luongCoBan, phuCap, status, avatarUrl,
      ];
}
