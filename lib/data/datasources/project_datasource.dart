import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/project.dart';
import '../models/project_model.dart';

abstract class ProjectDataSource {
  Future<List<ProjectModel>> getProjects({ProjectStatus? status});
  Future<List<ProjectModel>> getProjectsByUser(String userId);
  Future<ProjectModel?> getProject(String id);
  Future<ProjectModel> createProject(Project project);
  Future<ProjectModel> updateProject(Project project);
  Future<void> deleteProject(String id);
  Future<void> addMember(String projectId, String userId);
  Future<void> removeMember(String projectId, String userId);
  Stream<List<ProjectModel>> projectsStream({ProjectStatus? status});
}

class ProjectDataSourceImpl implements ProjectDataSource {
  final FirebaseFirestore _firestore;

  ProjectDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _projectsRef =>
      _firestore.collection('projects');

  @override
  Future<List<ProjectModel>> getProjects({ProjectStatus? status}) async {
    Query<Map<String, dynamic>> query = _projectsRef.orderBy('createdAt', descending: true);
    
    if (status != null) {
      query = query.where('status', isEqualTo: status.value);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => ProjectModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<ProjectModel>> getProjectsByUser(String userId) async {
    // Query by memberIds only, sort in memory to avoid composite index
    final snapshot = await _projectsRef
        .where('memberIds', arrayContains: userId)
        .get();
    final projects = snapshot.docs.map((doc) => ProjectModel.fromFirestore(doc)).toList();
    // Sort by createdAt descending in memory (handle nullable)
    projects.sort((a, b) {
      final aDate = a.createdAt ?? DateTime(2000);
      final bDate = b.createdAt ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });
    return projects;
  }

  @override
  Future<ProjectModel?> getProject(String id) async {
    final doc = await _projectsRef.doc(id).get();
    if (!doc.exists) return null;
    return ProjectModel.fromFirestore(doc);
  }

  @override
  Future<ProjectModel> createProject(Project project) async {
    final model = ProjectModel.fromEntity(project);
    final docRef = await _projectsRef.add(model.toFirestore());
    final newDoc = await docRef.get();
    return ProjectModel.fromFirestore(newDoc);
  }

  @override
  Future<ProjectModel> updateProject(Project project) async {
    final model = ProjectModel.fromEntity(project);
    await _projectsRef.doc(project.id).update(model.toFirestore());
    final updatedDoc = await _projectsRef.doc(project.id).get();
    return ProjectModel.fromFirestore(updatedDoc);
  }

  @override
  Future<void> deleteProject(String id) async {
    await _projectsRef.doc(id).delete();
  }

  @override
  Future<void> addMember(String projectId, String userId) async {
    await _projectsRef.doc(projectId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removeMember(String projectId, String userId) async {
    await _projectsRef.doc(projectId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<ProjectModel>> projectsStream({ProjectStatus? status}) {
    Query<Map<String, dynamic>> query = _projectsRef.orderBy('createdAt', descending: true);
    
    if (status != null) {
      query = query.where('status', isEqualTo: status.value);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ProjectModel.fromFirestore(doc)).toList());
  }
}
