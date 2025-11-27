import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_finance_manager/main.dart' as app;
import '../integration_test/pages/home_page.dart';

/**
 * Integration-style tests that run as widget tests
 *
 * These tests work on ALL platforms including web, unlike integration_test
 * which only supports mobile platforms.
 *
 * They provide the same coverage as integration tests but run in the
 * test environment rather than on a real device/browser.
 */

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('User Transaction Flow Integration Tests', () {
    testWidgets('User can add expense and see updated balance',
        (WidgetTester tester) async {
      // Launch app
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      final homePage = HomePage(tester);

      // Verify app loaded
      await homePage.verifyPageLoaded();

      // Initial state: all summaries should be €0.00
      homePage.verifySummary(
        income: '€0.00',
        expenses: '€0.00',
        balance: '€0.00',
      );

      // Add an expense
      await homePage.addExpense(
        category: 'Musicians',
        description: 'Band payment',
        amount: '1000',
      );

      // Verify expense was added
      homePage.verifyTransactionExists('Band payment');
      homePage.verifyTransactionExists('-€1000.00');

      // Verify summary updated
      homePage.verifySummary(expenses: '€1000.00', balance: '€-1000.00');
    });

    testWidgets('User can add income and expense, see correct balance',
        (WidgetTester tester) async {
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      final homePage = HomePage(tester);
      await homePage.verifyPageLoaded();

      // Add expense
      await homePage.addExpense(
        category: 'Musicians',
        description: 'Band payment',
        amount: '1000',
      );

      // Add income
      await homePage.addIncome(
        category: 'Event Tickets',
        description: 'Concert ticket sales',
        amount: '2500',
      );

      // Verify both transactions exist
      homePage.verifyTransactionExists('Band payment');
      homePage.verifyTransactionExists('Concert ticket sales');

      // Verify final balance (2500 - 1000 = 1500)
      homePage.verifySummary(
        income: '€2500.00',
        expenses: '€1000.00',
        balance: '€1500.00',
      );
    });

    testWidgets('User can delete a transaction', (WidgetTester tester) async {
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      final homePage = HomePage(tester);
      await homePage.verifyPageLoaded();

      // Add a transaction
      await homePage.addExpense(
        category: 'Other',
        description: 'Test expense',
        amount: '100',
      );

      // Verify transaction exists
      homePage.verifyTransactionExists('Test expense');
      homePage.verifySummary(expenses: '€100.00');

      // Delete the transaction
      await homePage.deleteFirstTransaction();

      // Verify transaction is gone
      homePage.verifyTransactionNotExists('Test expense');
      homePage.verifySummary(expenses: '€0.00');
    });

    testWidgets('Form validation prevents empty submission',
        (WidgetTester tester) async {
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      final homePage = HomePage(tester);
      await homePage.verifyPageLoaded();

      // Try to submit with empty form
      await homePage.clickAddButton();

      // Should show validation error
      expect(find.text('Please select a category'), findsOneWidget);
    });

    testWidgets('User can add multiple transactions',
        (WidgetTester tester) async {
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      final homePage = HomePage(tester);
      await homePage.verifyPageLoaded();

      // Add multiple expenses
      for (int i = 0; i < 3; i++) {
        await homePage.addExpense(
          category: 'Other',
          description: 'Transaction $i',
          amount: '${(i + 1) * 100}',
        );
      }

      // Verify all transactions are visible
      homePage.verifyTransactionExists('Transaction 0');
      homePage.verifyTransactionExists('Transaction 1');
      homePage.verifyTransactionExists('Transaction 2');

      // Verify total (100 + 200 + 300 = 600)
      homePage.verifySummary(expenses: '€600.00');
    });

    testWidgets('User can switch between income and expense categories',
        (WidgetTester tester) async {
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      final homePage = HomePage(tester);
      await homePage.verifyPageLoaded();

      // Test expense categories are available
      await tester.tap(homePage.categoryDropdown);
      await tester.pumpAndSettle();

      expect(find.text('Venue'), findsWidgets);
      expect(find.text('Musicians'), findsWidgets);
      expect(find.text('Food & Drinks'), findsWidgets);

      // Close dropdown
      await tester.tapAt(const Offset(0, 0));
      await tester.pumpAndSettle();

      // Switch to income
      await homePage.selectType('income');

      // Test income categories are available
      await tester.tap(homePage.categoryDropdown);
      await tester.pumpAndSettle();

      expect(find.text('Book Sales'), findsWidgets);
      expect(find.text('Event Tickets'), findsWidgets);
    });
  });
}
