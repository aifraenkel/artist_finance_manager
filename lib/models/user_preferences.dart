import 'package:cloud_firestore/cloud_firestore.dart';

/// Supported languages in the application
enum AppLanguage {
  english('en', 'English'),
  spanish('es', 'Spanish'),
  catalan('ca', 'Catalan');

  final String code;
  final String displayName;

  const AppLanguage(this.code, this.displayName);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}

/// Supported currencies in the application
enum AppCurrency {
  eur('EUR', '€', 'Euro'),
  usd('USD', '\$', 'US Dollar');

  final String code;
  final String symbol;
  final String displayName;

  const AppCurrency(this.code, this.symbol, this.displayName);

  static AppCurrency fromCode(String code) {
    return AppCurrency.values.firstWhere(
      (curr) => curr.code == code,
      orElse: () => AppCurrency.eur,
    );
  }
}

/// User preferences for language and currency settings
///
/// This model stores user-specific preferences in Firestore.
/// Each user has a single preferences document.
class UserPreferencesModel {
  final String userId;
  final AppLanguage language;
  final AppCurrency currency;
  final DateTime updatedAt;
  final double? conversionRate; // Stores last known conversion rate EUR->USD

  UserPreferencesModel({
    required this.userId,
    required this.language,
    required this.currency,
    required this.updatedAt,
    this.conversionRate,
  });

  /// Default preferences for new users (English, EUR)
  factory UserPreferencesModel.defaultPreferences(String userId) {
    return UserPreferencesModel(
      userId: userId,
      language: AppLanguage.english,
      currency: AppCurrency.eur,
      updatedAt: DateTime.now(),
      conversionRate: null,
    );
  }

  /// Create from Firestore document
  factory UserPreferencesModel.fromFirestore(
      String userId, Map<String, dynamic> data) {
    return UserPreferencesModel(
      userId: userId,
      language: AppLanguage.fromCode(data['language'] as String? ?? 'en'),
      currency: AppCurrency.fromCode(data['currency'] as String? ?? 'EUR'),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      conversionRate: data['conversionRate'] as double?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'language': language.code,
      'currency': currency.code,
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (conversionRate != null) 'conversionRate': conversionRate,
    };
  }

  /// Create a copy with updated fields
  UserPreferencesModel copyWith({
    String? userId,
    AppLanguage? language,
    AppCurrency? currency,
    DateTime? updatedAt,
    double? conversionRate,
  }) {
    return UserPreferencesModel(
      userId: userId ?? this.userId,
      language: language ?? this.language,
      currency: currency ?? this.currency,
      updatedAt: updatedAt ?? this.updatedAt,
      conversionRate: conversionRate ?? this.conversionRate,
    );
  }

  @override
  String toString() {
    return 'UserPreferences(userId: $userId, language: ${language.displayName}, currency: ${currency.code})';
  }
}
