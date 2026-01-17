import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/environment.dart';
import '../models/issue_model.dart';
import 'secure_storage_service.dart';

class IssueService {
  IssueService._();
  static final _client = http.Client();

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
        return ApiResult(success: false, message: 'User not authenticated');
      }

      // Verify image exists
      if (!await image.exists()) {
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

      if (Environment.enableLogging) {
        print('Creating issue with multipart request (DTO + Image)');
        print('DTO: $issueCreateDto');
        print('Image: $fileName');
      }

      final streamedResponse = await request.send().timeout(
        Duration(seconds: Environment.requestTimeout),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (Environment.enableLogging) {
        print(
          'Create issue response: ${response.statusCode} - ${response.body}',
        );
      }

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
    } catch (e) {
      if (Environment.enableLogging) {
        print('Create issue error: $e');
      }
      return ApiResult(success: false, message: 'Failed to create issue: $e');
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
    final lookup = {
      'road': 'ROAD',
      'drainage': 'DRAINAGE',
      'garbage': 'GARBAGE',
      'electricity': 'ELECTRICITY',
      'water': 'WATER',
      'streetlight': 'STREETLIGHT',
      'public safety': 'PUBLIC_SAFETY',
      'vehicle': 'VEHICLE',
      'other': 'OTHER',
    };
    final key = type.toLowerCase().trim();
    return lookup[key] ?? 'OTHER';
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
    } catch (e) {
      if (Environment.enableLogging) {
        print('Get user issues error: $e');
      }
      return ApiResult(success: false, message: 'Failed to fetch issues: $e');
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
    } catch (e) {
      if (Environment.enableLogging) {
        print('Get issue by ID error: $e');
      }
      return ApiResult(success: false, message: 'Failed to fetch issue: $e');
    }
  }

  static String _parseError(String body) {
    try {
      final data = jsonDecode(body);
      return data['message']?.toString() ??
          data['error']?.toString() ??
          'An error occurred';
    } catch (e) {
      return 'An error occurred';
    }
  }
}

class ApiResult<T> {
  final bool success;
  final T? data;
  final String? message;

  ApiResult({required this.success, this.data, this.message});
}
