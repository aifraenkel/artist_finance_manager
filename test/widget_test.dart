import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artist_finance_manager/main.dart';

void main() {
  testWidgets('App loads and shows title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify app title is present
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
    await tester.tap(find.text('Select category').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Venue').last);
    await tester.pumpAndSettle();

    // Enter description
    await tester.enterText(
      find.widgetWithText(TextFormField, 'What is this for?'),
      'Concert hall rental',
    );

    // Enter amount
    await tester.enterText(
      find.widgetWithText(TextFormField, '0.00'),
      '500.00',
    );

    // Tap add button
    await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.add));
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
    await tester.tap(find.text('Select category').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'What is this for?'),
      'Test expense',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '0.00'),
      '100',
    );

    await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.add));
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
    await tester.tap(find.text('Select category').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'What is this for?'),
      'Expense item',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '0.00'),
      '50',
    );

    await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.add));
    await tester.pumpAndSettle();

    // Verify expenses updated
    expect(find.text('\$50.00'), findsAtLeastNWidgets(2)); // In summary and transaction

    // Switch to income
    await tester.tap(find.text('Expense'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Income').last);
    await tester.pumpAndSettle();

    // Add income
    await tester.tap(find.text('Select category').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Book Sales').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'What is this for?'),
      'Book sale',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '0.00'),
      '100',
    );

    await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.add));
    await tester.pumpAndSettle();

    // Verify balance is correct (100 income - 50 expense = 50 balance)
    expect(find.textContaining('\$100.00'), findsAtLeastNWidgets(1)); // Income
  });
}
