import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import '../models/transaction.dart';
import 'project_service.dart';

/// Service for migrating data from single-project to multi-project structure.
///
/// This service handles the one-time migration of existing transaction data
/// to the new project-based structure.
class MigrationService {
  static const String _migrationCompletedKey =
      'migration_to_projects_completed';
  static const String _legacyTransactionsKey = 'project-finances';

  final ProjectService _projectService;

  MigrationService(this._projectService);

  /// Check if migration has already been completed.
  Future<bool> isMigrationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migrationCompletedKey) ?? false;
  }

  /// Mark migration as completed.
  Future<void> _markMigrationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationCompletedKey, true);
  }

  /// Perform the migration if needed.
  ///
  /// This will:
  /// 1. Check if there are legacy transactions (stored without project ID)
  /// 2. Create a "Default" project if it doesn't exist
  /// 3. Move legacy transactions to the Default project
  /// 4. Mark migration as completed
  ///
  /// Returns true if migration was performed, false if skipped.
  Future<bool> migrate() async {
    // Check if migration is already done
    if (await isMigrationCompleted()) {
      return false;
    }

    // Check if there are legacy transactions
    final legacyTransactions = await _loadLegacyTransactions();

    if (legacyTransactions.isEmpty) {
      // No legacy data, just mark as completed
      await _markMigrationCompleted();
      return false;
    }

    // Create or get the Default project
    final defaultProject = await _projectService.ensureDefaultProject();

    // Move legacy transactions to the new project-scoped storage
    final prefs = await SharedPreferences.getInstance();
    final newKey = 'project-finances-${defaultProject.id}';
    final jsonList = legacyTransactions.map((t) => t.toJson()).toList();
    final jsonString = json.encode(jsonList);
    await prefs.setString(newKey, jsonString);

    // Clear legacy storage (but keep a backup just in case)
    await prefs.setString('${_legacyTransactionsKey}_backup',
        prefs.getString(_legacyTransactionsKey) ?? '');
    await prefs.remove(_legacyTransactionsKey);

    // Mark migration as completed
    await _markMigrationCompleted();

    return true;
  }

  /// Load transactions from legacy storage (before multi-project support).
  Future<List<Transaction>> _loadLegacyTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_legacyTransactionsKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Transaction.fromJson(json)).toList();
    } catch (e) {
      // If there's any error reading legacy data, return empty list
      return [];
    }
  }

  /// Restore from backup if migration failed.
  ///
  /// This is a safety mechanism in case something goes wrong.
  Future<void> restoreFromBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final backup = prefs.getString('${_legacyTransactionsKey}_backup');

    if (backup != null && backup.isNotEmpty) {
      await prefs.setString(_legacyTransactionsKey, backup);
      await prefs.remove(_migrationCompletedKey);
    }
  }

  /// Get migration status information.
  Future<Map<String, dynamic>> getMigrationStatus() async {
    final completed = await isMigrationCompleted();
    final legacyCount = (await _loadLegacyTransactions()).length;

    return {
      'completed': completed,
      'legacyTransactionCount': legacyCount,
      'needsMigration': !completed && legacyCount > 0,
    };
  }
}
