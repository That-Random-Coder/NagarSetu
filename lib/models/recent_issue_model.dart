/// Model for recent issues displayed on the home page
/// Matches the IssueRecent schema from the API
class RecentIssue {
  final String id;
  final String title;
  final DateTime createdAt;
  final String
  stages; // PENDING, ACKNOWLEDGED, TEAM_ASSIGNED, IN_PROGRESS, RESOLVED, RECONSIDERED
  final String? imageUrl;

  RecentIssue({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.stages,
    this.imageUrl,
  });

  factory RecentIssue.fromJson(Map<String, dynamic> json) {
    return RecentIssue(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      createdAt: _parseDate(json['createdAt']),
      stages: json['stages']?.toString() ?? 'PENDING',
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'stages': stages,
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

  /// Returns a relative time string (e.g., "2h ago", "3d ago")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Returns color based on status
  StatusColor get statusColor {
    switch (stages.toUpperCase()) {
      case 'RESOLVED':
        return StatusColor.green;
      case 'IN_PROGRESS':
      case 'TEAM_ASSIGNED':
        return StatusColor.orange;
      case 'ACKNOWLEDGED':
        return StatusColor.blue;
      case 'RECONSIDERED':
        return StatusColor.purple;
      default:
        return StatusColor.red;
    }
  }
}

/// Enum for status colors
enum StatusColor { red, orange, green, blue, purple }
