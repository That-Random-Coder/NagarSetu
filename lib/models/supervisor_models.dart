/// Supervisor login response model
/// Contains additional 'started' field for admin approval status
class SupervisorLoginResponse {
  final String id;
  final String email;
  final String fullName;
  final String token;
  final bool started;

  SupervisorLoginResponse({
    required this.id,
    required this.email,
    required this.fullName,
    required this.token,
    required this.started,
  });

  factory SupervisorLoginResponse.fromJson(Map<String, dynamic> json) {
    return SupervisorLoginResponse(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      started: json['started'] == true,
    );
  }
}

/// Supervisor registration response model
class SupervisorRegisterResponse {
  final String id;
  final String token;
  final String roles;
  final bool started;

  SupervisorRegisterResponse({
    required this.id,
    required this.token,
    required this.roles,
    required this.started,
  });

  factory SupervisorRegisterResponse.fromJson(Map<String, dynamic> json) {
    return SupervisorRegisterResponse(
      id: json['id']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      roles: json['roles']?.toString() ?? 'SUPERVISOR',
      started: json['started'] == true,
    );
  }
}

/// Supervisor profile data
class SupervisorProfile {
  final String id;
  final String username;
  final String? email;
  final String? department;
  final DateTime? createdAt;
  final String? location;
  final bool started;

  SupervisorProfile({
    required this.id,
    required this.username,
    this.email,
    this.department,
    this.createdAt,
    this.location,
    required this.started,
  });

  factory SupervisorProfile.fromJson(Map<String, dynamic> json) {
    return SupervisorProfile(
      id: json['id']?.toString() ?? '',
      username:
          json['username']?.toString() ?? json['fullName']?.toString() ?? '',
      email: json['email']?.toString(),
      department: json['department']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      location: json['location']?.toString(),
      started: json['started'] == true,
    );
  }
}

/// Worker assigned to supervisor for assignment purposes
class AssignableWorker {
  final String id;
  final String username;
  final String? department;
  final String? location;
  final bool started;
  final int? tasksAssigned;
  final bool isAvailable;
  final String? currentTask;

  AssignableWorker({
    required this.id,
    required this.username,
    this.department,
    this.location,
    required this.started,
    this.tasksAssigned,
    this.isAvailable = true,
    this.currentTask,
  });

  factory AssignableWorker.fromJson(Map<String, dynamic> json) {
    return AssignableWorker(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      department: json['department']?.toString(),
      location: json['location']?.toString(),
      started: json['started'] == true,
      tasksAssigned: json['tasksAssigned'] as int? ?? 0,
      isAvailable: json['isAvailable'] == true,
      currentTask: json['currentTask']?.toString(),
    );
  }
}

/// Issue for supervisor management
class SupervisorIssue {
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
  final String? assignedWorkerId;
  final String? assignedWorkerName;

  SupervisorIssue({
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
    this.assignedWorkerId,
    this.assignedWorkerName,
  });

  factory SupervisorIssue.fromJson(Map<String, dynamic> json) {
    return SupervisorIssue(
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
      assignedWorkerId: json['assignedWorkerId']?.toString(),
      assignedWorkerName: json['assignedWorkerName']?.toString(),
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

  /// Alias for stages - for compatibility
  String get status => stages;

  /// Alias for issueType - for compatibility
  String get type => issueType;

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

  /// Check if issue is assigned to a worker
  bool get isAssigned =>
      assignedWorkerId != null && assignedWorkerId!.isNotEmpty;
}
