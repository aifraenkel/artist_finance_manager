import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/financial_goal.dart';

/// Service for managing financial goals in Firestore
///
/// Handles CRUD operations for user financial goals.
/// Each user has a single goal document at: users/{userId}/financialGoal
class FinancialGoalService {
  final FirebaseFirestore _firestore;

  FinancialGoalService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get the document reference for a user's financial goal
  DocumentReference<Map<String, dynamic>> _getGoalDoc(String userId) {
    return _firestore.collection('users').doc(userId).collection('financialGoal').doc('current');
  }

  /// Get the user's financial goal
  ///
  /// Returns null if no goal is set
  Future<FinancialGoal?> getGoal(String userId) async {
    try {
      final doc = await _getGoalDoc(userId).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return FinancialGoal.fromFirestore(doc.data()!);
    } catch (e) {
      throw FinancialGoalException('Failed to get financial goal: $e');
    }
  }

  /// Save a financial goal
  ///
  /// Creates a new goal or updates the existing one
  Future<void> saveGoal(String userId, FinancialGoal goal) async {
    try {
      await _getGoalDoc(userId).set(goal.toFirestore());
    } catch (e) {
      throw FinancialGoalException('Failed to save financial goal: $e');
    }
  }

  /// Update an existing financial goal
  Future<void> updateGoal(String userId, FinancialGoal goal) async {
    try {
      final updatedGoal = goal.copyWith(updatedAt: DateTime.now());
      await _getGoalDoc(userId).update(updatedGoal.toFirestore());
    } catch (e) {
      throw FinancialGoalException('Failed to update financial goal: $e');
    }
  }

  /// Delete the user's financial goal
  Future<void> deleteGoal(String userId) async {
    try {
      await _getGoalDoc(userId).delete();
    } catch (e) {
      throw FinancialGoalException('Failed to delete financial goal: $e');
    }
  }

  /// Check if user has a financial goal set
  Future<bool> hasGoal(String userId) async {
    try {
      final doc = await _getGoalDoc(userId).get();
      return doc.exists && doc.data() != null;
    } catch (e) {
      throw FinancialGoalException('Failed to check for financial goal: $e');
    }
  }

  /// Watch for changes to the user's financial goal
  Stream<FinancialGoal?> watchGoal(String userId) {
    return _getGoalDoc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return FinancialGoal.fromFirestore(snapshot.data()!);
    });
  }
}

/// Exception class for FinancialGoalService errors
class FinancialGoalException implements Exception {
  final String message;

  FinancialGoalException(this.message);

  @override
  String toString() => 'FinancialGoalException: $message';
}
