import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import 'secure_storage_service.dart';
import 'app_state_service.dart';

/// Response model for login API
class LoginResponse {
  final String id;
  final String email;
  final String fullName;
  final String token;

  LoginResponse({
    required this.id,
    required this.email,
    required this.fullName,
    required this.token,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
    );
  }
}

/// Response model for registration API
class RegisterResponse {
  final String id;
  final String token;

  RegisterResponse({required this.id, required this.token});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      id: json['id']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
    );
  }
}

/// Generic API response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;

  ApiResponse({required this.success, this.data, this.message});
}

/// Authentication service for handling login, registration, and OTP operations.
class AuthService {
  AuthService._();

  static final _client = http.Client();

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<Map<String, String>> get _authHeaders async {
    final token = await SecureStorageService.getToken();
    return {..._headers, if (token != null) 'Authorization': 'Bearer $token'};
  }

  /// Login user with email and password
  static Future<ApiResponse<LoginResponse>> login({
    required String email,
    required String password,
    bool isWorker = false,
  }) async {
    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.loginEndpoint}',
      );

      if (Environment.enableLogging) {
        print('LOGIN REQUEST: $uri');
      }

      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(Duration(seconds: Environment.requestTimeout));

      if (Environment.enableLogging) {
        print('LOGIN RESPONSE: ${response.statusCode} - ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final loginResponse = LoginResponse.fromJson(data);

        // Save user data to secure storage with worker status
        await SecureStorageService.saveUserData(
          token: loginResponse.token,
          userId: loginResponse.id,
          email: loginResponse.email,
          fullName: loginResponse.fullName,
          isWorker: isWorker,
        );

        return ApiResponse(success: true, data: loginResponse);
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return ApiResponse(
          success: false,
          message: errorMsg ?? 'Login failed. Please check your credentials.',
        );
      }
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      if (Environment.enableLogging) {
        print('LOGIN ERROR: $e');
      }
      return ApiResponse(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Register new user
  static Future<ApiResponse<RegisterResponse>> register({
    required String email,
    required String password,
    required String code,
    String? fullName,
    String? phoneNumber,
    int? age,
    String? gender,
    String? location,
    String role = 'CITIZEN',
    bool isWorker = false,
  }) async {
    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.registerEndpoint}',
      );

      final body = {
        'email': email,
        'password': password,
        'code': code,
        'role': role,
        if (fullName != null) 'fullName': fullName,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (age != null) 'age': age,
        if (gender != null) 'gender': gender,
        if (location != null) 'location': location,
      };

      if (Environment.enableLogging) {
        print('REGISTER REQUEST: $uri');
        print('REGISTER BODY: $body');
      }

      final response = await _client
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(Duration(seconds: Environment.requestTimeout));

      if (Environment.enableLogging) {
        print('REGISTER RESPONSE: ${response.statusCode} - ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final registerResponse = RegisterResponse.fromJson(data);

        // Save basic auth data with worker status
        await SecureStorageService.saveUserData(
          token: registerResponse.token,
          userId: registerResponse.id,
          email: email,
          fullName: fullName,
          isWorker: isWorker,
        );

        return ApiResponse(success: true, data: registerResponse);
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return ApiResponse(
          success: false,
          message: errorMsg ?? 'Registration failed. Please try again.',
        );
      }
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      if (Environment.enableLogging) {
        print('REGISTER ERROR: $e');
      }
      return ApiResponse(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Request OTP code for email verification
  static Future<ApiResponse<bool>> getCode({required String email}) async {
    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.getCodeEndpoint}?email=$email',
      );

      if (Environment.enableLogging) {
        print('GET CODE REQUEST: $uri');
      }

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(Duration(seconds: Environment.requestTimeout));

      if (Environment.enableLogging) {
        print('GET CODE RESPONSE: ${response.statusCode} - ${response.body}');
      }

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          data: true,
          message: 'OTP sent successfully to your email.',
        );
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return ApiResponse(
          success: false,
          message: errorMsg ?? 'Failed to send OTP. Please try again.',
        );
      }
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      if (Environment.enableLogging) {
        print('GET CODE ERROR: $e');
      }
      return ApiResponse(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Logout current user and clear all stored data
  static Future<void> logout() async {
    await SecureStorageService.clearAll();
    // Reset to first launch state so user sees discover page again
    await AppStateService.resetToFirstLaunch();
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    return await SecureStorageService.isLoggedIn();
  }

  /// Check if current user is a worker
  static Future<bool> isWorker() async {
    return await SecureStorageService.isWorker();
  }

  /// Get current user token
  static Future<String?> getToken() async {
    return await SecureStorageService.getToken();
  }

  /// Parse error message from API response
  static String? _parseErrorMessage(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        return data['message'] ?? data['error'] ?? data['msg'];
      }
    } catch (_) {}
    return null;
  }
}
