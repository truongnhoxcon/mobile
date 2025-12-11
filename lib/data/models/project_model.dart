import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/project.dart';

class ProjectModel extends Project {
  const ProjectModel({
    required super.id,
    required super.name,
    super.description,
    super.imageUrl,
    super.status,
    required super.ownerId,
    super.startDate,
    super.endDate,
    super.progress,
    super.createdAt,
    super.updatedAt,
    super.memberIds,
  });

  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProjectModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      imageUrl: data['imageUrl'],
      status: ProjectStatusExtension.fromString(data['status'] ?? 'PLANNING'),
      ownerId: data['ownerId'] ?? '',
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      progress: data['progress'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      memberIds: List<String>.from(data['memberIds'] ?? []),
    );
  }

  factory ProjectModel.fromEntity(Project project) {
    return ProjectModel(
      id: project.id,
      name: project.name,
      description: project.description,
      imageUrl: project.imageUrl,
      status: project.status,
      ownerId: project.ownerId,
      startDate: project.startDate,
      endDate: project.endDate,
      progress: project.progress,
      createdAt: project.createdAt,
      updatedAt: project.updatedAt,
      memberIds: project.memberIds,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'status': status.value,
      'ownerId': ownerId,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'progress': progress,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'memberIds': memberIds,
    };
  }

  Project toEntity() => Project(
    id: id, name: name, description: description, imageUrl: imageUrl,
    status: status, ownerId: ownerId, startDate: startDate, endDate: endDate,
    progress: progress, createdAt: createdAt, updatedAt: updatedAt, memberIds: memberIds,
  );
}
