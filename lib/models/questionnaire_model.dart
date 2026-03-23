import 'package:freezed_annotation/freezed_annotation.dart';

part 'questionnaire_model.freezed.dart';
part 'questionnaire_model.g.dart';

/// User onboarding questionnaire answers.
@freezed
class QuestionnaireModel with _$QuestionnaireModel {
  const factory QuestionnaireModel({
    required String userId,
    required String fitnessGoal,
    required String experienceLevel,
    @Default([]) List<String> availableEquipmentIds,
    @Default(4) int trainingDaysPerWeek,
    @Default(60) int sessionDurationMinutes,
    String? preferredSplit,
    String? injuryNotes,
  }) = _QuestionnaireModel;

  factory QuestionnaireModel.fromJson(Map<String, dynamic> json) =>
      _$QuestionnaireModelFromJson(json);
}
