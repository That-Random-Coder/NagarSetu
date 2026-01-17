/// Environment configuration for the NagarSetu app.
/// Contains API URLs and other environment-specific settings.
class Environment {
  Environment._();

  /// Base URL for the API server
  /// Change this for different environments (dev, staging, production)
  static const String apiBaseUrl =
      'https://sydney-skirts-guidance-intensity.trycloudflare.com';

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

  /// Request timeout duration in seconds
  static const int requestTimeout = 30;

  /// Enable/disable debug logging
  static const bool enableLogging = true;
}
