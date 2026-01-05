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
    print('createProject: Creating project ${project.name}');
    final model = ProjectModel.fromEntity(project);
    final docRef = await _projectsRef.add(model.toFirestore());
    print('createProject: Project created with id=${docRef.id}');
    
    // Auto-create Project Chat Room
    try {
      print('createProject: Creating chat room for project ${docRef.id}');
      final chatRoomData = {
        'name': project.name,
        'type': 'PROJECT',
        'memberIds': project.memberIds,
        'memberNames': {}, // Will be populated by users joining or initial set
        'projectId': docRef.id,
        'createdBy': project.ownerId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'typingUsers': {},
        'unreadCounts': {},
        'mutedBy': [],
      };
      final chatDoc = await _firestore.collection('chatRooms').add(chatRoomData);
      print('createProject: Chat room created with id=${chatDoc.id}');
    } catch (e) {
      print('Error creating project chat room: $e');
      // Non-blocking error
    }

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
    print('ProjectDataSource.addMember: projectId=$projectId, userId=$userId');
    
    await _projectsRef.doc(projectId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Sync with project chat room
    try {
      print('Searching for chat room with projectId=$projectId');
      final chatSnapshot = await _firestore.collection('chatRooms')
          .where('projectId', isEqualTo: projectId)
          .limit(1)
          .get();
      
      print('Found ${chatSnapshot.docs.length} chat rooms');
      
      if (chatSnapshot.docs.isNotEmpty) {
        final chatDoc = chatSnapshot.docs.first;
        print('Updating chat room: ${chatDoc.id}');
        await chatDoc.reference.update({
          'memberIds': FieldValue.arrayUnion([userId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('Chat room member sync completed');
      } else {
        print('No chat room found for projectId=$projectId');
      }
    } catch (e) {
      print('Error syncing chat room member: $e');
    }
  }

  @override
  Future<void> removeMember(String projectId, String userId) async {
    await _projectsRef.doc(projectId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Sync with project chat room
    try {
      final chatSnapshot = await _firestore.collection('chatRooms')
          .where('projectId', isEqualTo: projectId)
          .limit(1)
          .get();
      if (chatSnapshot.docs.isNotEmpty) {
        await chatSnapshot.docs.first.reference.update({
          'memberIds': FieldValue.arrayRemove([userId]),
          'memberNames.$userId': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error syncing chat room member removal: $e');
    }
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
