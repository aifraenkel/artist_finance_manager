import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:artist_finance_manager/screens/home_screen.dart';
import 'package:artist_finance_manager/providers/auth_provider.dart';
import 'package:artist_finance_manager/providers/project_provider.dart';
import 'package:artist_finance_manager/models/app_user.dart';
import 'package:artist_finance_manager/models/project.dart';
import 'package:artist_finance_manager/services/project_service.dart';
import 'package:artist_finance_manager/widgets/empty_project_state.dart';

/// Integration tests for HomeScreen empty state behavior
///
/// Tests the complete flow when user has no projects.

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  final bool _isAuthenticated = true;
  final AppUser? _user = AppUser(
    uid: 'test-uid',
    email: 'test@example.com',
    name: 'Test User',
    createdAt: DateTime.now(),
    lastLoginAt: DateTime.now(),
    metadata: UserMetadata(loginCount: 1),
  );

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  AppUser? get currentUser => _user;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  String? get emailForSignIn => null;

  @override
  void setEmailForSignIn(String email) {}

  @override
  void clearError() {}

  @override
  Future<bool> sendSignInLink(String email, String continueUrl, {String? name}) async => true;

  @override
  Future<bool> sendRegistrationLink(String email, String name, String continueUrl) async => true;

  @override
  Future<bool> verifyRegistrationToken(String token) async => true;

  @override
  Future<bool> registerUser(String email, String name) async => true;

  @override
  Future<bool> signInWithEmailLink(String email, String emailLink) async => true;

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> deleteAccount() async => true;

  @override
  Future<bool> updateProfile({required String name}) async => true;
}

class MockProjectProvider extends ChangeNotifier implements ProjectProvider {
  List<Project> _projects = [];
  Project? _currentProject;
  final bool _isLoading = false;
  String? _error;

  @override
  List<Project> get projects => _projects;

  @override
  Project? get currentProject => _currentProject;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get error => _error;

  @override
  ProjectService get projectService => throw UnimplementedError();

  void setProjects(List<Project> projects) {
    _projects = projects;
    _currentProject = projects.isNotEmpty ? projects.first : null;
    notifyListeners();
  }

  void clearProjects() {
    _projects = [];
    _currentProject = null;
    notifyListeners();
  }

  @override
  Future<void> initialize() async {
    // Do nothing in mock
  }

  @override
  Future<void> refresh() async {}

  @override
  Future<Project?> createProject(String name) async {
    final project = Project(
      id: 'new-${_projects.length}',
      name: name,
      createdAt: DateTime.now(),
    );
    _projects.add(project);
    _currentProject = project;
    notifyListeners();
    return project;
  }

  @override
  Future<void> selectProject(String projectId) async {}

  @override
  Future<bool> updateProject(Project project) async => true;

  @override
  Future<bool> renameProject(String projectId, String newName) async => true;

  @override
  Future<bool> deleteProject(String projectId) async {
    _projects.removeWhere((p) => p.id == projectId);
    _currentProject = _projects.isNotEmpty ? _projects.first : null;
    notifyListeners();
    return true;
  }

  @override
  Future<Map<String, double>> getGlobalSummary(
    Future<Map<String, double>> Function(String projectId) getSummary,
  ) async => {'income': 0, 'expenses': 0, 'balance': 0};
}

void main() {
  late MockAuthProvider mockAuthProvider;
  late MockProjectProvider mockProjectProvider;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
    mockProjectProvider = MockProjectProvider();
  });

  Widget createTestApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
        ChangeNotifierProvider<ProjectProvider>.value(value: mockProjectProvider),
      ],
      child: const MaterialApp(home: HomeScreen()),
    );
  }

  group('HomeScreen Empty State Integration Tests', () {
    testWidgets('AppBar title shows Loading when no project', (WidgetTester tester) async {
      // Setup: No projects
      mockProjectProvider.clearProjects();

      await tester.pumpWidget(createTestApp());
      await tester.pump();

      // Verify app bar shows "Loading..."
      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('Drawer is still accessible in empty state', (WidgetTester tester) async {
      // Setup: No projects
      mockProjectProvider.clearProjects();

      await tester.pumpWidget(createTestApp());
      await tester.pump();

      // Verify drawer icon is present
      expect(find.byType(DrawerButton), findsOneWidget);
    });

    testWidgets('Project provider reactivity updates UI', (WidgetTester tester) async {
      // Start with a project
      mockProjectProvider.setProjects([
        Project(
          id: 'test-project',
          name: 'My Art Project',
          createdAt: DateTime.now(),
        ),
      ]);

      await tester.pumpWidget(createTestApp());
      await tester.pump();

      // Verify app bar shows project name
      expect(find.text('My Art Project'), findsOneWidget);

      // Simulate project deletion
      mockProjectProvider.clearProjects();
      await tester.pump();

      // Verify app bar now shows "Loading..."
      expect(find.text('Loading...'), findsOneWidget);
    });
  });
}
