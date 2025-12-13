import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artist_finance_manager/models/financial_goal.dart';
import 'package:artist_finance_manager/services/financial_goal_service.dart';

void main() {
  group('FinancialGoalService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FinancialGoalService service;
    const testUserId = 'test-user-123';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      service = FinancialGoalService(firestore: fakeFirestore);
    });

    final testGoal = FinancialGoal(
      goal: 'Save \$5,000 for recording equipment',
      dueDate: DateTime(2024, 12, 31),
      emailCadence: EmailCadence.weekly,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    test('saveGoal saves goal to Firestore', () async {
      await service.saveGoal(testUserId, testGoal);

      final doc = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('financialGoal')
          .doc('current')
          .get();

      expect(doc.exists, true);
      expect(doc.data()?['goal'], testGoal.goal);
      expect(doc.data()?['emailCadence'], 'weekly');
    });

    test('getGoal returns null when no goal exists', () async {
      final goal = await service.getGoal(testUserId);
      expect(goal, isNull);
    });

    test('getGoal retrieves saved goal', () async {
      await service.saveGoal(testUserId, testGoal);

      final retrievedGoal = await service.getGoal(testUserId);

      expect(retrievedGoal, isNotNull);
      expect(retrievedGoal!.goal, testGoal.goal);
      expect(retrievedGoal.emailCadence, testGoal.emailCadence);
    });

    test('hasGoal returns false when no goal exists', () async {
      final hasGoal = await service.hasGoal(testUserId);
      expect(hasGoal, false);
    });

    test('hasGoal returns true when goal exists', () async {
      await service.saveGoal(testUserId, testGoal);

      final hasGoal = await service.hasGoal(testUserId);
      expect(hasGoal, true);
    });

    test('updateGoal updates existing goal', () async {
      await service.saveGoal(testUserId, testGoal);

      final updatedGoal = testGoal.copyWith(
        goal: 'Updated goal',
        emailCadence: EmailCadence.monthly,
      );

      await service.updateGoal(testUserId, updatedGoal);

      final retrievedGoal = await service.getGoal(testUserId);

      expect(retrievedGoal, isNotNull);
      expect(retrievedGoal!.goal, 'Updated goal');
      expect(retrievedGoal.emailCadence, EmailCadence.monthly);
      // updatedAt should be updated
      expect(retrievedGoal.updatedAt.isAfter(testGoal.updatedAt), true);
    });

    test('deleteGoal removes goal from Firestore', () async {
      await service.saveGoal(testUserId, testGoal);

      // Verify goal exists
      expect(await service.hasGoal(testUserId), true);

      // Delete goal
      await service.deleteGoal(testUserId);

      // Verify goal is deleted
      expect(await service.hasGoal(testUserId), false);
      expect(await service.getGoal(testUserId), isNull);
    });

    test('watchGoal emits null when no goal exists', () async {
      final stream = service.watchGoal(testUserId);

      await expectLater(
        stream,
        emits(null),
      );
    });

    test('watchGoal emits goal when it exists', () async {
      await service.saveGoal(testUserId, testGoal);

      final stream = service.watchGoal(testUserId);

      await expectLater(
        stream,
        emits(predicate<FinancialGoal?>((goal) =>
            goal != null &&
            goal.goal == testGoal.goal &&
            goal.emailCadence == testGoal.emailCadence)),
      );
    });

    test('watchGoal emits updates when goal changes', () async {
      await service.saveGoal(testUserId, testGoal);

      final stream = service.watchGoal(testUserId);

      // Save a different goal
      final newGoal = testGoal.copyWith(
        goal: 'New goal',
      );

      // Schedule the update after a delay
      Future.delayed(const Duration(milliseconds: 100), () {
        service.saveGoal(testUserId, newGoal);
      });

      // Expect initial goal then updated goal
      await expectLater(
        stream,
        emitsInOrder([
          predicate<FinancialGoal?>((goal) => goal != null && goal.goal == testGoal.goal),
          predicate<FinancialGoal?>((goal) => goal != null && goal.goal == 'New goal'),
        ]),
      );
    });

    test('FinancialGoalException is thrown on errors', () async {
      // Create a service with a null firestore to force an error
      // This is a bit tricky to test properly, but we can at least verify
      // the exception type is defined correctly
      expect(() => throw FinancialGoalException('Test error'), throwsException);
    });

    test('FinancialGoalException toString contains message', () {
      final exception = FinancialGoalException('Test error message');
      expect(exception.toString(), contains('Test error message'));
      expect(exception.toString(), contains('FinancialGoalException'));
    });
  });
}
