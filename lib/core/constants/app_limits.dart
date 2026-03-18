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
  // Free users get 100 credits/day — enough for a meaningful daily
  // study session (1 flashcard gen + 1 quiz + a few chats/snaps).
  // This keeps users engaged and coming back daily while still
  // incentivizing Pro for power users who study more.

  /// Total credits available per day for free users.
  static const int freeCreditsPerDay = 100;

  /// Credit cost per feature use.
  ///
  /// Calibrated for a generous free tier that lets users experience
  /// real value every day. Typical daily sessions for free users:
  ///
  ///   Standard day:
  ///     1 flashcard gen (15) + 1 quiz (15) + 3 chats (15)
  ///     + 2 snap solves (10) + 1 summary (15) = 70/100
  ///
  ///   Heavy day:
  ///     2 flashcard gens (30) + 1 quiz (15) + 1 PDF upload (20)
  ///     + 3 chats (15) + 2 snap solves (10) = 90/100
  ///
  ///   Power user (hits limit):
  ///     2 flashcard gens (30) + 2 quizzes (30) + 1 PDF (20)
  ///     + 1 summary (15) + 1 chat (5) = 100/100
  static const Map<String, int> creditCost = {
    'chat': 5, // ~20 messages/day
    'oracle': 5, // ~20 questions/day
    'snap_solve': 5, // ~20 snaps/day
    'glossary': 10, // ~10/day
    'flashcards': 15, // ~6 generations/day
    'quiz': 15, // ~6 quizzes/day
    'summary': 15, // ~6 summaries/day
    'audio_summary': 15, // ~6/day
    'whisper': 20, // ~5 audio files/day
    'ocr': 20, // ~5 PDFs/day
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
