// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OnboardingState _$OnboardingStateFromJson(Map<String, dynamic> json) =>
    _OnboardingState(
      currentPage: (json['current_page'] as num?)?.toInt() ?? 0,
      isCompleted: json['is_completed'] as bool? ?? false,
    );

Map<String, dynamic> _$OnboardingStateToJson(_OnboardingState instance) =>
    <String, dynamic>{
      'current_page': instance.currentPage,
      'is_completed': instance.isCompleted,
    };
