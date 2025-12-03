import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../models/project.dart';
import '../models/transaction.dart';
import '../services/project_service.dart';
import '../services/storage_service.dart';

/// Service for exporting project data to various formats.
///
/// Currently supports:
/// - CSV export of all projects and their transactions
class ExportService {
  final ProjectService projectService;
  final StorageService Function(String projectId) createStorageService;

  ExportService({
    required this.projectService,
    required this.createStorageService,
  });

  /// Export all projects and their transactions to CSV format.
  ///
  /// Returns a CSV string with the following columns:
  /// - Project name
  /// - Type (income/expense)
  /// - Category
  /// - Description
  /// - Amount
  /// - Datetime
  ///
  /// Throws an exception if there's an error loading data.
  Future<String> exportToCSV() async {
    // Load all active projects
    final projects = await projectService.loadProjects();

    // Prepare CSV data with headers
    final List<List<dynamic>> csvData = [
      ['Project name', 'Type', 'Category', 'Description', 'Amount', 'Datetime']
    ];

    // Load transactions for each project
    for (final project in projects) {
      final storageService = createStorageService(project.id);
      final transactions = await storageService.loadTransactions();

      // Add each transaction as a row
      for (final transaction in transactions) {
        csvData.add([
          project.name,
          _formatType(transaction.type),
          transaction.category,
          transaction.description,
          transaction.amount.toStringAsFixed(2),
          _formatDateTime(transaction.date),
        ]);
      }
    }

    // Convert to CSV string
    return const ListToCsvConverter().convert(csvData);
  }

  /// Format transaction type for display
  String _formatType(String type) {
    switch (type.toLowerCase()) {
      case 'income':
        return 'Income';
      case 'expense':
        return 'Expense';
      default:
        // Return the original type capitalized for unknown types
        return type.substring(0, 1).toUpperCase() + type.substring(1).toLowerCase();
    }
  }

  /// Format DateTime for CSV export
  String _formatDateTime(DateTime date) {
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(date);
  }
}
