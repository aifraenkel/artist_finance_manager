import 'package:flutter_test/flutter_test.dart';
import 'package:artist_finance_manager/models/transaction.dart';

void main() {
  group('Transaction Model Tests', () {
    test('Create transaction with all fields', () {
      final now = DateTime.now();
      final transaction = Transaction(
        id: 12345,
        description: 'Test transaction',
        amount: 100.50,
        type: 'expense',
        category: 'Venue',
        date: now,
      );

      expect(transaction.id, 12345);
      expect(transaction.description, 'Test transaction');
      expect(transaction.amount, 100.50);
      expect(transaction.type, 'expense');
      expect(transaction.category, 'Venue');
      expect(transaction.date, now);
    });

    test('Transaction toJson', () {
      final date = DateTime(2024, 1, 1, 12, 0, 0);
      final transaction = Transaction(
        id: 123,
        description: 'Test',
        amount: 50.0,
        type: 'income',
        category: 'Book Sales',
        date: date,
      );

      final json = transaction.toJson();

      expect(json['id'], 123);
      expect(json['description'], 'Test');
      expect(json['amount'], 50.0);
      expect(json['type'], 'income');
      expect(json['category'], 'Book Sales');
      expect(json['date'], date.toIso8601String());
    });

    test('Transaction fromJson', () {
      final dateString = DateTime(2024, 1, 1, 12, 0, 0).toIso8601String();
      final json = {
        'id': 456,
        'description': 'From JSON',
        'amount': 75.25,
        'type': 'expense',
        'category': 'Musicians',
        'date': dateString,
      };

      final transaction = Transaction.fromJson(json);

      expect(transaction.id, 456);
      expect(transaction.description, 'From JSON');
      expect(transaction.amount, 75.25);
      expect(transaction.type, 'expense');
      expect(transaction.category, 'Musicians');
      expect(transaction.date, DateTime.parse(dateString));
    });

    test('Transaction roundtrip (toJson -> fromJson)', () {
      final original = Transaction(
        id: 789,
        description: 'Roundtrip test',
        amount: 999.99,
        type: 'income',
        category: 'Event Tickets',
        date: DateTime.now(),
      );

      final json = original.toJson();
      final recreated = Transaction.fromJson(json);

      expect(recreated.id, original.id);
      expect(recreated.description, original.description);
      expect(recreated.amount, original.amount);
      expect(recreated.type, original.type);
      expect(recreated.category, original.category);
      expect(recreated.date.toIso8601String(), original.date.toIso8601String());
    });
  });
}
