/// User model representing the authenticated user's profile data.
class UserModel {
  final String id;
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final String? role;
  final int? age;
  final String? gender;
  final String? location;
  final bool isVerified;
  final int issuesReported;
  final int issuesResolved;
  final int issuesInProgress;
  final int leaderboardRank;
  final int totalPoints;
  final List<String> badges;
  final String? memberSince;

  const UserModel({
    required this.id,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.role,
    this.age,
    this.gender,
    this.location,
    this.isVerified = false,
    this.issuesReported = 0,
    this.issuesResolved = 0,
    this.issuesInProgress = 0,
    this.leaderboardRank = 0,
    this.totalPoints = 0,
    this.badges = const [],
    this.memberSince,
  });

  /// Create UserModel from JSON response
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      role: json['role'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      location: json['location'] as String?,
      isVerified: json['isVerified'] == true,
      issuesReported: (json['issuesReported'] as int?) ?? 0,
      issuesResolved: (json['issuesResolved'] as int?) ?? 0,
      issuesInProgress: (json['issuesInProgress'] as int?) ?? 0,
      leaderboardRank: (json['leaderboardRank'] as int?) ?? 0,
      totalPoints: (json['totalPoints'] as int?) ?? 0,
      badges:
          (json['badges'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      memberSince: json['memberSince'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'age': age,
      'gender': gender,
      'location': location,
      'isVerified': isVerified,
      'issuesReported': issuesReported,
      'issuesResolved': issuesResolved,
      'issuesInProgress': issuesInProgress,
      'leaderboardRank': leaderboardRank,
      'totalPoints': totalPoints,
      'badges': badges,
      'memberSince': memberSince,
    };
  }

  /// Get user initials for avatar
  String get initials {
    if (fullName == null || fullName!.isEmpty) return '?';
    final parts = fullName!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName![0].toUpperCase();
  }

  /// Get display name
  String get displayName => fullName ?? 'User';

  /// Get display role
  String get displayRole {
    if (role == null) return 'Citizen';
    // Convert CITIZEN to Citizen, DEPARTMENT_HEAD to Department Head, etc.
    return role!
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  /// Get display location
  String get displayLocation => location ?? 'Location not set';

  /// Get display email
  String get displayEmail => email ?? 'Email not set';

  /// Get display phone
  String get displayPhone => phoneNumber ?? 'Phone not set';

  /// Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? role,
    int? age,
    String? gender,
    String? location,
    bool? isVerified,
    int? issuesReported,
    int? issuesResolved,
    int? issuesInProgress,
    int? leaderboardRank,
    int? totalPoints,
    List<String>? badges,
    String? memberSince,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      location: location ?? this.location,
      isVerified: isVerified ?? this.isVerified,
      issuesReported: issuesReported ?? this.issuesReported,
      issuesResolved: issuesResolved ?? this.issuesResolved,
      issuesInProgress: issuesInProgress ?? this.issuesInProgress,
      leaderboardRank: leaderboardRank ?? this.leaderboardRank,
      totalPoints: totalPoints ?? this.totalPoints,
      badges: badges ?? this.badges,
      memberSince: memberSince ?? this.memberSince,
    );
  }
}
