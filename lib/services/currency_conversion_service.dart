import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for fetching currency conversion rates from Frankfurter API
///
/// Uses the free Frankfurter API (https://frankfurter.dev/) which provides
/// exchange rates from the European Central Bank.
class CurrencyConversionService {
  static const String _baseUrl = 'https://api.frankfurter.app';

  /// Get the latest conversion rate from EUR to USD
  ///
  /// Returns the conversion rate, or null if the request fails.
  /// The rate represents how many USD = 1 EUR
  Future<double?> getEurToUsdRate() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/latest?from=EUR&to=USD'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>;
        return rates['USD'] as double;
      } else {
        print('Failed to fetch conversion rate: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching conversion rate: $e');
      return null;
    }
  }

  /// Get the latest conversion rate from USD to EUR
  ///
  /// Returns the conversion rate, or null if the request fails.
  /// The rate represents how many EUR = 1 USD
  Future<double?> getUsdToEurRate() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/latest?from=USD&to=EUR'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>;
        return rates['EUR'] as double;
      } else {
        print('Failed to fetch conversion rate: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching conversion rate: $e');
      return null;
    }
  }

  /// Convert an amount from EUR to USD
  ///
  /// [amount] - Amount in EUR
  /// [rate] - Optional conversion rate. If not provided, fetches the latest rate
  /// Returns the converted amount in USD, or null if conversion fails
  Future<double?> convertEurToUsd(double amount, {double? rate}) async {
    final conversionRate = rate ?? await getEurToUsdRate();
    if (conversionRate == null) return null;
    return amount * conversionRate;
  }

  /// Convert an amount from USD to EUR
  ///
  /// [amount] - Amount in USD
  /// [rate] - Optional conversion rate. If not provided, fetches the latest rate
  /// Returns the converted amount in EUR, or null if conversion fails
  Future<double?> convertUsdToEur(double amount, {double? rate}) async {
    final conversionRate = rate ?? await getUsdToEurRate();
    if (conversionRate == null) return null;
    return amount * conversionRate;
  }

  /// Convert amount from one currency to another
  ///
  /// [amount] - Amount to convert
  /// [fromCurrency] - Source currency code (EUR or USD)
  /// [toCurrency] - Target currency code (EUR or USD)
  /// [rate] - Optional conversion rate
  /// Returns the converted amount, or null if conversion fails
  Future<double?> convertCurrency(
    double amount,
    String fromCurrency,
    String toCurrency, {
    double? rate,
  }) async {
    // If same currency, no conversion needed
    if (fromCurrency == toCurrency) return amount;

    if (fromCurrency == 'EUR' && toCurrency == 'USD') {
      return convertEurToUsd(amount, rate: rate);
    } else if (fromCurrency == 'USD' && toCurrency == 'EUR') {
      return convertUsdToEur(amount, rate: rate);
    }

    return null;
  }
}
