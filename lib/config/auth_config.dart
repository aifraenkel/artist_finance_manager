/// Authentication configuration
///
/// This app uses server-side token-based email authentication exclusively.
/// Users receive a secure one-time link via email to register or sign in.
/// Tokens are verified server-side before creating Firebase credentials.
class AuthConfig {
  /// Email link (token-based) authentication is always enabled
  /// This cannot be disabled as it's the only supported auth method
  static const bool useEmailLinkAuth = true;
}
