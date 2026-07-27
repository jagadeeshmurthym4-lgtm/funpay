import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/core/constants/app_constants.dart';
import 'package:cashspark/data/models/project_model.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class ProjectFirestoreDataSource {
  final FirebaseFirestore _firestore;

  ProjectFirestoreDataSource({FirebaseFirestore? firestoreInstance})
      : _firestore = firestoreInstance ?? FirebaseFirestore.instance;

  Future<List<ProjectModel>> getAllProjects() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.projectsCollection)
          .get();
      final projects = snapshot.docs
          .map((doc) => ProjectModel.fromFirestore(doc.data()))
          .toList();
      projects.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return projects;
    } catch (e) {
      debugPrint('getAllProjects error: $e');
      return [];
    }
  }

  Future<List<ProjectModel>> getActiveProjects() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.projectsCollection)
          .get();
      final projects = snapshot.docs
          .map((doc) => ProjectModel.fromFirestore(doc.data()))
          .where((p) => p.isActive)
          .toList();
      projects.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return projects;
    } catch (e) {
      debugPrint('getActiveProjects error: $e');
      return [];
    }
  }

  /// Real-time stream of all projects (including inactive, for admin use).
  Stream<List<ProjectModel>> streamAllProjects() {
    return _firestore
        .collection(AppConstants.projectsCollection)
        .snapshots()
        .map((snapshot) {
      final projects = snapshot.docs
          .map((doc) => ProjectModel.fromFirestore(doc.data()))
          .toList();
      projects.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return projects;
    });
  }

  /// Real-time stream of active projects.
  Stream<List<ProjectModel>> streamActiveProjects() {
    return _firestore
        .collection(AppConstants.projectsCollection)
        .snapshots()
        .map((snapshot) {
      final projects = snapshot.docs
          .map((doc) => ProjectModel.fromFirestore(doc.data()))
          .where((p) => p.isActive)
          .toList();
      projects.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return projects;
    });
  }

  Future<void> createProject(ProjectModel project) async {
    await _firestore
        .collection(AppConstants.projectsCollection)
        .doc(project.projectId)
        .set(project.toFirestore());
  }

  Future<void> updateProject(ProjectModel project) async {
    await _firestore
        .collection(AppConstants.projectsCollection)
        .doc(project.projectId)
        .update(project.toFirestore());
  }

  Future<void> deleteProject(String projectId) async {
    await _firestore
        .collection(AppConstants.projectsCollection)
        .doc(projectId)
        .delete();
  }

  Future<void> toggleProjectStatus(String projectId, bool isActive) async {
    await _firestore
        .collection(AppConstants.projectsCollection)
        .doc(projectId)
        .update({'isActive': isActive, 'updatedAt': DateTime.now()});
  }
}
