import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Page object for the home screen with transaction management
class HomePage {
  final WidgetTester tester;

  HomePage(this.tester);

  // Finders for main elements
  Finder get appTitle => find.byKey(const ValueKey('app-title'));
  Finder get summaryCards => find.byKey(const ValueKey('summary-cards'));
  Finder get incomeCard => find.byKey(const ValueKey('income-card'));
  Finder get expensesCard => find.byKey(const ValueKey('expenses-card'));
  Finder get balanceCard => find.byKey(const ValueKey('balance-card'));
  Finder get incomeAmount => find.byKey(const ValueKey('income-amount'));
  Finder get expensesAmount => find.byKey(const ValueKey('expenses-amount'));
  Finder get balanceAmount => find.byKey(const ValueKey('balance-amount'));

  // Transaction form finders
  Finder get transactionForm => find.byKey(const ValueKey('transaction-form'));
  Finder get typeDropdown => find.byKey(const Key('type_dropdown'));
  Finder get categoryDropdown => find.byKey(const Key('category_dropdown'));
  Finder get descriptionField => find.byKey(const Key('description_field'));
  Finder get amountField => find.byKey(const Key('amount_field'));
  Finder get addButton => find.byKey(const Key('add_transaction_button'));

  // Transaction list finders
  Finder get transactionList => find.byKey(const ValueKey('transaction-list'));

  /// Verify the home page has loaded
  Future<void> verifyPageLoaded() async {
    expect(appTitle, findsOneWidget);
    expect(summaryCards, findsOneWidget);
    expect(transactionForm, findsOneWidget);
  }

  /// Get the text content of the income amount
  String getIncomeAmount() {
    final widget = tester.widget<Text>(incomeAmount);
    return widget.data ?? '';
  }

  /// Get the text content of the expenses amount
  String getExpensesAmount() {
    final widget = tester.widget<Text>(expensesAmount);
    return widget.data ?? '';
  }

  /// Get the text content of the balance amount
  String getBalanceAmount() {
    final widget = tester.widget<Text>(balanceAmount);
    return widget.data ?? '';
  }

  /// Select transaction type (expense or income)
  Future<void> selectType(String type) async {
    await tester.ensureVisible(typeDropdown);
    await tester.tap(typeDropdown);
    await tester.pumpAndSettle();

    // Find and tap the type option
    await tester.tap(find.text(type.capitalize()).last);
    await tester.pumpAndSettle();
  }

  /// Select a category from the dropdown
  Future<void> selectCategory(String category) async {
    await tester.ensureVisible(categoryDropdown);
    await tester.tap(categoryDropdown);
    await tester.pumpAndSettle();

    // Tap the category option
    await tester.tap(find.text(category).last);
    await tester.pumpAndSettle();
  }

  /// Enter description for the transaction
  Future<void> enterDescription(String description) async {
    await tester.enterText(descriptionField, description);
    await tester.pumpAndSettle();
  }

  /// Enter amount for the transaction
  Future<void> enterAmount(String amount) async {
    await tester.enterText(amountField, amount);
    await tester.pumpAndSettle();
  }

  /// Click the add transaction button
  Future<void> clickAddButton() async {
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  /// Add a complete transaction (expense or income)
  Future<void> addTransaction({
    required String type,
    required String category,
    required String description,
    required String amount,
  }) async {
    await selectType(type);
    await selectCategory(category);
    await enterDescription(description);
    await enterAmount(amount);
    await clickAddButton();
  }

  /// Add an expense transaction
  Future<void> addExpense({
    required String category,
    required String description,
    required String amount,
  }) async {
    await addTransaction(
      type: 'expense',
      category: category,
      description: description,
      amount: amount,
    );
  }

  /// Add an income transaction
  Future<void> addIncome({
    required String category,
    required String description,
    required String amount,
  }) async {
    await addTransaction(
      type: 'income',
      category: category,
      description: description,
      amount: amount,
    );
  }

  /// Delete the first transaction in the list
  Future<void> deleteFirstTransaction() async {
    final deleteButton = find.text('Delete').first;
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Confirm deletion in dialog
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
  }

  /// Verify a transaction appears in the list
  void verifyTransactionExists(String description) {
    expect(find.text(description), findsAtLeastNWidgets(1));
  }

  /// Verify a transaction does not appear in the list
  void verifyTransactionNotExists(String description) {
    expect(find.text(description), findsNothing);
  }

  /// Verify the summary amounts
  void verifySummary({
    String? income,
    String? expenses,
    String? balance,
  }) {
    if (income != null) {
      expect(getIncomeAmount(), income);
    }
    if (expenses != null) {
      expect(getExpensesAmount(), expenses);
    }
    if (balance != null) {
      expect(getBalanceAmount(), balance);
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
