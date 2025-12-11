import 'package:equatable/equatable.dart';
import '../../../domain/entities/issue.dart';

enum IssueBlocStatus { initial, loading, loaded, creating, updating, deleting, error }

class IssueState extends Equatable {
  final IssueBlocStatus status;
  final List<Issue> issues;
  final String? currentProjectId;
  final String? errorMessage;

  const IssueState({
    this.status = IssueBlocStatus.initial,
    this.issues = const [],
    this.currentProjectId,
    this.errorMessage,
  });

  // Kanban helpers
  List<Issue> get todoIssues => issues.where((i) => i.status == IssueStatus.todo).toList();
  List<Issue> get inProgressIssues => issues.where((i) => i.status == IssueStatus.inProgress).toList();
  List<Issue> get doneIssues => issues.where((i) => i.status == IssueStatus.done).toList();

  IssueState copyWith({
    IssueBlocStatus? status,
    List<Issue>? issues,
    String? currentProjectId,
    String? errorMessage,
  }) {
    return IssueState(
      status: status ?? this.status,
      issues: issues ?? this.issues,
      currentProjectId: currentProjectId ?? this.currentProjectId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, issues, currentProjectId, errorMessage];
}
