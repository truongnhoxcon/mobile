import 'package:equatable/equatable.dart';

/// Department entity
class Department extends Equatable {
  final String id;
  final String tenPhongBan;
  final String? moTa;
  final int? soNhanVien;

  const Department({
    required this.id,
    required this.tenPhongBan,
    this.moTa,
    this.soNhanVien,
  });

  Department copyWith({
    String? id,
    String? tenPhongBan,
    String? moTa,
    int? soNhanVien,
  }) {
    return Department(
      id: id ?? this.id,
      tenPhongBan: tenPhongBan ?? this.tenPhongBan,
      moTa: moTa ?? this.moTa,
      soNhanVien: soNhanVien ?? this.soNhanVien,
    );
  }

  @override
  List<Object?> get props => [id, tenPhongBan, moTa, soNhanVien];
}
