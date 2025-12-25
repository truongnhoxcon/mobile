/// AI Action Entity
/// 
/// Represents an executable action that AI can perform.

import 'package:equatable/equatable.dart';

/// Action types that AI can execute
enum AIActionType {
  createTask,
  assignTask,
  updateTaskStatus,
  createProject,
}

extension AIActionTypeExtension on AIActionType {
  String get value {
    switch (this) {
      case AIActionType.createTask:
        return 'create_task';
      case AIActionType.assignTask:
        return 'assign_task';
      case AIActionType.updateTaskStatus:
        return 'update_task_status';
      case AIActionType.createProject:
        return 'create_project';
    }
  }

  String get displayName {
    switch (this) {
      case AIActionType.createTask:
        return 'Tạo công việc';
      case AIActionType.assignTask:
        return 'Giao việc';
      case AIActionType.updateTaskStatus:
        return 'Cập nhật trạng thái';
      case AIActionType.createProject:
        return 'Tạo dự án';
    }
  }

  static AIActionType? fromString(String value) {
    switch (value.toLowerCase()) {
      case 'create_task':
        return AIActionType.createTask;
      case 'assign_task':
        return AIActionType.assignTask;
      case 'update_task_status':
        return AIActionType.updateTaskStatus;
      case 'create_project':
        return AIActionType.createProject;
      default:
        return null;
    }
  }
}

/// Execution status of an action
enum AIActionStatus {
  pending,
  approved,
  rejected,
  executing,
  completed,
  failed,
}

/// AI Action entity
class AIAction extends Equatable {
  final String id;
  final AIActionType type;
  final Map<String, dynamic> params;
  final AIActionStatus status;
  final String? resultMessage;
  final DateTime createdAt;

  const AIAction({
    required this.id,
    required this.type,
    required this.params,
    this.status = AIActionStatus.pending,
    this.resultMessage,
    required this.createdAt,
  });

  /// Create from JSON (parsed from AI response)
  factory AIAction.fromJson(Map<String, dynamic> json, String id) {
    final typeStr = json['type'] as String? ?? '';
    final type = AIActionTypeExtension.fromString(typeStr);
    
    if (type == null) {
      throw Exception('Unknown action type: $typeStr');
    }
    
    return AIAction(
      id: id,
      type: type,
      params: json['params'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.now(),
    );
  }

  AIAction copyWith({
    String? id,
    AIActionType? type,
    Map<String, dynamic>? params,
    AIActionStatus? status,
    String? resultMessage,
    DateTime? createdAt,
  }) {
    return AIAction(
      id: id ?? this.id,
      type: type ?? this.type,
      params: params ?? this.params,
      status: status ?? this.status,
      resultMessage: resultMessage ?? this.resultMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get human-readable description of the action
  String get description {
    switch (type) {
      case AIActionType.createTask:
        final title = params['title'] ?? 'Không có tên';
        return 'Tạo task: $title';
      case AIActionType.assignTask:
        final taskId = params['taskId'] ?? '';
        final assigneeName = params['assigneeName'] ?? 'nhân viên';
        return 'Giao task $taskId cho $assigneeName';
      case AIActionType.updateTaskStatus:
        final taskId = params['taskId'] ?? '';
        final status = params['status'] ?? '';
        return 'Cập nhật task $taskId thành $status';
      case AIActionType.createProject:
        final name = params['name'] ?? 'Không có tên';
        return 'Tạo dự án: $name';
    }
  }

  @override
  List<Object?> get props => [id, type, params, status, resultMessage, createdAt];
}

/// AI Response with potential actions
class AIResponseWithActions {
  final String message;
  final List<AIAction> actions;

  const AIResponseWithActions({
    required this.message,
    this.actions = const [],
  });

  bool get hasActions => actions.isNotEmpty;
}
