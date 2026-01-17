class IssueModel {
  final String id;
  final String title;
  final String description;
  final String type;
  final String status;
  final String criticality;
  final String location;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<IssueTimeline> timeline;

  IssueModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.criticality,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.timeline,
  });

  factory IssueModel.fromJson(Map<String, dynamic> json) {
    List<IssueTimeline> timelineList = [];
    if (json['timeline'] != null) {
      timelineList = (json['timeline'] as List)
          .map((t) => IssueTimeline.fromJson(t))
          .toList();
    }

    return IssueModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      type: json['type']?.toString() ?? json['issueType']?.toString() ?? '',
      status:
          json['status']?.toString() ?? json['stages']?.toString() ?? 'Pending',
      criticality: json['criticality']?.toString() ?? 'Medium',
      location:
          json['location']?.toString() ?? json['address']?.toString() ?? '',
      latitude: _parseDouble(json['latitude'] ?? json['lat']),
      longitude: _parseDouble(json['longitude'] ?? json['lng'] ?? json['lon']),
      imageUrl: json['imageUrl']?.toString() ?? json['image']?.toString(),
      userId: json['userId']?.toString() ?? json['user']?.toString() ?? '',
      createdAt: _parseDate(
        json['createdAt'] ?? json['createAt'] ?? json['created_at'],
      ),
      updatedAt: _parseDate(
        json['updatedAt'] ?? json['updateAt'] ?? json['updated_at'],
      ),
      timeline: timelineList,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'status': status,
      'criticality': criticality,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'timeline': timeline.map((t) => t.toJson()).toList(),
    };
  }

  String get formattedDate {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[createdAt.month - 1]} ${createdAt.day}, ${createdAt.year}';
  }
}

class IssueTimeline {
  final String status;
  final String date;
  final String description;

  IssueTimeline({
    required this.status,
    required this.date,
    required this.description,
  });

  factory IssueTimeline.fromJson(Map<String, dynamic> json) {
    return IssueTimeline(
      status: json['status']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'date': date, 'description': description};
  }
}
