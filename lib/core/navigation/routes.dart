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
  static const srsReview = '/srs-review/:courseId';
  static const chat = '/chat/:courseId';
  static const quizSession = '/quiz-session/:testId';
  static const testResults = '/test-results/:testId';
  static const materialViewer = '/material/:courseId/:materialId';
  static const oracle = '/oracle';
  static const snapSolve = '/snap-solve';
  static const practiceExam = '/practice-exam';
  static const importDeck = '/import-deck/:courseId';
  static const paywall = '/paywall';
  static const audioPlayer = '/audio-player/:materialId';
  static const occlusionEditor = '/occlusion-editor/:courseId';
  static const groupsList = '/groups';
  static const groupDetail = '/groups/:groupId';
  static const createGroup = '/groups/create';
  static const joinGroup = '/groups/join';
  static const knowledgeScore = '/knowledge-score';
  static const monthReview = '/month-review';
  static const summary = '/summary/:summaryId';
  static const glossary = '/glossary/:courseId';
  static const studyPath = '/study-path';

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
  static String srsReviewPath(String courseId) => '/srs-review/$courseId';
  static String chatPath(String courseId) => '/chat/$courseId';
  static String quizSessionPath(String testId) => '/quiz-session/$testId';
  static String testResultsPath(String testId) => '/test-results/$testId';
  static String materialViewerPath(String courseId, String materialId) =>
      '/material/$courseId/$materialId';
  static String snapSolvePath() => '/snap-solve';
  static String importDeckPath(String courseId) => '/import-deck/$courseId';
  static String audioPlayerPath(String materialId, String courseId, String title) =>
      '/audio-player/$materialId?courseId=$courseId&title=${Uri.encodeComponent(title)}';
  static String occlusionEditorPath(String courseId) =>
      '/occlusion-editor/$courseId';
  static String groupDetailPath(String groupId) => '/groups/$groupId';
  static String summaryPath(String summaryId) => '/summary/$summaryId';
  static String glossaryPath(String courseId) => '/glossary/$courseId';
}
