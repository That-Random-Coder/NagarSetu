import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../models/worker_models.dart';
import 'secure_storage_service.dart';
import 'app_state_service.dart';

/// Generic API response wrapper
class ApiResult<T> {
  final bool success;
  final T? data;
  final String? message;

  ApiResult({required this.success, this.data, this.message});
}

/// Service for handling worker-specific API operations.
/// Workers have different endpoints and authentication flow.
class WorkerService {
  WorkerService._();

  static final _client = http.Client();

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<Map<String, String>> get _authHeaders async {
    final token = await SecureStorageService.getToken();
    return {..._headers, if (token != null) 'Authorization': 'Bearer $token'};
  }

  /// Login worker with email and password
  static Future<ApiResult<WorkerLoginResponse>> login({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.workerLoginEndpoint}',
      );

      if (Environment.enableLogging) {
        print('WORKER LOGIN REQUEST: $uri');
      }

      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(Duration(seconds: Environment.requestTimeout));

      if (Environment.enableLogging) {
        print(
          'WORKER LOGIN RESPONSE: ${response.statusCode} - ${response.body}',
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final loginResponse = WorkerLoginResponse.fromJson(data);

        // Save user data to secure storage with worker status
        await SecureStorageService.saveUserData(
          token: loginResponse.token,
          userId: loginResponse.id,
          email: loginResponse.email,
          fullName: loginResponse.fullName,
          isWorker: true,
        );

        // Store worker started status
        await SecureStorageService.setWorkerStarted(loginResponse.started);

        return ApiResult(success: true, data: loginResponse);
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return ApiResult(
          success: false,
          message: errorMsg ?? 'Login failed. Please check your credentials.',
        );
      }
    } on SocketException {
      return ApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      if (Environment.enableLogging) {
        print('WORKER LOGIN ERROR: $e');
      }
      return ApiResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Register new worker
  static Future<ApiResult<WorkerRegisterResponse>> register({
    required String email,
    required String password,
    required String code,
    String? fullName,
    String? phoneNumber,
    int? age,
    String? gender,
    String? location,
  }) async {
    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.workerRegisterEndpoint}',
      );

      final body = {
        'email': email,
        'password': password,
        'code': code,
        'role': 'WORKER',
        if (fullName != null) 'fullName': fullName,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (age != null) 'age': age,
        if (gender != null) 'gender': gender,
        if (location != null) 'location': location,
      };

      if (Environment.enableLogging) {
        print('WORKER REGISTER REQUEST: $uri');
        print('WORKER REGISTER BODY: $body');
      }

      final response = await _client
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(Duration(seconds: Environment.requestTimeout));

      if (Environment.enableLogging) {
        print(
          'WORKER REGISTER RESPONSE: ${response.statusCode} - ${response.body}',
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final registerResponse = WorkerRegisterResponse.fromJson(data);

        // Save basic auth data with worker status
        await SecureStorageService.saveUserData(
          token: registerResponse.token,
          userId: registerResponse.id,
          email: email,
          fullName: fullName,
          isWorker: true,
        );

        // Store worker started status
        await SecureStorageService.setWorkerStarted(registerResponse.started);

        return ApiResult(success: true, data: registerResponse);
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return ApiResult(
          success: false,
          message: errorMsg ?? 'Registration failed. Please try again.',
        );
      }
    } on SocketException {
      return ApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      if (Environment.enableLogging) {
        print('WORKER REGISTER ERROR: $e');
      }
      return ApiResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Request OTP code for worker email verification
  static Future<ApiResult<bool>> getCode({
    required String email,
    String roles = 'WORKER',
  }) async {
    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.workerGetCodeEndpoint}?email=$email&roles=$roles',
      );

      if (Environment.enableLogging) {
        print('WORKER GET CODE REQUEST: $uri');
      }

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(Duration(seconds: Environment.requestTimeout));

      if (Environment.enableLogging) {
        print(
          'WORKER GET CODE RESPONSE: ${response.statusCode} - ${response.body}',
        );
      }

      if (response.statusCode == 200) {
        return ApiResult(
          success: true,
          data: true,
          message: 'OTP sent successfully to your email.',
        );
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return ApiResult(
          success: false,
          message: errorMsg ?? 'Failed to send OTP. Please try again.',
        );
      }
    } on SocketException {
      return ApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      if (Environment.enableLogging) {
        print('WORKER GET CODE ERROR: $e');
      }
      return ApiResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Mark an issue as done (resolved) with proof image
  static Future<ApiResult<bool>> markIssueDone({
    required String issueId,
    required File imageFile,
  }) async {
    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.markIssueDoneEndpoint}?id=$issueId',
      );

      if (Environment.enableLogging) {
        print('MARK ISSUE DONE REQUEST: $uri');
      }

      final headers = await _authHeaders;

      // Create multipart request
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);

      // Add image file
      final imageBytes = await imageFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'proof_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      final streamedResponse = await request.send().timeout(
        Duration(seconds: Environment.requestTimeout),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (Environment.enableLogging) {
        print(
          'MARK ISSUE DONE RESPONSE: ${response.statusCode} - ${response.body}',
        );
      }

      if (response.statusCode == 200) {
        return ApiResult(
          success: true,
          data: true,
          message: 'Issue marked as done successfully.',
        );
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return ApiResult(
          success: false,
          message: errorMsg ?? 'Failed to update issue. Please try again.',
        );
      }
    } on SocketException {
      return ApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      if (Environment.enableLogging) {
        print('MARK ISSUE DONE ERROR: $e');
      }
      return ApiResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Get recent issues for dashboard
  static Future<ApiResult<List<RecentIssue>>> getRecentIssues() async {
    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.getRecentIssuesEndpoint}',
      );

      if (Environment.enableLogging) {
        print('GET RECENT ISSUES REQUEST: $uri');
      }

      final headers = await _authHeaders;
      final response = await _client
          .get(uri, headers: headers)
          .timeout(Duration(seconds: Environment.requestTimeout));

      if (Environment.enableLogging) {
        print(
          'GET RECENT ISSUES RESPONSE: ${response.statusCode} - ${response.body}',
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle paginated response
        List<dynamic> content;
        if (data is Map && data.containsKey('content')) {
          content = data['content'] as List<dynamic>;
        } else if (data is List) {
          content = data;
        } else {
          content = [];
        }

        final issues = content
            .map((json) => RecentIssue.fromJson(json as Map<String, dynamic>))
            .toList();

        return ApiResult(success: true, data: issues);
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return ApiResult(
          success: false,
          message: errorMsg ?? 'Failed to load recent issues.',
        );
      }
    } on SocketException {
      return ApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      if (Environment.enableLogging) {
        print('GET RECENT ISSUES ERROR: $e');
      }
      return ApiResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Logout worker and clear all stored data
  static Future<void> logout() async {
    await SecureStorageService.clearAll();
    await AppStateService.resetToFirstLaunch();
  }

  /// Check if worker is logged in
  static Future<bool> isLoggedIn() async {
    return await SecureStorageService.isLoggedIn();
  }

  /// Check if worker account is started (approved by admin)
  static Future<bool> isStarted() async {
    return await SecureStorageService.isWorkerStarted();
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
