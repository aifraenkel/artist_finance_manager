import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for interacting with OpenAI API
///
/// Handles communication with OpenAI's chat completion API
/// for budget goal analysis. Includes error handling and logging.
class OpenAIService {
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-3.5-turbo';
  static const int _maxTokens = 500;

  final String apiKey;

  OpenAIService({required this.apiKey});

  /// Analyze budget goal against financial data
  ///
  /// [prompt] - The complete prompt including goal and data
  ///
  /// Returns the AI-generated analysis or throws an exception on error
  Future<String> analyzeGoal(String prompt) async {
    if (apiKey.isEmpty) {
      throw OpenAIException('OpenAI API key is not set');
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a financial advisor helping artists understand their financial performance. Provide clear, concise analysis in a small paragraph (3-5 sentences).',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'max_tokens': _maxTokens,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'] as String?;

        if (content == null || content.isEmpty) {
          throw OpenAIException('Empty response from OpenAI API');
        }

        return content.trim();
      } else if (response.statusCode == 401) {
        throw OpenAIException('Invalid OpenAI API key');
      } else if (response.statusCode == 429) {
        throw OpenAIException(
            'OpenAI API rate limit exceeded. Please try again later.');
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        throw OpenAIException(
          'OpenAI API error (${response.statusCode}): $errorMessage',
        );
      }
    } on http.ClientException catch (e) {
      throw OpenAIException('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw OpenAIException('Invalid response format: ${e.message}');
    } catch (e) {
      if (e is OpenAIException) {
        rethrow;
      }
      throw OpenAIException('Unexpected error: ${e.toString()}');
    }
  }
}

/// Exception class for OpenAI API errors
class OpenAIException implements Exception {
  final String message;

  OpenAIException(this.message);

  @override
  String toString() => 'OpenAIException: $message';
}
