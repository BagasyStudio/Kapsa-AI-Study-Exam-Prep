import 'package:flutter/material.dart';

import '../utils/title_utils.dart';

/// Types of AI generation the user can trigger.
enum GenerationType { flashcards, quiz, summary, glossary }

/// Status of a background generation task.
enum GenerationStatus { running, completed, error }

/// Immutable snapshot of one background AI generation job.
@immutable
class GenerationTask {
  final String id;
  final GenerationType type;
  final String courseId;
  final String courseName;
  final GenerationStatus status;
  final String? resultRoute;
  final String? errorMessage;
  final DateTime startedAt;
  final DateTime? completedAt;

  const GenerationTask({
    required this.id,
    required this.type,
    required this.courseId,
    required this.courseName,
    required this.status,
    this.resultRoute,
    this.errorMessage,
    required this.startedAt,
    this.completedAt,
  });

  GenerationTask copyWith({
    GenerationStatus? status,
    String? resultRoute,
    String? errorMessage,
    DateTime? completedAt,
  }) {
    return GenerationTask(
      id: id,
      type: type,
      courseId: courseId,
      courseName: courseName,
      status: status ?? this.status,
      resultRoute: resultRoute ?? this.resultRoute,
      errorMessage: errorMessage ?? this.errorMessage,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  bool get isRunning => status == GenerationStatus.running;
  bool get isCompleted => status == GenerationStatus.completed;
  bool get isError => status == GenerationStatus.error;

  /// Clean display name for UI (strip prefix, humanize).
  String get displayCourseName => cleanDisplayTitle(courseName);

  /// Human-readable label for each type.
  String get typeLabel {
    switch (type) {
      case GenerationType.flashcards:
        return 'Flashcards';
      case GenerationType.quiz:
        return 'Quiz';
      case GenerationType.summary:
        return 'Summary';
      case GenerationType.glossary:
        return 'Glossary';
    }
  }

  /// Icon for each generation type.
  IconData get typeIcon {
    switch (type) {
      case GenerationType.flashcards:
        return Icons.style;
      case GenerationType.quiz:
        return Icons.quiz;
      case GenerationType.summary:
        return Icons.auto_stories;
      case GenerationType.glossary:
        return Icons.menu_book;
    }
  }

  /// Accent color for each generation type.
  Color get typeColor {
    switch (type) {
      case GenerationType.flashcards:
        return const Color(0xFF3B82F6);
      case GenerationType.quiz:
        return const Color(0xFF10B981);
      case GenerationType.summary:
        return const Color(0xFF06B6D4);
      case GenerationType.glossary:
        return const Color(0xFF8B5CF6);
    }
  }
}
