import '../models/project.dart';

/// Abstract interface for syncing projects to cloud storage.
///
/// This interface allows the app to support different backend implementations
/// (Firestore, REST API, etc.) without changing the business logic.
///
/// See [FirestoreProjectSyncService] for the Firestore implementation.
abstract class ProjectSyncService {
  /// Check if the sync service is available.
  ///
  /// Returns true if the user is authenticated and the backend is accessible.
  Future<bool> isAvailable();

  /// Load all projects from cloud storage.
  Future<List<Project>> loadProjects();

  /// Create a new project in cloud storage.
  Future<void> createProject(Project project);

  /// Update an existing project in cloud storage.
  Future<void> updateProject(Project project);

  /// Soft-delete a project in cloud storage.
  Future<void> deleteProject(String projectId);

  /// Clear all projects from cloud storage.
  Future<void> clearAll();

  /// Get the last sync time for projects.
  Future<DateTime?> getLastSyncTime();
}

/// Exception thrown when a sync operation fails.
class ProjectSyncException implements Exception {
  final String code;
  final String message;
  final dynamic cause;

  ProjectSyncException({
    required this.code,
    required this.message,
    this.cause,
  });

  @override
  String toString() => 'ProjectSyncException: $message (code: $code)';

  // Common error codes
  static const String notAuthenticated = 'not_authenticated';
  static const String permissionDenied = 'permission_denied';
  static const String notFound = 'not_found';
  static const String networkError = 'network_error';
  static const String unknown = 'unknown';
}
