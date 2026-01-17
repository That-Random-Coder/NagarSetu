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

  // Authentication endpoints (for Citizens)
  static const String authEndpoint = '$apiVersion/authenication';
  static const String loginEndpoint = '$authEndpoint/login';
  static const String registerEndpoint = '$authEndpoint/registration';
  static const String getCodeEndpoint = '$authEndpoint/getCode';

  // Worker endpoints
  static const String workerEndpoint = '$apiVersion/worker';
  static const String workerLoginEndpoint = '$workerEndpoint/login';
  static const String workerRegisterEndpoint = '$workerEndpoint/registration';
  static const String workerGetCodeEndpoint = '$workerEndpoint/getCode';

  // Supervisor endpoints
  static const String supervisorEndpoint = '$apiVersion/supervisior';
  static const String supervisorLoginEndpoint = '$supervisorEndpoint/login';
  static const String supervisorRegisterEndpoint =
      '$supervisorEndpoint/registration';
  static const String supervisorGetCodeEndpoint = '$supervisorEndpoint/getCode';
  static const String supervisorFilterEndpoint = '$supervisorEndpoint/filter';

  // Admin endpoints
  static const String adminEndpoint = '$apiVersion/admin';
  static const String adminWorkersEndpoint = '$adminEndpoint/workers';
  static const String adminWorkersNoStartEndpoint =
      '$adminEndpoint/workers/no-start';
  static const String adminSupervisorsEndpoint = '$adminEndpoint/supervisors';
  static const String adminSupervisorsNoStartEndpoint =
      '$adminEndpoint/supervisors/no-start';

  // User endpoints
  static const String userEndpoint = '$apiVersion/user';
  static const String getUserEndpoint = '$userEndpoint/get';
  static const String getUserMatrixEndpoint = '$userEndpoint/getMatrix';
  static const String getLeaderboardEndpoint = '$userEndpoint/getLeaderboard';

  // Issue endpoints
  static const String issueEndpoint = '$apiVersion/issue';
  static const String createIssueEndpoint = '$issueEndpoint/create';
  static const String getUserIssuesEndpoint = '$issueEndpoint/user';
  static const String getIssuesForMapEndpoint = '$issueEndpoint/user/map';
  static const String markIssueDoneEndpoint = '$issueEndpoint/done';
  static const String getRecentIssuesEndpoint = '$issueEndpoint/recent';

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
