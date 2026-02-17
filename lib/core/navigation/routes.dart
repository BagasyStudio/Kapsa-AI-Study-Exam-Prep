/// Route path constants for the app.
abstract final class Routes {
  // ── Auth ──
  static const login = '/login';
  static const register = '/register';

  // ── Shell tabs ──
  static const home = '/home';
  static const courses = '/courses';
  static const courseDetail = '/courses/:courseId';
  static const calendar = '/calendar';
  static const profile = '/profile';

  // ── Full-screen (outside shell) ──
  static const flashcardSession = '/flashcards/:sessionId';
  static const deckList = '/decks/:courseId';
  static const chat = '/chat/:courseId';
  static const quizSession = '/quiz-session/:testId';
  static const testResults = '/test-results/:testId';
  static const materialViewer = '/material/:courseId/:materialId';
  static const oracle = '/oracle';
  static const paywall = '/paywall';

  // ── Legal & Compliance ──
  static const terms = '/terms';
  static const privacy = '/privacy';
  static const deleteAccount = '/delete-account';

  // ── Onboarding ──
  static const onboarding = '/onboarding';

  // ── Helpers for path construction ──
  static String courseDetailPath(String courseId) => '/courses/$courseId';
  static String flashcardSessionPath(String sessionId) =>
      '/flashcards/$sessionId';
  static String deckListPath(String courseId) => '/decks/$courseId';
  static String chatPath(String courseId) => '/chat/$courseId';
  static String quizSessionPath(String testId) => '/quiz-session/$testId';
  static String testResultsPath(String testId) => '/test-results/$testId';
  static String materialViewerPath(String courseId, String materialId) =>
      '/material/$courseId/$materialId';
}
