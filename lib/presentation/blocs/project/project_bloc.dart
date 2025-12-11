import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/project_datasource.dart';
import 'project_event.dart';
import 'project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final ProjectDataSource _dataSource;

  ProjectBloc({required ProjectDataSource dataSource})
      : _dataSource = dataSource,
        super(const ProjectState()) {
    on<ProjectLoadAll>(_onLoadAll);
    on<ProjectLoadByUser>(_onLoadByUser);
    on<ProjectCreate>(_onCreate);
    on<ProjectUpdate>(_onUpdate);
    on<ProjectDelete>(_onDelete);
    on<ProjectAddMember>(_onAddMember);
    on<ProjectRemoveMember>(_onRemoveMember);
    on<ProjectSelect>(_onSelect);
  }

  Future<void> _onLoadAll(ProjectLoadAll event, Emitter<ProjectState> emit) async {
    emit(state.copyWith(status: ProjectBlocStatus.loading, filterStatus: event.filterStatus));
    try {
      final projects = await _dataSource.getProjects(status: event.filterStatus);
      emit(state.copyWith(
        status: ProjectBlocStatus.loaded,
        projects: projects.map((m) => m.toEntity()).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(status: ProjectBlocStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadByUser(ProjectLoadByUser event, Emitter<ProjectState> emit) async {
    emit(state.copyWith(status: ProjectBlocStatus.loading));
    try {
      final projects = await _dataSource.getProjectsByUser(event.userId);
      emit(state.copyWith(
        status: ProjectBlocStatus.loaded,
        projects: projects.map((m) => m.toEntity()).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(status: ProjectBlocStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onCreate(ProjectCreate event, Emitter<ProjectState> emit) async {
    emit(state.copyWith(status: ProjectBlocStatus.creating));
    try {
      final created = await _dataSource.createProject(event.project);
      final updatedList = [created.toEntity(), ...state.projects];
      emit(state.copyWith(status: ProjectBlocStatus.loaded, projects: updatedList));
    } catch (e) {
      emit(state.copyWith(status: ProjectBlocStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdate(ProjectUpdate event, Emitter<ProjectState> emit) async {
    emit(state.copyWith(status: ProjectBlocStatus.updating));
    try {
      final updated = await _dataSource.updateProject(event.project);
      final updatedList = state.projects.map((p) => p.id == updated.id ? updated.toEntity() : p).toList();
      emit(state.copyWith(
        status: ProjectBlocStatus.loaded, 
        projects: updatedList,
        selectedProject: state.selectedProject?.id == updated.id ? updated.toEntity() : state.selectedProject,
      ));
    } catch (e) {
      emit(state.copyWith(status: ProjectBlocStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onDelete(ProjectDelete event, Emitter<ProjectState> emit) async {
    emit(state.copyWith(status: ProjectBlocStatus.deleting));
    try {
      await _dataSource.deleteProject(event.projectId);
      final updatedList = state.projects.where((p) => p.id != event.projectId).toList();
      emit(state.copyWith(
        status: ProjectBlocStatus.loaded, 
        projects: updatedList,
        clearSelectedProject: state.selectedProject?.id == event.projectId,
      ));
    } catch (e) {
      emit(state.copyWith(status: ProjectBlocStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onAddMember(ProjectAddMember event, Emitter<ProjectState> emit) async {
    try {
      await _dataSource.addMember(event.projectId, event.userId);
      add(ProjectLoadAll(filterStatus: state.filterStatus));
    } catch (e) {
      emit(state.copyWith(status: ProjectBlocStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onRemoveMember(ProjectRemoveMember event, Emitter<ProjectState> emit) async {
    try {
      await _dataSource.removeMember(event.projectId, event.userId);
      add(ProjectLoadAll(filterStatus: state.filterStatus));
    } catch (e) {
      emit(state.copyWith(status: ProjectBlocStatus.error, errorMessage: e.toString()));
    }
  }

  void _onSelect(ProjectSelect event, Emitter<ProjectState> emit) {
    emit(state.copyWith(selectedProject: event.project, clearSelectedProject: event.project == null));
  }
}
