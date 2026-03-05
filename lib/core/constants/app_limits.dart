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

  // ── Free tier: unified credit pool ──
  //
  // Free users get 50 credits/day. Each feature costs 1-8 credits
  // based on API cost. Cheap text-only features cost less,
  // expensive vision/audio models cost more.

  /// Total credits available per day for free users.
  static const int freeCreditsPerDay = 50;

  /// Credit cost per feature use.
  ///
  /// Calibrated so free users get ~3-5 AI actions per day.
  /// Examples of a typical day:
  ///   1 flashcard gen (15) + 1 quiz (15) + 2 snap solves (16) = 46/50
  ///   1 OCR (25) + 1 summary (15) + 1 chat (10) = 50/50
  ///   3 chats (30) + 1 flashcard gen (15) = 45/50
  static const Map<String, int> creditCost = {
    'chat': 10, // ~5 messages/day max
    'oracle': 10, // ~5 questions/day max
    'snap_solve': 8, // ~6 snaps/day max
    'glossary': 10, // ~5/day max
    'flashcards': 15, // ~3 generations/day max
    'quiz': 15, // ~3 quizzes/day max
    'summary': 15, // ~3 summaries/day max
    'audio_summary': 15, // ~3/day max
    'whisper': 25, // ~2 audio files/day max
    'ocr': 25, // ~2 PDFs/day max
  };

  // ── Pro tier daily limits (per-feature safety net) ──
  //
  // Pro users have no credit pool — they get generous per-feature limits
  // as an anti-abuse safety net. Effectively unlimited for normal use.

  static const Map<String, int> proDailyLimits = {
    'chat': 50,
    'flashcards': 50,
    'quiz': 30,
    'ocr': 10,
    'whisper': 20,
    'oracle': 50,
    'snap_solve': 30,
    'audio_summary': 10,
    'summary': 10,
    'glossary': 10,
  };
}
