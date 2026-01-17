class LeaderboardEntry {
  final String fullName;
  final int score;

  LeaderboardEntry({required this.fullName, required this.score});

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      fullName: json['fullName']?.toString() ?? '',
      score: (json['score'] is int)
          ? json['score'] as int
          : int.tryParse(json['score']?.toString() ?? '') ?? 0,
    );
  }
}
