import 'package:equatable/equatable.dart';
import '../../../domain/entities/issue.dart';

abstract class IssueEvent extends Equatable {
  const IssueEvent();
  @override
  List<Object?> get props => [];
}

class IssueLoadByProject extends IssueEvent {
  final String projectId;
  const IssueLoadByProject(this.projectId);
  @override
  List<Object?> get props => [projectId];
}

class IssueLoadByAssignee extends IssueEvent {
  final String userId;
  const IssueLoadByAssignee(this.userId);
  @override
  List<Object?> get props => [userId];
}

class IssueCreate extends IssueEvent {
  final Issue issue;
  const IssueCreate(this.issue);
  @override
  List<Object?> get props => [issue];
}

class IssueUpdate extends IssueEvent {
  final Issue issue;
  const IssueUpdate(this.issue);
  @override
  List<Object?> get props => [issue];
}

class IssueUpdateStatus extends IssueEvent {
  final String issueId;
  final IssueStatus status;
  const IssueUpdateStatus(this.issueId, this.status);
  @override
  List<Object?> get props => [issueId, status];
}

class IssueDelete extends IssueEvent {
  final String issueId;
  const IssueDelete(this.issueId);
  @override
  List<Object?> get props => [issueId];
}

class IssueAssign extends IssueEvent {
  final String issueId;
  final String? userId;
  const IssueAssign(this.issueId, this.userId);
  @override
  List<Object?> get props => [issueId, userId];
}
