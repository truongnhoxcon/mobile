import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/issue.dart';

class IssueModel extends Issue {
  const IssueModel({
    required super.id,
    required super.projectId,
    required super.title,
    super.description,
    super.type,
    super.priority,
    super.status,
    super.assigneeId,
    required super.reporterId,
    super.dueDate,
    super.createdAt,
    super.updatedAt,
  });

  factory IssueModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IssueModel(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      type: IssueTypeExtension.fromString(data['type'] ?? 'TASK'),
      priority: IssuePriorityExtension.fromString(data['priority'] ?? 'MEDIUM'),
      status: IssueStatusExtension.fromString(data['status'] ?? 'TODO'),
      assigneeId: data['assigneeId'],
      reporterId: data['reporterId'] ?? '',
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory IssueModel.fromEntity(Issue issue) {
    return IssueModel(
      id: issue.id,
      projectId: issue.projectId,
      title: issue.title,
      description: issue.description,
      type: issue.type,
      priority: issue.priority,
      status: issue.status,
      assigneeId: issue.assigneeId,
      reporterId: issue.reporterId,
      dueDate: issue.dueDate,
      createdAt: issue.createdAt,
      updatedAt: issue.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'title': title,
      'description': description,
      'type': type.value,
      'priority': priority.value,
      'status': status.value,
      'assigneeId': assigneeId,
      'reporterId': reporterId,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Issue toEntity() => Issue(
    id: id, projectId: projectId, title: title, description: description,
    type: type, priority: priority, status: status, assigneeId: assigneeId,
    reporterId: reporterId, dueDate: dueDate, createdAt: createdAt, updatedAt: updatedAt,
  );
}
