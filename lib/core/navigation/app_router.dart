import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/delete_account_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/courses/presentation/screens/courses_list_screen.dart';
import '../../features/courses/presentation/screens/course_detail_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/flashcards/presentation/screens/flashcard_session_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/test_results/presentation/screens/test_results_screen.dart';
import '../../features/test_results/presentation/screens/quiz_session_screen.dart';
import '../../features/test_results/presentation/screens/practice_exam_setup_screen.dart';
import '../../features/flashcards/presentation/screens/deck_list_screen.dart';
import '../../features/flashcards/presentation/screens/import_deck_screen.dart';
import '../../features/flashcards/presentation/screens/srs_review_screen.dart';
import '../../features/paywall/presentation/screens/paywall_screen.dart';
import '../../features/assistant/presentation/screens/global_chat_screen.dart';
import '../../features/snap_solve/presentation/screens/snap_solve_screen.dart';
import '../../features/courses/presentation/screens/material_viewer_screen.dart';
import '../../features/legal/presentation/screens/legal_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/audio_summary/presentation/screens/audio_player_screen.dart';
import '../../features/image_occlusion/presentation/screens/occlusion_editor_screen.dart';
import '../../features/groups/presentation/screens/groups_list_screen.dart';
import '../../features/groups/presentation/screens/group_detail_screen.dart';
import '../../features/groups/presentation/screens/create_group_screen.dart';
import '../../features/groups/presentation/screens/join_group_screen.dart';
import '../../features/sharing/presentation/screens/knowledge_score_screen.dart';
import '../../features/sharing/presentation/screens/month_review_screen.dart';
import '../theme/app_animations.dart';
import 'routes.dart';
import 'sanctuary_shell.dart';

/// iOS-style slide-from-right page transition with parallax.
///
/// Mirrors native CupertinoPageRoute behaviour:
/// - New page slides in from the right edge
/// - Previous page shifts ~1/3 to the left (parallax)
/// - A vertical shadow decorates the leading edge of the incoming page
/// - Uses the same decelerate curve Apple employs (easeOut)
CustomTransitionPage<void> _slideFromRight(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Incoming page: slides from right (1.0 -> 0.0)
      final incomingSlide = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ));

      // Previous page: parallax shift left (0.0 -> -0.33)
      final outgoingSlide = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.33, 0),
      ).animate(CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ));

      // Edge shadow that fades with the transition
      final shadowOpacity = animation.drive(
        Tween<double>(begin: 0, end: 1)
            .chain(CurveTween(curve: Curves.easeOut)),
      );

      return SlideTransition(
        position: outgoingSlide,
        child: SlideTransition(
          position: incomingSlide,
          child: DecoratedBoxTransition(
            decoration: DecorationTween(
              begin: const BoxDecoration(),
              end: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(-4, 0),
                  ),
                ],
              ),
            ).animate(shadowOpacity),
            child: child,
          ),
        ),
      );
    },
  );
}

/// Fade page transition for auth screens.
CustomTransitionPage<void> _fadeIn(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionDuration: AppAnimations.durationMedium,
    reverseTransitionDuration: AppAnimations.durationMedium,
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

/// Global navigation key for the root navigator.
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Listenable that notifies GoRouter when auth state changes.
///
/// This bridges the Supabase auth stream to GoRouter's refreshListenable.
class _AuthStateNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _subscription;

  _AuthStateNotifier() {
    _subscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      // Only react to meaningful auth changes (sign-in, sign-out).
      // Ignore tokenRefreshed / userUpdated — these fire on every
      // refreshSession() call and would cause false redirects to /login
      // when concurrent refreshes temporarily nullify the session.
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.signedOut) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Provider for the onboarding flag.
final hasSeenOnboardingProvider = StateProvider<bool>((ref) => true);

/// Flag: user tapped "Try Pro Free" → show paywall after login.
final pendingPaywallProvider = StateProvider<bool>((ref) => false);

/// GoRouter provider with auth-based redirect logic.
///
/// Observes auth state via [refreshListenable] and redirects:
/// - First-time users → /onboarding
/// - Unauthenticated users hitting protected routes → /login
/// - Authenticated users hitting auth routes → /home
final goRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthStateNotifier();
  final hasSeenOnboarding = ref.watch(hasSeenOnboardingProvider);

  ref.onDispose(() => authNotifier.dispose());

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.home,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isAuthRoute = state.matchedLocation == Routes.login ||
          state.matchedLocation == Routes.register;
      final isOnboardingRoute = state.matchedLocation == Routes.onboarding;
      final isPaywallRoute = state.matchedLocation == Routes.paywall;

      // First launch → show onboarding
      if (!hasSeenOnboarding && !isOnboardingRoute) {
        return Routes.onboarding;
      }

      // On onboarding but already seen → move on
      if (hasSeenOnboarding && isOnboardingRoute) {
        return isLoggedIn ? Routes.home : Routes.login;
      }

      // Not logged in and trying to access a protected route → login
      if (!isLoggedIn && !isAuthRoute && !isOnboardingRoute && !isPaywallRoute) {
        return Routes.login;
      }

      // Logged in on auth route → check if paywall is pending
      if (isLoggedIn && isAuthRoute) {
        if (ref.read(pendingPaywallProvider)) {
          // Clear the flag and redirect to paywall
          ref.read(pendingPaywallProvider.notifier).state = false;
          return Routes.paywall;
        }
        return Routes.home;
      }

      // No redirect needed
      return null;
    },
    routes: [
      // ── Onboarding ──
      GoRoute(
        path: Routes.onboarding,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeIn(const OnboardingScreen()),
      ),

      // ── Auth routes (outside shell, no bottom nav) ──
      GoRoute(
        path: Routes.login,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeIn(const LoginScreen()),
      ),
      GoRoute(
        path: Routes.register,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeIn(const RegisterScreen()),
      ),

      // ── Shell with bottom navigation ──
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            KapsaShell(navigationShell: navigationShell),
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),

          // Branch 1: Courses
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.courses,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: CoursesListScreen(),
                ),
                routes: [
                  GoRoute(
                    path: ':courseId',
                    pageBuilder: (context, state) => _slideFromRight(
                      CourseDetailScreen(
                        courseId: state.pathParameters['courseId'] ?? '',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Branch 2: Calendar
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.calendar,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: CalendarScreen(),
                ),
              ),
            ],
          ),

          // Branch 3: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // ── Full-screen routes (outside shell = no bottom nav) ──

      GoRoute(
        path: Routes.flashcardSession,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: FlashcardSessionScreen(
            sessionId: state.pathParameters['sessionId'] ?? '',
          ),
          transitionDuration: AppAnimations.durationSlow,
          reverseTransitionDuration: AppAnimations.durationSlow,
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),

      GoRoute(
        path: Routes.deckList,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideFromRight(
          DeckListScreen(
            courseId: state.pathParameters['courseId'] ?? '',
          ),
        ),
      ),

      GoRoute(
        path: Routes.importDeck,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideFromRight(
          ImportDeckScreen(
            courseId: state.pathParameters['courseId'] ?? '',
          ),
        ),
      ),

      GoRoute(
        path: Routes.srsReview,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: SrsReviewScreen(
            courseId: state.pathParameters['courseId'] ?? '',
          ),
          transitionDuration: AppAnimations.durationSlow,
          reverseTransitionDuration: AppAnimations.durationSlow,
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),

      GoRoute(
        path: Routes.chat,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideFromRight(
          ChatScreen(
            courseId: state.pathParameters['courseId'] ?? '',
          ),
        ),
      ),

      GoRoute(
        path: Routes.quizSession,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final timeLimit = state.uri.queryParameters['timeLimit'];
          final isPracticeExam =
              state.uri.queryParameters['isPracticeExam'] == 'true';
          return CustomTransitionPage(
            child: QuizSessionScreen(
              testId: state.pathParameters['testId'] ?? '',
              timeLimitMinutes:
                  timeLimit != null ? int.tryParse(timeLimit) : null,
              isPracticeExam: isPracticeExam,
            ),
            transitionDuration: AppAnimations.durationSlow,
            reverseTransitionDuration: AppAnimations.durationSlow,
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          );
        },
      ),

      GoRoute(
        path: Routes.testResults,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideFromRight(
          TestResultsScreen(
            testId: state.pathParameters['testId'] ?? '',
          ),
        ),
      ),

      GoRoute(
        path: Routes.materialViewer,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideFromRight(
          MaterialViewerScreen(
            courseId: state.pathParameters['courseId'] ?? '',
            materialId: state.pathParameters['materialId'] ?? '',
          ),
        ),
      ),

      GoRoute(
        path: Routes.snapSolve,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const SnapSolveScreen(),
          transitionDuration: AppAnimations.durationSlow,
          reverseTransitionDuration: AppAnimations.durationSlow,
          transitionsBuilder: (_, animation, __, child) =>
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: AppAnimations.curveStandard,
                )),
                child: child,
              ),
        ),
      ),

      GoRoute(
        path: Routes.practiceExam,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideFromRight(
          const PracticeExamSetupScreen(),
        ),
      ),

      GoRoute(
        path: Routes.audioPlayer,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final courseId = state.uri.queryParameters['courseId'] ?? '';
          final title = state.uri.queryParameters['title'] ?? 'Material';
          return _slideFromRight(
            AudioPlayerScreen(
              materialId: state.pathParameters['materialId'] ?? '',
              courseId: courseId,
              materialTitle: title,
            ),
          );
        },
      ),

      GoRoute(
        path: Routes.occlusionEditor,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideFromRight(
          OcclusionEditorScreen(
            courseId: state.pathParameters['courseId'] ?? '',
          ),
        ),
      ),

      // ── Study Groups routes ──
      GoRoute(
        path: Routes.groupsList,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideFromRight(
          const GroupsListScreen(),
        ),
      ),
      GoRoute(
        path: Routes.createGroup,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideFromRight(
          const CreateGroupScreen(),
        ),
      ),
      GoRoute(
        path: Routes.joinGroup,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideFromRight(
          const JoinGroupScreen(),
        ),
      ),
      GoRoute(
        path: Routes.groupDetail,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideFromRight(
          GroupDetailScreen(
            groupId: state.pathParameters['groupId'] ?? '',
          ),
        ),
      ),

      GoRoute(
        path: Routes.knowledgeScore,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideFromRight(
          const KnowledgeScoreScreen(),
        ),
      ),

      GoRoute(
        path: Routes.monthReview,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideFromRight(
          const MonthReviewScreen(),
        ),
      ),

      GoRoute(
        path: Routes.oracle,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideFromRight(
          const GlobalChatScreen(),
        ),
      ),

      GoRoute(
        path: Routes.paywall,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const PaywallScreen(),
          transitionDuration: AppAnimations.durationSlow,
          reverseTransitionDuration: AppAnimations.durationSlow,
          transitionsBuilder: (_, animation, __, child) =>
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: AppAnimations.curveStandard,
                )),
                child: child,
              ),
        ),
      ),

      // ── Legal & Compliance routes ──

      GoRoute(
        path: Routes.terms,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideFromRight(
          const LegalScreen(
            title: 'Terms of Service',
            url: 'https://sites.google.com/view/kapsaaistudyexamprep/kapsa-app',
          ),
        ),
      ),

      GoRoute(
        path: Routes.privacy,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideFromRight(
          const LegalScreen(
            title: 'Privacy Policy',
            url: 'https://sites.google.com/view/kapsaaistudyexamprep/privacy-policy',
          ),
        ),
      ),

      GoRoute(
        path: Routes.deleteAccount,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideFromRight(
          const DeleteAccountScreen(),
        ),
      ),
    ],
  );
});
