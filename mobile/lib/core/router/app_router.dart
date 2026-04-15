import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cadence/features/auth/providers/auth_provider.dart';
import 'package:cadence/features/auth/screens/login_screen.dart';
import 'package:cadence/features/auth/screens/signup_screen.dart';
import 'package:cadence/features/auth/screens/forgot_password_screen.dart';
import 'package:cadence/features/onboarding/screens/onboarding_screen.dart';
import 'package:cadence/features/shell/screens/main_shell.dart';
import 'package:cadence/features/home/screens/home_screen.dart';
import 'package:cadence/features/learn/screens/learn_screen.dart';
import 'package:cadence/features/learn/screens/module_detail_screen.dart';
import 'package:cadence/features/learn/screens/practice_screen.dart';
import 'package:cadence/features/conversation/screens/conversation_screen.dart';
import 'package:cadence/features/conversation/screens/session_screen.dart';
import 'package:cadence/features/coach/screens/coach_screen.dart';
import 'package:cadence/features/profile/screens/profile_screen.dart';
import 'package:cadence/core/models/lesson_model.dart';

// Route names
class Routes {
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const learn = '/learn';
  static const moduleDetail = '/learn/:moduleId';
  static const practice = '/learn/:moduleId/practice/:lessonId';
  static const conversation = '/conversation';
  static const conversationSession = '/conversation/:moduleId';
  static const coach = '/coach';
  static const profile = '/profile';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);

  return GoRouter(
    initialLocation: Routes.home,
    refreshListenable: _AuthChangeNotifier(ref),
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      // Wait for auth to initialize
      if (!authState.isInitialized) return null;

      final isLoggedIn = authState.isAuthenticated;
      final isOnAuthPage = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/signup') ||
          state.matchedLocation.startsWith('/forgot-password');
      final isOnboarding = state.matchedLocation == Routes.onboarding;

      if (!isLoggedIn && !isOnAuthPage) {
        return Routes.login;
      }

      if (isLoggedIn && isOnAuthPage) {
        if (!authState.hasOnboarded) return Routes.onboarding;
        return Routes.home;
      }

      if (isLoggedIn && !authState.hasOnboarded && !isOnboarding) {
        return Routes.onboarding;
      }

      return null;
    },
    routes: [
      // Auth routes (no shell)
      GoRoute(
        path: Routes.login,
        pageBuilder: (context, state) => _fadeTransition(
          state,
          const LoginScreen(),
        ),
      ),
      GoRoute(
        path: Routes.signup,
        pageBuilder: (context, state) => _fadeTransition(
          state,
          const SignupScreen(),
        ),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        pageBuilder: (context, state) => _fadeTransition(
          state,
          const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: Routes.onboarding,
        pageBuilder: (context, state) => _fadeTransition(
          state,
          const OnboardingScreen(),
        ),
      ),

      // Main app shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: Routes.home,
            pageBuilder: (context, state) =>
                _slideTransition(state, const HomeScreen()),
          ),
          GoRoute(
            path: Routes.learn,
            pageBuilder: (context, state) =>
                _slideTransition(state, const LearnScreen()),
          ),
          GoRoute(
            path: Routes.conversation,
            pageBuilder: (context, state) =>
                _slideTransition(state, const ConversationScreen()),
          ),
          GoRoute(
            path: Routes.coach,
            pageBuilder: (context, state) =>
                _slideTransition(state, const CoachScreen()),
          ),
          GoRoute(
            path: Routes.profile,
            pageBuilder: (context, state) =>
                _slideTransition(state, const ProfileScreen()),
          ),
        ],
      ),

      // Lesson routes (full-screen, no shell)
      GoRoute(
        path: '/learn/:moduleId',
        pageBuilder: (context, state) {
          final moduleId = state.pathParameters['moduleId']!;
          final title = state.uri.queryParameters['title'] ?? '';
          return _slideTransition(
            state,
            ModuleDetailScreen(moduleId: moduleId, title: title),
          );
        },
      ),
      GoRoute(
        path: '/learn/:moduleId/practice/:lessonId',
        pageBuilder: (context, state) {
          final lesson = state.extra as LessonModel;
          return _slideTransition(state, PracticeScreen(lesson: lesson));
        },
      ),
      GoRoute(
        path: '/conversation/:moduleId',
        pageBuilder: (context, state) {
          final moduleId = state.pathParameters['moduleId']!;
          final title = state.uri.queryParameters['title'] ?? '';
          return _slideTransition(
            state,
            ConversationSessionScreen(moduleId: moduleId, title: title),
          );
        },
      ),
    ],
  );
});

CustomTransitionPage _fadeTransition(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 200),
    );

CustomTransitionPage _slideTransition(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, _, child) {
        final tween =
            Tween(begin: const Offset(0.04, 0), end: Offset.zero).chain(
          CurveTween(curve: Curves.easeOutCubic),
        );
        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
    );

/// Notifies GoRouter when auth state changes.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(ProviderRef ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}
