/// LEON — app-wide constants.
abstract final class AppConstants {
  AppConstants._();

  // ── App Meta ──────────────────────────────────────────────────────────────
  static const String appName = 'AEON';
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

  // ── New Feature Routes ────────────────────────────────────────────────────
  static const String routeOnboarding = '/onboarding';
  static const String routeExerciseLibrary = '/exercise-library';
  static const String routeExerciseDetail = '/exercise-detail';
  static const String routeRoutineLibrary = '/routine-library';
  static const String routeHealthTracking = '/health-tracking';

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
  static const String hiveBoxSplits = 'splits';

  /// Key the single on-device profile is stored under in [hiveBoxUser].
  /// LEON is local-first and guest-first, so there is exactly one local
  /// profile whether or not it is backed by a Supabase account.
  static const String hiveKeyLocalProfile = 'local';

  // ── Settings Keys (primitives in the settings box) ────────────────────────
  static const String settingOnboardingComplete = 'onboarding_complete';
  static const String settingWeightUnit = 'weight_unit';
  static const String settingActiveSplitId = 'active_split_id';
  static const String settingTrainingSchedules = 'training_schedules_v1';
  static const String settingPrimaryGoal = 'primary_goal';
  static const String settingTargetWeight = 'target_weight';
  static const String settingActiveSessionData = 'active_session_data';

  // ── Step Tracking Settings Keys ───────────────────────────────────────────
  static const String settingStepDate = 'step_tracking_date';
  static const String settingStepTodayCount = 'step_today_count';
  static const String settingStepBootBase = 'step_boot_base';
  static const String settingStepRebootOffset = 'step_reboot_offset';
  static const String settingStepLastHwReading = 'step_last_hw_reading';
  static const String settingStepHourlyDistribution =
      'step_hourly_distribution';
  static const String settingStepHistory = 'step_history_by_date';
  static const String settingStepDailySnapshot = 'step_daily_snapshot';
  static const String settingStepRecordSteps = 'step_record_steps';
  static const String settingStepRecordDate = 'step_record_date';

  // ── Animation Durations ───────────────────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
}
