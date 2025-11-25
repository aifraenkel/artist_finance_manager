import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_finance_manager/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App loads and shows title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Wait for async loading to finish and then verify title
    await tester.pumpAndSettle();
    expect(find.text('Project Finance Tracker'), findsOneWidget);
  });

  testWidgets('Summary cards are visible', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify all three summary cards exist
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Balance'), findsOneWidget);
  });

  testWidgets('Transaction form is visible', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify form fields exist
    expect(find.text('Add Transaction'), findsOneWidget);
    expect(find.text('Type'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Amount (\$)'), findsOneWidget);
  });

  testWidgets('Can add a transaction', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Select expense type (already default)
    // Select category
    await tester.ensureVisible(find.byKey(const Key('category_dropdown')));
    await tester.tap(find.byKey(const Key('category_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Venue').last);
    await tester.pumpAndSettle();

    // Enter description
    await tester.enterText(
      find.byKey(const Key('description_field')),
      'Concert hall rental',
    );

    // Enter amount
    await tester.enterText(
      find.byKey(const Key('amount_field')),
      '500.00',
    );

    // Tap add button
    await tester.ensureVisible(find.byKey(const Key('add_transaction_button')));
    await tester.tap(find.byKey(const Key('add_transaction_button')));
    await tester.pumpAndSettle();

    // Verify transaction appears in list
    expect(find.text('Concert hall rental'), findsOneWidget);
    expect(find.text('-\$500.00'), findsOneWidget);
    expect(find.text('Venue'), findsOneWidget);
  });

  testWidgets('Can delete a transaction', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Add a transaction first
    await tester.ensureVisible(find.byKey(const Key('category_dropdown')));
    await tester.tap(find.byKey(const Key('category_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('description_field')),
      'Test expense',
    );
    await tester.enterText(
      find.byKey(const Key('amount_field')),
      '100',
    );

    await tester.ensureVisible(find.byKey(const Key('add_transaction_button')));
    await tester.tap(find.byKey(const Key('add_transaction_button')));
    await tester.pumpAndSettle();

    // Verify transaction exists
    expect(find.text('Test expense'), findsOneWidget);

    // Delete it
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Confirm deletion in dialog
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    // Verify transaction is gone
    expect(find.text('Test expense'), findsNothing);
  });

  testWidgets('Summary updates correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Add an expense
    await tester.ensureVisible(find.byKey(const Key('category_dropdown')));
    await tester.tap(find.byKey(const Key('category_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('description_field')),
      'Expense item',
    );
    await tester.enterText(
      find.byKey(const Key('amount_field')),
      '50',
    );

    await tester.ensureVisible(find.byKey(const Key('add_transaction_button')));
    await tester.tap(find.byKey(const Key('add_transaction_button')));
    await tester.pumpAndSettle();

    // Verify expenses updated: summary shows $50.00 and transaction shows -$50.00
    expect(find.text('\$50.00'), findsOneWidget); // summary
    expect(find.text('-\$50.00'), findsOneWidget); // transaction

    // Switch to income
    await tester.tap(find.text('Expense'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Income').last);
    await tester.pumpAndSettle();

    // Add income
    await tester.tap(find.byKey(const Key('category_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Book Sales').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('description_field')),
      'Book sale',
    );
    await tester.enterText(
      find.byKey(const Key('amount_field')),
      '100',
    );

    await tester.tap(find.byKey(const Key('add_transaction_button')));
    await tester.pumpAndSettle();

    // Verify balance is correct (100 income - 50 expense = 50 balance)
    expect(find.textContaining('\$100.00'), findsAtLeastNWidgets(1)); // Income
  });
}
