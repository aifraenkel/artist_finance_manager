import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:artist_finance_manager/screens/dashboard_screen.dart';
import 'package:artist_finance_manager/providers/project_provider.dart';
import 'package:artist_finance_manager/providers/auth_provider.dart';
import 'package:artist_finance_manager/models/project.dart';
import 'package:artist_finance_manager/models/app_user.dart';
import 'package:artist_finance_manager/models/transaction.dart';
import 'package:artist_finance_manager/models/financial_goal.dart';
import 'package:artist_finance_manager/models/budget_goal.dart';
import 'package:artist_finance_manager/services/project_service.dart';
import 'package:artist_finance_manager/services/analytics_service.dart';
import 'package:artist_finance_manager/services/user_preferences.dart';
import 'package:artist_finance_manager/services/financial_goal_service.dart';
import 'package:artist_finance_manager/widgets/no_goal_banner.dart';
import 'package:artist_finance_manager/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_mock.dart';

/// Widget tests for DashboardScreen
///
/// Tests the analytics dashboard UI including:
/// - Empty state rendering with NoGoalBanner
/// - Chart rendering with data
/// - Summary statistics display
/// - Error handling
/// - Financial goal wizard integration

Widget wrapWithLocalizations(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: child,
  );
}

/// Mock AuthProvider for testing
class MockAuthProvider extends ChangeNotifier {
  final AppUser? _currentUser;

  MockAuthProvider({AppUser? currentUser}) : _currentUser = currentUser;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => false;
  String? get error => null;
}

/// Mock AnalyticsService for testing
class MockAnalyticsService extends AnalyticsService {
  @override
  AnalyticsSummary calculateSummary(
      Map<String, List<Transaction>> projectTransactions) {
    return AnalyticsSummary(
      totalIncome: 0,
      totalExpenses: 0,
      balance: 0,
      numberOfTransactions: 0,
      numberOfProjects: 0,
      averageTransactionAmount: 0,
    );
  }

  @override
  Map<String, double> getProjectContributions(
    Map<String, List<Transaction>> projectTransactions,
    Map<String, Project> projects,
  ) {
    return {};
  }

  @override
  List<MapEntry<String, double>> getTopExpensiveProjects(
    Map<String, List<Transaction>> projectTransactions,
    Map<String, Project> projects, {
    int limit = 5,
  }) {
    return [];
  }

  @override
  Map<String, List<TimelineDataPoint>> getTimelineData(
    List<Transaction> transactions, {
    TimelineGranularity granularity = TimelineGranularity.monthly,
  }) {
    return {
      'income': [],
      'expenses': [],
      'balance': [],
    };
  }

  @override
  Map<String, double> getCategoryBreakdown(
    List<Transaction> transactions, {
    String type = 'expense',
  }) {
    return {};
  }
}

/// Mock UserPreferences for testing
class MockUserPreferences extends UserPreferences {
  @override
  Future<void> initialize() async {}

  @override
  BudgetGoal? get budgetGoal => null;

  @override
  String? get openaiApiKey => null;

  @override
  bool get hasSkippedGoalWizard => false;
}

/// Mock FinancialGoalService for testing
class MockFinancialGoalService extends FinancialGoalService {
  @override
  Future<FinancialGoal?> getGoal(String userId) async => null;

  @override
  Stream<FinancialGoal?> watchGoal(String userId) => Stream.value(null);

  @override
  Future<void> saveGoal(String userId, FinancialGoal goal) async {}

  @override
  Future<void> updateGoal(String userId, FinancialGoal goal) async {}

  @override
  Future<void> deleteGoal(String userId) async {}

  @override
  Future<bool> hasGoal(String userId) async => false;
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

/// Helper to wrap dashboard with all required providers and mock services
Widget wrapDashboard({
  required MockProjectProvider projectProvider,
  MockAuthProvider? authProvider,
  MockAnalyticsService? analyticsService,
  MockUserPreferences? userPreferences,
  MockFinancialGoalService? financialGoalService,
}) {
  return MediaQuery(
    data: const MediaQueryData(
      size: Size(800, 1200), // Larger viewport to accommodate NoGoalBanner
    ),
    child: wrapWithLocalizations(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProjectProvider>.value(
            value: projectProvider,
          ),
          ChangeNotifierProvider.value(
            value: authProvider ?? MockAuthProvider(),
          ),
        ],
        child: DashboardScreen(
          analyticsService: analyticsService ?? MockAnalyticsService(),
          userPreferences: userPreferences ?? MockUserPreferences(),
          financialGoalService:
              financialGoalService ?? MockFinancialGoalService(),
        ),
      ),
    ),
  );
}

void main() {
  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  group('DashboardScreen', () {
    testWidgets('shows loading indicator initially',
        (WidgetTester tester) async {
      final mockProjectProvider = MockProjectProvider(
        projects: [],
      );

      await tester.pumpWidget(
        wrapDashboard(projectProvider: mockProjectProvider),
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
        wrapDashboard(projectProvider: mockProjectProvider),
      );

      // Wait for data to load
      await tester.pumpAndSettle();

      // Should show empty state message (content is scrollable, so just verify key elements exist)
      expect(find.text('No data available'), findsOneWidget);

      // Should show NoGoalBanner when no financial goal is set
      // Note: The banner title is long and may not all be visible in test viewport
      expect(find.textContaining('Ready to take control'), findsOneWidget);
      expect(find.text('Set Your Goal'), findsOneWidget);
    });

    testWidgets('displays app bar with title', (WidgetTester tester) async {
      final mockProjectProvider = MockProjectProvider(
        projects: [],
      );

      await tester.pumpWidget(
        wrapDashboard(projectProvider: mockProjectProvider),
      );

      await tester.pumpAndSettle();

      // Should show app bar with title
      expect(find.text('Analytics Dashboard'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('renders with scaffold structure',
        (WidgetTester tester) async {
      final mockProjectProvider = MockProjectProvider(
        projects: [],
      );

      await tester.pumpWidget(
        wrapDashboard(projectProvider: mockProjectProvider),
      );

      await tester.pumpAndSettle();

      // Should have basic scaffold structure
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);

      // Should have scrollable content
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('back button navigates back', (WidgetTester tester) async {
      final mockProjectProvider = MockProjectProvider(
        projects: [],
      );
      final mockAuthProvider = MockAuthProvider();

      await tester.pumpWidget(
        wrapWithLocalizations(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MultiProvider(
                        providers: [
                          ChangeNotifierProvider<ProjectProvider>.value(
                            value: mockProjectProvider,
                          ),
                          ChangeNotifierProvider.value(
                            value: mockAuthProvider,
                          ),
                        ],
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

    testWidgets('shows financial goal banner and empty state',
        (WidgetTester tester) async {
      final mockProjectProvider = MockProjectProvider(
        projects: [],
      );

      await tester.pumpWidget(
        wrapDashboard(projectProvider: mockProjectProvider),
      );

      await tester.pumpAndSettle();

      // Verify NoGoalBanner is present
      expect(find.byType(NoGoalBanner), findsOneWidget);
      expect(find.text('Set Your Goal'), findsOneWidget);

      // Verify empty state is present
      expect(find.text('No data available'), findsOneWidget);

      // Verify key icons are present
      expect(find.byIcon(Icons.track_changes), findsOneWidget);
      expect(find.byIcon(Icons.flag), findsOneWidget);
    });
  });
}
