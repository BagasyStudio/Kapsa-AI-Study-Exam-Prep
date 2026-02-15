/// Centralized usage limits for the app.
///
/// Controls file size caps, daily rate limits, and text length
/// restrictions to prevent API cost abuse.
abstract final class AppLimits {
  // ── File limits (all users) ──

  /// Maximum file upload size in megabytes.
  static const int maxFileSizeMB = 25;

  /// Maximum file upload size in bytes.
  static const int maxFileSizeBytes = maxFileSizeMB * 1024 * 1024;

  /// Maximum pages allowed per PDF upload.
  static const int maxPdfPages = 100;

  // ── Text length limits (all users) ──

  /// Maximum characters per chat message.
  static const int maxChatMessageLength = 2000;

  /// Maximum characters for quick paste notes.
  static const int maxPasteLength = 5000;

  // ── Free tier daily limits ──

  static const Map<String, int> freeDailyLimits = {
    'chat': 1,
    'flashcards': 1,
    'quiz': 1,
    'ocr': 1,
    'whisper': 1,
    'oracle': 1,
  };

  // ── Pro tier daily limits ──
  //
  // Generous for core study features (flashcards, quiz).
  // OCR: 10 PDFs/day × 100 pages max = 1000 pages/day ceiling.

  static const Map<String, int> proDailyLimits = {
    'chat': 50,
    'flashcards': 50,
    'quiz': 30,
    'ocr': 10,
    'whisper': 20,
    'oracle': 50,
  };
}
