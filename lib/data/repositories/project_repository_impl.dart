import 'package:cashspark/data/datasources/project_firestore_datasource.dart';
import 'package:cashspark/data/models/project_model.dart';
import 'package:cashspark/domain/entities/project_entity.dart';
import 'package:cashspark/domain/repositories/project_repository.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectFirestoreDataSource _dataSource;

  ProjectRepositoryImpl({
    required ProjectFirestoreDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  Future<List<ProjectEntity>> getActiveProjects() async {
    final models = await _dataSource.getActiveProjects();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Stream<List<ProjectEntity>> streamActiveProjects() {
    return _dataSource.streamActiveProjects().map((models) =>
        models.map((m) => m.toEntity()).toList());
  }

  @override
  Stream<List<ProjectEntity>> streamAllProjects() {
    return _dataSource.streamAllProjects().map((models) =>
        models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<List<ProjectEntity>> getAllProjects() async {
    final models = await _dataSource.getAllProjects();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> createProject(ProjectEntity project) async {
    final model = ProjectModel.fromEntity(project);
    await _dataSource.createProject(model);
  }

  @override
  Future<void> updateProject(ProjectEntity project) async {
    final model = ProjectModel.fromEntity(project);
    await _dataSource.updateProject(model);
  }

  @override
  Future<void> deleteProject(String projectId) async {
    await _dataSource.deleteProject(projectId);
  }

  @override
  Future<void> toggleProjectStatus(String projectId, bool isActive) async {
    await _dataSource.toggleProjectStatus(projectId, isActive);
  }
}
