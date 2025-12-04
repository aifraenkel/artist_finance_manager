import '../services/project_service.dart';
import '../services/storage_service.dart';
import '../services/openai_service.dart';
import '../models/budget_goal.dart';
import '../models/transaction.dart';
import '../models/project.dart';

/// Service for analyzing budget goals against financial data
///
/// This service:
/// - Exports all project data (similar to CSV export)
/// - Builds a prompt with the financial data and user's goal
/// - Calls OpenAI API to analyze if the goal is being achieved
class BudgetAnalysisService {
  final ProjectService projectService;
  final StorageService Function(String projectId) createStorageService;
  final OpenAIService openAIService;

  BudgetAnalysisService({
    required this.projectService,
    required this.createStorageService,
    required this.openAIService,
  });

  /// Analyze if the user's budget goal is being achieved
  ///
  /// [goal] - The user's budget goal
  ///
  /// Returns an analysis result from OpenAI
  Future<String> analyzeGoal(BudgetGoal goal) async {
    if (goal.isEmpty || !goal.isValid) {
      throw BudgetAnalysisException('Budget goal is empty or invalid');
    }

    // Load all active projects
    final projects = await projectService.loadProjects();

    if (projects.isEmpty) {
      return 'No projects found. Please add some transactions to analyze your financial goal.';
    }

    // Collect all transactions from all projects
    final Map<String, List<Transaction>> projectTransactions = {};
    final Map<String, Project> projectMap = {};

    for (final project in projects) {
      projectMap[project.id] = project;
      final storageService = createStorageService(project.id);
      await storageService.initialize();
      final transactions = await storageService.loadTransactions();
      projectTransactions[project.id] = transactions;
    }

    // Build the financial summary
    final financialSummary = _buildFinancialSummary(
      projectTransactions,
      projectMap,
    );

    // Build the prompt for OpenAI
    final prompt = _buildPrompt(goal, financialSummary);

    // Call OpenAI API
    try {
      final analysis = await openAIService.analyzeGoal(prompt);
      return analysis;
    } on OpenAIException catch (e) {
      throw BudgetAnalysisException('Failed to analyze goal: ${e.message}');
    }
  }

  /// Build a financial summary from all projects and transactions
  String _buildFinancialSummary(
    Map<String, List<Transaction>> projectTransactions,
    Map<String, Project> projectMap,
  ) {
    final buffer = StringBuffer();

    // Overall summary
    double totalIncome = 0;
    double totalExpenses = 0;
    int totalTransactions = 0;

    for (final transactions in projectTransactions.values) {
      for (final transaction in transactions) {
        totalTransactions++;
        if (transaction.type.toLowerCase() == 'income') {
          totalIncome += transaction.amount;
        } else if (transaction.type.toLowerCase() == 'expense') {
          totalExpenses += transaction.amount;
        }
      }
    }

    final balance = totalIncome - totalExpenses;

    buffer.writeln('OVERALL FINANCIAL SUMMARY:');
    buffer.writeln('Total Income: €${totalIncome.toStringAsFixed(2)}');
    buffer.writeln('Total Expenses: €${totalExpenses.toStringAsFixed(2)}');
    buffer.writeln('Current Balance: €${balance.toStringAsFixed(2)}');
    buffer.writeln('Total Transactions: $totalTransactions');
    buffer.writeln();

    // Per-project breakdown
    buffer.writeln('PROJECT BREAKDOWN:');
    for (final entry in projectTransactions.entries) {
      final projectId = entry.key;
      final transactions = entry.value;
      final project = projectMap[projectId];

      if (project == null || transactions.isEmpty) continue;

      double projectIncome = 0;
      double projectExpenses = 0;

      for (final transaction in transactions) {
        if (transaction.type.toLowerCase() == 'income') {
          projectIncome += transaction.amount;
        } else if (transaction.type.toLowerCase() == 'expense') {
          projectExpenses += transaction.amount;
        }
      }

      final projectBalance = projectIncome - projectExpenses;

      buffer.writeln('${project.name}:');
      buffer.writeln('  Income: €${projectIncome.toStringAsFixed(2)}');
      buffer.writeln('  Expenses: €${projectExpenses.toStringAsFixed(2)}');
      buffer.writeln('  Balance: €${projectBalance.toStringAsFixed(2)}');
      buffer.writeln('  Transactions: ${transactions.length}');
      buffer.writeln();
    }

    // Monthly average (if we have data)
    if (totalTransactions > 0) {
      final dates = <DateTime>[];
      for (final transactions in projectTransactions.values) {
        for (final transaction in transactions) {
          dates.add(transaction.date);
        }
      }

      if (dates.isNotEmpty) {
        dates.sort();
        final firstDate = dates.first;
        final lastDate = dates.last;
        final daysDiff = lastDate.difference(firstDate).inDays;
        final months = daysDiff > 0 ? daysDiff / 30.0 : 1.0;

        final monthlyIncome = totalIncome / months;
        final monthlyExpenses = totalExpenses / months;
        final monthlyBalance = balance / months;

        buffer.writeln(
            'MONTHLY AVERAGES (based on ${months.toStringAsFixed(1)} months):');
        buffer.writeln(
            'Average Monthly Income: €${monthlyIncome.toStringAsFixed(2)}');
        buffer.writeln(
            'Average Monthly Expenses: €${monthlyExpenses.toStringAsFixed(2)}');
        buffer.writeln(
            'Average Monthly Balance: €${monthlyBalance.toStringAsFixed(2)}');
      }
    }

    return buffer.toString();
  }

  /// Build the prompt for OpenAI analysis
  String _buildPrompt(BudgetGoal goal, String financialSummary) {
    return '''
User's Financial Goal:
"${goal.goalText}"

Current Financial Data:
$financialSummary

Please analyze whether the user is achieving their financial goal based on the data provided. 
Provide a clear, concise assessment in 3-5 sentences that:
1. States whether the goal is being met or not
2. Highlights key relevant metrics
3. Offers one brief, actionable suggestion if the goal is not being met

Keep the tone encouraging and professional.
''';
  }
}

/// Exception class for budget analysis errors
class BudgetAnalysisException implements Exception {
  final String message;

  BudgetAnalysisException(this.message);

  @override
  String toString() => 'BudgetAnalysisException: $message';
}
