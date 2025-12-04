import 'package:flutter_test/flutter_test.dart';
import 'package:artist_finance_manager/models/budget_goal.dart';

void main() {
  group('BudgetGoal', () {
    test('should create a valid budget goal', () {
      final now = DateTime.now();
      final goal = BudgetGoal(
        goalText: 'I want to have a positive balance of 200€ per month',
        isActive: true,
        createdAt: now,
      );

      expect(goal.goalText,
          'I want to have a positive balance of 200€ per month');
      expect(goal.isActive, true);
      expect(goal.createdAt, now);
      expect(goal.updatedAt, null);
      expect(goal.isValid, true);
      expect(goal.isEmpty, false);
    });

    test('should detect empty goal', () {
      final goal = BudgetGoal(
        goalText: '   ',
        isActive: false,
        createdAt: DateTime.now(),
      );

      expect(goal.isEmpty, true);
      expect(goal.isValid, false);
    });

    test('should convert to and from map', () {
      final now = DateTime.now();
      final updatedTime = now.add(const Duration(days: 1));

      final goal = BudgetGoal(
        goalText: 'Save 500€ per month',
        isActive: true,
        createdAt: now,
        updatedAt: updatedTime,
      );

      final map = goal.toMap();
      final recreated = BudgetGoal.fromMap(map);

      expect(recreated.goalText, goal.goalText);
      expect(recreated.isActive, goal.isActive);
      expect(
        recreated.createdAt.millisecondsSinceEpoch,
        goal.createdAt.millisecondsSinceEpoch,
      );
      expect(
        recreated.updatedAt?.millisecondsSinceEpoch,
        goal.updatedAt?.millisecondsSinceEpoch,
      );
    });

    test('should create copy with updated fields', () {
      final original = BudgetGoal(
        goalText: 'Original goal',
        isActive: false,
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(
        goalText: 'Updated goal',
        isActive: true,
      );

      expect(updated.goalText, 'Updated goal');
      expect(updated.isActive, true);
      expect(updated.createdAt, original.createdAt);
    });

    test('should handle equality correctly', () {
      final now = DateTime.now();
      final goal1 = BudgetGoal(
        goalText: 'Test goal',
        isActive: true,
        createdAt: now,
      );

      final goal2 = BudgetGoal(
        goalText: 'Test goal',
        isActive: true,
        createdAt: now,
      );

      final goal3 = BudgetGoal(
        goalText: 'Different goal',
        isActive: true,
        createdAt: now,
      );

      expect(goal1, goal2);
      expect(goal1, isNot(goal3));
      expect(goal1.hashCode, goal2.hashCode);
    });

    test('should handle null updatedAt in fromMap', () {
      final map = {
        'goalText': 'Test goal',
        'isActive': true,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      final goal = BudgetGoal.fromMap(map);

      expect(goal.goalText, 'Test goal');
      expect(goal.isActive, true);
      expect(goal.updatedAt, null);
    });

    test('should provide meaningful toString', () {
      final goal = BudgetGoal(
        goalText: 'Test goal',
        isActive: true,
        createdAt: DateTime.now(),
      );

      final str = goal.toString();
      expect(str, contains('BudgetGoal'));
      expect(str, contains('Test goal'));
      expect(str, contains('true'));
    });
  });
}
