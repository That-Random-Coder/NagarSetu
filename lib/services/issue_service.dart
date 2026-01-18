import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/environment.dart';
import '../models/issue_model.dart';
import '../models/issue_map_model.dart';
import '../models/recent_issue_model.dart';
import '../models/weekly_stats_model.dart';
import 'secure_storage_service.dart';

class IssueService {
  IssueService._();
  static final _client = http.Client();

  /// Debug logger for API calls
  static void _log(String message) {
    if (Environment.enableLogging) {
      print('[IssueService] $message');
    }
  }

  /// Debug method to test API connectivity
  static Future<Map<String, dynamic>> testApiConnection() async {
    final results = <String, dynamic>{};

    try {
      // Check auth status
      final token = await SecureStorageService.getToken();
      final userId = await SecureStorageService.getUserId();
      results['hasToken'] = token != null;
      results['hasUserId'] = userId != null;
      results['userId'] = userId;
      results['baseUrl'] = Environment.apiBaseUrl;

      _log('=== API Connection Test ===');
      _log('Base URL: ${Environment.apiBaseUrl}');
      _log('Has Token: ${token != null}');
      _log('User ID: $userId');

      // Test map endpoint
      if (userId != null) {
        final mapUri = Uri.parse(
          '${Environment.apiBaseUrl}${Environment.getIssuesForMapEndpoint}',
        ).replace(queryParameters: {'id': userId});

        _log('Testing Map Endpoint: $mapUri');

        final headers = await _getHeaders();
        final response = await _client
            .get(mapUri, headers: headers)
            .timeout(const Duration(seconds: 10));

        String statusMessage = '';
        if (response.statusCode == 200) {
          statusMessage = 'OK - Issues found';
        } else if (response.statusCode == 204) {
          statusMessage = 'OK - No issues (empty)';
        } else {
          statusMessage = 'Error';
        }

        results['mapEndpoint'] = {
          'url': mapUri.toString(),
          'statusCode': response.statusCode,
          'statusMessage': statusMessage,
          'body': response.body.isEmpty
              ? '(empty response - this is normal for 204)'
              : (response.body.length > 500
                    ? '${response.body.substring(0, 500)}...'
                    : response.body),
        };

        _log('Map Endpoint Response: ${response.statusCode} - $statusMessage');
        _log(
          'Response Body: ${response.body.isEmpty ? "(empty)" : response.body}',
        );
      }

      results['success'] = true;
    } catch (e) {
      results['success'] = false;
      results['error'] = e.toString();
      _log('API Test Error: $e');
    }

    return results;
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<ApiResult<IssueModel>> createIssue({
    required String title,
    required String description,
    required String type,
    required String criticality,
    required String location,
    required double latitude,
    required double longitude,
    required File image,
  }) async {
    try {
      final userId = await SecureStorageService.getUserId();
      if (userId == null) {
        _log('ERROR: User not authenticated');
        return ApiResult(success: false, message: 'User not authenticated');
      }

      // Verify image exists
      if (!await image.exists()) {
        _log('ERROR: Image file not found at ${image.path}');
        return ApiResult(success: false, message: 'Image file not found');
      }

      final uri = Uri.parse('${Environment.apiBaseUrl}/api/issue/create');
      final request = http.MultipartRequest('POST', uri);

      // Add authorization header
      final token = await SecureStorageService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Create the DTO matching the API spec
      final issueCreateDto = {
        'title': title,
        'issueType': _mapIssueType(type),
        'description': description,
        'criticality': _mapCriticality(criticality),
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'submittedById': userId,
      };

      // Add DTO as a JSON part with name 'issueCreateDto'
      request.files.add(
        http.MultipartFile.fromString(
          'issueCreateDto',
          jsonEncode(issueCreateDto),
          contentType: MediaType('application', 'json'),
        ),
      );

      // Add image file
      final fileName = image.path.split(Platform.pathSeparator).last;
      final mimeType = _getMimeType(fileName);
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.path,
          filename: fileName,
          contentType: mimeType,
        ),
      );

      _log('=== Creating Issue ===');
      _log('URL: $uri');
      _log('DTO: ${jsonEncode(issueCreateDto)}');
      _log('Image: $fileName (${await image.length()} bytes)');

      final streamedResponse = await request.send().timeout(
        Duration(seconds: Environment.requestTimeout),
      );
      final response = await http.Response.fromStream(streamedResponse);

      _log('Response Status: ${response.statusCode}');
      _log('Response Headers: ${response.headers}');
      _log('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Backend returns just the issue ID as a string
        final responseBody = response.body.trim();
        String issueId;

        // Handle different response formats
        if (responseBody.startsWith('"') && responseBody.endsWith('"')) {
          // Response is a quoted string (UUID)
          issueId = responseBody.substring(1, responseBody.length - 1);
        } else if (responseBody.startsWith('{')) {
          // Response is a JSON object
          final data = jsonDecode(responseBody);
          issueId =
              data['id']?.toString() ??
              data['issueId']?.toString() ??
              data['data']?['id']?.toString() ??
              '';
        } else {
          // Response is a plain string
          issueId = responseBody;
        }

        // Create a minimal IssueModel with the returned ID
        final issue = IssueModel(
          id: issueId,
          title: title,
          description: description,
          type: type,
          criticality: criticality,
          location: location,
          latitude: latitude,
          longitude: longitude,
          status: 'Submitted',
          userId: userId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          timeline: [],
        );
        return ApiResult(success: true, data: issue);
      } else {
        final error = _parseError(response.body);
        return ApiResult(success: false, message: error);
      }
    } on SocketException catch (e) {
      _log('Network error in createIssue: $e');
      return ApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException catch (e) {
      _log('SSL error in createIssue: $e');
      return ApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      if (Environment.enableLogging) {
        print('Create issue error: $e');
      }
      return ApiResult(
        success: false,
        message: 'Failed to create issue. Please check your connection.',
      );
    }
  }

  static MediaType _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  /// Maps issue type labels to API enum values
  static String _mapIssueType(String type) {
    // Ensure we send only the allowed set: ROAD, WATER, GARBAGE, VEHICLE, STREETLIGHT, OTHER
    final key = type.toLowerCase().trim();

    if (key.contains('road')) return 'ROAD';
    if (key.contains('water')) return 'WATER';
    if (key.contains('garbage') ||
        key.contains('waste') ||
        key.contains('drain'))
      return 'GARBAGE';
    if (key.contains('vehicle') ||
        key.contains('car') ||
        key.contains('traffic'))
      return 'VEHICLE';
    if (key.contains('streetlight') ||
        key.contains('light') ||
        key.contains('street light'))
      return 'STREETLIGHT';

    // If it already matches one of the uppercase allowed values, return it
    final upper = type.toUpperCase().trim();
    const allowed = {
      'ROAD',
      'WATER',
      'GARBAGE',
      'VEHICLE',
      'STREETLIGHT',
      'OTHER',
    };
    if (allowed.contains(upper)) return upper;

    // Fallback to OTHER
    return 'OTHER';
  }

  /// Maps criticality labels to API enum values
  static String _mapCriticality(String criticality) {
    final criticalityMap = {
      'Low': 'LOW',
      'Medium': 'MEDIUM',
      'High': 'HIGH',
      'Critical': 'CRITICAL',
    };
    return criticalityMap[criticality] ?? criticality.toUpperCase();
  }

  static Future<ApiResult<List<IssueModel>>> getUserIssues({
    int pageNumber = 0,
  }) async {
    try {
      final userId = await SecureStorageService.getUserId();
      if (userId == null) {
        return ApiResult(success: false, message: 'User not authenticated');
      }

      final headers = await _getHeaders();

      final uri = Uri.parse('${Environment.apiBaseUrl}/api/issue/user').replace(
        queryParameters: {'id': userId, 'pageNumber': pageNumber.toString()},
      );

      if (Environment.enableLogging) {
        print('Fetching issues for user: $userId, page: $pageNumber');
      }

      final response = await _client
          .get(uri, headers: headers)
          .timeout(Duration(seconds: Environment.requestTimeout));

      if (Environment.enableLogging) {
        print(
          'Get user issues response: ${response.statusCode} - ${response.body}',
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> issuesList = [];

        if (data is List) {
          issuesList = data;
        } else if (data['content'] != null) {
          // Paginated response from Spring Boot
          issuesList = data['content'] as List;
        } else if (data['data'] != null) {
          issuesList = data['data'] as List;
        } else if (data['issues'] != null) {
          issuesList = data['issues'] as List;
        }

        final issues = issuesList
            .map((json) => IssueModel.fromJson(json))
            .toList();
        return ApiResult(success: true, data: issues);
      } else {
        final error = _parseError(response.body);
        return ApiResult(success: false, message: error);
      }
    } on SocketException catch (e) {
      _log('Network error in getUserIssues: $e');
      return ApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException catch (e) {
      _log('SSL error in getUserIssues: $e');
      return ApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      if (Environment.enableLogging) {
        print('Get user issues error: $e');
      }
      return ApiResult(
        success: false,
        message: 'Failed to fetch issues. Please check your connection.',
      );
    }
  }

  static Future<ApiResult<IssueModel>> getIssueById(String issueId) async {
    try {
      final headers = await _getHeaders();

      if (Environment.enableLogging) {
        print('Fetching issue by ID: $issueId');
      }

      final response = await _client
          .get(
            Uri.parse('${Environment.apiBaseUrl}/api/issue/$issueId'),
            headers: headers,
          )
          .timeout(Duration(seconds: Environment.requestTimeout));

      if (Environment.enableLogging) {
        print(
          'Get issue by ID response: ${response.statusCode} - ${response.body}',
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final issue = IssueModel.fromJson(data['data'] ?? data);
        return ApiResult(success: true, data: issue);
      } else {
        final error = _parseError(response.body);
        return ApiResult(success: false, message: error);
      }
    } on SocketException catch (e) {
      _log('Network error in getIssueById: $e');
      return ApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException catch (e) {
      _log('SSL error in getIssueById: $e');
      return ApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      if (Environment.enableLogging) {
        print('Get issue by ID error: $e');
      }
      return ApiResult(
        success: false,
        message: 'Failed to fetch issue. Please check your connection.',
      );
    }
  }

  static String _parseError(String body) {
    try {
      final data = jsonDecode(body);
      return data['message']?.toString() ??
          data['error']?.toString() ??
          data['detail']?.toString() ??
          'Server error. Please try again.';
    } catch (e) {
      // If body is not JSON, return it directly if not empty
      if (body.isNotEmpty && body.length < 200) {
        return body;
      }
      return 'Server error. Please try again.';
    }
  }

  /// Fetches issues for map display using /api/issue/user/map endpoint
  /// Falls back to /api/issue/user if map endpoint returns empty
  /// Returns lightweight IssueMapModel objects with location and status info
  static Future<ApiResult<List<IssueMapModel>>> getIssuesForMap() async {
    try {
      final userId = await SecureStorageService.getUserId();
      if (userId == null) {
        return ApiResult(success: false, message: 'User not authenticated');
      }

      final headers = await _getHeaders();

      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.getIssuesForMapEndpoint}',
      ).replace(queryParameters: {'id': userId});

      _log('Fetching issues for map, user: $userId');
      _log('Map URL: $uri');

      final response = await _client
          .get(uri, headers: headers)
          .timeout(Duration(seconds: Environment.requestTimeout));

      _log(
        'Get issues for map response: ${response.statusCode} - ${response.body}',
      );

      List<IssueMapModel> issues = [];

      // Handle 204 No Content or empty response - try fallback
      if (response.statusCode == 204 || response.body.trim().isEmpty) {
        _log(
          'Map endpoint returned empty - trying fallback to /api/issue/user',
        );
        issues = await _getIssuesFromUserEndpoint();
      } else if (response.statusCode == 200) {
        final body = response.body.trim();
        final data = jsonDecode(body);
        List<dynamic> issuesList = [];

        if (data is List) {
          issuesList = data;
        } else if (data is Set) {
          issuesList = data.toList();
        } else if (data['data'] != null) {
          issuesList = data['data'] as List;
        }

        _log('Parsed ${issuesList.length} issues from map response');

        issues = issuesList
            .map((json) => IssueMapModel.fromJson(json))
            .toList();

        // If map endpoint returned empty list, try fallback
        if (issues.isEmpty) {
          _log('Map endpoint returned empty list - trying fallback');
          issues = await _getIssuesFromUserEndpoint();
        }
      } else {
        final error = _parseError(response.body);
        _log('Map endpoint error: $error - trying fallback');
        issues = await _getIssuesFromUserEndpoint();
      }

      return ApiResult(success: true, data: issues);
    } on SocketException catch (e) {
      _log('Network error in getIssuesForMap: $e');
      return ApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException catch (e) {
      _log('SSL error in getIssuesForMap: $e');
      return ApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      _log('Get issues for map error: $e');
      return ApiResult(
        success: false,
        message: 'Failed to fetch map issues. Please check your connection.',
      );
    }
  }

  /// Fallback method to get issues from /api/issue/user and fetch full details for each
  static Future<List<IssueMapModel>> _getIssuesFromUserEndpoint() async {
    try {
      final result = await getUserIssues(pageNumber: 0);
      if (result.success && result.data != null && result.data!.isNotEmpty) {
        _log(
          'Fallback: Got ${result.data!.length} issues from /api/issue/user',
        );

        // The /api/issue/user endpoint doesn't return lat/lng, so we need to fetch each issue's details
        final List<IssueMapModel> mapIssues = [];

        for (final issue in result.data!) {
          // Check if issue already has valid coordinates
          if (issue.latitude != 0.0 && issue.longitude != 0.0) {
            mapIssues.add(
              IssueMapModel(
                id: issue.id,
                latitude: issue.latitude,
                longitude: issue.longitude,
                criticality: _mapCriticality(issue.criticality),
                stages: _mapStatusToStages(issue.status),
                issueType: _mapIssueType(issue.type),
              ),
            );
          } else {
            // Fetch full issue details to get coordinates
            _log('Fetching full details for issue: ${issue.id}');
            final detailResult = await getIssueById(issue.id);
            if (detailResult.success && detailResult.data != null) {
              final fullIssue = detailResult.data!;
              _log(
                'Got coordinates: ${fullIssue.latitude}, ${fullIssue.longitude}',
              );
              mapIssues.add(
                IssueMapModel(
                  id: fullIssue.id,
                  latitude: fullIssue.latitude,
                  longitude: fullIssue.longitude,
                  criticality: _mapCriticality(fullIssue.criticality),
                  stages: _mapStatusToStages(fullIssue.status),
                  issueType: _mapIssueType(fullIssue.type),
                ),
              );
            }
          }
        }

        _log('Fallback: Returning ${mapIssues.length} issues with coordinates');
        return mapIssues;
      }
      return [];
    } catch (e) {
      _log('Fallback fetch error: $e');
      return [];
    }
  }

  /// Maps status strings to API stage enum values
  static String _mapStatusToStages(String status) {
    final statusMap = {
      'pending': 'PENDING',
      'submitted': 'PENDING',
      'acknowledged': 'ACKNOWLEDGED',
      'team assigned': 'TEAM_ASSIGNED',
      'in progress': 'IN_PROGRESS',
      'resolved': 'RESOLVED',
      'reconsidered': 'RECONSIDERED',
    };
    return statusMap[status.toLowerCase()] ?? status.toUpperCase();
  }

  /// Marks an issue as done by uploading a completion photo
  /// Uses /api/issue/done endpoint
  static Future<ApiResult<String>> markIssueDone({
    required String issueId,
    required File completionImage,
  }) async {
    try {
      // Verify image exists
      if (!await completionImage.exists()) {
        return ApiResult(success: false, message: 'Image file not found');
      }

      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.markIssueDoneEndpoint}',
      ).replace(queryParameters: {'id': issueId});

      final request = http.MultipartRequest('POST', uri);

      // Add authorization header
      final token = await SecureStorageService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add image file
      final fileName = completionImage.path.split(Platform.pathSeparator).last;
      final mimeType = _getMimeType(fileName);
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          completionImage.path,
          filename: fileName,
          contentType: mimeType,
        ),
      );

      if (Environment.enableLogging) {
        print('Marking issue as done: $issueId');
        print('Completion image: $fileName');
      }

      final streamedResponse = await request.send().timeout(
        Duration(seconds: Environment.requestTimeout),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (Environment.enableLogging) {
        print(
          'Mark issue done response: ${response.statusCode} - ${response.body}',
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = response.body.trim();
        String returnedId;

        if (responseBody.startsWith('"') && responseBody.endsWith('"')) {
          returnedId = responseBody.substring(1, responseBody.length - 1);
        } else {
          returnedId = responseBody;
        }

        return ApiResult(success: true, data: returnedId);
      } else {
        final error = _parseError(response.body);
        return ApiResult(success: false, message: error);
      }
    } on SocketException catch (e) {
      _log('Network error in markIssueDone: $e');
      return ApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException catch (e) {
      _log('SSL error in markIssueDone: $e');
      return ApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      if (Environment.enableLogging) {
        print('Mark issue done error: $e');
      }
      return ApiResult(
        success: false,
        message: 'Failed to mark issue as done. Please check your connection.',
      );
    }
  }

  /// Get recent issues for the home page
  /// Uses /api/issue/recent endpoint
  static Future<ApiResult<List<RecentIssue>>> getRecentIssues({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final uri =
          Uri.parse(
            '${Environment.apiBaseUrl}${Environment.getRecentIssuesEndpoint}',
          ).replace(
            queryParameters: {'page': page.toString(), 'size': size.toString()},
          );

      _log('GET RECENT ISSUES REQUEST: $uri');

      final headers = await _getHeaders();
      final response = await _client
          .get(uri, headers: headers)
          .timeout(Duration(seconds: Environment.requestTimeout));

      _log(
        'GET RECENT ISSUES RESPONSE: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> content;

        // Handle paginated response (PageIssueRecent)
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
      } else if (response.statusCode == 204) {
        // No content - empty list
        return ApiResult(success: true, data: []);
      } else {
        final error = _parseError(response.body);
        return ApiResult(success: false, message: error);
      }
    } on SocketException catch (e) {
      _log('Network error in getRecentIssues: $e');
      return ApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException catch (e) {
      _log('SSL error in getRecentIssues: $e');
      return ApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      _log('GET RECENT ISSUES ERROR: $e');
      return ApiResult(
        success: false,
        message: 'Failed to load recent issues. Please try again.',
      );
    }
  }

  /// Get weekly stage counts for stats display
  /// Uses /api/issue/stats/weekly/stages endpoint
  static Future<ApiResult<List<WeeklyStageCount>>> getWeeklyStats() async {
    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.getWeeklyStatsEndpoint}',
      );

      _log('GET WEEKLY STATS REQUEST: $uri');

      final headers = await _getHeaders();
      final response = await _client
          .get(uri, headers: headers)
          .timeout(Duration(seconds: Environment.requestTimeout));

      _log(
        'GET WEEKLY STATS RESPONSE: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final stats = data
            .map(
              (json) => WeeklyStageCount.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        return ApiResult(success: true, data: stats);
      } else if (response.statusCode == 204) {
        // No content - empty list
        return ApiResult(success: true, data: []);
      } else {
        final error = _parseError(response.body);
        return ApiResult(success: false, message: error);
      }
    } on SocketException catch (e) {
      _log('Network error in getWeeklyStats: $e');
      return ApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException catch (e) {
      _log('SSL error in getWeeklyStats: $e');
      return ApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      _log('GET WEEKLY STATS ERROR: $e');
      return ApiResult(
        success: false,
        message: 'Failed to load weekly stats. Please try again.',
      );
    }
  }

  /// Get issue map data for worker
  /// Uses /api/issue/map/worker endpoint
  static Future<ApiResult<List<IssueMapModel>>> getIssueMapForWorker(
    String workerId,
  ) async {
    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.getIssueMapWorkerEndpoint}',
      ).replace(queryParameters: {'workerId': workerId});

      _log('GET ISSUE MAP WORKER REQUEST: $uri');

      final headers = await _getHeaders();
      final response = await _client
          .get(uri, headers: headers)
          .timeout(Duration(seconds: Environment.requestTimeout));

      _log(
        'GET ISSUE MAP WORKER RESPONSE: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final issues = data
            .map((json) => IssueMapModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResult(success: true, data: issues);
      } else if (response.statusCode == 204) {
        return ApiResult(success: true, data: []);
      } else {
        final error = _parseError(response.body);
        return ApiResult(success: false, message: error);
      }
    } on SocketException catch (e) {
      _log('Network error in getIssueMapForWorker: $e');
      return ApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException catch (e) {
      _log('SSL error in getIssueMapForWorker: $e');
      return ApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      _log('GET ISSUE MAP WORKER ERROR: $e');
      return ApiResult(
        success: false,
        message: 'Failed to load issue map data. Please try again.',
      );
    }
  }

  /// Get issue map data for supervisor
  /// Uses /api/issue/map/supervisor endpoint
  static Future<ApiResult<List<IssueMapModel>>> getIssueMapForSupervisor(
    String supervisorId,
  ) async {
    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.getIssueMapSupervisorEndpoint}',
      ).replace(queryParameters: {'supervisorId': supervisorId});

      _log('GET ISSUE MAP SUPERVISOR REQUEST: $uri');

      final headers = await _getHeaders();
      final response = await _client
          .get(uri, headers: headers)
          .timeout(Duration(seconds: Environment.requestTimeout));

      _log(
        'GET ISSUE MAP SUPERVISOR RESPONSE: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final issues = data
            .map((json) => IssueMapModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResult(success: true, data: issues);
      } else if (response.statusCode == 204) {
        return ApiResult(success: true, data: []);
      } else {
        final error = _parseError(response.body);
        return ApiResult(success: false, message: error);
      }
    } on SocketException catch (e) {
      _log('Network error in getIssueMapForSupervisor: $e');
      return ApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException catch (e) {
      _log('SSL error in getIssueMapForSupervisor: $e');
      return ApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      _log('GET ISSUE MAP SUPERVISOR ERROR: $e');
      return ApiResult(
        success: false,
        message: 'Failed to load issue map data. Please try again.',
      );
    }
  }

  /// Get issue map data for admin (all issues)
  /// Uses /api/issue/map/admin endpoint
  static Future<ApiResult<List<IssueMapModel>>> getIssueMapForAdmin() async {
    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}${Environment.getIssueMapAdminEndpoint}',
      );

      _log('GET ISSUE MAP ADMIN REQUEST: $uri');

      final headers = await _getHeaders();
      final response = await _client
          .get(uri, headers: headers)
          .timeout(Duration(seconds: Environment.requestTimeout));

      _log(
        'GET ISSUE MAP ADMIN RESPONSE: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final issues = data
            .map((json) => IssueMapModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResult(success: true, data: issues);
      } else if (response.statusCode == 204) {
        return ApiResult(success: true, data: []);
      } else {
        final error = _parseError(response.body);
        return ApiResult(success: false, message: error);
      }
    } on SocketException catch (e) {
      _log('Network error in getIssueMapForAdmin: $e');
      return ApiResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on HandshakeException catch (e) {
      _log('SSL error in getIssueMapForAdmin: $e');
      return ApiResult(
        success: false,
        message: 'Connection security error. Please try again.',
      );
    } catch (e) {
      _log('GET ISSUE MAP ADMIN ERROR: $e');
      return ApiResult(
        success: false,
        message: 'Failed to load issue map data. Please try again.',
      );
    }
  }
}

class ApiResult<T> {
  final bool success;
  final T? data;
  final String? message;

  ApiResult({required this.success, this.data, this.message});
}
