import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../capture/data/models/capture_result.dart';
import '../../courses/presentation/providers/course_provider.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../../core/providers/supabase_provider.dart';

/// Study area options matching the onboarding indices.
const _studyAreaNames = [
  'Sciences',
  'Engineering',
  'Law',
  'Medicine',
  'Economics',
  'Arts',
  'Computer Science',
  'Other',
];

/// Processes material uploaded during onboarding after the user signs up.
///
/// Creates a course, uploads the file, processes it, and returns a [CaptureResult]
/// so the PostUploadToolSelector can be shown immediately.
Future<CaptureResult?> processOnboardingMaterial(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();

  // Already processed?
  if (prefs.getBool('onboarding_material_processed') ?? false) return null;

  final materialPath = prefs.getString('onboarding_material_path');
  final materialType = prefs.getString('onboarding_material_type');

  if (materialPath == null || materialType == null) return null;

  // Check file exists
  final file = File(materialPath);
  if (!file.existsSync()) {
    await _clearOnboardingKeys(prefs);
    return null;
  }

  try {
    final user = ref.read(currentUserProvider);
    if (user == null) return null;

    final client = ref.read(supabaseClientProvider);
    final courseRepo = ref.read(courseRepositoryProvider);
    final materialRepo = ref.read(materialRepositoryProvider);

    // Determine course title from study area
    final studyAreaIndex = prefs.getInt('onboarding_study_area');
    final courseTitle = (studyAreaIndex != null &&
            studyAreaIndex >= 0 &&
            studyAreaIndex < _studyAreaNames.length)
        ? _studyAreaNames[studyAreaIndex]
        : 'My First Course';

    // Create course
    final course = await courseRepo.createCourse(
      userId: user.id,
      title: courseTitle,
    );

    // Upload file to Supabase Storage
    final fileBytes = await file.readAsBytes();
    final ext = materialType == 'pdf' ? 'pdf' : 'jpg';
    final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await client.storage.from('course-materials').uploadBinary(fileName, fileBytes);
    final fileUrl = client.storage.from('course-materials').getPublicUrl(fileName);

    // Process material
    final type = materialType == 'pdf' ? 'pdf' : 'ocr';
    final material = await materialRepo.processCapture(
      courseId: course.id,
      type: type,
      fileUrl: fileUrl,
      title: materialType == 'pdf' ? 'Uploaded PDF' : 'Scanned Page',
    );

    // Clean up
    await _clearOnboardingKeys(prefs);
    // Delete the persistent copy
    try { await file.delete(); } catch (e) { debugPrint('OnboardingMaterialProcessor: file delete failed: $e'); }

    // Refresh courses list
    ref.invalidate(coursesProvider);

    return CaptureResult(
      materialId: material.id,
      courseId: course.id,
      materialType: material.type,
      displayTitle: material.displayTitle,
    );
  } catch (e) {
    debugPrint('OnboardingMaterialProcessor: failed: $e');
    await _clearOnboardingKeys(prefs);
    return null;
  }
}

Future<void> _clearOnboardingKeys(SharedPreferences prefs) async {
  await prefs.remove('onboarding_material_path');
  await prefs.remove('onboarding_material_type');
  await prefs.remove('onboarding_flashcard_count');
  await prefs.remove('onboarding_quiz_count');
  await prefs.remove('onboarding_study_area');
  await prefs.setBool('onboarding_material_processed', true);
}
