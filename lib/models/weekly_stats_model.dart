import 'package:flutter/material.dart';

/// Represents a weekly stage count from the API
/// Maps to IssueStageCountDto from backend
class WeeklyStageCount {
  final String stage;
  final int count;

  WeeklyStageCount({required this.stage, required this.count});

  factory WeeklyStageCount.fromJson(Map<String, dynamic> json) {
    return WeeklyStageCount(
      stage: json['stage']?.toString() ?? 'UNKNOWN',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Get display label for the stage
  String get displayLabel {
    switch (stage) {
      case 'PENDING':
        return 'Pending';
      case 'ACKNOWLEDGED':
        return 'Acknowledged';
      case 'TEAM_ASSIGNED':
        return 'Assigned';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'RESOLVED':
        return 'Resolved';
      case 'RECONSIDERED':
        return 'Reconsidered';
      default:
        return stage;
    }
  }

  /// Get color for the stage
  Color get stageColor {
    switch (stage) {
      case 'PENDING':
        return Colors.red;
      case 'ACKNOWLEDGED':
        return Colors.orange;
      case 'TEAM_ASSIGNED':
        return Colors.blue;
      case 'IN_PROGRESS':
        return Colors.amber;
      case 'RESOLVED':
        return Colors.green;
      case 'RECONSIDERED':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Get icon for the stage
  IconData get stageIcon {
    switch (stage) {
      case 'PENDING':
        return Icons.pending_actions_rounded;
      case 'ACKNOWLEDGED':
        return Icons.thumb_up_alt_rounded;
      case 'TEAM_ASSIGNED':
        return Icons.assignment_ind_rounded;
      case 'IN_PROGRESS':
        return Icons.engineering_rounded;
      case 'RESOLVED':
        return Icons.check_circle_rounded;
      case 'RECONSIDERED':
        return Icons.replay_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}
