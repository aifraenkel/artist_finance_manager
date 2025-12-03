import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_finance_manager/services/migration_service.dart';
import 'package:artist_finance_manager/services/project_service.dart';
import 'package:artist_finance_manager/models/transaction.dart';
import 'dart:convert';

void main() {
  group('MigrationService Tests', () {
    late MigrationService migrationService;
    late ProjectService projectService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      projectService = ProjectService();
      migrationService = MigrationService(projectService);
    });

    test('Migration not completed initially', () async {
      final completed = await migrationService.isMigrationCompleted();
      expect(completed, isFalse);
    });

    test('Migration with no legacy data', () async {
      final migrated = await migrationService.migrate();

      expect(migrated, isFalse);
      expect(await migrationService.isMigrationCompleted(), isTrue);
    });

    test('Migration with legacy transactions', () async {
      // Create legacy transactions
      final legacyTransactions = [
        Transaction(
          id: 1,
          description: 'Legacy Transaction 1',
          amount: 100.0,
          type: 'income',
          category: 'Book Sales',
          date: DateTime(2024, 1, 1),
        ),
        Transaction(
          id: 2,
          description: 'Legacy Transaction 2',
          amount: 50.0,
          type: 'expense',
          category: 'Materials',
          date: DateTime(2024, 1, 2),
        ),
      ];

      // Store them in legacy location
      final prefs = await SharedPreferences.getInstance();
      final jsonList = legacyTransactions.map((t) => t.toJson()).toList();
      await prefs.setString('project-finances', json.encode(jsonList));

      // Run migration
      final migrated = await migrationService.migrate();

      expect(migrated, isTrue);
      expect(await migrationService.isMigrationCompleted(), isTrue);

      // Verify legacy data is backed up and removed
      expect(prefs.getString('project-finances'), isNull);
      expect(prefs.getString('project-finances_backup'), isNotNull);

      // Verify default project was created
      final projects = await projectService.loadProjects();
      expect(projects.length, 1);
      expect(projects.first.name, 'Default');

      // Verify transactions were migrated to project-scoped storage
      final migratedKey = 'project-finances-${projects.first.id}';
      final migratedData = prefs.getString(migratedKey);
      expect(migratedData, isNotNull);

      final migratedTransactions = (json.decode(migratedData!) as List)
          .map((j) => Transaction.fromJson(j))
          .toList();
      expect(migratedTransactions.length, 2);
      expect(migratedTransactions[0].description, 'Legacy Transaction 1');
      expect(migratedTransactions[1].description, 'Legacy Transaction 2');
    });

    test('Migration runs only once', () async {
      // Create legacy transactions
      final legacyTransactions = [
        Transaction(
          id: 1,
          description: 'Test',
          amount: 100.0,
          type: 'income',
          category: 'Book Sales',
          date: DateTime(2024, 1, 1),
        ),
      ];

      final prefs = await SharedPreferences.getInstance();
      final jsonList = legacyTransactions.map((t) => t.toJson()).toList();
      await prefs.setString('project-finances', json.encode(jsonList));

      // First migration
      final migrated1 = await migrationService.migrate();
      expect(migrated1, isTrue);

      // Second migration should skip
      final migrated2 = await migrationService.migrate();
      expect(migrated2, isFalse);
    });

    test('Get migration status', () async {
      // Initially no migration
      var status = await migrationService.getMigrationStatus();
      expect(status['completed'], isFalse);
      expect(status['legacyTransactionCount'], 0);
      expect(status['needsMigration'], isFalse);

      // Add legacy data
      final legacyTransactions = [
        Transaction(
          id: 1,
          description: 'Test',
          amount: 100.0,
          type: 'income',
          category: 'Book Sales',
          date: DateTime(2024, 1, 1),
        ),
      ];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('project-finances',
          json.encode(legacyTransactions.map((t) => t.toJson()).toList()));

      // Should need migration
      status = await migrationService.getMigrationStatus();
      expect(status['completed'], isFalse);
      expect(status['legacyTransactionCount'], 1);
      expect(status['needsMigration'], isTrue);

      // After migration
      await migrationService.migrate();
      status = await migrationService.getMigrationStatus();
      expect(status['completed'], isTrue);
      expect(status['needsMigration'], isFalse);
    });

    test('Restore from backup', () async {
      // Create and migrate legacy data
      final legacyTransactions = [
        Transaction(
          id: 1,
          description: 'Test',
          amount: 100.0,
          type: 'income',
          category: 'Book Sales',
          date: DateTime(2024, 1, 1),
        ),
      ];

      final prefs = await SharedPreferences.getInstance();
      final jsonString =
          json.encode(legacyTransactions.map((t) => t.toJson()).toList());
      await prefs.setString('project-finances', jsonString);

      await migrationService.migrate();

      // Restore from backup
      await migrationService.restoreFromBackup();

      // Verify data is restored
      expect(prefs.getString('project-finances'), jsonString);
      expect(await migrationService.isMigrationCompleted(), isFalse);
    });
  });
}
