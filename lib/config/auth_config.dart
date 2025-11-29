/// Authentication configuration
///
/// This file contains feature flags and configuration for authentication
class AuthConfig {
  /// Enable email link (passwordless) authentication
  ///
  /// When true: Users receive a one-time link via email to sign in
  /// When false: Users can sign in directly with just their email (for development/testing)
  static const bool useEmailLinkAuth = true;

  /// Email domain whitelist for simple email auth
  ///
  /// When useEmailLinkAuth is false, only these domains are allowed
  /// Empty list means all domains are allowed
  static const List<String> allowedEmailDomains = [];

  /// Auto-login email for development
  ///
  /// When set and useEmailLinkAuth is false, this email will be auto-logged in
  /// Set to null to disable auto-login
  static const String? devAutoLoginEmail = null;
}
