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
  /// Lower cost = cheaper API call (text-only LLM).
  /// Higher cost = expensive model (vision, OCR, audio).
  static const Map<String, int> creditCost = {
    'chat': 1, // llama-3-8b text — cheapest
    'oracle': 2, // llama-3-8b text
    'snap_solve': 2, // llama3.2-vision — moderate
    'glossary': 2, // llama-3-8b text
    'flashcards': 3, // llama-3-8b text — core feature
    'quiz': 3, // llama-3-8b text — core feature
    'summary': 3, // llama-3-8b text
    'audio_summary': 3, // llama-3-8b text
    'whisper': 5, // fast-whisper audio — moderate
    'ocr': 8, // gemma-3-27b vision — expensive
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
