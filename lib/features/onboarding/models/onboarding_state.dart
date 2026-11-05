import 'package:flutter/foundation.dart';

/// Immutable state tracking the comprehensive AEON Onboarding flow.
@immutable
class OnboardingState {
  const OnboardingState({
    this.currentPage = 0,
    this.agentName = '',
    this.age = 24,
    this.height = 178,
    this.isHeightCm = true,
    this.weight = 78,
    this.isWeightKg = true,
    this.targetWeight = 74,
    this.experienceLevel = 'Not set',
    this.primaryGoal = 'BUILD MUSCLE',
    this.trainingDaysPerWeek = 5,
    this.preferredSplit = 'PPL',
    this.equipment = const ['Dumbbells', 'Barbell', 'Bench', 'Pull-up Bar'],
    this.injuries = const [],
    this.isCompleted = false,
    this.ageProvided = false,
    this.heightProvided = false,
    this.weightProvided = false,
    this.targetProvided = false,
  });

  final bool ageProvided, heightProvided, weightProvided, targetProvided;
  final int currentPage;
  final String agentName;
  final int age;
  final double height;
  final bool isHeightCm;
  final double weight;
  final bool isWeightKg;
  final double targetWeight;
  final String experienceLevel;
  final String primaryGoal;
  final int trainingDaysPerWeek;
  final String preferredSplit;
  final List<String> equipment;
  final List<String> injuries;
  final bool isCompleted;

  // Opening, four questions, and the actual routine preview.
  static const int totalPages = 6;

  bool get isLastPage => currentPage == totalPages - 1;

  /// Progress across the four questionnaire steps.
  double get stepProgress {
    return (currentPage / 4.0).clamp(0.0, 1.0);
  }

  /// Step label in format "01 / 04" through "04 / 04"
  String get stepLabel {
    if (currentPage < 1 || currentPage > 4) return '';
    final stepNum = currentPage;
    return '0$stepNum / 04';
  }

  Map<String, dynamic> toJson() => {
    'page': currentPage,
    'name': agentName,
    'age': age,
    'height': height,
    'weight': weight,
    'target': targetWeight,
    'heightCm': isHeightCm,
    'weightKg': isWeightKg,
    'ageProvided': ageProvided,
    'heightProvided': heightProvided,
    'weightProvided': weightProvided,
    'targetProvided': targetProvided,
    'experience': experienceLevel,
    'goal': primaryGoal,
    'days': trainingDaysPerWeek,
    'split': preferredSplit,
    'equipment': equipment,
    'injuries': injuries,
  };

  factory OnboardingState.fromJson(Map<String, dynamic> json) =>
      OnboardingState(
        currentPage: (json['page'] as int).clamp(0, totalPages - 1),
        agentName: json['name'] as String,
        age: json['age'] as int,
        height: (json['height'] as num).toDouble(),
        weight: (json['weight'] as num).toDouble(),
        targetWeight: (json['target'] as num).toDouble(),
        isHeightCm: json['heightCm'] as bool,
        isWeightKg: json['weightKg'] as bool,
        ageProvided: json['ageProvided'] as bool,
        heightProvided: json['heightProvided'] as bool,
        weightProvided: json['weightProvided'] as bool,
        targetProvided: json['targetProvided'] as bool,
        experienceLevel: json['experience'] as String,
        primaryGoal: json['goal'] as String,
        trainingDaysPerWeek: (json['days'] as int).clamp(1, 7),
        preferredSplit: json['split'] as String,
        equipment: List<String>.from(json['equipment'] as List),
        injuries: List<String>.from(json['injuries'] as List),
      );

  OnboardingState copyWith({
    int? currentPage,
    String? agentName,
    int? age,
    double? height,
    bool? isHeightCm,
    double? weight,
    bool? isWeightKg,
    double? targetWeight,
    String? experienceLevel,
    String? primaryGoal,
    int? trainingDaysPerWeek,
    String? preferredSplit,
    List<String>? equipment,
    List<String>? injuries,
    bool? isCompleted,
    bool? ageProvided,
    bool? heightProvided,
    bool? weightProvided,
    bool? targetProvided,
  }) {
    return OnboardingState(
      ageProvided: ageProvided ?? this.ageProvided,
      heightProvided: heightProvided ?? this.heightProvided,
      weightProvided: weightProvided ?? this.weightProvided,
      targetProvided: targetProvided ?? this.targetProvided,
      currentPage: currentPage ?? this.currentPage,
      agentName: agentName ?? this.agentName,
      age: age ?? this.age,
      height: height ?? this.height,
      isHeightCm: isHeightCm ?? this.isHeightCm,
      weight: weight ?? this.weight,
      isWeightKg: isWeightKg ?? this.isWeightKg,
      targetWeight: targetWeight ?? this.targetWeight,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      trainingDaysPerWeek: trainingDaysPerWeek ?? this.trainingDaysPerWeek,
      preferredSplit: preferredSplit ?? this.preferredSplit,
      equipment: equipment ?? this.equipment,
      injuries: injuries ?? this.injuries,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
