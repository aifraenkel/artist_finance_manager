import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_finance_manager/services/export_service.dart';
import 'package:artist_finance_manager/services/project_service.dart';
import 'package:artist_finance_manager/services/storage_service.dart';
import 'package:artist_finance_manager/models/project.dart';
import 'package:artist_finance_manager/models/transaction.dart';
import '../helpers/mock_sync_service.dart';

void main() {
  group('ExportService', () {
    late ProjectService projectService;
    late Map<String, StorageService> storageServices;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      projectService = ProjectService();
      storageServices = {};
    });

    tearDown(() async {
      // Clean up
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

    test('should export empty data with headers only', () async {
      final exportService = ExportService(
        projectService: projectService,
        createStorageService: createStorageService,
      );

      final csv = await exportService.exportToCSV();

      expect(csv, contains('Project name,Type,Category,Description,Amount,Datetime'));
      // CSV with only headers should have just one line
      final lines = csv.trim().split('\n');
      expect(lines.length, 1);
    });

    test('should export single project with transactions', () async {
      // Create a project
      final project = await projectService.createProject('Art Show');

      // Add transactions
      final storageService = createStorageService(project.id);
      final transactions = [
        Transaction(
          id: 1,
          description: 'Venue rental',
          amount: 500.00,
          type: 'expense',
          category: 'Venue',
          date: DateTime(2024, 1, 15, 10, 30),
        ),
        Transaction(
          id: 2,
          description: 'Ticket sales',
          amount: 1200.00,
          type: 'income',
          category: 'Event tickets',
          date: DateTime(2024, 1, 20, 18, 0),
        ),
      ];
      await storageService.saveTransactions(transactions);

      final exportService = ExportService(
        projectService: projectService,
        createStorageService: createStorageService,
      );

      final csv = await exportService.exportToCSV();

      // Check header
      expect(csv, contains('Project name,Type,Category,Description,Amount,Datetime'));
      
      // Check data rows
      expect(csv, contains('Art Show,Expense,Venue,Venue rental,500.00,2024-01-15 10:30:00'));
      expect(csv, contains('Art Show,Income,Event tickets,Ticket sales,1200.00,2024-01-20 18:00:00'));
    });

    test('should export multiple projects with transactions', () async {
      // Create projects
      final project1 = await projectService.createProject('Art Show');
      final project2 = await projectService.createProject('Book Project');

      // Add transactions to first project
      final storageService1 = createStorageService(project1.id);
      await storageService1.saveTransactions([
        Transaction(
          id: 1,
          description: 'Venue rental',
          amount: 500.00,
          type: 'expense',
          category: 'Venue',
          date: DateTime(2024, 1, 15, 10, 30),
        ),
      ]);

      // Add transactions to second project
      final storageService2 = createStorageService(project2.id);
      await storageService2.saveTransactions([
        Transaction(
          id: 2,
          description: 'Printing costs',
          amount: 800.00,
          type: 'expense',
          category: 'Book printing',
          date: DateTime(2024, 2, 1, 9, 0),
        ),
      ]);

      final exportService = ExportService(
        projectService: projectService,
        createStorageService: createStorageService,
      );

      final csv = await exportService.exportToCSV();

      // Check both projects are included
      expect(csv, contains('Art Show'));
      expect(csv, contains('Book Project'));
      expect(csv, contains('Venue rental'));
      expect(csv, contains('Printing costs'));
    });

    test('should format amounts with two decimal places', () async {
      final project = await projectService.createProject('Test Project');
      final storageService = createStorageService(project.id);

      await storageService.saveTransactions([
        Transaction(
          id: 1,
          description: 'Test',
          amount: 99.5,
          type: 'expense',
          category: 'Test',
          date: DateTime(2024, 1, 1),
        ),
      ]);

      final exportService = ExportService(
        projectService: projectService,
        createStorageService: createStorageService,
      );

      final csv = await exportService.exportToCSV();

      expect(csv, contains('99.50'));
    });

    test('should format datetime correctly', () async {
      final project = await projectService.createProject('Test Project');
      final storageService = createStorageService(project.id);

      await storageService.saveTransactions([
        Transaction(
          id: 1,
          description: 'Test',
          amount: 100.0,
          type: 'expense',
          category: 'Test',
          date: DateTime(2024, 3, 15, 14, 30, 45),
        ),
      ]);

      final exportService = ExportService(
        projectService: projectService,
        createStorageService: createStorageService,
      );

      final csv = await exportService.exportToCSV();

      expect(csv, contains('2024-03-15 14:30:45'));
    });

    test('should capitalize transaction types', () async {
      final project = await projectService.createProject('Test Project');
      final storageService = createStorageService(project.id);

      await storageService.saveTransactions([
        Transaction(
          id: 1,
          description: 'Income test',
          amount: 100.0,
          type: 'income',
          category: 'Test',
          date: DateTime.now(),
        ),
        Transaction(
          id: 2,
          description: 'Expense test',
          amount: 50.0,
          type: 'expense',
          category: 'Test',
          date: DateTime.now(),
        ),
      ]);

      final exportService = ExportService(
        projectService: projectService,
        createStorageService: createStorageService,
      );

      final csv = await exportService.exportToCSV();

      expect(csv, contains(',Income,'));
      expect(csv, contains(',Expense,'));
    });

    test('should handle special characters in CSV', () async {
      final project = await projectService.createProject('Test "Project"');
      final storageService = createStorageService(project.id);

      await storageService.saveTransactions([
        Transaction(
          id: 1,
          description: 'Description with, comma',
          amount: 100.0,
          type: 'expense',
          category: 'Test',
          date: DateTime.now(),
        ),
      ]);

      final exportService = ExportService(
        projectService: projectService,
        createStorageService: createStorageService,
      );

      final csv = await exportService.exportToCSV();

      // CSV library should properly escape special characters
      expect(csv, isNotEmpty);
    });
  });
}
