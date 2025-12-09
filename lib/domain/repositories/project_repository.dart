/// Project Repository Interface
/// 
/// Defines the contract for project data operations.

import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/project.dart';

abstract class ProjectRepository {
  /// Get all projects for current user
  Future<Either<Failure, List<Project>>> getMyProjects();

  /// Get project by ID
  Future<Either<Failure, Project>> getProjectById(String projectId);

  /// Create new project
  Future<Either<Failure, Project>> createProject(Project project);

  /// Update project
  Future<Either<Failure, Project>> updateProject(Project project);

  /// Delete project
  Future<Either<Failure, void>> deleteProject(String projectId);

  /// Add member to project
  Future<Either<Failure, void>> addMember(String projectId, String userId);

  /// Remove member from project
  Future<Either<Failure, void>> removeMember(String projectId, String userId);

  /// Stream of project changes
  Stream<List<Project>> projectsStream();
}
