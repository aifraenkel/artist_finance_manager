import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_finance_manager/services/budget_analysis_service.dart';
import 'package:artist_finance_manager/services/project_service.dart';
import 'package:artist_finance_manager/services/storage_service.dart';
import 'package:artist_finance_manager/services/openai_service.dart';
import 'package:artist_finance_manager/models/budget_goal.dart';
import 'package:artist_finance_manager/models/transaction.dart';
import '../helpers/mock_sync_service.dart';

// Mock OpenAI service for testing
class MockOpenAIService extends OpenAIService {
  MockOpenAIService() : super(apiKey: 'test-key');

  @override
  Future<String> analyzeGoal(String prompt) async {
    // Simulate a successful analysis
    return 'Based on your current financial data, you are making good progress toward your goal. Your average monthly balance is positive, which is a great sign. Keep tracking your expenses to maintain this trend.';
  }
}

// Mock OpenAI service that throws an error
class MockOpenAIServiceError extends OpenAIService {
  MockOpenAIServiceError() : super(apiKey: 'test-key');

  @override
  Future<String> analyzeGoal(String prompt) async {
    throw OpenAIException('API rate limit exceeded');
  }
}

void main() {
  group('BudgetAnalysisService', () {
    late ProjectService projectService;
    late Map<String, StorageService> storageServices;
    late MockOpenAIService mockOpenAIService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      projectService = ProjectService();
      storageServices = {};
      mockOpenAIService = MockOpenAIService();
    });

    tearDown(() async {
      await projectService.clearAll();
      for (final service in storageServices.values) {
        await service.clearAll();
      }
    });

    StorageService createStorageService(String projectId) {
      if (!storageServices.containsKey(projectId)) {
        storageServices[projectId] = StorageService(
          syncService: MockSyncService(),
          projectId: projectId,
        );
      }
      return storageServices[projectId]!;
    }

    test('should throw exception for empty goal', () async {
      final analysisService = BudgetAnalysisService(
        projectService: projectService,
        createStorageService: createStorageService,
        openAIService: mockOpenAIService,
      );

      final emptyGoal = BudgetGoal(
        goalText: '',
        isActive: true,
        createdAt: DateTime.now(),
      );

      expect(
        () => analysisService.analyzeGoal(emptyGoal),
        throwsA(isA<BudgetAnalysisException>()),
      );
    });

    test('should return message when no projects exist', () async {
      final analysisService = BudgetAnalysisService(
        projectService: projectService,
        createStorageService: createStorageService,
        openAIService: mockOpenAIService,
      );

      final goal = BudgetGoal(
        goalText: 'Save 200€ per month',
        isActive: true,
        createdAt: DateTime.now(),
      );

      final result = await analysisService.analyzeGoal(goal);

      expect(result, contains('No projects found'));
    });

    test('should analyze goal with project data', () async {
      // Create a project with transactions
      final project = await projectService.createProject('Art Show');
      final storageService = createStorageService(project.id);

      await storageService.saveTransactions([
        Transaction(
          id: 1,
          description: 'Venue rental',
          amount: 500.00,
          type: 'expense',
          category: 'Venue',
          date: DateTime(2024, 1, 15),
        ),
        Transaction(
          id: 2,
          description: 'Ticket sales',
          amount: 1200.00,
          type: 'income',
          category: 'Event tickets',
          date: DateTime(2024, 1, 20),
        ),
      ]);

      final analysisService = BudgetAnalysisService(
        projectService: projectService,
        createStorageService: createStorageService,
        openAIService: mockOpenAIService,
      );

      final goal = BudgetGoal(
        goalText: 'I want to have a positive balance of 200€ per month',
        isActive: true,
        createdAt: DateTime.now(),
      );

      final result = await analysisService.analyzeGoal(goal);

      expect(result, isNotEmpty);
      expect(result, contains('progress'));
    });

    test('should handle OpenAI service errors', () async {
      final project = await projectService.createProject('Test Project');
      final storageService = createStorageService(project.id);

      await storageService.saveTransactions([
        Transaction(
          id: 1,
          description: 'Test',
          amount: 100.00,
          type: 'income',
          category: 'Test',
          date: DateTime.now(),
        ),
      ]);

      final errorService = MockOpenAIServiceError();
      final analysisService = BudgetAnalysisService(
        projectService: projectService,
        createStorageService: createStorageService,
        openAIService: errorService,
      );

      final goal = BudgetGoal(
        goalText: 'Save 200€ per month',
        isActive: true,
        createdAt: DateTime.now(),
      );

      expect(
        () => analysisService.analyzeGoal(goal),
        throwsA(isA<BudgetAnalysisException>()),
      );
    });

    test('BudgetAnalysisException should have meaningful message', () {
      final exception = BudgetAnalysisException('Test error');

      expect(exception.message, 'Test error');
      expect(exception.toString(), 'BudgetAnalysisException: Test error');
    });

    test('should analyze multiple projects', () async {
      // Create multiple projects with transactions
      final project1 = await projectService.createProject('Art Show');
      final project2 = await projectService.createProject('Book Project');

      final storage1 = createStorageService(project1.id);
      final storage2 = createStorageService(project2.id);

      await storage1.saveTransactions([
        Transaction(
          id: 1,
          description: 'Venue',
          amount: 500.00,
          type: 'expense',
          category: 'Venue',
          date: DateTime(2024, 1, 15),
        ),
      ]);

      await storage2.saveTransactions([
        Transaction(
          id: 2,
          description: 'Book sales',
          amount: 800.00,
          type: 'income',
          category: 'Book sales',
          date: DateTime(2024, 1, 20),
        ),
      ]);

      final analysisService = BudgetAnalysisService(
        projectService: projectService,
        createStorageService: createStorageService,
        openAIService: mockOpenAIService,
      );

      final goal = BudgetGoal(
        goalText: 'Maintain positive cash flow',
        isActive: true,
        createdAt: DateTime.now(),
      );

      final result = await analysisService.analyzeGoal(goal);

      expect(result, isNotEmpty);
    });
  });
}
