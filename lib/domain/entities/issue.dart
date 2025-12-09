/// Issue Entity
/// 
/// Domain entity representing a task/issue in a project.

import 'package:equatable/equatable.dart';

/// Issue type enum
enum IssueType { task, bug, story }

/// Issue priority enum
enum IssuePriority { low, medium, high, critical }

/// Issue status enum
enum IssueStatus { todo, inProgress, done }

extension IssueTypeExtension on IssueType {
  String get value => name.toUpperCase();
  String get displayName {
    switch (this) {
      case IssueType.task: return 'Task';
      case IssueType.bug: return 'Bug';
      case IssueType.story: return 'Story';
    }
  }
  static IssueType fromString(String v) {
    switch (v.toUpperCase()) {
      case 'BUG': return IssueType.bug;
      case 'STORY': return IssueType.story;
      default: return IssueType.task;
    }
  }
}

extension IssuePriorityExtension on IssuePriority {
  String get value => name.toUpperCase();
  String get displayName {
    switch (this) {
      case IssuePriority.low: return 'Thấp';
      case IssuePriority.medium: return 'Trung bình';
      case IssuePriority.high: return 'Cao';
      case IssuePriority.critical: return 'Khẩn cấp';
    }
  }
  static IssuePriority fromString(String v) {
    switch (v.toUpperCase()) {
      case 'LOW': return IssuePriority.low;
      case 'HIGH': return IssuePriority.high;
      case 'CRITICAL': return IssuePriority.critical;
      default: return IssuePriority.medium;
    }
  }
}

extension IssueStatusExtension on IssueStatus {
  String get value {
    switch (this) {
      case IssueStatus.todo: return 'TODO';
      case IssueStatus.inProgress: return 'IN_PROGRESS';
      case IssueStatus.done: return 'DONE';
    }
  }
  String get displayName {
    switch (this) {
      case IssueStatus.todo: return 'Chờ xử lý';
      case IssueStatus.inProgress: return 'Đang làm';
      case IssueStatus.done: return 'Hoàn thành';
    }
  }
  static IssueStatus fromString(String v) {
    switch (v.toUpperCase()) {
      case 'IN_PROGRESS': return IssueStatus.inProgress;
      case 'DONE': return IssueStatus.done;
      default: return IssueStatus.todo;
    }
  }
}

/// Issue entity
class Issue extends Equatable {
  final String id;
  final String projectId;
  final String title;
  final String? description;
  final IssueType type;
  final IssuePriority priority;
  final IssueStatus status;
  final String? assigneeId;
  final String reporterId;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Issue({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    this.type = IssueType.task,
    this.priority = IssuePriority.medium,
    this.status = IssueStatus.todo,
    this.assigneeId,
    required this.reporterId,
    this.dueDate,
    this.createdAt,
    this.updatedAt,
  });

  Issue copyWith({
    String? id, String? projectId, String? title, String? description,
    IssueType? type, IssuePriority? priority, IssueStatus? status,
    String? assigneeId, String? reporterId, DateTime? dueDate,
    DateTime? createdAt, DateTime? updatedAt,
  }) {
    return Issue(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      assigneeId: assigneeId ?? this.assigneeId,
      reporterId: reporterId ?? this.reporterId,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, projectId, title, description, type, priority,
        status, assigneeId, reporterId, dueDate, createdAt, updatedAt,
      ];
}
