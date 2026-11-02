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
abstract class HealthSnapshot with _$HealthSnapshot {
  // Private generative constructor required to add the empty() factory.
  const HealthSnapshot._();

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory HealthSnapshot({
    /// When the displayed snapshot was assembled. Imported sample times are tracked separately.
    required DateTime recordedAt,

    /// Total step count for the current day.
    int? steps,

    /// Latest readable heart-rate sample today in BPM; not a resting baseline.
    int? heartRateBpm,

    /// Manual sleep or merged asleep intervals from yesterday noon to today noon (or now).
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
