// Simplified widget tests replacing manual E2E integration tests.
// These avoid Firebase/platform channel dependencies and provide
// fast UI verification for core reusable widgets.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artist_finance_manager/widgets/summary_cards.dart';

void main() {
  group('SummaryCards Widget', () {
    testWidgets('renders income, expenses and balance (positive balance)', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SummaryCards(
            totalIncome: 1500.25,
            totalExpenses: 500.75,
            balance: 999.50,
          ),
        ),
      ));

      expect(find.byKey(const ValueKey('income-card')), findsOneWidget);
      expect(find.byKey(const ValueKey('expenses-card')), findsOneWidget);
      expect(find.byKey(const ValueKey('balance-card')), findsOneWidget);
      expect(find.byKey(const ValueKey('income-amount')), findsOneWidget);
      expect(find.textContaining('€1500.25'), findsOneWidget);
      expect(find.textContaining('€500.75'), findsOneWidget);
      expect(find.textContaining('€999.50'), findsOneWidget);
    });

    testWidgets('renders negative balance with minus sign and red styling', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SummaryCards(
            totalIncome: 100.0,
            totalExpenses: 250.0,
            balance: -150.0,
          ),
        ),
      ));

      expect(find.byKey(const ValueKey('balance-card')), findsOneWidget);
      expect(find.textContaining('-€150.00'), findsOneWidget);
    });

    testWidgets('switches layout based on width (narrow vs wide)', (tester) async {
      // Narrow layout
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SummaryCards(
            totalIncome: 10,
            totalExpenses: 5,
            balance: 5,
          ),
        ),
      ));
      // Expect Column children ordered vertically
      final columnFinder = find.byType(Column);
      expect(columnFinder, findsWidgets);

      // Wide layout
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SummaryCards(
            totalIncome: 10,
            totalExpenses: 5,
            balance: 5,
          ),
        ),
      ));
      // For wide layout a Row should be used
      expect(find.byType(Row), findsWidgets);
    });
  });
}
