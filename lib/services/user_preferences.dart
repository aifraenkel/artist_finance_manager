import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget_goal.dart';

/// Service for managing user preferences including analytics consent and budget goals
///
/// Stores user consent preferences for data collection and analytics.
/// Also manages budget goal storage and retrieval.
/// Default is privacy-first (no tracking without explicit consent).
class UserPreferences {
  static const String _analyticsConsentKey = 'analytics_consent';
  static const String _consentTimestampKey = 'consent_timestamp';
  static const String _budgetGoalTextKey = 'budget_goal_text';
  static const String _budgetGoalActiveKey = 'budget_goal_active';
  static const String _budgetGoalCreatedAtKey = 'budget_goal_created_at';
  static const String _budgetGoalUpdatedAtKey = 'budget_goal_updated_at';
  static const String _openaiApiKeyKey = 'openai_api_key';

  bool _analyticsConsent = false;
  DateTime? _consentTimestamp;
  BudgetGoal? _budgetGoal;
  String? _openaiApiKey;

  /// Whether the user has consented to analytics tracking
  bool get analyticsConsent => _analyticsConsent;

  /// When the user last updated their consent preference
  DateTime? get consentTimestamp => _consentTimestamp;

  /// Whether the consent prompt has been shown to the user
  bool get hasSeenConsentPrompt => _consentTimestamp != null;

  /// The user's budget goal (if set)
  BudgetGoal? get budgetGoal => _budgetGoal;

  /// The OpenAI API key for budget analysis
  String? get openaiApiKey => _openaiApiKey;

  /// Initialize and load preferences from storage
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _analyticsConsent = prefs.getBool(_analyticsConsentKey) ?? false;

    final timestampMillis = prefs.getInt(_consentTimestampKey);
    if (timestampMillis != null) {
      _consentTimestamp = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
    }

    // Load budget goal
    final goalText = prefs.getString(_budgetGoalTextKey);
    if (goalText != null && goalText.isNotEmpty) {
      final isActive = prefs.getBool(_budgetGoalActiveKey) ?? false;
      final createdAt = prefs.getInt(_budgetGoalCreatedAtKey);
      final updatedAt = prefs.getInt(_budgetGoalUpdatedAtKey);

      _budgetGoal = BudgetGoal(
        goalText: goalText,
        isActive: isActive,
        createdAt: createdAt != null
            ? DateTime.fromMillisecondsSinceEpoch(createdAt)
            : DateTime.now(),
        updatedAt: updatedAt != null
            ? DateTime.fromMillisecondsSinceEpoch(updatedAt)
            : null,
      );
    }

    // Load OpenAI API key
    _openaiApiKey = prefs.getString(_openaiApiKeyKey);
  }

  /// Set analytics consent preference
  ///
  /// [consent] - true to enable analytics, false to disable
  Future<void> setAnalyticsConsent(bool consent) async {
    _analyticsConsent = consent;
    _consentTimestamp = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_analyticsConsentKey, consent);
    await prefs.setInt(
        _consentTimestampKey, _consentTimestamp!.millisecondsSinceEpoch);
  }

  /// Save or update the user's budget goal
  ///
  /// [goal] - the budget goal to save
  Future<void> setBudgetGoal(BudgetGoal goal) async {
    _budgetGoal = goal;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_budgetGoalTextKey, goal.goalText);
    await prefs.setBool(_budgetGoalActiveKey, goal.isActive);
    await prefs.setInt(
        _budgetGoalCreatedAtKey, goal.createdAt.millisecondsSinceEpoch);
    if (goal.updatedAt != null) {
      await prefs.setInt(
          _budgetGoalUpdatedAtKey, goal.updatedAt!.millisecondsSinceEpoch);
    }
  }

  /// Clear the user's budget goal
  Future<void> clearBudgetGoal() async {
    _budgetGoal = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_budgetGoalTextKey);
    await prefs.remove(_budgetGoalActiveKey);
    await prefs.remove(_budgetGoalCreatedAtKey);
    await prefs.remove(_budgetGoalUpdatedAtKey);
  }

  /// Set the OpenAI API key
  ///
  /// [apiKey] - the OpenAI API key
  Future<void> setOpenaiApiKey(String apiKey) async {
    _openaiApiKey = apiKey;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_openaiApiKeyKey, apiKey);
  }

  /// Clear the OpenAI API key
  Future<void> clearOpenaiApiKey() async {
    _openaiApiKey = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_openaiApiKeyKey);
  }

  /// Reset all preferences (useful for testing)
  Future<void> reset() async {
    _analyticsConsent = false;
    _consentTimestamp = null;
    _budgetGoal = null;
    _openaiApiKey = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_analyticsConsentKey);
    await prefs.remove(_consentTimestampKey);
    await prefs.remove(_budgetGoalTextKey);
    await prefs.remove(_budgetGoalActiveKey);
    await prefs.remove(_budgetGoalCreatedAtKey);
    await prefs.remove(_budgetGoalUpdatedAtKey);
    await prefs.remove(_openaiApiKeyKey);
  }
}
