import '../models/transaction.dart';
import '../models/project.dart';
import 'package:intl/intl.dart';

/// Service for calculating financial analytics and insights.
///
/// Provides methods to aggregate transaction data and generate insights
/// for the analytics dashboard.
class AnalyticsService {
  /// Calculate project-level financial summary
  Map<String, double> calculateProjectSummary(List<Transaction> transactions) {
    final income = transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final expenses = transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    return {
      'income': income,
      'expenses': expenses,
      'balance': income - expenses,
    };
  }

  /// Get project contributions (income per project)
  Map<String, double> getProjectContributions(
    Map<String, List<Transaction>> projectTransactions,
    Map<String, Project> projects,
  ) {
    final contributions = <String, double>{};

    for (final entry in projectTransactions.entries) {
      final projectId = entry.key;
      final transactions = entry.value;
      final project = projects[projectId];

      if (project != null && project.isActive) {
        final income = transactions
            .where((t) => t.type == 'income')
            .fold(0.0, (sum, t) => sum + t.amount);
        contributions[project.name] = income;
      }
    }

    return contributions;
  }

  /// Get top expensive projects
  List<MapEntry<String, double>> getTopExpensiveProjects(
    Map<String, List<Transaction>> projectTransactions,
    Map<String, Project> projects, {
    int limit = 5,
  }) {
    final expenses = <String, double>{};

    for (final entry in projectTransactions.entries) {
      final projectId = entry.key;
      final transactions = entry.value;
      final project = projects[projectId];

      if (project != null && project.isActive) {
        final totalExpenses = transactions
            .where((t) => t.type == 'expense')
            .fold(0.0, (sum, t) => sum + t.amount);
        expenses['${project.name} (${project.id})'] = totalExpenses;
      }
    }

    final sorted = expenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).toList();
  }

  /// Get timeline data for income, expenses, and balance
  /// Groups transactions by time period (daily, weekly, or monthly)
  Map<String, List<TimelineDataPoint>> getTimelineData(
    List<Transaction> transactions, {
    TimelineGranularity granularity = TimelineGranularity.monthly,
  }) {
    if (transactions.isEmpty) {
      return {
        'income': [],
        'expenses': [],
        'balance': [],
      };
    }

    // Group transactions by time period
    final groupedTransactions = <String, List<Transaction>>{};

    for (final transaction in transactions) {
      final key = _getTimeKey(transaction.date, granularity);
      groupedTransactions.putIfAbsent(key, () => []).add(transaction);
    }

    // Sort keys chronologically
    final sortedKeys = groupedTransactions.keys.toList()..sort();

    final incomeData = <TimelineDataPoint>[];
    final expensesData = <TimelineDataPoint>[];
    final balanceData = <TimelineDataPoint>[];

    double cumulativeBalance = 0;

    for (final key in sortedKeys) {
      final txns = groupedTransactions[key]!;
      final income =
          txns.where((t) => t.type == 'income').fold(0.0, (sum, t) => sum + t.amount);
      final expenses =
          txns.where((t) => t.type == 'expense').fold(0.0, (sum, t) => sum + t.amount);

      cumulativeBalance += income - expenses;

      incomeData.add(TimelineDataPoint(date: key, value: income));
      expensesData.add(TimelineDataPoint(date: key, value: expenses));
      balanceData.add(TimelineDataPoint(date: key, value: cumulativeBalance));
    }

    return {
      'income': incomeData,
      'expenses': expensesData,
      'balance': balanceData,
    };
  }

  /// Helper to get time key based on granularity
  String _getTimeKey(DateTime date, TimelineGranularity granularity) {
    switch (granularity) {
      case TimelineGranularity.daily:
        return DateFormat('yyyy-MM-dd').format(date);
      case TimelineGranularity.weekly:
        // Get the Monday of the week
        final weekStart = date.subtract(Duration(days: date.weekday - 1));
        return DateFormat('yyyy-MM-dd').format(weekStart);
      case TimelineGranularity.monthly:
        return DateFormat('yyyy-MM').format(date);
    }
  }

  /// Get category breakdown for expenses
  Map<String, double> getCategoryBreakdown(
    List<Transaction> transactions, {
    String type = 'expense',
  }) {
    final breakdown = <String, double>{};

    for (final transaction in transactions.where((t) => t.type == type)) {
      breakdown[transaction.category] =
          (breakdown[transaction.category] ?? 0) + transaction.amount;
    }

    return breakdown;
  }

  /// Calculate summary statistics
  AnalyticsSummary calculateSummary(
    Map<String, List<Transaction>> projectTransactions,
  ) {
    final allTransactions =
        projectTransactions.values.expand((txns) => txns).toList();

    if (allTransactions.isEmpty) {
      return AnalyticsSummary(
        totalIncome: 0,
        totalExpenses: 0,
        balance: 0,
        numberOfTransactions: 0,
        numberOfProjects: projectTransactions.length,
        averageTransactionAmount: 0,
      );
    }

    final totalIncome = allTransactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpenses = allTransactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
    final avgAmount =
        allTransactions.fold(0.0, (sum, t) => sum + t.amount) / allTransactions.length;

    return AnalyticsSummary(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      balance: totalIncome - totalExpenses,
      numberOfTransactions: allTransactions.length,
      numberOfProjects: projectTransactions.length,
      averageTransactionAmount: avgAmount,
    );
  }
}

/// Granularity for timeline data
enum TimelineGranularity {
  daily,
  weekly,
  monthly,
}

/// Data point for timeline charts
class TimelineDataPoint {
  final String date;
  final double value;

  TimelineDataPoint({
    required this.date,
    required this.value,
  });
}

/// Summary statistics for analytics
class AnalyticsSummary {
  final double totalIncome;
  final double totalExpenses;
  final double balance;
  final int numberOfTransactions;
  final int numberOfProjects;
  final double averageTransactionAmount;

  AnalyticsSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.balance,
    required this.numberOfTransactions,
    required this.numberOfProjects,
    required this.averageTransactionAmount,
  });
}
