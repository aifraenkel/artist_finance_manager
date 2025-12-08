import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import '../models/financial_goal.dart';

/// Service for interacting with OpenAI API
///
/// Handles communication with OpenAI's chat completion API
/// for budget goal analysis and financial goal acknowledgment.
/// Includes error handling, retry logic, and logging.
class OpenAIService {
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-4o';
  static const int _maxTokens = 500;
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(seconds: 1);

  final String apiKey;

  OpenAIService({required this.apiKey});

  /// Analyze budget goal against financial data
  ///
  /// [prompt] - The complete prompt including goal and data
  ///
  /// Returns the AI-generated analysis or throws an exception on error
  Future<String> analyzeGoal(String prompt) async {
    return _callOpenAI(
      systemPrompt:
          'You are a financial advisor helping artists understand their financial performance. Provide clear, concise analysis in a small paragraph (3-5 sentences).',
      userPrompt: prompt,
    );
  }

  /// Generate acknowledgment message for financial goal
  ///
  /// Reads the prompt template and generates a personalized acknowledgment
  Future<String> acknowledgeGoal(FinancialGoal goal) async {
    try {
      // Load the prompt template
      final template = await rootBundle
          .loadString('lib/prompts/goal_acknowledgment.md');

      // Format due date
      final dateFormat = DateFormat('MMMM d, y');
      final formattedDate = dateFormat.format(goal.dueDate);

      // Get email cadence display string
      String cadenceText;
      switch (goal.emailCadence) {
        case EmailCadence.daily:
          cadenceText = 'daily';
          break;
        case EmailCadence.weekly:
          cadenceText = 'weekly';
          break;
        case EmailCadence.biweekly:
          cadenceText = 'every two weeks';
          break;
        case EmailCadence.monthly:
          cadenceText = 'monthly';
          break;
        case EmailCadence.never:
          cadenceText = 'never (dashboard only)';
          break;
      }

      // Replace placeholders
      final prompt = template
          .replaceAll('{{goal}}', goal.goal)
          .replaceAll('{{due_date}}', formattedDate)
          .replaceAll('{{email_cadence}}', cadenceText);

      // Call OpenAI with the prepared prompt
      return _callOpenAI(
        systemPrompt: '',
        userPrompt: prompt,
        temperature: 0.8, // Higher temperature for more creative responses
      );
    } catch (e) {
      throw OpenAIException('Failed to generate goal acknowledgment: $e');
    }
  }

  /// Internal method to call OpenAI API with retry logic
  Future<String> _callOpenAI({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
  }) async {
  /// Internal method to call OpenAI API with retry logic
  Future<String> _callOpenAI({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
  }) async {
    if (apiKey.isEmpty) {
      throw OpenAIException('OpenAI API key is not set');
    }

    int retryCount = 0;
    Duration retryDelay = _initialRetryDelay;

    while (retryCount < _maxRetries) {
      try {
        final messages = <Map<String, String>>[];
        if (systemPrompt.isNotEmpty) {
          messages.add({
            'role': 'system',
            'content': systemPrompt,
          });
        }
        messages.add({
          'role': 'user',
          'content': userPrompt,
        });

        final response = await http.post(
          Uri.parse(_apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': _model,
            'messages': messages,
            'max_tokens': _maxTokens,
            'temperature': temperature,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content =
              data['choices']?[0]?['message']?['content'] as String?;

          if (content == null || content.isEmpty) {
            throw OpenAIException('Empty response from OpenAI API');
          }

          return content.trim();
        } else if (response.statusCode == 401) {
          throw OpenAIException('Invalid OpenAI API key');
        } else if (response.statusCode == 429) {
          // Rate limit - retry with exponential backoff
          if (retryCount < _maxRetries - 1) {
            await Future.delayed(retryDelay);
            retryDelay *= 2; // Exponential backoff
            retryCount++;
            continue;
          }
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
        // Network error - retry
        if (retryCount < _maxRetries - 1) {
          await Future.delayed(retryDelay);
          retryDelay *= 2;
          retryCount++;
          continue;
        }
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

    throw OpenAIException('Max retries exceeded');
  }
}

/// Exception class for OpenAI API errors
class OpenAIException implements Exception {
  final String message;

  OpenAIException(this.message);

  @override
  String toString() => 'OpenAIException: $message';
}
