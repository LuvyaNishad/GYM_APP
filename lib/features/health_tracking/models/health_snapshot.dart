import 'package:freezed_annotation/freezed_annotation.dart';

part 'health_snapshot.freezed.dart';
part 'health_snapshot.g.dart';

/// A point-in-time snapshot of a user's health metrics.
///
/// All metric fields are nullable — a missing value means the data source
/// did not return that metric for this recording period.
///
/// Uses Freezed for immutability and JsonSerializable for serialisation.
@freezed
class HealthSnapshot with _$HealthSnapshot {
  // Private generative constructor required to add the empty() factory.
  const HealthSnapshot._();

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory HealthSnapshot({
    /// When this snapshot was recorded / last synced.
    required DateTime recordedAt,

    /// Total step count for the current day.
    int? steps,

    /// Most recent resting/active heart rate in BPM.
    int? heartRateBpm,

    /// Hours of sleep for the most recent sleep session.
    double? sleepHours,

    /// Active (exercise) calories burned today.
    int? activeCalories,
  }) = _HealthSnapshot;

  factory HealthSnapshot.fromJson(Map<String, dynamic> json) =>
      _$HealthSnapshotFromJson(json);

  // ── Convenience factories ──────────────────────────────────────────────────

  /// Returns an empty snapshot timestamped to now.
  static HealthSnapshot empty() => HealthSnapshot(recordedAt: DateTime.now());
}
