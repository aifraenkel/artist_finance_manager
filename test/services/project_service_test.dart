import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_finance_manager/services/project_service.dart';
import 'package:artist_finance_manager/models/project.dart';

void main() {
  group('ProjectService Tests', () {
    late ProjectService projectService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      projectService = ProjectService();
    });

    test('Load projects - initially empty', () async {
      final projects = await projectService.loadProjects();
      expect(projects, isEmpty);
    });

    test('Create project', () async {
      final project = await projectService.createProject('My Art Project');
      
      expect(project.name, 'My Art Project');
      expect(project.id, isNotEmpty);
      expect(project.isActive, isTrue);
      expect(project.deletedAt, isNull);
    });

    test('Create and load projects', () async {
      await projectService.createProject('Project 1');
      await projectService.createProject('Project 2');
      
      final projects = await projectService.loadProjects();
      expect(projects.length, 2);
      expect(projects.map((p) => p.name), containsAll(['Project 1', 'Project 2']));
    });

    test('Update project name', () async {
      final original = await projectService.createProject('Original Name');
      final updated = original.copyWith(name: 'Updated Name');
      
      await projectService.updateProject(updated);
      
      final projects = await projectService.loadProjects();
      expect(projects.length, 1);
      expect(projects.first.name, 'Updated Name');
      expect(projects.first.id, original.id);
    });

    test('Update non-existent project throws error', () async {
      final fakeProject = Project(
        id: 'non-existent',
        name: 'Fake',
        createdAt: DateTime.now(),
      );
      
      expect(
        () => projectService.updateProject(fakeProject),
        throwsA(isA<Exception>()),
      );
    });

    test('Delete project (soft delete)', () async {
      final project = await projectService.createProject('To Delete');
      
      await projectService.deleteProject(project.id);
      
      // Active projects should not include deleted
      final activeProjects = await projectService.loadProjects();
      expect(activeProjects, isEmpty);
      
      // All projects should include deleted with deletedAt set
      final allProjects = await projectService.loadAllProjects();
      expect(allProjects.length, 1);
      expect(allProjects.first.deletedAt, isNotNull);
      expect(allProjects.first.isDeleted, isTrue);
    });

    test('Delete non-existent project throws error', () async {
      expect(
        () => projectService.deleteProject('non-existent'),
        throwsA(isA<Exception>()),
      );
    });

    test('Get and set current project ID', () async {
      final project = await projectService.createProject('Current Project');
      
      await projectService.setCurrentProjectId(project.id);
      final currentId = await projectService.getCurrentProjectId();
      
      expect(currentId, project.id);
    });

    test('Current project ID is null initially', () async {
      final currentId = await projectService.getCurrentProjectId();
      expect(currentId, isNull);
    });

    test('Ensure default project - creates when none exist', () async {
      final defaultProject = await projectService.ensureDefaultProject();
      
      expect(defaultProject.id, 'default');
      expect(defaultProject.name, 'Default');
      expect(defaultProject.isActive, isTrue);
      
      final projects = await projectService.loadProjects();
      expect(projects.length, 1);
      expect(projects.first.id, 'default');
    });

    test('Ensure default project - returns existing', () async {
      final created = await projectService.createProject('First Project');
      
      final defaultProject = await projectService.ensureDefaultProject();
      
      // Should return the existing project, not create a new one
      expect(defaultProject.id, created.id);
      expect(defaultProject.name, created.name);
    });

    test('Ensure default project - finds Default by name', () async {
      await projectService.createProject('Default');
      await projectService.createProject('Other Project');
      
      final defaultProject = await projectService.ensureDefaultProject();
      
      expect(defaultProject.name, 'Default');
    });

    test('Ensure default project - finds by ID', () async {
      // Manually create a project with the default ID
      final prefs = await SharedPreferences.getInstance();
      final projects = [
        Project(
          id: 'default',
          name: 'Custom Default',
          createdAt: DateTime.now(),
        ).toJson()
      ];
      await prefs.setString('projects', 
          '${projects.map((p) => p).toList()}');
      
      final defaultProject = await projectService.ensureDefaultProject();
      
      expect(defaultProject.id, 'default');
    });

    test('Load all projects includes deleted', () async {
      await projectService.createProject('Active 1');
      final toDelete = await projectService.createProject('To Delete');
      await projectService.createProject('Active 2');
      
      await projectService.deleteProject(toDelete.id);
      
      final activeProjects = await projectService.loadProjects();
      expect(activeProjects.length, 2);
      
      final allProjects = await projectService.loadAllProjects();
      expect(allProjects.length, 3);
    });

    test('Clear all projects', () async {
      await projectService.createProject('Project 1');
      await projectService.createProject('Project 2');
      await projectService.setCurrentProjectId('some-id');
      
      await projectService.clearAll();
      
      final projects = await projectService.loadProjects();
      expect(projects, isEmpty);
      
      final currentId = await projectService.getCurrentProjectId();
      expect(currentId, isNull);
    });

    test('Multiple operations maintain data integrity', () async {
      final project1 = await projectService.createProject('Project 1');
      final project2 = await projectService.createProject('Project 2');
      final project3 = await projectService.createProject('Project 3');
      
      await projectService.deleteProject(project2.id);
      
      final renamed = project1.copyWith(name: 'Renamed Project 1');
      await projectService.updateProject(renamed);
      
      await projectService.setCurrentProjectId(project3.id);
      
      final activeProjects = await projectService.loadProjects();
      expect(activeProjects.length, 2);
      expect(activeProjects.any((p) => p.name == 'Renamed Project 1'), isTrue);
      expect(activeProjects.any((p) => p.id == project3.id), isTrue);
      expect(activeProjects.any((p) => p.id == project2.id), isFalse);
      
      final currentId = await projectService.getCurrentProjectId();
      expect(currentId, project3.id);
    });
  });
}
