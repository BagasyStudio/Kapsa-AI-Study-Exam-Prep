import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/course_model.dart';

/// Repository for course CRUD operations.
class CourseRepository {
  final SupabaseClient _client;

  CourseRepository(this._client);

  /// Fetch all courses for the given user.
  Future<List<CourseModel>> getCourses(String userId) async {
    final data = await _client
        .from('courses')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return (data as List).map((e) => CourseModel.fromJson(e)).toList();
  }

  /// Fetch a single course by ID.
  ///
  /// Returns null if course not found.
  Future<CourseModel?> getCourse(String courseId) async {
    final data = await _client
        .from('courses')
        .select()
        .eq('id', courseId)
        .maybeSingle();
    if (data == null) return null;
    return CourseModel.fromJson(data);
  }

  /// Create a new course.
  Future<CourseModel> createCourse({
    required String userId,
    required String title,
    String? subtitle,
    String iconName = 'menu_book',
    String colorHex = '6467F2',
    DateTime? examDate,
  }) async {
    final data = await _client
        .from('courses')
        .insert({
          'user_id': userId,
          'title': title,
          'subtitle': subtitle,
          'icon_name': iconName,
          'color_hex': colorHex,
          'exam_date': examDate?.toIso8601String(),
        })
        .select()
        .single();
    return CourseModel.fromJson(data);
  }

  /// Update course fields.
  Future<void> updateCourse(
    String courseId, {
    String? title,
    String? subtitle,
    String? iconName,
    String? colorHex,
    double? progress,
    DateTime? examDate,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (title != null) updates['title'] = title;
    if (subtitle != null) updates['subtitle'] = subtitle;
    if (iconName != null) updates['icon_name'] = iconName;
    if (colorHex != null) updates['color_hex'] = colorHex;
    if (progress != null) updates['progress'] = progress;
    if (examDate != null) updates['exam_date'] = examDate.toIso8601String();

    await _client.from('courses').update(updates).eq('id', courseId);
  }

  /// Recalculate and persist course progress (0.0 – 1.0).
  ///
  /// Progress uses two signals:
  ///  • Flashcard study (50%): reviewed cards + mastered bonus
  ///  • Quiz performance (50%): average score of evaluated tests
  ///
  /// If only one signal has data, it counts 100%.
  Future<void> recalculateProgress(String courseId) async {
    double? flashcardProgress;
    double? quizProgress;

    // ── Flashcard study ──────────────────────────────────────────
    final decks = await _client
        .from('flashcard_decks')
        .select('id')
        .eq('course_id', courseId);

    if ((decks as List).isNotEmpty) {
      final deckIds = decks.map((d) => d['id'] as String).toList();
      final cards = await _client
          .from('flashcards')
          .select('mastery, reps')
          .inFilter('deck_id', deckIds);

      final totalCards = (cards as List).length;
      if (totalCards > 0) {
        // Cards reviewed at least once count as 0.5 credit
        // Cards "mastered" count as 1.0 credit
        double credits = 0;
        for (final c in cards) {
          final mastery = c['mastery'] as String? ?? 'new';
          final reps = (c['reps'] as num?)?.toInt() ?? 0;
          if (mastery == 'mastered') {
            credits += 1.0;
          } else if (reps > 0 || mastery == 'learning') {
            credits += 0.5;
          }
        }
        flashcardProgress = credits / totalCards;
      }
    }

    // ── Quiz scores ──────────────────────────────────────────────
    // Use score when available, fallback to correct_count/total_count.
    final tests = await _client
        .from('tests')
        .select('score, correct_count, total_count')
        .eq('course_id', courseId)
        .eq('status', 'completed');

    if ((tests as List).isNotEmpty) {
      final scores = <double>[];
      for (final t in tests) {
        if (t['score'] != null) {
          // Score is 0.0–1.0 from edge function
          scores.add((t['score'] as num).toDouble());
        } else if (t['correct_count'] != null && t['total_count'] != null) {
          final correct = (t['correct_count'] as num).toInt();
          final total = (t['total_count'] as num).toInt();
          if (total > 0) scores.add(correct / total);
        }
      }
      if (scores.isNotEmpty) {
        quizProgress = scores.reduce((a, b) => a + b) / scores.length;
      }
    }

    // ── Combine ────────────────────────────────────────────────────
    double progress = 0.0;
    if (flashcardProgress != null && quizProgress != null) {
      progress = (flashcardProgress * 0.5) + (quizProgress * 0.5);
    } else if (flashcardProgress != null) {
      progress = flashcardProgress;
    } else if (quizProgress != null) {
      progress = quizProgress;
    }

    // Clamp to 0.0–1.0
    progress = progress.clamp(0.0, 1.0);

    await _client.from('courses').update({
      'progress': progress,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', courseId);
  }

  /// Batch recalculate progress for all user courses.
  ///
  /// Lightweight — runs in parallel. Call on home screen load.
  Future<void> recalculateAllProgress(String userId) async {
    final courses = await _client
        .from('courses')
        .select('id')
        .eq('user_id', userId);

    if ((courses as List).isEmpty) return;

    await Future.wait(
      courses.map((c) => recalculateProgress(c['id'] as String)),
    );
  }

  /// Delete a course.
  Future<void> deleteCourse(String courseId) async {
    await _client.from('courses').delete().eq('id', courseId);
  }
}
