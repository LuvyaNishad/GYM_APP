import 'package:freezed_annotation/freezed_annotation.dart';

part 'split_model.freezed.dart';
part 'split_model.g.dart';

/// Represents a training split (e.g., Push/Pull/Legs, Upper/Lower).
@freezed
class SplitModel with _$SplitModel {
  const factory SplitModel({
    required String id,
    required String name,
    required String description,
    @Default([]) List<String> dayLabels,
    @Default([]) List<List<String>> dayExerciseIds,
    required DateTime createdAt,
  }) = _SplitModel;

  factory SplitModel.fromJson(Map<String, dynamic> json) =>
      _$SplitModelFromJson(json);
}
