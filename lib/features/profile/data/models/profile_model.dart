/// Model representing a user profile from the `profiles` table.
class ProfileModel {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final int streakDays;
  final int totalCourses;
  final String? averageGrade;
  final bool aiConsentAccepted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProfileModel({
    required this.id,
    this.fullName,
    this.avatarUrl,
    this.streakDays = 0,
    this.totalCourses = 0,
    this.averageGrade,
    this.aiConsentAccepted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      streakDays: (json['streak_days'] as num?)?.toInt() ?? 0,
      totalCourses: (json['total_courses'] as num?)?.toInt() ?? 0,
      averageGrade: json['average_grade'] as String?,
      aiConsentAccepted: json['ai_consent_accepted'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'streak_days': streakDays,
      'total_courses': totalCourses,
      'average_grade': averageGrade,
      'ai_consent_accepted': aiConsentAccepted,
    };
  }

  ProfileModel copyWith({
    String? fullName,
    String? avatarUrl,
    int? streakDays,
    int? totalCourses,
    String? averageGrade,
    bool? aiConsentAccepted,
  }) {
    return ProfileModel(
      id: id,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      streakDays: streakDays ?? this.streakDays,
      totalCourses: totalCourses ?? this.totalCourses,
      averageGrade: averageGrade ?? this.averageGrade,
      aiConsentAccepted: aiConsentAccepted ?? this.aiConsentAccepted,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// First letter of the user's name for the avatar circle.
  String get initials {
    if (fullName == null || fullName!.isEmpty) return '?';
    return fullName![0].toUpperCase();
  }

  /// First name only (for greetings like "Good Morning, Alex").
  String get firstName {
    if (fullName == null || fullName!.isEmpty) return 'Student';
    return fullName!.split(' ').first;
  }
}
