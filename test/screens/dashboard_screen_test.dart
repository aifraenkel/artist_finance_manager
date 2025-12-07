import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:artist_finance_manager/screens/dashboard_screen.dart';
import 'package:artist_finance_manager/providers/project_provider.dart';
import 'package:artist_finance_manager/models/project.dart';
import 'package:artist_finance_manager/services/project_service.dart';
import 'package:artist_finance_manager/l10n/app_localizations.dart';

/// Widget tests for DashboardScreen
///
/// Tests the analytics dashboard UI including:
/// - Empty state rendering
/// - Chart rendering with data
/// - Summary statistics display
/// - Error handling

Widget wrapWithLocalizations(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: child,
  );
}

class MockProjectProvider extends ChangeNotifier implements ProjectProvider {
  List<Project> _projects = [];
  Project? _currentProject;
  final bool _isLoading = false;
  String? _error;

  MockProjectProvider({List<Project>? projects, Project? currentProject}) {
    _projects = projects ?? [];
    _currentProject = currentProject;
  }

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

  @override
  Future<void> initialize() async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<Project?> createProject(String name) async => null;

  @override
  Future<bool> updateProject(Project project) async => false;

  @override
  Future<bool> renameProject(String projectId, String newName) async => false;

  @override
  Future<bool> deleteProject(String projectId) async => false;

  @override
  Future<void> selectProject(String projectId) async {}

  @override
  Future<Map<String, double>> getGlobalSummary(
    Future<Map<String, double>> Function(String projectId) getSummary,
  ) async {
    return {
      'income': 0,
      'expenses': 0,
      'balance': 0,
    };
  }
}

void main() {
  group('DashboardScreen', () {
    testWidgets('shows loading indicator initially',
        (WidgetTester tester) async {
      final mockProjectProvider = MockProjectProvider(
        projects: [],
      );

      await tester.pumpWidget(
        wrapWithLocalizations(
          ChangeNotifierProvider<ProjectProvider>.value(
            value: mockProjectProvider,
            child: const DashboardScreen(),
          ),
        ),
      );

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no data available',
        (WidgetTester tester) async {
      final mockProjectProvider = MockProjectProvider(
        projects: [],
      );

      await tester.pumpWidget(
        wrapWithLocalizations(
          ChangeNotifierProvider<ProjectProvider>.value(
            value: mockProjectProvider,
            child: const DashboardScreen(),
          ),
        ),
      );

      // Wait for data to load
      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.text('No data available'), findsOneWidget);
      expect(
          find.text('Add some transactions to see analytics'), findsOneWidget);
      expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
    });

    testWidgets('displays app bar with title', (WidgetTester tester) async {
      final mockProjectProvider = MockProjectProvider(
        projects: [],
      );

      await tester.pumpWidget(
        wrapWithLocalizations(
          ChangeNotifierProvider<ProjectProvider>.value(
            value: mockProjectProvider,
            child: const DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show app bar with title
      expect(find.text('Analytics Dashboard'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('renders with gradient background',
        (WidgetTester tester) async {
      final mockProjectProvider = MockProjectProvider(
        projects: [],
      );

      await tester.pumpWidget(
        wrapWithLocalizations(
          ChangeNotifierProvider<ProjectProvider>.value(
            value: mockProjectProvider,
            child: const DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have Container with gradient decoration
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(Scaffold),
              matching: find.byType(Container),
            )
            .first,
      );

      expect(container.decoration, isA<BoxDecoration>());
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());
    });

    testWidgets('back button navigates back', (WidgetTester tester) async {
      final mockProjectProvider = MockProjectProvider(
        projects: [],
      );

      await tester.pumpWidget(
        wrapWithLocalizations(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ChangeNotifierProvider<ProjectProvider>.value(
                        value: mockProjectProvider,
                        child: const DashboardScreen(),
                      ),
                    ),
                  );
                },
                child: const Text('Go to Dashboard'),
              ),
            ),
          ),
        ),
      );

      // Navigate to dashboard
      await tester.tap(find.text('Go to Dashboard'));
      await tester.pumpAndSettle();

      // Should be on dashboard
      expect(find.text('Analytics Dashboard'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Should be back to initial screen
      expect(find.text('Go to Dashboard'), findsOneWidget);
      expect(find.text('Analytics Dashboard'), findsNothing);
    });

    testWidgets('empty state has proper styling', (WidgetTester tester) async {
      final mockProjectProvider = MockProjectProvider(
        projects: [],
      );

      await tester.pumpWidget(
        wrapWithLocalizations(
          ChangeNotifierProvider<ProjectProvider>.value(
            value: mockProjectProvider,
            child: const DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the icon widget
      final iconWidget = tester.widget<Icon>(
        find.byIcon(Icons.analytics_outlined),
      );

      // Verify icon size and color
      expect(iconWidget.size, 80);
      expect(iconWidget.color, isNotNull);
    });
  });
}
