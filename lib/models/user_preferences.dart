import 'package:cloud_firestore/cloud_firestore.dart';

/// Sentinel value for optional parameters in copyWith
class _Undefined {
  const _Undefined();
}

const _undefined = _Undefined();

/// Supported languages in the application
enum AppLanguage {
  english('en', 'English'),
  german('de', 'Deutsch'),
  spanish('es', 'Español');

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
  final double?
      conversionRate; // Stores last known conversion rate when currency was changed

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
  ///
  /// To explicitly set conversionRate to null, pass conversionRate: null
  /// To keep the existing value, don't pass conversionRate at all
  UserPreferencesModel copyWith({
    String? userId,
    AppLanguage? language,
    AppCurrency? currency,
    DateTime? updatedAt,
    Object? conversionRate = _undefined,
  }) {
    return UserPreferencesModel(
      userId: userId ?? this.userId,
      language: language ?? this.language,
      currency: currency ?? this.currency,
      updatedAt: updatedAt ?? this.updatedAt,
      conversionRate: conversionRate == _undefined
          ? this.conversionRate
          : conversionRate as double?,
    );
  }

  @override
  String toString() {
    return 'UserPreferences(userId: $userId, language: ${language.displayName}, currency: ${currency.code})';
  }
}
