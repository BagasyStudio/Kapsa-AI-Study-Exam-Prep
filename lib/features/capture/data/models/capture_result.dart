/// Structured result from a successful material capture/upload.
class CaptureResult {
  final String materialId;
  final String courseId;
  final String materialType; // 'pdf', 'audio', 'notes', 'paste'
  final String displayTitle;

  const CaptureResult({
    required this.materialId,
    required this.courseId,
    required this.materialType,
    required this.displayTitle,
  });
}
