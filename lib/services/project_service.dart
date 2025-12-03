import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/project.dart';
import 'observability_service.dart';
import 'project_sync_service.dart';

/// Service for managing projects.
///
/// This service provides a unified interface for storing projects both
/// locally (SharedPreferences) and in the cloud (via [ProjectSyncService]).
///
/// Features:
/// - **Local-first**: Projects are always stored locally for offline access
/// - **Cloud sync**: When enabled, projects are synced to the cloud
/// - **Fallback behavior**: If cloud sync fails, local storage is used
class ProjectService {
  static const String _projectsKey = 'projects';
  static const String _currentProjectKey = 'current_project_id';
  static const String _defaultProjectId = 'default';
  final ObservabilityService _observability = ObservabilityService();
  final Uuid _uuid = const Uuid();

  /// Optional sync service for cloud storage.
  ProjectSyncService? syncService;

  /// Creates a new ProjectService.
  ProjectService({this.syncService});

  /// Load all active projects from storage.
  Future<List<Project>> loadProjects() async {
    try {
      // Try to load from cloud first if sync is enabled
      if (syncService != null) {
        try {
          final isSyncAvailable = await syncService!.isAvailable();
          if (isSyncAvailable) {
            final cloudProjects = await syncService!.loadProjects();
            // Update local cache with cloud data
            await _saveToLocalStorage(cloudProjects);
            return cloudProjects.where((p) => p.isActive).toList();
          }
        } catch (e, stackTrace) {
          _observability.trackError(
            e,
            stackTrace: stackTrace,
            context: {'operation': 'load_projects_cloud'},
          );
          // Fall through to local storage
        }
      }

      // Load from local storage
      final projects = await _loadFromLocalStorage();
      return projects.where((p) => p.isActive).toList();
    } catch (e, stackTrace) {
      _observability.trackError(
        e,
        stackTrace: stackTrace,
        context: {'operation': 'load_projects'},
      );
      return [];
    }
  }

  /// Load all projects including deleted ones (for admin/recovery purposes).
  Future<List<Project>> loadAllProjects() async {
    return await _loadFromLocalStorage();
  }

  /// Create a new project.
  Future<Project> createProject(String name) async {
    final project = Project(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
    );

    final allProjects = await _loadFromLocalStorage();
    allProjects.add(project);
    await _saveToLocalStorage(allProjects);

    // Sync to cloud if enabled
    if (syncService != null) {
      try {
        final isSyncAvailable = await syncService!.isAvailable();
        if (isSyncAvailable) {
          await syncService!.createProject(project);
        }
      } catch (e, stackTrace) {
        _observability.trackError(
          e,
          stackTrace: stackTrace,
          context: {'operation': 'create_project_cloud'},
        );
      }
    }

    _observability.trackEvent(
      'project_created',
      attributes: {'project_id': project.id},
    );

    return project;
  }

  /// Update an existing project.
  Future<void> updateProject(Project project) async {
    final allProjects = await _loadFromLocalStorage();
    final index = allProjects.indexWhere((p) => p.id == project.id);

    if (index == -1) {
      throw Exception('Project not found: ${project.id}');
    }

    allProjects[index] = project;
    await _saveToLocalStorage(allProjects);

    // Sync to cloud if enabled
    if (syncService != null) {
      try {
        final isSyncAvailable = await syncService!.isAvailable();
        if (isSyncAvailable) {
          await syncService!.updateProject(project);
        }
      } catch (e, stackTrace) {
        _observability.trackError(
          e,
          stackTrace: stackTrace,
          context: {'operation': 'update_project_cloud'},
        );
      }
    }

    _observability.trackEvent(
      'project_updated',
      attributes: {'project_id': project.id},
    );
  }

  /// Soft-delete a project by setting deletedAt timestamp.
  Future<void> deleteProject(String projectId) async {
    final allProjects = await _loadFromLocalStorage();
    final index = allProjects.indexWhere((p) => p.id == projectId);

    if (index == -1) {
      throw Exception('Project not found: $projectId');
    }

    allProjects[index] = allProjects[index].copyWith(
      deletedAt: DateTime.now(),
    );
    await _saveToLocalStorage(allProjects);

    // Sync to cloud if enabled
    if (syncService != null) {
      try {
        final isSyncAvailable = await syncService!.isAvailable();
        if (isSyncAvailable) {
          await syncService!.deleteProject(projectId);
        }
      } catch (e, stackTrace) {
        _observability.trackError(
          e,
          stackTrace: stackTrace,
          context: {'operation': 'delete_project_cloud'},
        );
      }
    }

    _observability.trackEvent(
      'project_deleted',
      attributes: {'project_id': projectId},
    );
  }

  /// Get the currently selected project ID.
  Future<String?> getCurrentProjectId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentProjectKey);
  }

  /// Set the currently selected project.
  Future<void> setCurrentProjectId(String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentProjectKey, projectId);
  }

  /// Ensure a default project exists. Creates one if none exist.
  /// Returns the default project or the first active project.
  Future<Project> ensureDefaultProject() async {
    final projects = await loadProjects();

    // If projects exist, return the first one or find "Default"
    if (projects.isNotEmpty) {
      final defaultProject = projects.firstWhere(
        (p) => p.id == _defaultProjectId || p.name == 'Default',
        orElse: () => projects.first,
      );
      return defaultProject;
    }

    // No projects exist, create the default one
    final defaultProject = Project(
      id: _defaultProjectId,
      name: 'Default',
      createdAt: DateTime.now(),
    );

    final allProjects = await _loadFromLocalStorage();
    allProjects.add(defaultProject);
    await _saveToLocalStorage(allProjects);

    // Sync to cloud if enabled
    if (syncService != null) {
      try {
        final isSyncAvailable = await syncService!.isAvailable();
        if (isSyncAvailable) {
          await syncService!.createProject(defaultProject);
        }
      } catch (e, stackTrace) {
        _observability.trackError(
          e,
          stackTrace: stackTrace,
          context: {'operation': 'ensure_default_project_cloud'},
        );
      }
    }

    return defaultProject;
  }

  /// Clear all projects (useful for testing and account deletion).
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_projectsKey);
    await prefs.remove(_currentProjectKey);

    // Clear cloud data if sync is enabled
    if (syncService != null) {
      try {
        final isSyncAvailable = await syncService!.isAvailable();
        if (isSyncAvailable) {
          await syncService!.clearAll();
        }
      } catch (e, stackTrace) {
        _observability.trackError(
          e,
          stackTrace: stackTrace,
          context: {'operation': 'clear_all_projects_cloud'},
        );
      }
    }
  }

  // Private methods for local storage operations

  Future<List<Project>> _loadFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_projectsKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => Project.fromJson(json)).toList();
  }

  Future<void> _saveToLocalStorage(List<Project> projects) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = projects.map((p) => p.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await prefs.setString(_projectsKey, jsonString);
    } catch (e, stackTrace) {
      _observability.trackError(
        e,
        stackTrace: stackTrace,
        context: {
          'operation': 'save_projects_local',
          'project_count': projects.length.toString(),
        },
      );
    }
  }
}
