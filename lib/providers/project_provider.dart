import 'package:flutter/foundation.dart';
import '../models/project.dart';
import '../services/project_service.dart';

/// Provider for managing project state.
///
/// This provider handles:
/// - Loading and caching projects
/// - Managing the currently selected project
/// - Project CRUD operations
class ProjectProvider extends ChangeNotifier {
  final ProjectService projectService;
  
  List<Project> _projects = [];
  Project? _currentProject;
  bool _isLoading = false;
  String? _error;

  ProjectProvider(this.projectService);

  /// Get all active projects
  List<Project> get projects => _projects;

  /// Get the currently selected project
  Project? get currentProject => _currentProject;

  /// Check if projects are being loaded
  bool get isLoading => _isLoading;

  /// Get any error message
  String? get error => _error;

  /// Initialize the provider by loading projects and setting current project
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load all projects
      _projects = await projectService.loadProjects();

      // Get or create default project
      final defaultProject = await projectService.ensureDefaultProject();

      // Get the previously selected project or use default
      final savedProjectId = await projectService.getCurrentProjectId();
      if (savedProjectId != null) {
        _currentProject = _projects.firstWhere(
          (p) => p.id == savedProjectId,
          orElse: () => defaultProject,
        );
      } else {
        _currentProject = defaultProject;
        await projectService.setCurrentProjectId(defaultProject.id);
      }

      // If current project is not in the list, add it
      if (!_projects.contains(_currentProject)) {
        _projects.insert(0, _currentProject!);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reload projects from storage
  Future<void> refresh() async {
    await initialize();
  }

  /// Create a new project
  Future<Project?> createProject(String name) async {
    try {
      _error = null;
      final project = await projectService.createProject(name);
      _projects.add(project);
      notifyListeners();
      return project;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update a project
  Future<bool> updateProject(Project project) async {
    try {
      _error = null;
      await projectService.updateProject(project);
      
      final index = _projects.indexWhere((p) => p.id == project.id);
      if (index != -1) {
        _projects[index] = project;
      }
      
      if (_currentProject?.id == project.id) {
        _currentProject = project;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Rename a project
  Future<bool> renameProject(String projectId, String newName) async {
    final project = _projects.firstWhere((p) => p.id == projectId);
    final updatedProject = project.copyWith(name: newName);
    return await updateProject(updatedProject);
  }

  /// Delete a project (soft delete)
  Future<bool> deleteProject(String projectId) async {
    try {
      _error = null;
      await projectService.deleteProject(projectId);
      
      _projects.removeWhere((p) => p.id == projectId);
      
      // If we deleted the current project, switch to another one
      if (_currentProject?.id == projectId) {
        if (_projects.isNotEmpty) {
          await selectProject(_projects.first.id);
        } else {
          // Create a new default project if no projects remain
          final defaultProject = await projectService.ensureDefaultProject();
          _projects.add(defaultProject);
          _currentProject = defaultProject;
          await projectService.setCurrentProjectId(defaultProject.id);
        }
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Select a project as the current project
  Future<void> selectProject(String projectId) async {
    final project = _projects.firstWhere((p) => p.id == projectId);
    _currentProject = project;
    await projectService.setCurrentProjectId(projectId);
    notifyListeners();
  }

  /// Get financial summary across all projects
  Future<Map<String, double>> getGlobalSummary(
    Future<Map<String, double>> Function(String projectId) getSummary,
  ) async {
    double totalIncome = 0;
    double totalExpenses = 0;

    for (final project in _projects) {
      final summary = await getSummary(project.id);
      totalIncome += summary['income'] ?? 0;
      totalExpenses += summary['expenses'] ?? 0;
    }

    return {
      'income': totalIncome,
      'expenses': totalExpenses,
      'balance': totalIncome - totalExpenses,
    };
  }
}
