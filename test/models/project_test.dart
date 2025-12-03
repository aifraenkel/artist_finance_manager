import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artist_finance_manager/models/project.dart';

void main() {
  group('Project Model Tests', () {
    test('Project creation with required fields', () {
      final project = Project(
        id: 'test-id',
        name: 'Test Project',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(project.id, 'test-id');
      expect(project.name, 'Test Project');
      expect(project.createdAt, DateTime(2024, 1, 1));
      expect(project.deletedAt, isNull);
      expect(project.isActive, isTrue);
      expect(project.isDeleted, isFalse);
    });

    test('Project with deletedAt timestamp', () {
      final deletedAt = DateTime(2024, 6, 1);
      final project = Project(
        id: 'test-id',
        name: 'Deleted Project',
        createdAt: DateTime(2024, 1, 1),
        deletedAt: deletedAt,
      );

      expect(project.deletedAt, deletedAt);
      expect(project.isActive, isFalse);
      expect(project.isDeleted, isTrue);
    });

    test('Project JSON serialization', () {
      final createdAt = DateTime(2024, 1, 1);
      final project = Project(
        id: 'json-test-id',
        name: 'JSON Test',
        createdAt: createdAt,
      );

      final json = project.toJson();

      expect(json['id'], 'json-test-id');
      expect(json['name'], 'JSON Test');
      expect(json['createdAt'], createdAt.toIso8601String());
      expect(json['deletedAt'], isNull);
    });

    test('Project JSON deserialization', () {
      final createdAt = DateTime(2024, 1, 1);
      final json = {
        'id': 'deserialize-id',
        'name': 'Deserialized Project',
        'createdAt': createdAt.toIso8601String(),
        'deletedAt': null,
      };

      final project = Project.fromJson(json);

      expect(project.id, 'deserialize-id');
      expect(project.name, 'Deserialized Project');
      expect(project.createdAt, createdAt);
      expect(project.deletedAt, isNull);
    });

    test('Project JSON round-trip with deletedAt', () {
      final createdAt = DateTime(2024, 1, 1);
      final deletedAt = DateTime(2024, 6, 1);
      final original = Project(
        id: 'round-trip-id',
        name: 'Round Trip',
        createdAt: createdAt,
        deletedAt: deletedAt,
      );

      final json = original.toJson();
      final recreated = Project.fromJson(json);

      expect(recreated.id, original.id);
      expect(recreated.name, original.name);
      expect(recreated.createdAt, original.createdAt);
      expect(recreated.deletedAt, original.deletedAt);
      expect(recreated.isActive, original.isActive);
    });

    test('Project copyWith method', () {
      final original = Project(
        id: 'original-id',
        name: 'Original Name',
        createdAt: DateTime(2024, 1, 1),
      );

      final renamed = original.copyWith(name: 'New Name');
      expect(renamed.id, original.id);
      expect(renamed.name, 'New Name');
      expect(renamed.createdAt, original.createdAt);

      final deleted = original.copyWith(deletedAt: DateTime(2024, 6, 1));
      expect(deleted.id, original.id);
      expect(deleted.name, original.name);
      expect(deleted.deletedAt, isNotNull);
      expect(deleted.isDeleted, isTrue);
    });

    test('Project equality', () {
      final project1 = Project(
        id: 'same-id',
        name: 'Project 1',
        createdAt: DateTime(2024, 1, 1),
      );

      final project2 = Project(
        id: 'same-id',
        name: 'Project 2',
        createdAt: DateTime(2024, 2, 1),
      );

      final project3 = Project(
        id: 'different-id',
        name: 'Project 1',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(project1, equals(project2)); // Same ID
      expect(project1, isNot(equals(project3))); // Different ID
      expect(project1.hashCode, equals(project2.hashCode));
    });

    test('Project toString', () {
      final project = Project(
        id: 'test-id',
        name: 'Test Project',
        createdAt: DateTime(2024, 1, 1),
      );

      final str = project.toString();
      expect(str, contains('test-id'));
      expect(str, contains('Test Project'));
      expect(str, contains('isActive: true'));
    });
  });
}
