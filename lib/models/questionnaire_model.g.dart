// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'questionnaire_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QuestionnaireModelImpl _$$QuestionnaireModelImplFromJson(
        Map<String, dynamic> json) =>
    _$QuestionnaireModelImpl(
      userId: json['userId'] as String,
      fitnessGoal: json['fitnessGoal'] as String,
      experienceLevel: json['experienceLevel'] as String,
      availableEquipmentIds: (json['availableEquipmentIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      trainingDaysPerWeek: (json['trainingDaysPerWeek'] as num?)?.toInt() ?? 4,
      sessionDurationMinutes:
          (json['sessionDurationMinutes'] as num?)?.toInt() ?? 60,
      preferredSplit: json['preferredSplit'] as String?,
      injuryNotes: json['injuryNotes'] as String?,
    );

Map<String, dynamic> _$$QuestionnaireModelImplToJson(
        _$QuestionnaireModelImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'fitnessGoal': instance.fitnessGoal,
      'experienceLevel': instance.experienceLevel,
      'availableEquipmentIds': instance.availableEquipmentIds,
      'trainingDaysPerWeek': instance.trainingDaysPerWeek,
      'sessionDurationMinutes': instance.sessionDurationMinutes,
      'preferredSplit': instance.preferredSplit,
      'injuryNotes': instance.injuryNotes,
    };
