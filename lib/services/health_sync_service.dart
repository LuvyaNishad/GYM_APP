import '../features/health_tracking/models/health_snapshot.dart';

/// Contract for fetching health & wearable data in LEON.
///
/// Implement this interface for each health platform (Apple Health,
/// Google Fit, Garmin Connect, Whoop, etc.).
///
/// The [NoOpHealthSyncService] default implementation is used until a real
/// wearable integration is configured, so the app compiles immediately.
abstract interface class HealthSyncService {
  /// Fetch the most recent [HealthSnapshot] from the connected data source.
  Future<HealthSnapshot> fetchLatestSnapshot();

  /// Fetch current resting heart rate in BPM, or `null` if unavailable.
  Future<int?> fetchHeartRate();

  /// Fetch total step count for today, or `null` if unavailable.
  Future<int?> fetchSteps();

  /// Fetch hours slept in the most recent sleep session, or `null`.
  Future<double?> fetchSleepData();

  /// Fetch active (exercise) calories burned today, or `null`.
  Future<int?> fetchActiveCalories();

  /// Returns `true` when a compatible wearable/health platform is paired.
  Future<bool> isAvailable();

  /// Request permission to access health data from the platform.
  ///
  /// Returns `true` if permissions were granted.
  Future<bool> requestPermissions();
}

// ─────────────────────────────────────────────────────────────────────────────
// ── No-Op Implementation ─────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────

/// A safe, no-op implementation of [HealthSyncService] used before real
/// wearable integrations are configured.
///
/// All methods return `null` / empty values so the app compiles and runs
/// without crashing when no health platform is connected.
final class NoOpHealthSyncService implements HealthSyncService {
  const NoOpHealthSyncService();

  @override
  Future<HealthSnapshot> fetchLatestSnapshot() async => HealthSnapshot.empty();

  @override
  Future<int?> fetchHeartRate() async => null;

  @override
  Future<int?> fetchSteps() async => null;

  @override
  Future<double?> fetchSleepData() async => null;

  @override
  Future<int?> fetchActiveCalories() async => null;

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> requestPermissions() async => false;
}
