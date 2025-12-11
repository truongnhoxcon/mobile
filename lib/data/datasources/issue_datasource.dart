import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/issue.dart';
import '../models/issue_model.dart';

abstract class IssueDataSource {
  Future<List<IssueModel>> getIssuesByProject(String projectId);
  Future<List<IssueModel>> getIssuesByAssignee(String userId);
  Future<IssueModel?> getIssue(String id);
  Future<IssueModel> createIssue(Issue issue);
  Future<IssueModel> updateIssue(Issue issue);
  Future<void> updateIssueStatus(String id, IssueStatus status);
  Future<void> deleteIssue(String id);
  Future<void> assignIssue(String issueId, String? userId);
  Stream<List<IssueModel>> issuesStreamByProject(String projectId);
}

class IssueDataSourceImpl implements IssueDataSource {
  final FirebaseFirestore _firestore;

  IssueDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _issuesRef =>
      _firestore.collection('issues');

  @override
  Future<List<IssueModel>> getIssuesByProject(String projectId) async {
    final snapshot = await _issuesRef
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => IssueModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<IssueModel>> getIssuesByAssignee(String userId) async {
    final snapshot = await _issuesRef
        .where('assigneeId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => IssueModel.fromFirestore(doc)).toList();
  }

  @override
  Future<IssueModel?> getIssue(String id) async {
    final doc = await _issuesRef.doc(id).get();
    if (!doc.exists) return null;
    return IssueModel.fromFirestore(doc);
  }

  @override
  Future<IssueModel> createIssue(Issue issue) async {
    final model = IssueModel.fromEntity(issue);
    final docRef = await _issuesRef.add(model.toFirestore());
    final newDoc = await docRef.get();
    return IssueModel.fromFirestore(newDoc);
  }

  @override
  Future<IssueModel> updateIssue(Issue issue) async {
    final model = IssueModel.fromEntity(issue);
    await _issuesRef.doc(issue.id).update(model.toFirestore());
    final updatedDoc = await _issuesRef.doc(issue.id).get();
    return IssueModel.fromFirestore(updatedDoc);
  }

  @override
  Future<void> updateIssueStatus(String id, IssueStatus status) async {
    await _issuesRef.doc(id).update({
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteIssue(String id) async {
    await _issuesRef.doc(id).delete();
  }

  @override
  Future<void> assignIssue(String issueId, String? userId) async {
    await _issuesRef.doc(issueId).update({
      'assigneeId': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<IssueModel>> issuesStreamByProject(String projectId) {
    return _issuesRef
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => IssueModel.fromFirestore(doc)).toList());
  }
}
