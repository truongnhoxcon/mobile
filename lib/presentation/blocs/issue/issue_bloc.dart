import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/issue_datasource.dart';
import 'issue_event.dart';
import 'issue_state.dart';

class IssueBloc extends Bloc<IssueEvent, IssueState> {
  final IssueDataSource _dataSource;

  IssueBloc({required IssueDataSource dataSource})
      : _dataSource = dataSource,
        super(const IssueState()) {
    on<IssueLoadByProject>(_onLoadByProject);
    on<IssueLoadByAssignee>(_onLoadByAssignee);
    on<IssueCreate>(_onCreate);
    on<IssueUpdate>(_onUpdate);
    on<IssueUpdateStatus>(_onUpdateStatus);
    on<IssueDelete>(_onDelete);
    on<IssueAssign>(_onAssign);
  }

  Future<void> _onLoadByProject(IssueLoadByProject event, Emitter<IssueState> emit) async {
    emit(state.copyWith(status: IssueBlocStatus.loading, currentProjectId: event.projectId));
    try {
      final issues = await _dataSource.getIssuesByProject(event.projectId);
      emit(state.copyWith(
        status: IssueBlocStatus.loaded,
        issues: issues.map((m) => m.toEntity()).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(status: IssueBlocStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadByAssignee(IssueLoadByAssignee event, Emitter<IssueState> emit) async {
    emit(state.copyWith(status: IssueBlocStatus.loading));
    try {
      final issues = await _dataSource.getIssuesByAssignee(event.userId);
      emit(state.copyWith(
        status: IssueBlocStatus.loaded,
        issues: issues.map((m) => m.toEntity()).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(status: IssueBlocStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onCreate(IssueCreate event, Emitter<IssueState> emit) async {
    emit(state.copyWith(status: IssueBlocStatus.creating));
    try {
      final created = await _dataSource.createIssue(event.issue);
      final updatedList = [created.toEntity(), ...state.issues];
      emit(state.copyWith(status: IssueBlocStatus.loaded, issues: updatedList));
    } catch (e) {
      emit(state.copyWith(status: IssueBlocStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdate(IssueUpdate event, Emitter<IssueState> emit) async {
    emit(state.copyWith(status: IssueBlocStatus.updating));
    try {
      final updated = await _dataSource.updateIssue(event.issue);
      final updatedList = state.issues.map((i) => i.id == updated.id ? updated.toEntity() : i).toList();
      emit(state.copyWith(status: IssueBlocStatus.loaded, issues: updatedList));
    } catch (e) {
      emit(state.copyWith(status: IssueBlocStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdateStatus(IssueUpdateStatus event, Emitter<IssueState> emit) async {
    // Optimistic update
    final updatedList = state.issues.map((i) => 
      i.id == event.issueId ? i.copyWith(status: event.status) : i
    ).toList();
    emit(state.copyWith(issues: updatedList));

    try {
      await _dataSource.updateIssueStatus(event.issueId, event.status);
    } catch (e) {
      // Revert on error
      if (state.currentProjectId != null) {
        add(IssueLoadByProject(state.currentProjectId!));
      }
      emit(state.copyWith(status: IssueBlocStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onDelete(IssueDelete event, Emitter<IssueState> emit) async {
    emit(state.copyWith(status: IssueBlocStatus.deleting));
    try {
      await _dataSource.deleteIssue(event.issueId);
      final updatedList = state.issues.where((i) => i.id != event.issueId).toList();
      emit(state.copyWith(status: IssueBlocStatus.loaded, issues: updatedList));
    } catch (e) {
      emit(state.copyWith(status: IssueBlocStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onAssign(IssueAssign event, Emitter<IssueState> emit) async {
    try {
      await _dataSource.assignIssue(event.issueId, event.userId);
      final updatedList = state.issues.map((i) => 
        i.id == event.issueId ? i.copyWith(assigneeId: event.userId) : i
      ).toList();
      emit(state.copyWith(issues: updatedList));
    } catch (e) {
      emit(state.copyWith(status: IssueBlocStatus.error, errorMessage: e.toString()));
    }
  }
}
