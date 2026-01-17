/// Worker login response model
/// Contains additional 'started' field compared to regular login
class WorkerLoginResponse {
  final String id;
  final String email;
  final String fullName;
  final String token;
  final bool started;

  WorkerLoginResponse({
    required this.id,
    required this.email,
    required this.fullName,
    required this.token,
    required this.started,
  });

  factory WorkerLoginResponse.fromJson(Map<String, dynamic> json) {
    return WorkerLoginResponse(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      started: json['started'] == true,
    );
  }
}

/// Worker registration response model
class WorkerRegisterResponse {
  final String id;
  final String token;
  final String roles;
  final bool started;

  WorkerRegisterResponse({
    required this.id,
    required this.token,
    required this.roles,
    required this.started,
  });

  factory WorkerRegisterResponse.fromJson(Map<String, dynamic> json) {
    return WorkerRegisterResponse(
      id: json['id']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      roles: json['roles']?.toString() ?? 'WORKER',
      started: json['started'] == true,
    );
  }
}

/// Admin worker/supervisor DTO
class AdminWorkerDto {
  final String id;
  final String username;
  final DateTime? createdAt;
  final String? location;
  final bool started;
  final String? department;

  AdminWorkerDto({
    required this.id,
    required this.username,
    this.createdAt,
    this.location,
    required this.started,
    this.department,
  });

  factory AdminWorkerDto.fromJson(Map<String, dynamic> json) {
    return AdminWorkerDto(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      location: json['location']?.toString(),
      started: json['started'] == true,
      department: json['department']?.toString(),
    );
  }
}

/// Issue assigned to worker
class WorkerIssue {
  final String id;
  final String title;
  final String issueType;
  final String description;
  final String criticality;
  final String location;
  final double latitude;
  final double longitude;
  final String stages;
  final String? submittedBy;
  final DateTime? createdAt;
  final String? imageUrl;

  WorkerIssue({
    required this.id,
    required this.title,
    required this.issueType,
    required this.description,
    required this.criticality,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.stages,
    this.submittedBy,
    this.createdAt,
    this.imageUrl,
  });

  factory WorkerIssue.fromJson(Map<String, dynamic> json) {
    return WorkerIssue(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      issueType: json['issueType']?.toString() ?? 'OTHER',
      description: json['description']?.toString() ?? '',
      criticality: json['criticality']?.toString() ?? 'MEDIUM',
      location: json['location']?.toString() ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      stages: json['stages']?.toString() ?? 'PENDING',
      submittedBy: json['submittedBy']?.toString(),
      createdAt: json['createAt'] != null || json['createdAt'] != null
          ? DateTime.tryParse(
              (json['createAt'] ?? json['createdAt']).toString(),
            )
          : null,
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  /// Returns a user-friendly status string
  String get statusDisplay {
    switch (stages.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'ACKNOWLEDGED':
        return 'Acknowledged';
      case 'TEAM_ASSIGNED':
        return 'Team Assigned';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'RESOLVED':
        return 'Resolved';
      case 'RECONSIDERED':
        return 'Reconsidered';
      default:
        return stages;
    }
  }

  /// Returns a user-friendly issue type string
  String get issueTypeDisplay {
    switch (issueType.toUpperCase()) {
      case 'ROAD':
        return 'Road';
      case 'WATER':
        return 'Water';
      case 'GARBAGE':
        return 'Garbage';
      case 'VEHICLE':
        return 'Vehicle';
      case 'STREETLIGHT':
        return 'Streetlight';
      case 'OTHER':
        return 'Other';
      default:
        return issueType;
    }
  }

  /// Returns a user-friendly criticality string
  String get criticalityDisplay {
    switch (criticality.toUpperCase()) {
      case 'LOW':
        return 'Low';
      case 'MEDIUM':
        return 'Medium';
      case 'HIGH':
        return 'High';
      default:
        return criticality;
    }
  }
}

/// Recent issue model for dashboard
class RecentIssue {
  final String id;
  final String title;
  final DateTime? createdAt;
  final String stages;
  final String? imageUrl;

  RecentIssue({
    required this.id,
    required this.title,
    this.createdAt,
    required this.stages,
    this.imageUrl,
  });

  factory RecentIssue.fromJson(Map<String, dynamic> json) {
    return RecentIssue(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      stages: json['stages']?.toString() ?? 'PENDING',
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  String get statusDisplay {
    switch (stages.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'ACKNOWLEDGED':
        return 'Acknowledged';
      case 'TEAM_ASSIGNED':
        return 'Team Assigned';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'RESOLVED':
        return 'Resolved';
      case 'RECONSIDERED':
        return 'Reconsidered';
      default:
        return stages;
    }
  }
}
