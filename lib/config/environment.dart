/// Environment configuration for the NagarSetu app.
/// Contains API URLs and other environment-specific settings.
class Environment {
  Environment._();

  /// Base URL for the API server
  /// Change this for different environments (dev, staging, production)
  static const String apiBaseUrl =
      'https://journals-urban-agency-sage.trycloudflare.com';

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

  /// Google Gemini AI API Key (Free tier: 15 RPM, 1500 RPD)
  /// Get your free API key from: https://aistudio.google.com/app/apikey
  // static const String geminiApiKey = 'AIzaSyBuKMAWjJapcvCVDDZdfvHC8p3SqJXHnHk';

  /// Google Gemini AI API Key (Free tier: 15 RPM, 1500 RPD)
  /// Get your free API key from: https://aistudio.google.com/app/apikey
  static const String geminiApiKey = '';

  /// Groq AI API Key (Free tier: 30 RPM, 14,400 RPD - FASTEST)
  /// Get your free API key from: https://console.groq.com/keys
  // static const String groqApiKey =
  //     '[YOUR KEY]';

  /// Which AI provider to use: 'gemini' or 'groq'
  static const String aiProvider = 'groq';

  /// Request timeout duration in seconds
  static const int requestTimeout = 30;

  /// Enable/disable debug logging
  static const bool enableLogging = true;
}
