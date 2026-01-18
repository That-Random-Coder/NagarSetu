class IssueMapModel {
  final String id;
  final double latitude;
  final double longitude;
  final String criticality; // LOW, MEDIUM, HIGH
  final String
  stages; // PENDING, ACKNOWLEDGED, TEAM_ASSIGNED, IN_PROGRESS, RESOLVED, RECONSIDERED
  final String issueType; // ROAD, WATER, ELECTRICITY, GARBAGE, VEHICLE, OTHER
  final String? title;
  final String? description;
  final String? location;
  final DateTime? createdAt;
  final String? imageUrl;

  IssueMapModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.criticality,
    required this.stages,
    required this.issueType,
    this.title,
    this.description,
    this.location,
    this.createdAt,
    this.imageUrl,
  });

  factory IssueMapModel.fromJson(Map<String, dynamic> json) {
    return IssueMapModel(
      id: json['id']?.toString() ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      criticality: json['criticality']?.toString() ?? 'MEDIUM',
      stages: json['stages']?.toString() ?? 'PENDING',
      issueType: json['issueType']?.toString() ?? 'OTHER',
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      location: json['location']?.toString(),
      createdAt: json['createdAt'] != null || json['createAt'] != null
          ? DateTime.tryParse(
              (json['createdAt'] ?? json['createAt']).toString(),
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'criticality': criticality,
      'stages': stages,
      'issueType': issueType,
      'title': title,
      'description': description,
      'location': location,
      'createdAt': createdAt?.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }

  /// Returns a user-friendly status string from the stages enum
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
      case 'ELECTRICITY':
        return 'Electricity';
      case 'GARBAGE':
        return 'Garbage';
      case 'VEHICLE':
        return 'Vehicle';
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
