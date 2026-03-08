import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/screens/login_screen.dart';
import '../../features/authentication/screens/signup_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/workout_builder/screens/workout_builder_screen.dart';
import '../../features/workout_session/screens/workout_session_screen.dart';
import '../../features/recovery/screens/recovery_screen.dart';
import '../../features/analytics/screens/analytics_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
// ── New features ──────────────────────────────────────────────────────────────
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/exercise_library/screens/exercise_library_screen.dart';
import '../../features/health_tracking/screens/health_tracking_screen.dart';
import '../constants/app_constants.dart';

/// Central [GoRouter] configuration for LEON.
///
/// All routes are declared here. Feature teams should NOT create their own
/// routers; add named sub-routes to the appropriate [GoRoute] instead.
final class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppConstants.routeDashboard,
    debugLogDiagnostics: true,
    routes: [
      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(
        path: AppConstants.routeLogin,
        name: 'login',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.routeSignup,
        name: 'signup',
        builder: (BuildContext context, GoRouterState state) =>
            const SignupScreen(),
      ),

      // ── Main Shell ────────────────────────────────────────────────────────
      GoRoute(
        path: AppConstants.routeDashboard,
        name: 'dashboard',
        builder: (BuildContext context, GoRouterState state) =>
            const DashboardScreen(),
      ),
      GoRoute(
        path: AppConstants.routeWorkoutBuilder,
        name: 'workout-builder',
        builder: (BuildContext context, GoRouterState state) =>
            const WorkoutBuilderScreen(),
      ),
      GoRoute(
        path: AppConstants.routeWorkoutSession,
        name: 'workout-session',
        builder: (BuildContext context, GoRouterState state) =>
            const WorkoutSessionScreen(),
      ),
      GoRoute(
        path: AppConstants.routeRecovery,
        name: 'recovery',
        builder: (BuildContext context, GoRouterState state) =>
            const RecoveryScreen(),
      ),
      GoRoute(
        path: AppConstants.routeAnalytics,
        name: 'analytics',
        builder: (BuildContext context, GoRouterState state) =>
            const AnalyticsScreen(),
      ),
      GoRoute(
        path: AppConstants.routeProfile,
        name: 'profile',
        builder: (BuildContext context, GoRouterState state) =>
            const ProfileScreen(),
      ),

      // ── New Features ────────────────────────────────────────────────────
      GoRoute(
        path: AppConstants.routeOnboarding,
        name: 'onboarding',
        builder: (BuildContext context, GoRouterState state) =>
            const OnboardingScreen(),
      ),
      GoRoute(
        path: AppConstants.routeExerciseLibrary,
        name: 'exercise-library',
        builder: (BuildContext context, GoRouterState state) =>
            const ExerciseLibraryScreen(),
      ),
      GoRoute(
        path: AppConstants.routeHealthTracking,
        name: 'health-tracking',
        builder: (BuildContext context, GoRouterState state) =>
            const HealthTrackingScreen(),
      ),
    ],

    // ── Error Page ────────────────────────────────────────────────────────
    errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
      body: Center(
        child: Text(
          'Route not found: ${state.uri.path}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    ),
  );
}
