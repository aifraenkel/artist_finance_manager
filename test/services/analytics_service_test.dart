import 'package:flutter_test/flutter_test.dart';
import 'package:artist_finance_manager/services/analytics_service.dart';
import 'package:artist_finance_manager/models/transaction.dart';
import 'package:artist_finance_manager/models/project.dart';

void main() {
  group('AnalyticsService', () {
    late AnalyticsService analyticsService;

    setUp(() {
      analyticsService = AnalyticsService();
    });

    group('calculateProjectSummary', () {
      test('calculates summary for empty transactions', () {
        final result = analyticsService.calculateProjectSummary([]);
        expect(result['income'], 0.0);
        expect(result['expenses'], 0.0);
        expect(result['balance'], 0.0);
      });

      test('calculates summary with income and expenses', () {
        final transactions = [
          Transaction(
            id: 1,
            description: 'Sale',
            amount: 100.0,
            type: 'income',
            category: 'sales',
            date: DateTime(2024, 1, 1),
          ),
          Transaction(
            id: 2,
            description: 'Materials',
            amount: 30.0,
            type: 'expense',
            category: 'materials',
            date: DateTime(2024, 1, 2),
          ),
          Transaction(
            id: 3,
            description: 'Another Sale',
            amount: 50.0,
            type: 'income',
            category: 'sales',
            date: DateTime(2024, 1, 3),
          ),
        ];

        final result = analyticsService.calculateProjectSummary(transactions);
        expect(result['income'], 150.0);
        expect(result['expenses'], 30.0);
        expect(result['balance'], 120.0);
      });
    });

    group('getProjectContributions', () {
      test('calculates contributions for multiple projects', () {
        final project1 = Project(
          id: 'p1',
          name: 'Project A',
          createdAt: DateTime(2024, 1, 1),
        );
        final project2 = Project(
          id: 'p2',
          name: 'Project B',
          createdAt: DateTime(2024, 1, 1),
        );

        final projectTransactions = {
          'p1': [
            Transaction(
              id: 1,
              description: 'Sale',
              amount: 100.0,
              type: 'income',
              category: 'sales',
              date: DateTime(2024, 1, 1),
            ),
          ],
          'p2': [
            Transaction(
              id: 2,
              description: 'Sale',
              amount: 200.0,
              type: 'income',
              category: 'sales',
              date: DateTime(2024, 1, 2),
            ),
          ],
        };

        final projects = {
          'p1': project1,
          'p2': project2,
        };

        final contributions = analyticsService.getProjectContributions(
          projectTransactions,
          projects,
        );

        expect(contributions['Project A (p1)'], 100.0);
        expect(contributions['Project B (p2)'], 200.0);
      });

      test('excludes deleted projects', () {
        final project1 = Project(
          id: 'p1',
          name: 'Project A',
          createdAt: DateTime(2024, 1, 1),
        );
        final project2 = Project(
          id: 'p2',
          name: 'Project B',
          createdAt: DateTime(2024, 1, 1),
          deletedAt: DateTime(2024, 2, 1),
        );

        final projectTransactions = {
          'p1': [
            Transaction(
              id: 1,
              description: 'Sale',
              amount: 100.0,
              type: 'income',
              category: 'sales',
              date: DateTime(2024, 1, 1),
            ),
          ],
          'p2': [
            Transaction(
              id: 2,
              description: 'Sale',
              amount: 200.0,
              type: 'income',
              category: 'sales',
              date: DateTime(2024, 1, 2),
            ),
          ],
        };

        final projects = {
          'p1': project1,
          'p2': project2,
        };

        final contributions = analyticsService.getProjectContributions(
          projectTransactions,
          projects,
        );

        expect(contributions.containsKey('Project A (p1)'), true);
        expect(contributions.containsKey('Project B (p2)'), false);
      });
    });

    group('getTopExpensiveProjects', () {
      test('returns top expensive projects sorted', () {
        final project1 = Project(
          id: 'p1',
          name: 'Project A',
          createdAt: DateTime(2024, 1, 1),
        );
        final project2 = Project(
          id: 'p2',
          name: 'Project B',
          createdAt: DateTime(2024, 1, 1),
        );
        final project3 = Project(
          id: 'p3',
          name: 'Project C',
          createdAt: DateTime(2024, 1, 1),
        );

        final projectTransactions = {
          'p1': [
            Transaction(
              id: 1,
              description: 'Expense',
              amount: 50.0,
              type: 'expense',
              category: 'materials',
              date: DateTime(2024, 1, 1),
            ),
          ],
          'p2': [
            Transaction(
              id: 2,
              description: 'Expense',
              amount: 150.0,
              type: 'expense',
              category: 'materials',
              date: DateTime(2024, 1, 2),
            ),
          ],
          'p3': [
            Transaction(
              id: 3,
              description: 'Expense',
              amount: 100.0,
              type: 'expense',
              category: 'materials',
              date: DateTime(2024, 1, 3),
            ),
          ],
        };

        final projects = {
          'p1': project1,
          'p2': project2,
          'p3': project3,
        };

        final topExpensive = analyticsService.getTopExpensiveProjects(
          projectTransactions,
          projects,
          limit: 2,
        );

        expect(topExpensive.length, 2);
        expect(topExpensive[0].key, 'Project B (p2)');
        expect(topExpensive[0].value, 150.0);
        expect(topExpensive[1].key, 'Project C (p3)');
        expect(topExpensive[1].value, 100.0);
      });
    });

    group('getTimelineData', () {
      test('creates timeline with monthly granularity', () {
        final transactions = [
          Transaction(
            id: 1,
            description: 'Sale',
            amount: 100.0,
            type: 'income',
            category: 'sales',
            date: DateTime(2024, 1, 15),
          ),
          Transaction(
            id: 2,
            description: 'Expense',
            amount: 30.0,
            type: 'expense',
            category: 'materials',
            date: DateTime(2024, 1, 20),
          ),
          Transaction(
            id: 3,
            description: 'Sale',
            amount: 200.0,
            type: 'income',
            category: 'sales',
            date: DateTime(2024, 2, 10),
          ),
        ];

        final timelineData = analyticsService.getTimelineData(
          transactions,
          granularity: TimelineGranularity.monthly,
        );

        expect(timelineData.containsKey('income'), true);
        expect(timelineData.containsKey('expenses'), true);
        expect(timelineData.containsKey('balance'), true);

        final incomeData = timelineData['income']!;
        expect(incomeData.length, 2);
        expect(incomeData[0].date, '2024-01');
        expect(incomeData[0].value, 100.0);
        expect(incomeData[1].date, '2024-02');
        expect(incomeData[1].value, 200.0);

        final expensesData = timelineData['expenses']!;
        expect(expensesData[0].value, 30.0);
        expect(expensesData[1].value, 0.0);

        final balanceData = timelineData['balance']!;
        expect(balanceData[0].value, 70.0); // 100 - 30
        expect(balanceData[1].value, 270.0); // 70 + 200
      });

      test('returns empty for no transactions', () {
        final timelineData = analyticsService.getTimelineData([]);

        expect(timelineData['income']!.isEmpty, true);
        expect(timelineData['expenses']!.isEmpty, true);
        expect(timelineData['balance']!.isEmpty, true);
      });
    });

    group('getCategoryBreakdown', () {
      test('calculates category breakdown for expenses', () {
        final transactions = [
          Transaction(
            id: 1,
            description: 'Materials',
            amount: 50.0,
            type: 'expense',
            category: 'materials',
            date: DateTime(2024, 1, 1),
          ),
          Transaction(
            id: 2,
            description: 'More materials',
            amount: 30.0,
            type: 'expense',
            category: 'materials',
            date: DateTime(2024, 1, 2),
          ),
          Transaction(
            id: 3,
            description: 'Food',
            amount: 20.0,
            type: 'expense',
            category: 'food',
            date: DateTime(2024, 1, 3),
          ),
        ];

        final breakdown = analyticsService.getCategoryBreakdown(transactions);

        expect(breakdown['materials'], 80.0);
        expect(breakdown['food'], 20.0);
      });
    });

    group('calculateSummary', () {
      test('calculates overall summary statistics', () {
        final projectTransactions = {
          'p1': [
            Transaction(
              id: 1,
              description: 'Sale',
              amount: 100.0,
              type: 'income',
              category: 'sales',
              date: DateTime(2024, 1, 1),
            ),
            Transaction(
              id: 2,
              description: 'Expense',
              amount: 30.0,
              type: 'expense',
              category: 'materials',
              date: DateTime(2024, 1, 2),
            ),
          ],
          'p2': [
            Transaction(
              id: 3,
              description: 'Sale',
              amount: 200.0,
              type: 'income',
              category: 'sales',
              date: DateTime(2024, 1, 3),
            ),
          ],
        };

        final summary = analyticsService.calculateSummary(projectTransactions);

        expect(summary.totalIncome, 300.0);
        expect(summary.totalExpenses, 30.0);
        expect(summary.balance, 270.0);
        expect(summary.numberOfTransactions, 3);
        expect(summary.numberOfProjects, 2);
        expect(summary.averageTransactionAmount, closeTo(110.0, 0.01));
      });

      test('handles empty transactions', () {
        final summary = analyticsService.calculateSummary({});

        expect(summary.totalIncome, 0.0);
        expect(summary.totalExpenses, 0.0);
        expect(summary.balance, 0.0);
        expect(summary.numberOfTransactions, 0);
        expect(summary.numberOfProjects, 0);
        expect(summary.averageTransactionAmount, 0.0);
      });
    });
  });
}
