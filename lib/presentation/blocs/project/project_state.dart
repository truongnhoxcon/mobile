import 'package:equatable/equatable.dart';
import '../../../domain/entities/project.dart';

enum ProjectBlocStatus { initial, loading, loaded, creating, updating, deleting, error }

class ProjectState extends Equatable {
  final ProjectBlocStatus status;
  final List<Project> projects;
  final Project? selectedProject;
  final ProjectStatus? filterStatus;
  final String? errorMessage;

  const ProjectState({
    this.status = ProjectBlocStatus.initial,
    this.projects = const [],
    this.selectedProject,
    this.filterStatus,
    this.errorMessage,
  });

  ProjectState copyWith({
    ProjectBlocStatus? status,
    List<Project>? projects,
    Project? selectedProject,
    ProjectStatus? filterStatus,
    String? errorMessage,
    bool clearSelectedProject = false,
    bool clearFilter = false,
  }) {
    return ProjectState(
      status: status ?? this.status,
      projects: projects ?? this.projects,
      selectedProject: clearSelectedProject ? null : (selectedProject ?? this.selectedProject),
      filterStatus: clearFilter ? null : (filterStatus ?? this.filterStatus),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, projects, selectedProject, filterStatus, errorMessage];
}
