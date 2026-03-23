import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_log_model.freezed.dart';
part 'session_log_model.g.dart';

/// A completed workout session log entry.
@freezed
class SessionLogModel with _$SessionLogModel {
  const factory SessionLogModel({
    required String id,
    required String userId,
    required String workoutId,
    required String workoutName,
    required DateTime startedAt,
    required DateTime completedAt,
    @Default(0) int totalVolumeKg,
    @Default(0) int totalSets,
    @Default([]) List<String> exerciseIds,
    String? notes,
  }) = _SessionLogModel;

  factory SessionLogModel.fromJson(Map<String, dynamic> json) =>
      _$SessionLogModelFromJson(json);
}
