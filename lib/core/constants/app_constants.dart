/// LEON — app-wide constants.
abstract final class AppConstants {
  AppConstants._();

  // ── App Meta ──────────────────────────────────────────────────────────────
  static const String appName = 'LEON';
  static const String appVersion = '1.0.0';

  // ── Route names (mirrors AppRouter path constants) ────────────────────────
  static const String routeDashboard = '/';
  static const String routeWorkoutBuilder = '/workout-builder';
  static const String routeWorkoutSession = '/workout-session';
  static const String routeRecovery = '/recovery';
  static const String routeAnalytics = '/analytics';
  static const String routeProfile = '/profile';
  static const String routeLogin = '/login';
  static const String routeSignup = '/signup';

  // ── Workout Defaults ──────────────────────────────────────────────────────
  static const int defaultRestSeconds = 90;
  static const int maxSetsPerExercise = 10;
  static const double junkVolumeRpeThreshold = 5.0;

  // ── Muscle Group Keys ─────────────────────────────────────────────────────
  static const String muscleGroupPush = 'push';
  static const String muscleGroupPull = 'pull';
  static const String muscleGroupLegs = 'legs';
  static const String muscleGroupCore = 'core';

  // ── Hive Box Names ────────────────────────────────────────────────────────
  static const String hiveBoxWorkouts = 'workouts';
  static const String hiveBoxUser = 'user';
  static const String hiveBoxSettings = 'settings';
  static const String hiveBoxProgress = 'progress';

  // ── Animation Durations ───────────────────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
}
