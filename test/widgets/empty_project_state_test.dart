import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artist_finance_manager/widgets/empty_project_state.dart';
import 'package:artist_finance_manager/config/app_colors.dart';

/// Widget tests for EmptyProjectState
///
/// Tests the empty state view shown when user has no projects.
void main() {
  group('EmptyProjectState Widget', () {
    testWidgets('Displays icon when no projects exist',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyProjectState(),
          ),
        ),
      );

      // Verify icon is displayed
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
    });

    testWidgets('Displays main message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyProjectState(),
          ),
        ),
      );

      // Verify main message is displayed
      expect(find.text('No Projects Yet'), findsOneWidget);
    });

    testWidgets('Displays call-to-action message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyProjectState(),
          ),
        ),
      );

      // Verify call-to-action message
      expect(
        find.text(
            'Create a project to start registering your incomes and expenses'),
        findsOneWidget,
      );
    });

    testWidgets('Displays create project button', (WidgetTester tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyProjectState(
              onCreateProject: () {
                buttonPressed = true;
              },
            ),
          ),
        ),
      );

      // Verify button is displayed
      expect(find.widgetWithText(ElevatedButton, 'Create Your First Project'),
          findsOneWidget);

      // Tap the button
      await tester.tap(
          find.widgetWithText(ElevatedButton, 'Create Your First Project'));
      await tester.pumpAndSettle();

      // Verify callback was called
      expect(buttonPressed, isTrue);
    });

    testWidgets('Has proper layout structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyProjectState(),
          ),
        ),
      );

      // Verify EmptyProjectState widget exists
      expect(find.byType(EmptyProjectState), findsOneWidget);

      // Verify Column exists for vertical layout
      expect(find.byType(Column), findsOneWidget);

      // Verify Icon exists
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('Icon has correct size and color', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyProjectState(),
          ),
        ),
      );

      final iconFinder = find.byIcon(Icons.folder_open);
      expect(iconFinder, findsOneWidget);

      final Icon iconWidget = tester.widget(iconFinder);
      expect(iconWidget.size, 120.0);
      expect(iconWidget.color, AppColors.textMuted);
    });

    testWidgets('Texts have correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyProjectState(),
          ),
        ),
      );

      // Find the main title text
      final titleFinder = find.text('No Projects Yet');
      expect(titleFinder, findsOneWidget);

      final Text titleWidget = tester.widget(titleFinder);
      expect(titleWidget.style?.fontSize, 24);
      expect(titleWidget.style?.fontWeight, FontWeight.bold);
      expect(titleWidget.style?.color, AppColors.textPrimary);

      // Find the subtitle text
      final subtitleFinder = find.text(
        'Create a project to start registering your incomes and expenses',
      );
      expect(subtitleFinder, findsOneWidget);

      final Text subtitleWidget = tester.widget(subtitleFinder);
      expect(subtitleWidget.style?.fontSize, 16);
      expect(subtitleWidget.style?.color, AppColors.textSecondary);
      expect(subtitleWidget.textAlign, TextAlign.center);
    });

    testWidgets('Button has correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyProjectState(
              onCreateProject: () {},
            ),
          ),
        ),
      );

      final buttonFinder =
          find.widgetWithText(ElevatedButton, 'Create Your First Project');
      expect(buttonFinder, findsOneWidget);

      final ElevatedButton buttonWidget = tester.widget(buttonFinder);
      expect(buttonWidget.child, isA<Padding>());
    });

    testWidgets('Works without callback', (WidgetTester tester) async {
      // Should not throw when no callback is provided
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyProjectState(),
          ),
        ),
      );

      expect(find.byType(EmptyProjectState), findsOneWidget);
    });

    testWidgets('Has proper spacing between elements',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyProjectState(),
          ),
        ),
      );

      // Verify SizedBox widgets exist for spacing
      final sizedBoxes = find.byType(SizedBox);
      expect(sizedBoxes, findsWidgets);
    });
  });
}
