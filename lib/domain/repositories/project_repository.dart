import 'package:cashspark/domain/entities/project_entity.dart';

abstract class ProjectRepository {
  Future<List<ProjectEntity>> getActiveProjects();
  Future<List<ProjectEntity>> getAllProjects();
  Stream<List<ProjectEntity>> streamActiveProjects();
  Stream<List<ProjectEntity>> streamAllProjects();
  Future<void> createProject(ProjectEntity project);
  Future<void> updateProject(ProjectEntity project);
  Future<void> deleteProject(String projectId);
  Future<void> toggleProjectStatus(String projectId, bool isActive);
}
