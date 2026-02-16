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
import '../../features/paywall/presentation/screens/paywall_screen.dart';
import '../../features/assistant/presentation/screens/global_chat_screen.dart';
import '../../features/legal/presentation/screens/legal_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../theme/app_animations.dart';
import 'routes.dart';
import 'sanctuary_shell.dart';

/// iOS-style slide-from-right page transition.
CustomTransitionPage<void> _slideFromRight(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionDuration: AppAnimations.durationSlow,
    reverseTransitionDuration: AppAnimations.durationSlow,
    transitionsBuilder: (_, animation, __, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: AppAnimations.curveStandard,
        )),
        child: child,
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
      // Allow paywall access without auth (from onboarding "Try Pro Free")
      if (!isLoggedIn && !isAuthRoute && !isOnboardingRoute && !isPaywallRoute) {
        return Routes.login;
      }

      // Logged in but on an auth route → home
      if (isLoggedIn && isAuthRoute) return Routes.home;

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
        path: Routes.chat,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideFromRight(
          ChatScreen(
            courseId: state.pathParameters['courseId'] ?? '',
          ),
        ),
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
