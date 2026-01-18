import 'package:latlong2/latlong.dart';
import '../models/issue_map_model.dart';
import '../models/hotspot_model.dart';

/// Service for detecting and analyzing issue hotspots
/// Uses clustering algorithm to identify areas with high issue concentration
class HotspotService {
  HotspotService._();

  /// Grid size for clustering (in degrees, approximately 500m)
  static const double _gridSize = 0.005;

  /// Minimum issues required to form a hotspot
  static const int _minIssuesForHotspot = 3;

  /// Radius for hotspot visualization in meters
  static const double _baseRadius = 300.0;

  /// Analyzes issues and returns detected hotspots
  /// Uses grid-based clustering with criticality weighting
  static List<HotspotModel> detectHotspots(List<IssueMapModel> issues) {
    if (issues.isEmpty) return [];

    // Group issues by grid cells
    final Map<String, List<IssueMapModel>> grid = {};

    for (final issue in issues) {
      // Skip issues without valid coordinates
      if (issue.latitude == 0 && issue.longitude == 0) continue;

      // Calculate grid cell key
      final cellX = (issue.longitude / _gridSize).floor();
      final cellY = (issue.latitude / _gridSize).floor();
      final key = '$cellX,$cellY';

      grid.putIfAbsent(key, () => []);
      grid[key]!.add(issue);
    }

    // Convert grid cells with sufficient issues into hotspots
    final List<HotspotModel> hotspots = [];
    int hotspotIndex = 0;

    for (final entry in grid.entries) {
      final cellIssues = entry.value;

      // Skip cells with too few issues
      if (cellIssues.length < _minIssuesForHotspot) continue;

      // Calculate center point
      double totalLat = 0;
      double totalLng = 0;
      for (final issue in cellIssues) {
        totalLat += issue.latitude;
        totalLng += issue.longitude;
      }
      final centerLat = totalLat / cellIssues.length;
      final centerLng = totalLng / cellIssues.length;

      // Count criticality levels
      int highCount = 0;
      int mediumCount = 0;
      int lowCount = 0;
      final Map<String, int> issueTypeCount = {};

      for (final issue in cellIssues) {
        switch (issue.criticality.toUpperCase()) {
          case 'HIGH':
          case 'CRITICAL':
            highCount++;
            break;
          case 'MEDIUM':
            mediumCount++;
            break;
          default:
            lowCount++;
        }

        // Count issue types
        final type = issue.issueType;
        issueTypeCount[type] = (issueTypeCount[type] ?? 0) + 1;
      }

      // Calculate hotspot score (0-100)
      // Formula: (issueCount * 10) + (highCriticality * 15) + (mediumCriticality * 5)
      // Capped at 100
      double score =
          (cellIssues.length * 10) + (highCount * 15) + (mediumCount * 5);
      score = score.clamp(0, 100);

      // Get top issue types
      final sortedTypes = issueTypeCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topTypes = sortedTypes.take(3).map((e) => e.key).toList();

      // Generate locality name based on grid position and issue types
      String locality = 'Hotspot ${hotspotIndex + 1}';
      if (topTypes.isNotEmpty) {
        locality = '${topTypes.first} Area ${hotspotIndex + 1}';
      }

      // Calculate radius based on issue count
      final radius = _baseRadius + (cellIssues.length * 20);

      hotspots.add(
        HotspotModel(
          id: 'hotspot_$hotspotIndex',
          locality: locality,
          center: LatLng(centerLat, centerLng),
          radiusMeters: radius.clamp(300, 800),
          issueCount: cellIssues.length,
          highCriticalityCount: highCount,
          mediumCriticalityCount: mediumCount,
          lowCriticalityCount: lowCount,
          hotspotScore: score,
          severity: score.toSeverity(),
          topIssueTypes: topTypes,
        ),
      );

      hotspotIndex++;
    }

    // Sort by score (highest first)
    hotspots.sort((a, b) => b.hotspotScore.compareTo(a.hotspotScore));

    return hotspots;
  }

  /// Get summary statistics for hotspots
  static Map<String, dynamic> getHotspotSummary(List<HotspotModel> hotspots) {
    if (hotspots.isEmpty) {
      return {
        'total': 0,
        'critical': 0,
        'high': 0,
        'moderate': 0,
        'low': 0,
        'totalIssues': 0,
        'averageScore': 0.0,
      };
    }

    int critical = 0;
    int high = 0;
    int moderate = 0;
    int low = 0;
    int totalIssues = 0;
    double totalScore = 0;

    for (final hotspot in hotspots) {
      totalIssues += hotspot.issueCount;
      totalScore += hotspot.hotspotScore;

      switch (hotspot.severity) {
        case HotspotSeverity.critical:
          critical++;
          break;
        case HotspotSeverity.high:
          high++;
          break;
        case HotspotSeverity.moderate:
          moderate++;
          break;
        case HotspotSeverity.low:
          low++;
          break;
      }
    }

    return {
      'total': hotspots.length,
      'critical': critical,
      'high': high,
      'moderate': moderate,
      'low': low,
      'totalIssues': totalIssues,
      'averageScore': totalScore / hotspots.length,
    };
  }

  /// Filter hotspots by minimum severity level
  static List<HotspotModel> filterBySeverity(
    List<HotspotModel> hotspots,
    HotspotSeverity minSeverity,
  ) {
    return hotspots.where((h) {
      switch (minSeverity) {
        case HotspotSeverity.low:
          return true;
        case HotspotSeverity.moderate:
          return h.severity == HotspotSeverity.moderate ||
              h.severity == HotspotSeverity.high ||
              h.severity == HotspotSeverity.critical;
        case HotspotSeverity.high:
          return h.severity == HotspotSeverity.high ||
              h.severity == HotspotSeverity.critical;
        case HotspotSeverity.critical:
          return h.severity == HotspotSeverity.critical;
      }
    }).toList();
  }
}
