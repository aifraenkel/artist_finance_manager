import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a project in the application.
///
/// Projects allow artists to organize their finances by different art projects.
/// Each project has its own set of transactions (income and expenses).
class Project {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime? deletedAt;

  Project({
    required this.id,
    required this.name,
    required this.createdAt,
    this.deletedAt,
  });

  /// Check if project is active (not soft-deleted)
  bool get isActive => deletedAt == null;

  /// Check if project is deleted
  bool get isDeleted => deletedAt != null;

  /// Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  /// Create from JSON (local storage)
  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
    };
  }

  /// Create from Firestore document
  factory Project.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Project(
      id: doc.id,
      name: data['name'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      deletedAt: data['deletedAt'] != null
          ? (data['deletedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Create a copy with updated fields
  Project copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Project && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Project(id: $id, name: $name, isActive: $isActive)';
  }
}
