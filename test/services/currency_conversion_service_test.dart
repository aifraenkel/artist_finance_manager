import 'package:flutter_test/flutter_test.dart';
import 'package:artist_finance_manager/services/currency_conversion_service.dart';

void main() {
  group('CurrencyConversionService', () {
    late CurrencyConversionService service;

    setUp(() {
      service = CurrencyConversionService();
    });

    test('should convert same currency without change', () async {
      final result = await service.convertCurrency(100, 'EUR', 'EUR');
      expect(result, 100);
    });

    test('should convert EUR to USD with rate', () async {
      final result = await service.convertEurToUsd(100, rate: 1.10);
      expect(result, closeTo(110, 0.01));
    });

    test('should convert USD to EUR with rate', () async {
      final result = await service.convertUsdToEur(110, rate: 0.91);
      expect(result, closeTo(100.1, 0.1));
    });

    test('should convert currency with provided rate', () async {
      final result = await service.convertCurrency(
        100,
        'EUR',
        'USD',
        rate: 1.12,
      );
      expect(result, closeTo(112, 0.01));
    });

    // Note: Real API tests are commented out as they require network access
    // and may fail in CI environment. Uncomment to test manually.
    
    // test('should fetch EUR to USD rate from API', () async {
    //   final rate = await service.getEurToUsdRate();
    //   expect(rate, isNotNull);
    //   expect(rate, greaterThan(0));
    // });

    // test('should fetch USD to EUR rate from API', () async {
    //   final rate = await service.getUsdToEurRate();
    //   expect(rate, isNotNull);
    //   expect(rate, greaterThan(0));
    // });

    // test('should convert EUR to USD using live rate', () async {
    //   final result = await service.convertEurToUsd(100);
    //   expect(result, isNotNull);
    //   expect(result, greaterThan(0));
    // });

    // test('should convert USD to EUR using live rate', () async {
    //   final result = await service.convertUsdToEur(100);
    //   expect(result, isNotNull);
    //   expect(result, greaterThan(0));
    // });
  });
}
