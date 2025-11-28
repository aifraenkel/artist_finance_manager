import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user in the application
///
/// This model stores user profile information and metadata in Firestore.
/// Users are soft-deleted by setting [deletedAt] timestamp.
class AppUser {
  final String uid;
  final String email;
  final String name;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final DateTime? deletedAt;
  final UserMetadata metadata;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.createdAt,
    required this.lastLoginAt,
    this.deletedAt,
    UserMetadata? metadata,
  }) : metadata = metadata ?? UserMetadata();

  /// Check if user account is active (not soft-deleted)
  bool get isActive => deletedAt == null;

  /// Check if user account is deleted
  bool get isDeleted => deletedAt != null;

  /// Create AppUser from Firestore document
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] as String,
      name: data['name'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp).toDate(),
      deletedAt: data['deletedAt'] != null
          ? (data['deletedAt'] as Timestamp).toDate()
          : null,
      metadata: data['metadata'] != null
          ? UserMetadata.fromMap(data['metadata'] as Map<String, dynamic>)
          : UserMetadata(),
    );
  }

  /// Convert AppUser to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'metadata': metadata.toMap(),
    };
  }

  /// Create a copy of AppUser with updated fields
  AppUser copyWith({
    String? uid,
    String? email,
    String? name,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    DateTime? deletedAt,
    UserMetadata? metadata,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      deletedAt: deletedAt ?? this.deletedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'AppUser(uid: $uid, email: $email, name: $name, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppUser && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}

/// User metadata for tracking login history and device information
class UserMetadata {
  final int loginCount;
  final List<DeviceInfo> devices;
  final String? lastLoginIp;
  final String? lastLoginUserAgent;

  UserMetadata({
    this.loginCount = 0,
    List<DeviceInfo>? devices,
    this.lastLoginIp,
    this.lastLoginUserAgent,
  }) : devices = devices ?? [];

  factory UserMetadata.fromMap(Map<String, dynamic> map) {
    return UserMetadata(
      loginCount: map['loginCount'] as int? ?? 0,
      devices: (map['devices'] as List<dynamic>?)
              ?.map((d) => DeviceInfo.fromMap(d as Map<String, dynamic>))
              .toList() ??
          [],
      lastLoginIp: map['lastLoginIp'] as String?,
      lastLoginUserAgent: map['lastLoginUserAgent'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'loginCount': loginCount,
      'devices': devices.map((d) => d.toMap()).toList(),
      'lastLoginIp': lastLoginIp,
      'lastLoginUserAgent': lastLoginUserAgent,
    };
  }

  UserMetadata copyWith({
    int? loginCount,
    List<DeviceInfo>? devices,
    String? lastLoginIp,
    String? lastLoginUserAgent,
  }) {
    return UserMetadata(
      loginCount: loginCount ?? this.loginCount,
      devices: devices ?? this.devices,
      lastLoginIp: lastLoginIp ?? this.lastLoginIp,
      lastLoginUserAgent: lastLoginUserAgent ?? this.lastLoginUserAgent,
    );
  }
}

/// Device information for tracking user logins
class DeviceInfo {
  final String deviceId;
  final String? deviceName;
  final DateTime firstSeen;
  final DateTime lastSeen;

  DeviceInfo({
    required this.deviceId,
    this.deviceName,
    required this.firstSeen,
    required this.lastSeen,
  });

  factory DeviceInfo.fromMap(Map<String, dynamic> map) {
    return DeviceInfo(
      deviceId: map['deviceId'] as String,
      deviceName: map['deviceName'] as String?,
      firstSeen: (map['firstSeen'] as Timestamp).toDate(),
      lastSeen: (map['lastSeen'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'firstSeen': Timestamp.fromDate(firstSeen),
      'lastSeen': Timestamp.fromDate(lastSeen),
    };
  }
}
