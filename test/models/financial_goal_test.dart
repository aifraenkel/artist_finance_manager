import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artist_finance_manager/models/financial_goal.dart';

void main() {
  group('EmailCadence', () {
    test('fromString returns correct cadence', () {
      expect(EmailCadence.fromString('daily'), EmailCadence.daily);
      expect(EmailCadence.fromString('weekly'), EmailCadence.weekly);
      expect(EmailCadence.fromString('biweekly'), EmailCadence.biweekly);
      expect(EmailCadence.fromString('monthly'), EmailCadence.monthly);
      expect(EmailCadence.fromString('never'), EmailCadence.never);
    });

    test('fromString returns never for invalid value', () {
      expect(EmailCadence.fromString('invalid'), EmailCadence.never);
    });

    test('value returns correct string', () {
      expect(EmailCadence.daily.value, 'daily');
      expect(EmailCadence.weekly.value, 'weekly');
      expect(EmailCadence.biweekly.value, 'biweekly');
      expect(EmailCadence.monthly.value, 'monthly');
      expect(EmailCadence.never.value, 'never');
    });
  });

  group('FinancialGoal', () {
    final testDate = DateTime(2024, 12, 31);
    final createdAt = DateTime(2024, 1, 1);
    final updatedAt = DateTime(2024, 1, 2);

    test('creates a valid financial goal', () {
      final goal = FinancialGoal(
        goal: 'Save \$5,000 for recording equipment',
        dueDate: testDate,
        emailCadence: EmailCadence.weekly,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(goal.goal, 'Save \$5,000 for recording equipment');
      expect(goal.dueDate, testDate);
      expect(goal.emailCadence, EmailCadence.weekly);
      expect(goal.createdAt, createdAt);
      expect(goal.updatedAt, updatedAt);
    });

    test('isValid returns true for valid goal', () {
      final goal = FinancialGoal(
        goal: 'Save money',
        dueDate: testDate,
        emailCadence: EmailCadence.weekly,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(goal.isValid, true);
    });

    test('isValid returns false for empty goal', () {
      final goal = FinancialGoal(
        goal: '   ',
        dueDate: testDate,
        emailCadence: EmailCadence.weekly,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(goal.isValid, false);
    });

    test('isValid returns false for goal exceeding max length', () {
      final longGoal = 'a' * 2001;
      final goal = FinancialGoal(
        goal: longGoal,
        dueDate: testDate,
        emailCadence: EmailCadence.weekly,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(goal.isValid, false);
    });

    test('toFirestore converts to map correctly', () {
      final goal = FinancialGoal(
        goal: 'Test goal',
        dueDate: testDate,
        emailCadence: EmailCadence.monthly,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final map = goal.toFirestore();

      expect(map['goal'], 'Test goal');
      expect(map['dueDate'], isA<Timestamp>());
      expect(map['emailCadence'], 'monthly');
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<Timestamp>());
    });

    test('fromFirestore creates goal from map', () {
      final map = {
        'goal': 'Test goal',
        'dueDate': Timestamp.fromDate(testDate),
        'emailCadence': 'biweekly',
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

      final goal = FinancialGoal.fromFirestore(map);

      expect(goal.goal, 'Test goal');
      expect(goal.dueDate.year, testDate.year);
      expect(goal.dueDate.month, testDate.month);
      expect(goal.dueDate.day, testDate.day);
      expect(goal.emailCadence, EmailCadence.biweekly);
    });

    test('fromFirestore handles missing fields', () {
      final map = <String, dynamic>{};

      final goal = FinancialGoal.fromFirestore(map);

      expect(goal.goal, '');
      expect(goal.emailCadence, EmailCadence.never);
      expect(goal.dueDate, isNotNull);
      expect(goal.createdAt, isNotNull);
      expect(goal.updatedAt, isNotNull);
    });

    test('copyWith creates a copy with updated fields', () {
      final original = FinancialGoal(
        goal: 'Original goal',
        dueDate: testDate,
        emailCadence: EmailCadence.weekly,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final newDate = DateTime(2025, 6, 30);
      final copy = original.copyWith(
        goal: 'Updated goal',
        dueDate: newDate,
      );

      expect(copy.goal, 'Updated goal');
      expect(copy.dueDate, newDate);
      expect(copy.emailCadence, EmailCadence.weekly); // unchanged
      expect(copy.createdAt, createdAt); // unchanged
    });

    test('equality works correctly', () {
      final goal1 = FinancialGoal(
        goal: 'Test',
        dueDate: testDate,
        emailCadence: EmailCadence.weekly,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final goal2 = FinancialGoal(
        goal: 'Test',
        dueDate: testDate,
        emailCadence: EmailCadence.weekly,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(goal1, equals(goal2));
      expect(goal1.hashCode, equals(goal2.hashCode));
    });

    test('toString returns formatted string', () {
      final goal = FinancialGoal(
        goal: 'Test goal',
        dueDate: testDate,
        emailCadence: EmailCadence.daily,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final str = goal.toString();

      expect(str, contains('Test goal'));
      expect(str, contains('daily'));
    });
  });
}
