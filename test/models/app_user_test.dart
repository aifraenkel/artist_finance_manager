import 'package:artist_finance_manager/models/app_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUser Model Tests', () {
    late DateTime testCreatedAt;
    late DateTime testLastLoginAt;
    late DateTime testDeletedAt;

    setUp(() {
      testCreatedAt = DateTime(2025, 1, 1, 12, 0, 0);
      testLastLoginAt = DateTime(2025, 1, 15, 10, 30, 0);
      testDeletedAt = DateTime(2025, 1, 20, 14, 0, 0);
    });

    group('AppUser creation', () {
      test('creates user with all required fields', () {
        final user = AppUser(
          uid: 'user123',
          email: 'test@example.com',
          name: 'Test User',
          createdAt: testCreatedAt,
          lastLoginAt: testLastLoginAt,
        );

        expect(user.uid, equals('user123'));
        expect(user.email, equals('test@example.com'));
        expect(user.name, equals('Test User'));
        expect(user.createdAt, equals(testCreatedAt));
        expect(user.lastLoginAt, equals(testLastLoginAt));
        expect(user.deletedAt, isNull);
        expect(user.metadata, isNotNull);
      });

      test('creates user with deletedAt timestamp', () {
        final user = AppUser(
          uid: 'user123',
          email: 'test@example.com',
          name: 'Test User',
          createdAt: testCreatedAt,
          lastLoginAt: testLastLoginAt,
          deletedAt: testDeletedAt,
        );

        expect(user.deletedAt, equals(testDeletedAt));
      });

      test('creates user with custom metadata', () {
        final metadata = UserMetadata(
          loginCount: 5,
          lastLoginIp: '192.168.1.1',
          lastLoginUserAgent: 'Test Agent',
        );

        final user = AppUser(
          uid: 'user123',
          email: 'test@example.com',
          name: 'Test User',
          createdAt: testCreatedAt,
          lastLoginAt: testLastLoginAt,
          metadata: metadata,
        );

        expect(user.metadata.loginCount, equals(5));
        expect(user.metadata.lastLoginIp, equals('192.168.1.1'));
        expect(user.metadata.lastLoginUserAgent, equals('Test Agent'));
      });
    });

    group('AppUser status checks', () {
      test('isActive returns true for non-deleted user', () {
        final user = AppUser(
          uid: 'user123',
          email: 'test@example.com',
          name: 'Test User',
          createdAt: testCreatedAt,
          lastLoginAt: testLastLoginAt,
        );

        expect(user.isActive, isTrue);
        expect(user.isDeleted, isFalse);
      });

      test('isDeleted returns true for deleted user', () {
        final user = AppUser(
          uid: 'user123',
          email: 'test@example.com',
          name: 'Test User',
          createdAt: testCreatedAt,
          lastLoginAt: testLastLoginAt,
          deletedAt: testDeletedAt,
        );

        expect(user.isDeleted, isTrue);
        expect(user.isActive, isFalse);
      });
    });

    group('AppUser Firestore serialization', () {
      test('toFirestore() converts user to Firestore map', () {
        final user = AppUser(
          uid: 'user123',
          email: 'test@example.com',
          name: 'Test User',
          createdAt: testCreatedAt,
          lastLoginAt: testLastLoginAt,
        );

        final firestoreMap = user.toFirestore();

        expect(firestoreMap['uid'], equals('user123'));
        expect(firestoreMap['email'], equals('test@example.com'));
        expect(firestoreMap['name'], equals('Test User'));
        expect(firestoreMap['createdAt'], isA<Timestamp>());
        expect(firestoreMap['lastLoginAt'], isA<Timestamp>());
        expect(firestoreMap['deletedAt'], isNull);
        expect(firestoreMap['metadata'], isA<Map<String, dynamic>>());
      });

      test('toFirestore() includes deletedAt when present', () {
        final user = AppUser(
          uid: 'user123',
          email: 'test@example.com',
          name: 'Test User',
          createdAt: testCreatedAt,
          lastLoginAt: testLastLoginAt,
          deletedAt: testDeletedAt,
        );

        final firestoreMap = user.toFirestore();

        expect(firestoreMap['deletedAt'], isA<Timestamp>());
        final timestamp = firestoreMap['deletedAt'] as Timestamp;
        expect(timestamp.toDate(), equals(testDeletedAt));
      });

      test('toFirestore() includes metadata', () {
        final metadata = UserMetadata(
          loginCount: 5,
          lastLoginIp: '192.168.1.1',
          devices: [
            DeviceInfo(
              deviceId: 'device1',
              deviceName: 'Test Device',
              firstSeen: testCreatedAt,
              lastSeen: testLastLoginAt,
            ),
          ],
        );

        final user = AppUser(
          uid: 'user123',
          email: 'test@example.com',
          name: 'Test User',
          createdAt: testCreatedAt,
          lastLoginAt: testLastLoginAt,
          metadata: metadata,
        );

        final firestoreMap = user.toFirestore();
        final metadataMap = firestoreMap['metadata'] as Map<String, dynamic>;

        expect(metadataMap['loginCount'], equals(5));
        expect(metadataMap['lastLoginIp'], equals('192.168.1.1'));
        expect(metadataMap['devices'], isA<List>());
        expect((metadataMap['devices'] as List).length, equals(1));
      });

      test('fromFirestore() deserializes user correctly', () async {
        final fakeFirestore = FakeFirebaseFirestore();
        final userRef = fakeFirestore.collection('users').doc('user123');

        await userRef.set({
          'email': 'test@example.com',
          'name': 'Test User',
          'createdAt': Timestamp.fromDate(testCreatedAt),
          'lastLoginAt': Timestamp.fromDate(testLastLoginAt),
          'deletedAt': null,
          'metadata': {
            'loginCount': 3,
            'devices': [],
            'lastLoginIp': null,
            'lastLoginUserAgent': null,
          },
        });

        final doc = await userRef.get();
        final user = AppUser.fromFirestore(doc);

        expect(user.uid, equals('user123'));
        expect(user.email, equals('test@example.com'));
        expect(user.name, equals('Test User'));
        expect(user.createdAt.year, equals(testCreatedAt.year));
        expect(user.createdAt.month, equals(testCreatedAt.month));
        expect(user.createdAt.day, equals(testCreatedAt.day));
        expect(user.deletedAt, isNull);
        expect(user.metadata.loginCount, equals(3));
      });

      test('fromFirestore() handles deletedAt timestamp', () async {
        final fakeFirestore = FakeFirebaseFirestore();
        final userRef = fakeFirestore.collection('users').doc('user123');

        await userRef.set({
          'email': 'test@example.com',
          'name': 'Test User',
          'createdAt': Timestamp.fromDate(testCreatedAt),
          'lastLoginAt': Timestamp.fromDate(testLastLoginAt),
          'deletedAt': Timestamp.fromDate(testDeletedAt),
          'metadata': {
            'loginCount': 0,
            'devices': [],
          },
        });

        final doc = await userRef.get();
        final user = AppUser.fromFirestore(doc);

        expect(user.deletedAt, isNotNull);
        expect(user.deletedAt!.year, equals(testDeletedAt.year));
        expect(user.isDeleted, isTrue);
      });

      test('fromFirestore() handles missing metadata', () async {
        final fakeFirestore = FakeFirebaseFirestore();
        final userRef = fakeFirestore.collection('users').doc('user123');

        await userRef.set({
          'email': 'test@example.com',
          'name': 'Test User',
          'createdAt': Timestamp.fromDate(testCreatedAt),
          'lastLoginAt': Timestamp.fromDate(testLastLoginAt),
          'deletedAt': null,
          // metadata is missing
        });

        final doc = await userRef.get();
        final user = AppUser.fromFirestore(doc);

        expect(user.metadata, isNotNull);
        expect(user.metadata.loginCount, equals(0));
        expect(user.metadata.devices, isEmpty);
      });
    });

    group('AppUser round-trip serialization', () {
      test('toFirestore() and fromFirestore() preserve data', () async {
        final originalUser = AppUser(
          uid: 'user123',
          email: 'test@example.com',
          name: 'Test User',
          createdAt: testCreatedAt,
          lastLoginAt: testLastLoginAt,
        );

        final fakeFirestore = FakeFirebaseFirestore();
        final userRef = fakeFirestore.collection('users').doc('user123');

        await userRef.set(originalUser.toFirestore());
        final doc = await userRef.get();
        final deserializedUser = AppUser.fromFirestore(doc);

        expect(deserializedUser.uid, equals(originalUser.uid));
        expect(deserializedUser.email, equals(originalUser.email));
        expect(deserializedUser.name, equals(originalUser.name));
        expect(deserializedUser.deletedAt, equals(originalUser.deletedAt));
      });

      test('round-trip with deletedAt preserves data', () async {
        final originalUser = AppUser(
          uid: 'user123',
          email: 'test@example.com',
          name: 'Test User',
          createdAt: testCreatedAt,
          lastLoginAt: testLastLoginAt,
          deletedAt: testDeletedAt,
        );

        final fakeFirestore = FakeFirebaseFirestore();
        final userRef = fakeFirestore.collection('users').doc('user123');

        await userRef.set(originalUser.toFirestore());
        final doc = await userRef.get();
        final deserializedUser = AppUser.fromFirestore(doc);

        expect(deserializedUser.isDeleted, equals(originalUser.isDeleted));
        expect(deserializedUser.deletedAt, isNotNull);
      });
    });

    group('AppUser copyWith', () {
      test('copyWith() creates copy with updated fields', () {
        final user = AppUser(
          uid: 'user123',
          email: 'test@example.com',
          name: 'Test User',
          createdAt: testCreatedAt,
          lastLoginAt: testLastLoginAt,
        );

        final updated = user.copyWith(
          name: 'Updated Name',
          lastLoginAt: testDeletedAt,
        );

        expect(updated.uid, equals(user.uid));
        expect(updated.email, equals(user.email));
        expect(updated.name, equals('Updated Name'));
        expect(updated.lastLoginAt, equals(testDeletedAt));
        expect(updated.createdAt, equals(user.createdAt));
      });

      test('copyWith() can set deletedAt', () {
        final user = AppUser(
          uid: 'user123',
          email: 'test@example.com',
          name: 'Test User',
          createdAt: testCreatedAt,
          lastLoginAt: testLastLoginAt,
        );

        final deleted = user.copyWith(deletedAt: testDeletedAt);

        expect(deleted.isDeleted, isTrue);
        expect(deleted.deletedAt, equals(testDeletedAt));
      });

      test('copyWith() preserves original when no changes', () {
        final user = AppUser(
          uid: 'user123',
          email: 'test@example.com',
          name: 'Test User',
          createdAt: testCreatedAt,
          lastLoginAt: testLastLoginAt,
        );

        final copy = user.copyWith();

        expect(copy.uid, equals(user.uid));
        expect(copy.email, equals(user.email));
        expect(copy.name, equals(user.name));
        expect(copy.createdAt, equals(user.createdAt));
        expect(copy.lastLoginAt, equals(user.lastLoginAt));
      });
    });

    group('AppUser equality and toString', () {
      test('equality is based on uid', () {
        final user1 = AppUser(
          uid: 'user123',
          email: 'test@example.com',
          name: 'Test User',
          createdAt: testCreatedAt,
          lastLoginAt: testLastLoginAt,
        );

        final user2 = AppUser(
          uid: 'user123',
          email: 'different@example.com',
          name: 'Different Name',
          createdAt: testCreatedAt,
          lastLoginAt: testLastLoginAt,
        );

        expect(user1, equals(user2));
        expect(user1.hashCode, equals(user2.hashCode));
      });

      test('inequality when uid differs', () {
        final user1 = AppUser(
          uid: 'user123',
          email: 'test@example.com',
          name: 'Test User',
          createdAt: testCreatedAt,
          lastLoginAt: testLastLoginAt,
        );

        final user2 = AppUser(
          uid: 'user456',
          email: 'test@example.com',
          name: 'Test User',
          createdAt: testCreatedAt,
          lastLoginAt: testLastLoginAt,
        );

        expect(user1, isNot(equals(user2)));
      });

      test('toString() includes key information', () {
        final user = AppUser(
          uid: 'user123',
          email: 'test@example.com',
          name: 'Test User',
          createdAt: testCreatedAt,
          lastLoginAt: testLastLoginAt,
        );

        final str = user.toString();

        expect(str, contains('user123'));
        expect(str, contains('test@example.com'));
        expect(str, contains('Test User'));
        expect(str, contains('isActive: true'));
      });

      test('toString() shows isActive: false for deleted user', () {
        final user = AppUser(
          uid: 'user123',
          email: 'test@example.com',
          name: 'Test User',
          createdAt: testCreatedAt,
          lastLoginAt: testLastLoginAt,
          deletedAt: testDeletedAt,
        );

        final str = user.toString();

        expect(str, contains('isActive: false'));
      });
    });
  });

  group('UserMetadata Tests', () {
    late DateTime testFirstSeen;
    late DateTime testLastSeen;

    setUp(() {
      testFirstSeen = DateTime(2025, 1, 1);
      testLastSeen = DateTime(2025, 1, 15);
    });

    group('UserMetadata creation', () {
      test('creates metadata with default values', () {
        final metadata = UserMetadata();

        expect(metadata.loginCount, equals(0));
        expect(metadata.devices, isEmpty);
        expect(metadata.lastLoginIp, isNull);
        expect(metadata.lastLoginUserAgent, isNull);
      });

      test('creates metadata with custom values', () {
        final devices = [
          DeviceInfo(
            deviceId: 'device1',
            deviceName: 'Test Device',
            firstSeen: testFirstSeen,
            lastSeen: testLastSeen,
          ),
        ];

        final metadata = UserMetadata(
          loginCount: 5,
          devices: devices,
          lastLoginIp: '192.168.1.1',
          lastLoginUserAgent: 'Test Agent',
        );

        expect(metadata.loginCount, equals(5));
        expect(metadata.devices.length, equals(1));
        expect(metadata.lastLoginIp, equals('192.168.1.1'));
        expect(metadata.lastLoginUserAgent, equals('Test Agent'));
      });
    });

    group('UserMetadata serialization', () {
      test('toMap() converts metadata to map', () {
        final device = DeviceInfo(
          deviceId: 'device1',
          deviceName: 'Test Device',
          firstSeen: testFirstSeen,
          lastSeen: testLastSeen,
        );

        final metadata = UserMetadata(
          loginCount: 5,
          devices: [device],
          lastLoginIp: '192.168.1.1',
          lastLoginUserAgent: 'Test Agent',
        );

        final map = metadata.toMap();

        expect(map['loginCount'], equals(5));
        expect(map['devices'], isA<List>());
        expect((map['devices'] as List).length, equals(1));
        expect(map['lastLoginIp'], equals('192.168.1.1'));
        expect(map['lastLoginUserAgent'], equals('Test Agent'));
      });

      test('fromMap() deserializes metadata correctly', () {
        final map = {
          'loginCount': 5,
          'devices': [
            {
              'deviceId': 'device1',
              'deviceName': 'Test Device',
              'firstSeen': Timestamp.fromDate(testFirstSeen),
              'lastSeen': Timestamp.fromDate(testLastSeen),
            }
          ],
          'lastLoginIp': '192.168.1.1',
          'lastLoginUserAgent': 'Test Agent',
        };

        final metadata = UserMetadata.fromMap(map);

        expect(metadata.loginCount, equals(5));
        expect(metadata.devices.length, equals(1));
        expect(metadata.devices[0].deviceId, equals('device1'));
        expect(metadata.lastLoginIp, equals('192.168.1.1'));
        expect(metadata.lastLoginUserAgent, equals('Test Agent'));
      });

      test('fromMap() handles missing fields with defaults', () {
        final map = <String, dynamic>{};

        final metadata = UserMetadata.fromMap(map);

        expect(metadata.loginCount, equals(0));
        expect(metadata.devices, isEmpty);
        expect(metadata.lastLoginIp, isNull);
        expect(metadata.lastLoginUserAgent, isNull);
      });

      test('fromMap() handles null devices list', () {
        final map = {
          'loginCount': 5,
          'devices': null,
        };

        final metadata = UserMetadata.fromMap(map);

        expect(metadata.loginCount, equals(5));
        expect(metadata.devices, isEmpty);
      });
    });

    group('UserMetadata copyWith', () {
      test('copyWith() updates specified fields', () {
        final metadata = UserMetadata(
          loginCount: 5,
          lastLoginIp: '192.168.1.1',
        );

        final updated = metadata.copyWith(
          loginCount: 10,
          lastLoginUserAgent: 'New Agent',
        );

        expect(updated.loginCount, equals(10));
        expect(updated.lastLoginIp, equals('192.168.1.1'));
        expect(updated.lastLoginUserAgent, equals('New Agent'));
      });

      test('copyWith() preserves original when no changes', () {
        final metadata = UserMetadata(
          loginCount: 5,
          lastLoginIp: '192.168.1.1',
        );

        final copy = metadata.copyWith();

        expect(copy.loginCount, equals(metadata.loginCount));
        expect(copy.lastLoginIp, equals(metadata.lastLoginIp));
      });
    });
  });

  group('DeviceInfo Tests', () {
    late DateTime testFirstSeen;
    late DateTime testLastSeen;

    setUp(() {
      testFirstSeen = DateTime(2025, 1, 1);
      testLastSeen = DateTime(2025, 1, 15);
    });

    group('DeviceInfo creation', () {
      test('creates device with all fields', () {
        final device = DeviceInfo(
          deviceId: 'device123',
          deviceName: 'Test Device',
          firstSeen: testFirstSeen,
          lastSeen: testLastSeen,
        );

        expect(device.deviceId, equals('device123'));
        expect(device.deviceName, equals('Test Device'));
        expect(device.firstSeen, equals(testFirstSeen));
        expect(device.lastSeen, equals(testLastSeen));
      });

      test('creates device with null deviceName', () {
        final device = DeviceInfo(
          deviceId: 'device123',
          firstSeen: testFirstSeen,
          lastSeen: testLastSeen,
        );

        expect(device.deviceName, isNull);
      });
    });

    group('DeviceInfo serialization', () {
      test('toMap() converts device to map', () {
        final device = DeviceInfo(
          deviceId: 'device123',
          deviceName: 'Test Device',
          firstSeen: testFirstSeen,
          lastSeen: testLastSeen,
        );

        final map = device.toMap();

        expect(map['deviceId'], equals('device123'));
        expect(map['deviceName'], equals('Test Device'));
        expect(map['firstSeen'], isA<Timestamp>());
        expect(map['lastSeen'], isA<Timestamp>());
      });

      test('toMap() includes null deviceName', () {
        final device = DeviceInfo(
          deviceId: 'device123',
          firstSeen: testFirstSeen,
          lastSeen: testLastSeen,
        );

        final map = device.toMap();

        expect(map['deviceName'], isNull);
      });

      test('fromMap() deserializes device correctly', () {
        final map = {
          'deviceId': 'device123',
          'deviceName': 'Test Device',
          'firstSeen': Timestamp.fromDate(testFirstSeen),
          'lastSeen': Timestamp.fromDate(testLastSeen),
        };

        final device = DeviceInfo.fromMap(map);

        expect(device.deviceId, equals('device123'));
        expect(device.deviceName, equals('Test Device'));
        expect(device.firstSeen.year, equals(testFirstSeen.year));
        expect(device.lastSeen.year, equals(testLastSeen.year));
      });

      test('fromMap() handles null deviceName', () {
        final map = {
          'deviceId': 'device123',
          'deviceName': null,
          'firstSeen': Timestamp.fromDate(testFirstSeen),
          'lastSeen': Timestamp.fromDate(testLastSeen),
        };

        final device = DeviceInfo.fromMap(map);

        expect(device.deviceName, isNull);
      });
    });

    group('DeviceInfo round-trip serialization', () {
      test('toMap() and fromMap() preserve data', () {
        final original = DeviceInfo(
          deviceId: 'device123',
          deviceName: 'Test Device',
          firstSeen: testFirstSeen,
          lastSeen: testLastSeen,
        );

        final map = original.toMap();
        final deserialized = DeviceInfo.fromMap(map);

        expect(deserialized.deviceId, equals(original.deviceId));
        expect(deserialized.deviceName, equals(original.deviceName));
      });
    });
  });
}
