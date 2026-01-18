import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Represents a geographic hotspot area based on issue density and criticality
class HotspotModel {
  final String id;
  final String locality;
  final LatLng center;
  final double radiusMeters;
  final int issueCount;
  final int highCriticalityCount;
  final int mediumCriticalityCount;
  final int lowCriticalityCount;
  final double hotspotScore;
  final HotspotSeverity severity;
  final List<String> topIssueTypes;

  HotspotModel({
    required this.id,
    required this.locality,
    required this.center,
    required this.radiusMeters,
    required this.issueCount,
    required this.highCriticalityCount,
    required this.mediumCriticalityCount,
    required this.lowCriticalityCount,
    required this.hotspotScore,
    required this.severity,
    required this.topIssueTypes,
  });

  /// Get color based on severity level
  Color get color {
    switch (severity) {
      case HotspotSeverity.critical:
        return Colors.red.shade800;
      case HotspotSeverity.high:
        return Colors.red;
      case HotspotSeverity.moderate:
        return Colors.orange;
      case HotspotSeverity.low:
        return Colors.yellow.shade700;
    }
  }

  /// Get transparent color for map overlay
  Color get overlayColor => color.withValues(alpha: 0.25);

  /// Get border color for map overlay
  Color get borderColor => color.withValues(alpha: 0.6);

  /// Get severity label
  String get severityLabel {
    switch (severity) {
      case HotspotSeverity.critical:
        return 'Critical';
      case HotspotSeverity.high:
        return 'High';
      case HotspotSeverity.moderate:
        return 'Moderate';
      case HotspotSeverity.low:
        return 'Low';
    }
  }

  /// Get icon based on severity
  IconData get icon {
    switch (severity) {
      case HotspotSeverity.critical:
        return Icons.warning_amber_rounded;
      case HotspotSeverity.high:
        return Icons.error_outline_rounded;
      case HotspotSeverity.moderate:
        return Icons.info_outline_rounded;
      case HotspotSeverity.low:
        return Icons.check_circle_outline_rounded;
    }
  }
}

/// Severity level for hotspots
enum HotspotSeverity {
  critical, // Score > 80
  high, // Score 60-80
  moderate, // Score 40-60
  low, // Score < 40
}

/// Extension to calculate severity from score
extension HotspotSeverityExtension on double {
  HotspotSeverity toSeverity() {
    if (this > 80) return HotspotSeverity.critical;
    if (this > 60) return HotspotSeverity.high;
    if (this > 40) return HotspotSeverity.moderate;
    return HotspotSeverity.low;
  }
}
