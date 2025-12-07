/// Represents a user's financial budget goal
///
/// This model stores the user's natural language financial goal
/// and tracks whether the goal is currently active.
class BudgetGoal {
  /// The financial goal in natural language
  /// Example: "I want to have a positive balance of 200€ per month"
  final String goalText;

  /// Whether the goal is currently active for analysis
  final bool isActive;

  /// When the goal was created
  final DateTime createdAt;

  /// When the goal was last updated
  final DateTime? updatedAt;

  BudgetGoal({
    required this.goalText,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create a BudgetGoal from a map (for storage)
  factory BudgetGoal.fromMap(Map<String, dynamic> map) {
    return BudgetGoal(
      goalText: map['goalText'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : null,
    );
  }

  /// Convert BudgetGoal to a map (for storage)
  Map<String, dynamic> toMap() {
    return {
      'goalText': goalText,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  /// Create a copy of BudgetGoal with updated fields
  BudgetGoal copyWith({
    String? goalText,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetGoal(
      goalText: goalText ?? this.goalText,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if the goal is empty
  bool get isEmpty => goalText.trim().isEmpty;

  /// Check if the goal is valid
  bool get isValid => goalText.trim().isNotEmpty;

  @override
  String toString() {
    return 'BudgetGoal(goalText: $goalText, isActive: $isActive, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BudgetGoal &&
        other.goalText == goalText &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return goalText.hashCode ^
        isActive.hashCode ^
        createdAt.hashCode ^
        (updatedAt?.hashCode ?? 0);
  }
}
