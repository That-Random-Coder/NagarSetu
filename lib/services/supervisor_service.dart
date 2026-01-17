import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../models/supervisor_models.dart';
import 'secure_storage_service.dart';
import 'app_state_service.dart';

/// Generic API response wrapper
class SupervisorApiResult<T> {
  final bool success;
  final T? data;
  final String? message;

  SupervisorApiResult({required this.success, this.data, this.message});
}

/// Service for handling supervisor-specific API operations.
/// Supervisors have different endpoints and authentication flow.
class SupervisorService {
  SupervisorService._();

  static final _client = http.Client();

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<Map<String, String>> get _authHeaders async {
    final token = await SecureStorageService.getToken();
    return {..._headers, if (token != null) 'Authorization': 'Bearer $token'};
  }

  static void _log(String message) {
    if (Environment.enableLogging) {
      print('[SupervisorService] $message');
    }
  }

  /// Login supervisor with email and password
  static Future<SupervisorApiResult<SupervisorLoginResponse>> login({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.supervisorLoginEndpoint}',
      );

      _log('SUPERVISOR LOGIN REQUEST: $uri');

      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(Duration(seconds: Environment.requestTimeout));

      _log(
        'SUPERVISOR LOGIN RESPONSE: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final loginResponse = SupervisorLoginResponse.fromJson(data);

        // Save user data to secure storage with supervisor status
        await SecureStorageService.saveUserData(
          token: loginResponse.token,
          userId: loginResponse.id,
          email: loginResponse.email,
          fullName: loginResponse.fullName,
          isWorker: false,
        );

        // Store supervisor started status and role
        await SecureStorageService.setWorkerStarted(loginResponse.started);
        await SecureStorageService.saveUserRole('SUPERVISOR');

        return SupervisorApiResult(success: true, data: loginResponse);
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return SupervisorApiResult(
          success: false,
          message: errorMsg ?? 'Login failed. Please check your credentials.',
        );
      }
    } on SocketException {
      return SupervisorApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException {
      return SupervisorApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      _log('SUPERVISOR LOGIN ERROR: $e');
      return SupervisorApiResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Register new supervisor
  static Future<SupervisorApiResult<SupervisorRegisterResponse>> register({
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
        '${Environment.apiBaseUrl}${Environment.supervisorRegisterEndpoint}',
      );

      final body = {
        'email': email,
        'password': password,
        'code': code,
        'role': 'SUPERVISOR',
        if (fullName != null) 'fullName': fullName,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (age != null) 'age': age,
        if (gender != null) 'gender': gender,
        if (location != null) 'location': location,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

      _log('SUPERVISOR REGISTER REQUEST: $uri');
      _log('SUPERVISOR REGISTER BODY: $body');

      final response = await _client
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(Duration(seconds: Environment.requestTimeout));

      _log(
        'SUPERVISOR REGISTER RESPONSE: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final registerResponse = SupervisorRegisterResponse.fromJson(data);

        // Save basic auth data with supervisor status
        await SecureStorageService.saveUserData(
          token: registerResponse.token,
          userId: registerResponse.id,
          email: email,
          fullName: fullName,
          isWorker: false,
        );

        // Store supervisor started status and role
        await SecureStorageService.setWorkerStarted(registerResponse.started);
        await SecureStorageService.saveUserRole('SUPERVISOR');

        return SupervisorApiResult(success: true, data: registerResponse);
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return SupervisorApiResult(
          success: false,
          message: errorMsg ?? 'Registration failed. Please try again.',
        );
      }
    } on SocketException {
      return SupervisorApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException {
      return SupervisorApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      _log('SUPERVISOR REGISTER ERROR: $e');
      return SupervisorApiResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Request OTP code for supervisor email verification
  static Future<SupervisorApiResult<bool>> getCode({
    required String email,
    String roles = 'SUPERVISOR',
  }) async {
    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.supervisorGetCodeEndpoint}?email=$email&roles=$roles',
      );

      _log('SUPERVISOR GET CODE REQUEST: $uri');

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(Duration(seconds: Environment.requestTimeout));

      _log(
        'SUPERVISOR GET CODE RESPONSE: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        return SupervisorApiResult(
          success: true,
          data: true,
          message: 'OTP sent successfully to your email.',
        );
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return SupervisorApiResult(
          success: false,
          message: errorMsg ?? 'Failed to send OTP. Please try again.',
        );
      }
    } on SocketException {
      return SupervisorApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException {
      return SupervisorApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      _log('SUPERVISOR GET CODE ERROR: $e');
      return SupervisorApiResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Get supervisor by ID
  static Future<SupervisorApiResult<SupervisorProfile>> getSupervisorById(
    String id,
  ) async {
    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.supervisorEndpoint}/$id',
      );

      _log('GET SUPERVISOR BY ID REQUEST: $uri');

      final headers = await _authHeaders;
      final response = await _client
          .get(uri, headers: headers)
          .timeout(Duration(seconds: Environment.requestTimeout));

      _log(
        'GET SUPERVISOR BY ID RESPONSE: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final profile = SupervisorProfile.fromJson(data);
        return SupervisorApiResult(success: true, data: profile);
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return SupervisorApiResult(
          success: false,
          message: errorMsg ?? 'Failed to load supervisor profile.',
        );
      }
    } on SocketException {
      return SupervisorApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException {
      return SupervisorApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      _log('GET SUPERVISOR BY ID ERROR: $e');
      return SupervisorApiResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Filter supervisors by department
  static Future<SupervisorApiResult<List<SupervisorProfile>>>
  filterSupervisors({String? department}) async {
    try {
      var uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.supervisorFilterEndpoint}',
      );

      if (department != null) {
        uri = uri.replace(queryParameters: {'department': department});
      }

      _log('FILTER SUPERVISORS REQUEST: $uri');

      final headers = await _authHeaders;
      final response = await _client
          .get(uri, headers: headers)
          .timeout(Duration(seconds: Environment.requestTimeout));

      _log(
        'FILTER SUPERVISORS RESPONSE: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> list = data is List ? data : (data['content'] ?? []);
        final supervisors = list
            .map(
              (json) =>
                  SupervisorProfile.fromJson(json as Map<String, dynamic>),
            )
            .toList();
        return SupervisorApiResult(success: true, data: supervisors);
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return SupervisorApiResult(
          success: false,
          message: errorMsg ?? 'Failed to load supervisors.',
        );
      }
    } on SocketException {
      return SupervisorApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException {
      return SupervisorApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      _log('FILTER SUPERVISORS ERROR: $e');
      return SupervisorApiResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Get all workers (for assignment)
  static Future<SupervisorApiResult<List<AssignableWorker>>>
  getAllWorkers() async {
    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.adminWorkersEndpoint}',
      );

      _log('GET ALL WORKERS REQUEST: $uri');

      final headers = await _authHeaders;
      final response = await _client
          .get(uri, headers: headers)
          .timeout(Duration(seconds: Environment.requestTimeout));

      _log(
        'GET ALL WORKERS RESPONSE: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> list = data is List ? data : (data['content'] ?? []);
        final workers = list
            .map(
              (json) => AssignableWorker.fromJson(json as Map<String, dynamic>),
            )
            .toList();
        return SupervisorApiResult(success: true, data: workers);
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return SupervisorApiResult(
          success: false,
          message: errorMsg ?? 'Failed to load workers.',
        );
      }
    } on SocketException {
      return SupervisorApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException {
      return SupervisorApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      _log('GET ALL WORKERS ERROR: $e');
      return SupervisorApiResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Get workers not yet started/approved
  static Future<SupervisorApiResult<List<AssignableWorker>>>
  getWorkersNoStart() async {
    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.adminWorkersNoStartEndpoint}',
      );

      _log('GET WORKERS NO START REQUEST: $uri');

      final headers = await _authHeaders;
      final response = await _client
          .get(uri, headers: headers)
          .timeout(Duration(seconds: Environment.requestTimeout));

      _log(
        'GET WORKERS NO START RESPONSE: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> list = data is List ? data : (data['content'] ?? []);
        final workers = list
            .map(
              (json) => AssignableWorker.fromJson(json as Map<String, dynamic>),
            )
            .toList();
        return SupervisorApiResult(success: true, data: workers);
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return SupervisorApiResult(
          success: false,
          message: errorMsg ?? 'Failed to load pending workers.',
        );
      }
    } on SocketException {
      return SupervisorApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException {
      return SupervisorApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      _log('GET WORKERS NO START ERROR: $e');
      return SupervisorApiResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Get recent issues for supervisor dashboard
  static Future<SupervisorApiResult<List<SupervisorIssue>>> getRecentIssues({
    int page = 0,
  }) async {
    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.getRecentIssuesEndpoint}',
      ).replace(queryParameters: {'page': page.toString()});

      _log('GET RECENT ISSUES REQUEST: $uri');

      final headers = await _authHeaders;
      final response = await _client
          .get(uri, headers: headers)
          .timeout(Duration(seconds: Environment.requestTimeout));

      _log(
        'GET RECENT ISSUES RESPONSE: ${response.statusCode} - ${response.body}',
      );

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
            .map(
              (json) => SupervisorIssue.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        return SupervisorApiResult(success: true, data: issues);
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return SupervisorApiResult(
          success: false,
          message: errorMsg ?? 'Failed to load recent issues.',
        );
      }
    } on SocketException {
      return SupervisorApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException {
      return SupervisorApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      _log('GET RECENT ISSUES ERROR: $e');
      return SupervisorApiResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Get issue by ID
  static Future<SupervisorApiResult<SupervisorIssue>> getIssueById(
    String issueId,
  ) async {
    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.issueEndpoint}/$issueId',
      );

      _log('GET ISSUE BY ID REQUEST: $uri');

      final headers = await _authHeaders;
      final response = await _client
          .get(uri, headers: headers)
          .timeout(Duration(seconds: Environment.requestTimeout));

      _log(
        'GET ISSUE BY ID RESPONSE: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final issue = SupervisorIssue.fromJson(data['data'] ?? data);
        return SupervisorApiResult(success: true, data: issue);
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return SupervisorApiResult(
          success: false,
          message: errorMsg ?? 'Failed to load issue details.',
        );
      }
    } on SocketException {
      return SupervisorApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException {
      return SupervisorApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      _log('GET ISSUE BY ID ERROR: $e');
      return SupervisorApiResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Reassign worker to an issue
  static Future<SupervisorApiResult<bool>> reassignWorker({
    required String workerId,
    required String supervisorId,
  }) async {
    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.adminEndpoint}/reassignWorker/$workerId/$supervisorId',
      );

      _log('REASSIGN WORKER REQUEST: $uri');

      final headers = await _authHeaders;
      final response = await _client
          .put(uri, headers: headers)
          .timeout(Duration(seconds: Environment.requestTimeout));

      _log(
        'REASSIGN WORKER RESPONSE: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        return SupervisorApiResult(
          success: true,
          data: true,
          message: 'Worker reassigned successfully.',
        );
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return SupervisorApiResult(
          success: false,
          message: errorMsg ?? 'Failed to reassign worker.',
        );
      }
    } on SocketException {
      return SupervisorApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException {
      return SupervisorApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      _log('REASSIGN WORKER ERROR: $e');
      return SupervisorApiResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Accept/approve worker
  static Future<SupervisorApiResult<bool>> acceptWorker({
    required String workerId,
    required String supervisorId,
  }) async {
    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.adminEndpoint}/acceptWorker/$workerId/$supervisorId',
      );

      _log('ACCEPT WORKER REQUEST: $uri');

      final headers = await _authHeaders;
      final response = await _client
          .post(uri, headers: headers)
          .timeout(Duration(seconds: Environment.requestTimeout));

      _log('ACCEPT WORKER RESPONSE: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return SupervisorApiResult(
          success: true,
          data: true,
          message: 'Worker approved successfully.',
        );
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return SupervisorApiResult(
          success: false,
          message: errorMsg ?? 'Failed to approve worker.',
        );
      }
    } on SocketException {
      return SupervisorApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException {
      return SupervisorApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      _log('ACCEPT WORKER ERROR: $e');
      return SupervisorApiResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Logout supervisor and clear all stored data
  static Future<void> logout() async {
    await SecureStorageService.clearAll();
    await AppStateService.resetToFirstLaunch();
  }

  /// Check if supervisor is logged in
  static Future<bool> isLoggedIn() async {
    return await SecureStorageService.isLoggedIn();
  }

  /// Check if supervisor account is started (approved)
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
