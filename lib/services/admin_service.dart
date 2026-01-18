import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../models/admin_models.dart';
import 'secure_storage_service.dart';

/// Generic API response wrapper for Admin operations
class AdminApiResult<T> {
  final bool success;
  final T? data;
  final String? message;

  AdminApiResult({required this.success, this.data, this.message});
}

/// Service for handling admin-specific API operations.
/// Admin users can manage workers, supervisors, and issues.
class AdminService {
  AdminService._();

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
      print('[AdminService] $message');
    }
  }

  static String? _parseErrorMessage(String body) {
    try {
      final data = jsonDecode(body);
      return data['message']?.toString() ??
          data['error']?.toString() ??
          data['detail']?.toString();
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // GET ENDPOINTS
  // ============================================================

  /// Get all workers (both started and not started)
  static Future<AdminApiResult<List<AdminUserDto>>> getAllWorkers() async {
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
        final List<dynamic> data = jsonDecode(response.body);
        final workers = data.map((e) => AdminUserDto.fromJson(e)).toList();
        return AdminApiResult(success: true, data: workers);
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return AdminApiResult(
          success: false,
          message: errorMsg ?? 'Failed to load workers.',
        );
      }
    } on SocketException {
      return AdminApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException {
      return AdminApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      _log('GET ALL WORKERS ERROR: $e');
      return AdminApiResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Get all workers that have not been started/approved yet
  static Future<AdminApiResult<List<AdminUserDto>>>
  getWorkersNotStarted() async {
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
        final List<dynamic> data = jsonDecode(response.body);
        final workers = data.map((e) => AdminUserDto.fromJson(e)).toList();
        return AdminApiResult(success: true, data: workers);
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return AdminApiResult(
          success: false,
          message: errorMsg ?? 'Failed to load pending workers.',
        );
      }
    } on SocketException {
      return AdminApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException {
      return AdminApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      _log('GET WORKERS NO START ERROR: $e');
      return AdminApiResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Get all supervisors (both started and not started)
  static Future<AdminApiResult<List<AdminWorkerDto>>>
  getAllSupervisors() async {
    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.adminSupervisorsEndpoint}',
      );

      _log('GET ALL SUPERVISORS REQUEST: $uri');

      final headers = await _authHeaders;
      final response = await _client
          .get(uri, headers: headers)
          .timeout(Duration(seconds: Environment.requestTimeout));

      _log(
        'GET ALL SUPERVISORS RESPONSE: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final supervisors = data
            .map((e) => AdminWorkerDto.fromJson(e))
            .toList();
        return AdminApiResult(success: true, data: supervisors);
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return AdminApiResult(
          success: false,
          message: errorMsg ?? 'Failed to load supervisors.',
        );
      }
    } on SocketException {
      return AdminApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException {
      return AdminApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      _log('GET ALL SUPERVISORS ERROR: $e');
      return AdminApiResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Get all supervisors that have not been started/approved yet
  static Future<AdminApiResult<List<AdminWorkerDto>>>
  getSupervisorsNotStarted() async {
    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.adminSupervisorsNoStartEndpoint}',
      );

      _log('GET SUPERVISORS NO START REQUEST: $uri');

      final headers = await _authHeaders;
      final response = await _client
          .get(uri, headers: headers)
          .timeout(Duration(seconds: Environment.requestTimeout));

      _log(
        'GET SUPERVISORS NO START RESPONSE: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final supervisors = data
            .map((e) => AdminWorkerDto.fromJson(e))
            .toList();
        return AdminApiResult(success: true, data: supervisors);
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return AdminApiResult(
          success: false,
          message: errorMsg ?? 'Failed to load pending supervisors.',
        );
      }
    } on SocketException {
      return AdminApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException {
      return AdminApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      _log('GET SUPERVISORS NO START ERROR: $e');
      return AdminApiResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  // ============================================================
  // POST ENDPOINTS - Accept/Approve
  // ============================================================

  /// Accept/Approve a worker and assign to a supervisor
  /// POST /api/admin/acceptWorker/{workerId}/{supervisorId}
  static Future<AdminApiResult<bool>> acceptWorker({
    required String workerId,
    required String supervisorId,
  }) async {
    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.adminAcceptWorkerEndpoint}/$workerId/$supervisorId',
      );

      _log('ACCEPT WORKER REQUEST: $uri');

      final headers = await _authHeaders;
      final response = await _client
          .post(uri, headers: headers)
          .timeout(Duration(seconds: Environment.requestTimeout));

      _log('ACCEPT WORKER RESPONSE: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return AdminApiResult(
          success: result == true,
          data: result == true,
          message: result == true
              ? 'Worker approved successfully!'
              : 'Failed to approve worker.',
        );
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return AdminApiResult(
          success: false,
          message: errorMsg ?? 'Failed to approve worker.',
        );
      }
    } on SocketException {
      return AdminApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException {
      return AdminApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      _log('ACCEPT WORKER ERROR: $e');
      return AdminApiResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Accept/Approve a supervisor and assign a department
  /// POST /api/admin/acceptSupervisor/{supervisorId}/{department}
  static Future<AdminApiResult<bool>> acceptSupervisor({
    required String supervisorId,
    required String department,
  }) async {
    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.adminAcceptSupervisorEndpoint}/$supervisorId/$department',
      );

      _log('ACCEPT SUPERVISOR REQUEST: $uri');

      final headers = await _authHeaders;
      final response = await _client
          .post(uri, headers: headers)
          .timeout(Duration(seconds: Environment.requestTimeout));

      _log(
        'ACCEPT SUPERVISOR RESPONSE: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return AdminApiResult(
          success: result == true,
          data: result == true,
          message: result == true
              ? 'Supervisor approved successfully!'
              : 'Failed to approve supervisor.',
        );
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return AdminApiResult(
          success: false,
          message: errorMsg ?? 'Failed to approve supervisor.',
        );
      }
    } on SocketException {
      return AdminApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException {
      return AdminApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      _log('ACCEPT SUPERVISOR ERROR: $e');
      return AdminApiResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  // ============================================================
  // PUT ENDPOINTS - Reassign
  // ============================================================

  /// Reassign a worker to a different supervisor
  /// PUT /api/admin/reassignWorker/{workerId}/{supervisorId}
  static Future<AdminApiResult<bool>> reassignWorker({
    required String workerId,
    required String supervisorId,
  }) async {
    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.adminReassignWorkerEndpoint}/$workerId/$supervisorId',
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
        final result = jsonDecode(response.body);
        return AdminApiResult(
          success: result == true,
          data: result == true,
          message: result == true
              ? 'Worker reassigned successfully!'
              : 'Failed to reassign worker.',
        );
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return AdminApiResult(
          success: false,
          message: errorMsg ?? 'Failed to reassign worker.',
        );
      }
    } on SocketException {
      return AdminApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException {
      return AdminApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      _log('REASSIGN WORKER ERROR: $e');
      return AdminApiResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Reassign an issue to a different worker
  /// PUT /api/admin/reassignIssueWorker/{issueId}/{workerId}
  static Future<AdminApiResult<bool>> reassignIssueWorker({
    required String issueId,
    required String workerId,
  }) async {
    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.adminReassignIssueWorkerEndpoint}/$issueId/$workerId',
      );

      _log('REASSIGN ISSUE WORKER REQUEST: $uri');

      final headers = await _authHeaders;
      final response = await _client
          .put(uri, headers: headers)
          .timeout(Duration(seconds: Environment.requestTimeout));

      _log(
        'REASSIGN ISSUE WORKER RESPONSE: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return AdminApiResult(
          success: result == true,
          data: result == true,
          message: result == true
              ? 'Issue reassigned successfully!'
              : 'Failed to reassign issue.',
        );
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        return AdminApiResult(
          success: false,
          message: errorMsg ?? 'Failed to reassign issue.',
        );
      }
    } on SocketException {
      return AdminApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException {
      return AdminApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      _log('REASSIGN ISSUE WORKER ERROR: $e');
      return AdminApiResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }
}
