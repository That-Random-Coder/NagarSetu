import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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

        await SecureStorageService.saveUserData(
          token: loginResponse.token,
          userId: loginResponse.id,
          email: loginResponse.email,
          fullName: loginResponse.fullName,
          isWorker: true,
        );

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
    double? latitude,
    double? longitude,
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
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
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

        await SecureStorageService.saveUserData(
          token: registerResponse.token,
          userId: registerResponse.id,
          email: email,
          fullName: fullName,
          isWorker: true,
        );

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
  /// API: POST /api/issue/done?id={issueId} with file in body
  static Future<ApiResult<bool>> markIssueDone({
    required String issueId,
    required File imageFile,
  }) async {
    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.markIssueDoneEndpoint}',
      ).replace(queryParameters: {'id': issueId});

      if (Environment.enableLogging) {
        print('MARK ISSUE DONE REQUEST: $uri');
      }

      final token = await SecureStorageService.getToken();

      final request = http.MultipartRequest('POST', uri);
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final imageBytes = await imageFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
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

  /// Get assigned issues for worker
  /// API: GET /api/worker/issues/assigned?workerId={workerId}
  static Future<ApiResult<List<IssueForWorkerDto>>> getAssignedIssues() async {
    try {
      final workerId = await SecureStorageService.getUserId();
      if (workerId == null || workerId.isEmpty) {
        return ApiResult(
          success: false,
          message: 'Worker ID not found. Please login again.',
        );
      }

      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.workerAssignedIssuesEndpoint}',
      ).replace(queryParameters: {'workerId': workerId});

      if (Environment.enableLogging) {
        print('GET ASSIGNED ISSUES REQUEST: $uri');
      }

      final headers = await _authHeaders;
      final response = await _client
          .get(uri, headers: headers)
          .timeout(Duration(seconds: Environment.requestTimeout));

      if (Environment.enableLogging) {
        print(
          'GET ASSIGNED ISSUES RESPONSE: ${response.statusCode} - ${response.body}',
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> content;
        if (data is List) {
          content = data;
        } else if (data is Map && data.containsKey('content')) {
          content = data['content'] as List<dynamic>;
        } else {
          content = [];
        }

        final issues = content
            .map(
              (json) =>
                  IssueForWorkerDto.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        return ApiResult(success: true, data: issues);
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return ApiResult(
          success: false,
          message: errorMsg ?? 'Failed to load assigned issues.',
        );
      }
    } on SocketException {
      return ApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      if (Environment.enableLogging) {
        print('GET ASSIGNED ISSUES ERROR: $e');
      }
      return ApiResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Start working on an issue
  /// API: PUT /api/worker/issues/{issueId}/start?workerId={workerId}
  static Future<ApiResult<bool>> startIssue({required String issueId}) async {
    try {
      final workerId = await SecureStorageService.getUserId();
      if (workerId == null || workerId.isEmpty) {
        return ApiResult(
          success: false,
          message: 'Worker ID not found. Please login again.',
        );
      }

      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.workerIssuesEndpoint}/$issueId/start',
      ).replace(queryParameters: {'workerId': workerId});

      if (Environment.enableLogging) {
        print('START ISSUE REQUEST: $uri');
      }

      final headers = await _authHeaders;
      final response = await _client
          .put(uri, headers: headers)
          .timeout(Duration(seconds: Environment.requestTimeout));

      if (Environment.enableLogging) {
        print(
          'START ISSUE RESPONSE: ${response.statusCode} - ${response.body}',
        );
      }

      if (response.statusCode == 200) {
        return ApiResult(
          success: true,
          data: true,
          message: 'Issue started successfully.',
        );
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return ApiResult(
          success: false,
          message: errorMsg ?? 'Failed to start issue. Please try again.',
        );
      }
    } on SocketException {
      return ApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      if (Environment.enableLogging) {
        print('START ISSUE ERROR: $e');
      }
      return ApiResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Resolve an issue
  /// API: PUT /api/worker/issues/{issueId}/resolve?workerId={workerId}
  static Future<ApiResult<bool>> resolveIssue({required String issueId}) async {
    try {
      final workerId = await SecureStorageService.getUserId();
      if (workerId == null || workerId.isEmpty) {
        return ApiResult(
          success: false,
          message: 'Worker ID not found. Please login again.',
        );
      }

      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.workerIssuesEndpoint}/$issueId/resolve',
      ).replace(queryParameters: {'workerId': workerId});

      if (Environment.enableLogging) {
        print('RESOLVE ISSUE REQUEST: $uri');
      }

      final headers = await _authHeaders;
      final response = await _client
          .put(uri, headers: headers)
          .timeout(Duration(seconds: Environment.requestTimeout));

      if (Environment.enableLogging) {
        print(
          'RESOLVE ISSUE RESPONSE: ${response.statusCode} - ${response.body}',
        );
      }

      if (response.statusCode == 200) {
        return ApiResult(
          success: true,
          data: true,
          message: 'Issue resolved successfully.',
        );
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return ApiResult(
          success: false,
          message: errorMsg ?? 'Failed to resolve issue. Please try again.',
        );
      }
    } on SocketException {
      return ApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      if (Environment.enableLogging) {
        print('RESOLVE ISSUE ERROR: $e');
      }
      return ApiResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Update issue stage with optional proof image
  /// API: PUT /api/worker/stage with WorkerUpdateIssue body + optional file
  /// Stages: PENDING, ACKNOWLEDGED, TEAM_ASSIGNED, IN_PROGRESS, RESOLVED, RECONSIDERED
  static Future<ApiResult<String>> updateStage({
    required String issueId,
    required String stage,
    String? description,
    File? proofImage,
  }) async {
    try {
      final workerId = await SecureStorageService.getUserId();
      if (workerId == null || workerId.isEmpty) {
        return ApiResult(
          success: false,
          message: 'Worker ID not found. Please login again.',
        );
      }

      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.workerStageEndpoint}',
      );

      if (Environment.enableLogging) {
        print('UPDATE STAGE REQUEST: $uri');
        print('Stage: $stage, IssueId: $issueId, WorkerId: $workerId');
      }

      final token = await SecureStorageService.getToken();

      final request = http.MultipartRequest('PUT', uri);
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      final workerUpdateIssue = {
        'workerId': workerId,
        'issueId': issueId,
        'stages': stage.toUpperCase(),
        if (description != null && description.isNotEmpty)
          'description': description,
      };

      // Send dto as a JSON blob with application/json content type (matching HTML implementation)
      final dtoJson = jsonEncode(workerUpdateIssue);
      request.files.add(
        http.MultipartFile.fromString(
          'dto',
          dtoJson,
          contentType: MediaType('application', 'json'),
        ),
      );

      if (proofImage != null) {
        final imageBytes = await proofImage.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: 'proof_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      }

      final streamedResponse = await request.send().timeout(
        Duration(seconds: Environment.requestTimeout),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (Environment.enableLogging) {
        print(
          'UPDATE STAGE RESPONSE: ${response.statusCode} - ${response.body}',
        );
      }

      if (response.statusCode == 200) {
        return ApiResult(
          success: true,
          data: response.body,
          message: 'Stage updated successfully.',
        );
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return ApiResult(
          success: false,
          message: errorMsg ?? 'Failed to update stage. Please try again.',
        );
      }
    } on SocketException {
      return ApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      if (Environment.enableLogging) {
        print('UPDATE STAGE ERROR: $e');
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
