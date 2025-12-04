import 'package:flutter_test/flutter_test.dart';
import 'package:artist_finance_manager/services/openai_service.dart';

void main() {
  group('OpenAIService', () {
    test('should throw exception when API key is empty', () async {
      final service = OpenAIService(apiKey: '');

      expect(
        () => service.analyzeGoal('test prompt'),
        throwsA(isA<OpenAIException>()),
      );
    });

    test('OpenAIException should have meaningful message', () {
      final exception = OpenAIException('Test error message');

      expect(exception.message, 'Test error message');
      expect(exception.toString(), 'OpenAIException: Test error message');
    });

    test('should create service with API key', () {
      final service = OpenAIService(apiKey: 'sk-test-key');

      expect(service.apiKey, 'sk-test-key');
    });
  });
}
