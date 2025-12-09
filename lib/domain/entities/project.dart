/// Project Entity
/// 
/// Domain entity representing a project in the system.

import 'package:equatable/equatable.dart';

/// Project status enum
enum ProjectStatus {
  planning,
  active,
  onHold,
  completed,
  archived,
}

/// Extension to convert ProjectStatus to/from string
extension ProjectStatusExtension on ProjectStatus {
  String get value {
    switch (this) {
      case ProjectStatus.planning:
        return 'PLANNING';
      case ProjectStatus.active:
        return 'ACTIVE';
      case ProjectStatus.onHold:
        return 'ON_HOLD';
      case ProjectStatus.completed:
        return 'COMPLETED';
      case ProjectStatus.archived:
        return 'ARCHIVED';
    }
  }

  String get displayName {
    switch (this) {
      case ProjectStatus.planning:
        return 'Lập kế hoạch';
      case ProjectStatus.active:
        return 'Đang thực hiện';
      case ProjectStatus.onHold:
        return 'Tạm dừng';
      case ProjectStatus.completed:
        return 'Hoàn thành';
      case ProjectStatus.archived:
        return 'Lưu trữ';
    }
  }

  static ProjectStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ACTIVE':
        return ProjectStatus.active;
      case 'ON_HOLD':
        return ProjectStatus.onHold;
      case 'COMPLETED':
        return ProjectStatus.completed;
      case 'ARCHIVED':
        return ProjectStatus.archived;
      case 'PLANNING':
      default:
        return ProjectStatus.planning;
    }
  }
}

/// Project entity
class Project extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final ProjectStatus status;
  final String ownerId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int progress; // 0-100
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> memberIds;

  const Project({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.status = ProjectStatus.planning,
    required this.ownerId,
    this.startDate,
    this.endDate,
    this.progress = 0,
    this.createdAt,
    this.updatedAt,
    this.memberIds = const [],
  });

  /// Creates a copy with updated fields
  Project copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    ProjectStatus? status,
    String? ownerId,
    DateTime? startDate,
    DateTime? endDate,
    int? progress,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? memberIds,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      ownerId: ownerId ?? this.ownerId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      memberIds: memberIds ?? this.memberIds,
    );
  }

  @override
  List<Object?> get props => [
        id, name, description, imageUrl, status, ownerId,
        startDate, endDate, progress, createdAt, updatedAt, memberIds,
      ];
}
