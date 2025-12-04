import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_preferences.dart';

/// Service for managing user preferences in Firestore
///
/// Handles CRUD operations for user language and currency preferences.
class PreferencesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get user preferences from Firestore
  ///
  /// Returns default preferences if none exist
  Future<UserPreferencesModel> getPreferences(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('settings')
          .get();

      if (doc.exists && doc.data() != null) {
        return UserPreferencesModel.fromFirestore(userId, doc.data()!);
      }

      // Return default preferences if none exist
      return UserPreferencesModel.defaultPreferences(userId);
    } catch (e) {
      print('Error loading preferences: $e');
      // Return default preferences on error
      return UserPreferencesModel.defaultPreferences(userId);
    }
  }

  /// Save user preferences to Firestore
  Future<void> savePreferences(UserPreferencesModel preferences) async {
    try {
      await _firestore
          .collection('users')
          .doc(preferences.userId)
          .collection('preferences')
          .doc('settings')
          .set(preferences.toFirestore());
    } catch (e) {
      print('Error saving preferences: $e');
      rethrow;
    }
  }

  /// Update only the language preference
  Future<void> updateLanguage(String userId, AppLanguage language) async {
    try {
      final preferences = await getPreferences(userId);
      final updated = preferences.copyWith(
        language: language,
        updatedAt: DateTime.now(),
      );
      await savePreferences(updated);
    } catch (e) {
      print('Error updating language: $e');
      rethrow;
    }
  }

  /// Update only the currency preference
  Future<void> updateCurrency(
    String userId,
    AppCurrency currency, {
    double? conversionRate,
  }) async {
    try {
      final preferences = await getPreferences(userId);
      final updated = preferences.copyWith(
        currency: currency,
        updatedAt: DateTime.now(),
        conversionRate: conversionRate,
      );
      await savePreferences(updated);
    } catch (e) {
      print('Error updating currency: $e');
      rethrow;
    }
  }

  /// Initialize default preferences for a new user
  Future<void> initializeDefaultPreferences(String userId) async {
    try {
      // Check if preferences already exist
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('settings')
          .get();

      // Only create if they don't exist
      if (!doc.exists) {
        final defaultPrefs = UserPreferencesModel.defaultPreferences(userId);
        await savePreferences(defaultPrefs);
      }
    } catch (e) {
      print('Error initializing default preferences: $e');
      rethrow;
    }
  }

  /// Migrate existing users to have default preferences
  ///
  /// This should be called once per user when they log in
  /// to ensure all users have preferences set
  Future<void> migrateUserPreferences(String userId) async {
    try {
      await initializeDefaultPreferences(userId);
    } catch (e) {
      print('Error migrating user preferences: $e');
      // Don't rethrow - we don't want to block user login
    }
  }

  /// Stream of user preferences changes
  Stream<UserPreferencesModel> watchPreferences(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('preferences')
        .doc('settings')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserPreferencesModel.fromFirestore(userId, snapshot.data()!);
      }
      return UserPreferencesModel.defaultPreferences(userId);
    });
  }
}
