/// Data models for Admin functionality

/// Department enum for supervisor assignment
enum Department {
  ROAD,
  WATER,
  GARBAGE,
  VEHICLE,
  STREETLIGHT,
  OTHER;

  String get displayName {
    switch (this) {
      case Department.ROAD:
        return 'Road & Infrastructure';
      case Department.WATER:
        return 'Water & Sewage';
      case Department.GARBAGE:
        return 'Garbage & Sanitation';
      case Department.VEHICLE:
        return 'Vehicle & Transport';
      case Department.STREETLIGHT:
        return 'Street Lighting';
      case Department.OTHER:
        return 'Other';
    }
  }

  static Department fromString(String value) {
    return Department.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => Department.OTHER,
    );
  }
}

/// Worker DTO for admin panel (for workers list)
class AdminUserDto {
  final String id;
  final String username;
  final DateTime? createdAt;
  final String? location;
  final bool started;

  AdminUserDto({
    required this.id,
    required this.username,
    this.createdAt,
    this.location,
    this.started = false,
  });

  factory AdminUserDto.fromJson(Map<String, dynamic> json) {
    return AdminUserDto(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Unknown',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      location: json['location']?.toString(),
      started: json['started'] == true,
    );
  }

  /// Format created date for display
  String get formattedDate {
    if (createdAt == null) return 'Unknown';
    return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
  }

  /// Get time ago string
  String get timeAgo {
    if (createdAt == null) return 'Unknown';
    final difference = DateTime.now().difference(createdAt!);
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year(s) ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month(s) ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day(s) ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour(s) ago';
    } else {
      return 'Just now';
    }
  }
}

/// Supervisor DTO for admin panel (includes department)
class AdminWorkerDto {
  final String id;
  final String username;
  final DateTime? createdAt;
  final String? location;
  final bool started;
  final Department? department;

  AdminWorkerDto({
    required this.id,
    required this.username,
    this.createdAt,
    this.location,
    this.started = false,
    this.department,
  });

  factory AdminWorkerDto.fromJson(Map<String, dynamic> json) {
    return AdminWorkerDto(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Unknown',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      location: json['location']?.toString(),
      started: json['started'] == true,
      department: json['department'] != null
          ? Department.fromString(json['department'].toString())
          : null,
    );
  }

  /// Format created date for display
  String get formattedDate {
    if (createdAt == null) return 'Unknown';
    return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
  }

  /// Get time ago string
  String get timeAgo {
    if (createdAt == null) return 'Unknown';
    final difference = DateTime.now().difference(createdAt!);
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year(s) ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month(s) ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day(s) ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour(s) ago';
    } else {
      return 'Just now';
    }
  }
}
