import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:artist_finance_manager/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E Test: Complete User Flow', () {
    testWidgets('Full transaction workflow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify app loaded
      expect(find.text('Project Finance Tracker'), findsOneWidget);

      // Initial state: all summaries should be €0.00
      expect(find.text('€0.00'), findsNWidgets(3));

      // Step 1: Add an expense
      await tester.tap(find.text('Select category').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Musicians').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'What is this for?'),
        'Band payment',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '0.00'),
        '1000',
      );
      await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.add));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify expense was added
      expect(find.text('Band payment'), findsOneWidget);
      expect(find.text('-€1000.00'), findsOneWidget);

      // Verify summary updated
      expect(find.text('€1000.00'), findsAtLeastNWidgets(1));

      // Step 2: Add income
      await tester.tap(find.text('Expense'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Income').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select category').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Event Tickets').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'What is this for?'),
        'Concert ticket sales',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '0.00'),
        '2500',
      );
      await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.add));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify income was added
      expect(find.text('Concert ticket sales'), findsOneWidget);
      expect(find.text('+€2500.00'), findsOneWidget);

      // Step 3: Verify final balance (2500 - 1000 = 1500)
      expect(find.text('€1500.00'), findsOneWidget); // Balance card

      // Step 4: Delete a transaction
      await tester.tap(find.text('Delete').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      // Verify transaction was deleted
      expect(find.text('Concert ticket sales'), findsNothing);
    });

    testWidgets('Form validation works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Try to submit empty form
      await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.add));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please select a category'), findsOneWidget);

      // Fill in only category
      await tester.tap(find.text('Select category').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.add));
      await tester.pumpAndSettle();

      // Should still show errors for other fields
      expect(find.text('Please enter a description'), findsOneWidget);
    });

    testWidgets('Multiple transactions persist', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Add multiple transactions
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Select category').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Other').last);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'What is this for?'),
          'Transaction $i',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, '0.00'),
          '${(i + 1) * 100}',
        );
        await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.add));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
      }

      // Verify all transactions are visible
      expect(find.text('Transaction 0'), findsOneWidget);
      expect(find.text('Transaction 1'), findsOneWidget);
      expect(find.text('Transaction 2'), findsOneWidget);

      // Verify totals
        expect(find.text('€600.00'),
          findsOneWidget); // Total expenses (100+200+300)
    });

    testWidgets('Category switching works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test expense categories
      await tester.tap(find.text('Select category').first);
      await tester.pumpAndSettle();

      expect(find.text('Venue'), findsWidgets);
      expect(find.text('Musicians'), findsWidgets);
      expect(find.text('Food & Drinks'), findsWidgets);
      expect(find.text('Materials/Clothes'), findsWidgets);
      expect(find.text('Book Printing'), findsWidgets);
      expect(find.text('Podcast'), findsWidgets);

      // Tap outside to close
      await tester.tapAt(const Offset(0, 0));
      await tester.pumpAndSettle();

      // Switch to income
      await tester.tap(find.text('Expense'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Income').last);
      await tester.pumpAndSettle();

      // Test income categories
      await tester.tap(find.text('Select category').first);
      await tester.pumpAndSettle();

      expect(find.text('Book Sales'), findsWidgets);
      expect(find.text('Event Tickets'), findsWidgets);
    });
  });
}
