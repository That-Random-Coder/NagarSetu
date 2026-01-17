import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../models/user_model.dart';
import 'secure_storage_service.dart';

/// Service for user-related API operations.
class UserService {
  UserService._();

  static final _client = http.Client();

  /// Get authorization headers with Bearer token
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await SecureStorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Fetch user profile by ID
  /// Endpoint: GET /api/user/get?id={userId}
  static Future<UserServiceResponse> getUserById(String userId) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.getUserEndpoint}?id=$userId',
      );

      if (Environment.enableLogging) {
        print('GET USER REQUEST: $uri');
      }

      final response = await _client
          .get(uri, headers: headers)
          .timeout(Duration(seconds: Environment.requestTimeout));

      if (Environment.enableLogging) {
        print('GET USER RESPONSE: ${response.statusCode} - ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = UserModel.fromJson(data);
        return UserServiceResponse(success: true, user: user);
      } else if (response.statusCode == 401) {
        return UserServiceResponse(
          success: false,
          message: 'Session expired. Please login again.',
          isUnauthorized: true,
        );
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return UserServiceResponse(
          success: false,
          message: errorMsg ?? 'Failed to fetch user profile.',
        );
      }
    } on SocketException {
      return UserServiceResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      if (Environment.enableLogging) {
        print('GET USER ERROR: $e');
      }
      return UserServiceResponse(
        success: false,
        message: 'An error occurred while fetching profile.',
      );
    }
  }

  /// Fetch current logged-in user profile
  /// Uses stored user ID from SecureStorageService
  static Future<UserServiceResponse> getCurrentUser() async {
    final userId = await SecureStorageService.getUserId();
    if (userId == null || userId.isEmpty) {
      return UserServiceResponse(
        success: false,
        message: 'User not logged in.',
        isUnauthorized: true,
      );
    }
    return getUserById(userId);
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

/// Response wrapper for UserService operations
class UserServiceResponse {
  final bool success;
  final UserModel? user;
  final String? message;
  final bool isUnauthorized;

  UserServiceResponse({
    required this.success,
    this.user,
    this.message,
    this.isUnauthorized = false,
  });
}
