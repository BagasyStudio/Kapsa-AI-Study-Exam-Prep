import 'package:flutter/material.dart';

/// Model representing a course from the `courses` table.
class CourseModel {
  final String id;
  final String userId;
  final String title;
  final String? subtitle;
  final String iconName;
  final String colorHex;
  final double progress;
  final DateTime? examDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CourseModel({
    required this.id,
    required this.userId,
    required this.title,
    this.subtitle,
    this.iconName = 'menu_book',
    this.colorHex = '6467F2',
    this.progress = 0.0,
    this.examDate,
    this.createdAt,
    this.updatedAt,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      iconName: json['icon_name'] as String? ?? 'menu_book',
      colorHex: json['color_hex'] as String? ?? '6467F2',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      examDate: json['exam_date'] != null
          ? DateTime.parse(json['exam_date'] as String)
          : null,
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
      'user_id': userId,
      'title': title,
      'subtitle': subtitle,
      'icon_name': iconName,
      'color_hex': colorHex,
      'progress': progress,
      'exam_date': examDate?.toIso8601String(),
    };
  }

  CourseModel copyWith({
    String? title,
    String? subtitle,
    String? iconName,
    String? colorHex,
    double? progress,
    DateTime? examDate,
  }) {
    return CourseModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      progress: progress ?? this.progress,
      examDate: examDate ?? this.examDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Parse the hex color string into a Flutter Color.
  Color get color {
    final hex = colorHex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  /// Map icon name string to IconData.
  ///
  /// Also handles legacy codePoint strings from older course records.
  IconData get icon {
    const iconMap = <String, IconData>{
      'menu_book': Icons.menu_book,
      'biotech': Icons.biotech,
      'history_edu': Icons.history_edu,
      'science': Icons.science,
      'calculate': Icons.calculate,
      'language': Icons.language,
      'music_note': Icons.music_note,
      'palette': Icons.palette,
      'psychology': Icons.psychology,
      'computer': Icons.computer,
      'gavel': Icons.gavel,
      'business': Icons.business,
      'sports_soccer': Icons.sports_soccer,
      'architecture': Icons.architecture,
    };

    // First try by name
    if (iconMap.containsKey(iconName)) return iconMap[iconName]!;

    // Fallback: try legacy codePoint format (e.g. "58725")
    final codePoint = int.tryParse(iconName);
    if (codePoint != null) {
      for (final entry in iconMap.entries) {
        if (entry.value.codePoint == codePoint) return entry.value;
      }
    }

    return Icons.menu_book;
  }
}
