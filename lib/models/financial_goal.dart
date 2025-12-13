import 'package:cloud_firestore/cloud_firestore.dart';

/// Email cadence options for goal progress updates
enum EmailCadence {
  daily('daily'),
  weekly('weekly'),
  biweekly('biweekly'),
  monthly('monthly'),
  never('never');

  final String value;
  const EmailCadence(this.value);

  static EmailCadence fromString(String value) {
    return EmailCadence.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EmailCadence.never,
    );
  }
}

/// Represents a user's financial goal
///
/// Stored in Firestore at: users/{userId}/financialGoal (single document)
class FinancialGoal {
  /// User's goal description (max 2000 characters)
  final String goal;

  /// Target date for achieving the goal
  final DateTime dueDate;

  /// How often the user wants progress update emails
  final EmailCadence emailCadence;

  /// When the goal was created
  final DateTime createdAt;

  /// When the goal was last updated
  final DateTime updatedAt;

  FinancialGoal({
    required this.goal,
    required this.dueDate,
    required this.emailCadence,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory FinancialGoal.fromFirestore(Map<String, dynamic> data) {
    return FinancialGoal(
      goal: data['goal'] as String? ?? '',
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      emailCadence:
          EmailCadence.fromString(data['emailCadence'] as String? ?? 'never'),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'goal': goal,
      'dueDate': Timestamp.fromDate(dueDate),
      'emailCadence': emailCadence.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  FinancialGoal copyWith({
    String? goal,
    DateTime? dueDate,
    EmailCadence? emailCadence,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FinancialGoal(
      goal: goal ?? this.goal,
      dueDate: dueDate ?? this.dueDate,
      emailCadence: emailCadence ?? this.emailCadence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if the goal text is valid
  bool get isValid => goal.trim().isNotEmpty && goal.length <= 2000;

  @override
  String toString() {
    return 'FinancialGoal(goal: $goal, dueDate: $dueDate, emailCadence: ${emailCadence.value})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FinancialGoal &&
        other.goal == goal &&
        other.dueDate == dueDate &&
        other.emailCadence == emailCadence &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return goal.hashCode ^
        dueDate.hashCode ^
        emailCadence.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
