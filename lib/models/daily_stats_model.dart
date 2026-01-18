import 'package:flutter/material.dart';

/// Represents a single date-count pair from the API
class DateCount {
  final DateTime date;
  final int count;

  DateCount({required this.date, required this.count});

  factory DateCount.fromJson(Map<String, dynamic> json) {
    return DateCount(
      date: DateTime.parse(json['date'] as String),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Get formatted date string (e.g., "Jan 15")
  String get formattedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

/// Represents the 30-day stats response from the API
/// Format: {"created":[{"count":3,"date":"2026-01-18"}],"resolved":[]}
class MonthlyStatsResponse {
  final List<DateCount> created;
  final List<DateCount> resolved;

  MonthlyStatsResponse({required this.created, required this.resolved});

  factory MonthlyStatsResponse.fromJson(Map<String, dynamic> json) {
    final createdList =
        (json['created'] as List<dynamic>?)
            ?.map((e) => DateCount.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final resolvedList =
        (json['resolved'] as List<dynamic>?)
            ?.map((e) => DateCount.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return MonthlyStatsResponse(created: createdList, resolved: resolvedList);
  }

  /// Convert to daily stats for charting (combines created and resolved by date)
  List<DailyStats> toDailyStats() {
    final Map<String, DailyStats> statsMap = {};

    // Process created issues
    for (final item in created) {
      final dateKey = '${item.date.year}-${item.date.month}-${item.date.day}';
      statsMap[dateKey] = DailyStats(
        date: item.date,
        created: item.count,
        resolved: 0,
      );
    }

    // Process resolved issues
    for (final item in resolved) {
      final dateKey = '${item.date.year}-${item.date.month}-${item.date.day}';
      if (statsMap.containsKey(dateKey)) {
        statsMap[dateKey] = DailyStats(
          date: item.date,
          created: statsMap[dateKey]!.created,
          resolved: item.count,
        );
      } else {
        statsMap[dateKey] = DailyStats(
          date: item.date,
          created: 0,
          resolved: item.count,
        );
      }
    }

    // Sort by date
    final result = statsMap.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  /// Total created issues in the period
  int get totalCreated => created.fold(0, (sum, item) => sum + item.count);

  /// Total resolved issues in the period
  int get totalResolved => resolved.fold(0, (sum, item) => sum + item.count);

  /// Resolution rate percentage
  double get resolutionRate {
    if (totalCreated == 0) return 0;
    return (totalResolved / totalCreated * 100).clamp(0, 100);
  }
}

/// Represents daily statistics combining created and resolved counts
class DailyStats {
  final DateTime date;
  final int created;
  final int resolved;

  DailyStats({
    required this.date,
    required this.created,
    required this.resolved,
  });

  /// Get total issues for this day
  int get total => created + resolved;

  /// Get net issues (created - resolved)
  int get net => created - resolved;

  /// Get formatted date string (e.g., "Jan 15")
  String get formattedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Get short day name (e.g., "Mon")
  String get dayName {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
}

/// Summary statistics for the 30-day period
class MonthlyStatsSummary {
  final int totalCreated;
  final int totalResolved;
  final int pendingIssues;
  final double resolutionRate;
  final int peakCreatedDay;
  final int avgDailyCreated;

  MonthlyStatsSummary({
    required this.totalCreated,
    required this.totalResolved,
    required this.pendingIssues,
    required this.resolutionRate,
    required this.peakCreatedDay,
    required this.avgDailyCreated,
  });

  factory MonthlyStatsSummary.fromDailyStats(List<DailyStats> stats) {
    if (stats.isEmpty) {
      return MonthlyStatsSummary(
        totalCreated: 0,
        totalResolved: 0,
        pendingIssues: 0,
        resolutionRate: 0,
        peakCreatedDay: 0,
        avgDailyCreated: 0,
      );
    }

    int totalCreated = 0;
    int totalResolved = 0;
    int maxCreated = 0;
    int peakDayIndex = 0;

    for (int i = 0; i < stats.length; i++) {
      final s = stats[i];
      totalCreated += s.created;
      totalResolved += s.resolved;

      if (s.created > maxCreated) {
        maxCreated = s.created;
        peakDayIndex = i;
      }
    }

    final pending = totalCreated - totalResolved;

    return MonthlyStatsSummary(
      totalCreated: totalCreated,
      totalResolved: totalResolved,
      pendingIssues: pending > 0 ? pending : 0,
      resolutionRate: totalCreated > 0
          ? (totalResolved / totalCreated * 100)
          : 0,
      peakCreatedDay: peakDayIndex,
      avgDailyCreated: stats.isNotEmpty
          ? (totalCreated / stats.length).round()
          : 0,
    );
  }
}

/// Represents a stage with its color for chart display
class StageData {
  final String name;
  final String displayName;
  final Color color;
  final int count;

  const StageData({
    required this.name,
    required this.displayName,
    required this.color,
    required this.count,
  });

  static Color getStageColor(String stage) {
    switch (stage) {
      case 'CREATED':
        return const Color(0xFF1976D2); // Blue
      case 'RESOLVED':
        return const Color(0xFF43A047); // Green
      case 'PENDING':
        return const Color(0xFFE53935); // Red
      default:
        return Colors.grey;
    }
  }

  static String getDisplayName(String stage) {
    switch (stage) {
      case 'CREATED':
        return 'Created';
      case 'RESOLVED':
        return 'Resolved';
      case 'PENDING':
        return 'Pending';
      default:
        return stage;
    }
  }
}
