import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/screens/login_screen.dart';
import '../../features/authentication/screens/signup_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/workout_builder/screens/workout_builder_screen.dart';
import '../../features/workout_session/screens/workout_session_screen.dart';
import '../../features/recovery/screens/recovery_screen.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
// ── New features ──────────────────────────────────────────────────────────────
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/exercise_library/models/exercise_library_item.dart';
import '../../features/exercise_library/screens/exercise_detail_screen.dart';
import '../../features/exercise_library/screens/exercise_library_screen.dart';
import '../../features/workout_builder/screens/routine_library_screen.dart';
import '../../features/health_tracking/screens/health_tracking_screen.dart';
import '../../features/onboarding/providers/onboarding_provider.dart';
import '../../shared/widgets/app_shell.dart';
import '../constants/app_constants.dart';

/// The app's [GoRouter], with its start location resolved from persisted state.
///
/// If onboarding has not been completed, routes directly to [AppConstants.routeOnboarding].
/// Once completed, routes directly to [AppConstants.routeDashboard].
final routerProvider = Provider<GoRouter>((ref) {
  ref.keepAlive();
  final isComplete = ref.watch(onboardingCompleteProvider);
  return AppRouter.build(
    initialLocation: isComplete
        ? AppConstants.routeDashboard
        : AppConstants.routeOnboarding,
  );
});

/// Central [GoRouter] configuration for LEON.
///
/// All routes are declared here. Feature teams should NOT create their own
/// routers; add named sub-routes to the appropriate [GoRoute] instead.
final class AppRouter {
  AppRouter._();

  static GoRouter build({
    String initialLocation = AppConstants.routeDashboard,
  }) {
    return GoRouter(
      initialLocation: initialLocation,
      debugLogDiagnostics: kDebugMode,
      routes: [
        // ── Main tabs ───────────────────────────────────────────────────────
        // Wrapped in the shell so the floating nav pill persists across tab
        // switches instead of being rebuilt per screen.
        StatefulShellRoute.indexedStack(
          builder:
              (
                BuildContext context,
                GoRouterState state,
                StatefulNavigationShell navigationShell,
              ) => AppShell.navigation(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppConstants.routeDashboard,
                  name: 'dashboard',
                  builder: (BuildContext context, GoRouterState state) =>
                      const DashboardScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              preload: true,
              routes: [
                GoRoute(
                  path: AppConstants.routeWorkoutBuilder,
                  name: 'workout-builder',
                  builder: (BuildContext context, GoRouterState state) =>
                      const WorkoutBuilderScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              preload: true,
              routes: [
                GoRoute(
                  path: AppConstants.routeExerciseLibrary,
                  name: 'exercise-library',
                  builder: (BuildContext context, GoRouterState state) =>
                      const ExerciseLibraryScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              preload: true,
              routes: [
                GoRoute(
                  path: AppConstants.routeAnalytics,
                  name: 'analytics',
                  builder: (BuildContext context, GoRouterState state) =>
                      const HistoryScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              preload: true,
              routes: [
                GoRoute(
                  path: AppConstants.routeProfile,
                  name: 'profile',
                  builder: (BuildContext context, GoRouterState state) =>
                      const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),

        // ── Auth (no nav pill) ──────────────────────────────────────────────
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

        // ── Onboarding (no nav pill) ────────────────────────────────────────
        GoRoute(
          path: AppConstants.routeOnboarding,
          name: 'onboarding',
          builder: (BuildContext context, GoRouterState state) =>
              const OnboardingScreen(),
        ),

        // ── Full-screen: distraction-free OLED session ──────────────────────
        GoRoute(
          path: AppConstants.routeWorkoutSession,
          name: 'workout-session',
          builder: (BuildContext context, GoRouterState state) =>
              const WorkoutSessionScreen(),
        ),

        // ── Detail screens pushed from a tab ────────────────────────────────
        GoRoute(
          path: AppConstants.routeRecovery,
          name: 'recovery',
          builder: (BuildContext context, GoRouterState state) =>
              const RecoveryScreen(),
        ),
        GoRoute(
          path: AppConstants.routeHealthTracking,
          name: 'health-tracking',
          builder: (BuildContext context, GoRouterState state) =>
              const HealthTrackingScreen(),
        ),
        GoRoute(
          path: AppConstants.routeExerciseDetail,
          name: 'exercise-detail',
          builder: (BuildContext context, GoRouterState state) {
            final exercise = state.extra is ExerciseLibraryItem
                ? state.extra as ExerciseLibraryItem
                : null;
            final exerciseId = state.uri.queryParameters['id'];
            return ExerciseDetailScreen(
              exercise: exercise,
              exerciseId: exerciseId,
            );
          },
        ),
        GoRoute(
          path: AppConstants.routeRoutineLibrary,
          name: 'routine-library',
          builder: (BuildContext context, GoRouterState state) =>
              const RoutineLibraryScreen(),
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
}
