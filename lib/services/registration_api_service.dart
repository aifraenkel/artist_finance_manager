import 'dart:convert';
import 'package:http/http.dart' as http;

/// API Service for registration-related Cloud Functions
///
/// Handles server-side registration flow with token-based verification
class RegistrationApiService {
  // Cloud Functions base URL
  // TODO: Update this with your actual Cloud Run service URL
  static const String _functionsBaseUrl =
      'https://us-central1-artist-manager-479514.cloudfunctions.net';

  /// Create a registration request
  ///
  /// Calls the Cloud Function to create a pending registration and send verification email
  ///
  /// [email] - User's email address
  /// [name] - User's display name
  /// [continueUrl] - URL to redirect to after verification
  ///
  /// Returns true if successful, throws exception otherwise
  Future<Map<String, dynamic>> createRegistration({
    required String email,
    required String name,
    required String continueUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_functionsBaseUrl/createRegistration'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'name': name,
          'continueUrl': continueUrl,
        }),
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      } else if (response.statusCode == 409 &&
          responseData['error'] == 'USER_EXISTS') {
        throw RegistrationException('USER_EXISTS',
            'A user with this email already exists. Please sign in instead.');
      } else {
        throw RegistrationException(
          'REGISTRATION_FAILED',
          responseData['error'] ?? 'Failed to create registration',
        );
      }
    } catch (e) {
      if (e is RegistrationException) rethrow;
      throw RegistrationException('NETWORK_ERROR',
          'Failed to connect to server. Please check your internet connection.');
    }
  }

  /// Verify a registration token
  ///
  /// Calls the Cloud Function to verify the token and retrieve registration data
  ///
  /// [token] - Registration token from email link
  ///
  /// Returns registration data (email, name, continueUrl) if successful
  Future<Map<String, dynamic>> verifyRegistrationToken({
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_functionsBaseUrl/verifyRegistrationToken'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': token,
        }),
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      } else if (response.statusCode == 404) {
        throw RegistrationException(
          'INVALID_TOKEN',
          'Invalid registration link. Please request a new one.',
        );
      } else if (response.statusCode == 410) {
        throw RegistrationException(
          'TOKEN_EXPIRED',
          'This registration link has expired. Please register again.',
        );
      } else if (response.statusCode == 409) {
        throw RegistrationException(
          'TOKEN_ALREADY_USED',
          'This registration link has already been used.',
        );
      } else {
        throw RegistrationException(
          'VERIFICATION_FAILED',
          responseData['message'] ?? 'Failed to verify registration',
        );
      }
    } catch (e) {
      if (e is RegistrationException) rethrow;
      throw RegistrationException('NETWORK_ERROR',
          'Failed to connect to server. Please check your internet connection.');
    }
  }

  /// Create a sign-in request (for existing users)
  ///
  /// Calls the Cloud Function to create a sign-in token and send email
  ///
  /// [email] - User's email address
  /// [continueUrl] - URL to redirect to after sign-in
  ///
  /// Returns true if successful, throws exception otherwise
  Future<Map<String, dynamic>> createSignInRequest({
    required String email,
    required String continueUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_functionsBaseUrl/createSignInRequest'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'continueUrl': continueUrl,
        }),
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      } else if (response.statusCode == 404 &&
          responseData['error'] == 'USER_NOT_FOUND') {
        throw RegistrationException('USER_NOT_FOUND',
            'No account found with this email. Please register first.');
      } else {
        throw RegistrationException(
          'SIGN_IN_FAILED',
          responseData['error'] ?? 'Failed to send sign-in link',
        );
      }
    } catch (e) {
      if (e is RegistrationException) rethrow;
      throw RegistrationException('NETWORK_ERROR',
          'Failed to connect to server. Please check your internet connection.');
    }
  }
}

/// Custom exception for registration-related errors
class RegistrationException implements Exception {
  final String code;
  final String message;

  RegistrationException(this.code, this.message);

  @override
  String toString() => message;
}
