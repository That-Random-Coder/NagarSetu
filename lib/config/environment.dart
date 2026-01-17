/// Environment configuration for the NagarSetu app.
/// Contains API URLs and other environment-specific settings.
class Environment {
  Environment._();

  /// Base URL for the API server
  /// Change this for different environments (dev, staging, production)
  static const String apiBaseUrl =
      'https://deborah-mega-databases-accomplish.trycloudflare.com';

  /// API endpoints
  static const String apiVersion = '/api';

  // Authentication endpoints
  static const String authEndpoint = '$apiVersion/authenication';
  static const String loginEndpoint = '$authEndpoint/login';
  static const String registerEndpoint = '$authEndpoint/registration';
  static const String getCodeEndpoint = '$authEndpoint/getCode';

  // User endpoints
  static const String userEndpoint = '$apiVersion/user';
  static const String getUserEndpoint = '$userEndpoint/get';
  static const String getUserMatrixEndpoint = '$userEndpoint/getMatrix';

  // Issue endpoints
  static const String issueEndpoint = '$apiVersion/issue';
  static const String createIssueEndpoint = '$issueEndpoint/create';
  static const String getUserIssuesEndpoint = '$issueEndpoint/user';

  /// Google Gemini AI API Key (Free tier: 15 RPM, 1500 RPD)
  /// Get your free API key from: https://aistudio.google.com/app/apikey
  // static const String geminiApiKey = 'AIzaSyBuKMAWjJapcvCVDDZdfvHC8p3SqJXHnHk';

  /// Google Gemini AI API Key (Free tier: 15 RPM, 1500 RPD)
  /// Get your free API key from: https://aistudio.google.com/app/apikey
  static const String geminiApiKey = '';

  /// Groq AI API Key (Free tier: 30 RPM, 14,400 RPD - FASTEST)
  /// Get your free API key from: https://console.groq.com/keys
  static const String groqApiKey =
      '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';

  /// Which AI provider to use: 'gemini' or 'groq'
  static const String aiProvider = 'groq';

  /// Request timeout duration in seconds
  static const int requestTimeout = 30;

  /// Enable/disable debug logging
  static const bool enableLogging = true;
}
