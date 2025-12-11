import 'package:equatable/equatable.dart';
import '../../../domain/entities/project.dart';

abstract class ProjectEvent extends Equatable {
  const ProjectEvent();
  @override
  List<Object?> get props => [];
}

class ProjectLoadAll extends ProjectEvent {
  final ProjectStatus? filterStatus;
  const ProjectLoadAll({this.filterStatus});
  @override
  List<Object?> get props => [filterStatus];
}

class ProjectLoadByUser extends ProjectEvent {
  final String userId;
  const ProjectLoadByUser(this.userId);
  @override
  List<Object?> get props => [userId];
}

class ProjectCreate extends ProjectEvent {
  final Project project;
  const ProjectCreate(this.project);
  @override
  List<Object?> get props => [project];
}

class ProjectUpdate extends ProjectEvent {
  final Project project;
  const ProjectUpdate(this.project);
  @override
  List<Object?> get props => [project];
}

class ProjectDelete extends ProjectEvent {
  final String projectId;
  const ProjectDelete(this.projectId);
  @override
  List<Object?> get props => [projectId];
}

class ProjectAddMember extends ProjectEvent {
  final String projectId;
  final String userId;
  const ProjectAddMember(this.projectId, this.userId);
  @override
  List<Object?> get props => [projectId, userId];
}

class ProjectRemoveMember extends ProjectEvent {
  final String projectId;
  final String userId;
  const ProjectRemoveMember(this.projectId, this.userId);
  @override
  List<Object?> get props => [projectId, userId];
}

class ProjectSelect extends ProjectEvent {
  final Project? project;
  const ProjectSelect(this.project);
  @override
  List<Object?> get props => [project];
}
