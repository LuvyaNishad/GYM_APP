// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'split_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SplitModel _$SplitModelFromJson(Map<String, dynamic> json) => _SplitModel(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  dayLabels:
      (json['dayLabels'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  dayExerciseIds:
      (json['dayExerciseIds'] as List<dynamic>?)
          ?.map((e) => (e as List<dynamic>).map((e) => e as String).toList())
          .toList() ??
      const [],
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$SplitModelToJson(_SplitModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'dayLabels': instance.dayLabels,
      'dayExerciseIds': instance.dayExerciseIds,
      'createdAt': instance.createdAt.toIso8601String(),
    };
