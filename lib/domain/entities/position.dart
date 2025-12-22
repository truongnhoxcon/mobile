import 'package:equatable/equatable.dart';

/// Position entity
class Position extends Equatable {
  final String id;
  final String tenChucVu;
  final String? moTa;

  const Position({
    required this.id,
    required this.tenChucVu,
    this.moTa,
  });

  Position copyWith({
    String? id,
    String? tenChucVu,
    String? moTa,
  }) {
    return Position(
      id: id ?? this.id,
      tenChucVu: tenChucVu ?? this.tenChucVu,
      moTa: moTa ?? this.moTa,
    );
  }

  @override
  List<Object?> get props => [id, tenChucVu, moTa];
}
