import 'package:flutter/foundation.dart';
import '../../workout_session/models/active_session_state.dart';
import '../../../models/workout_model.dart';

/// Complete catalog item for the LEON Exercise Library.
@immutable
class ExerciseLibraryItem {
  const ExerciseLibraryItem({
    required this.id,
    required this.name,
    required this.category,
    this.subCategory = '',
    required this.description,
    this.primaryMuscles = const [],
    this.secondaryMuscles = const [],
    this.equipment = const [],
    this.primaryEquipment = 'barbell',
    this.movementPattern = 'general',
    this.exerciseType = 'compound',
    this.difficulty = 'beginner to intermediate',
    this.tags = const [],
    this.instructions = const [],
    this.coachingNotes = '',
    this.safetyNotes = '',
    this.loggingSuggestions = '',
    this.defaultRestSeconds = 90,
    this.isCustom = false,
    this.alternatives = const [],
  });

  final String id;
  final String name;
  final String category;
  final String subCategory;
  final String description;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final List<String> equipment;
  final String primaryEquipment;
  final String movementPattern;
  final String exerciseType;
  final String difficulty;
  final List<String> tags;
  final List<String> instructions;
  final String coachingNotes;
  final String safetyNotes;
  final String loggingSuggestions;
  final int defaultRestSeconds;
  final bool isCustom;
  final List<String> alternatives;

  /// Formatted primary muscles display (capitalized, comma-separated)
  String get primaryMusclesDisplay {
    if (primaryMuscles.isEmpty) return category;
    return primaryMuscles
        .map((m) => m.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' '))
        .join(', ');
  }

  /// Formatted secondary muscles display
  String get secondaryMusclesDisplay {
    if (secondaryMuscles.isEmpty) return 'None';
    return secondaryMuscles
        .map((m) => m.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' '))
        .join(', ');
  }

  /// Formatted equipment display
  String get equipmentDisplay {
    if (equipment.isEmpty) return primaryEquipment.toUpperCase();
    return equipment
        .map((e) => e.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' '))
        .join(', ');
  }

  /// Clean display difficulty label
  String get difficultyDisplay {
    final lower = difficulty.toLowerCase();
    if (lower.contains('beginner to intermediate')) return 'Beginner - Inter.';
    if (lower.contains('intermediate to advanced')) return 'Inter. - Advanced';
    if (lower.contains('beginner')) return 'Beginner';
    if (lower.contains('intermediate')) return 'Intermediate';
    if (lower.contains('advanced')) return 'Advanced';
    return 'All Levels';
  }

  /// Movement pattern display
  String get movementPatternDisplay {
    switch (movementPattern) {
      case 'horizontal_push':
        return 'Horizontal Push';
      case 'vertical_push':
        return 'Vertical Push';
      case 'horizontal_pull':
        return 'Horizontal Pull';
      case 'vertical_pull':
        return 'Vertical Pull';
      case 'squat':
        return 'Squat';
      case 'hinge':
        return 'Hip Hinge';
      case 'lunge':
        return 'Lunge';
      case 'curl':
        return 'Bicep Curl';
      case 'extension':
        return 'Tricep Ext.';
      case 'carry':
        return 'Loaded Carry';
      case 'rotation':
        return 'Core Rotation';
      default:
        return 'General';
    }
  }

  /// Converts this library item into an ActiveExerciseState for immediate workout injection.
  ActiveExerciseState toActiveExercise({
    int targetSets = 3,
    double defaultWeightKg = 60.0,
    int defaultReps = 10,
    int? customRestSeconds,
  }) {
    final sets = List.generate(
      targetSets,
      (index) => ActiveSetState(
        setNumber: index + 1,
        weightKg: defaultWeightKg,
        reps: defaultReps,
        rir: 2.0,
        rpe: 8.0,
      ),
    );

    return ActiveExerciseState(
      exerciseId: id,
      name: name,
      muscleGroup: category,
      equipment: primaryEquipment,
      sets: sets,
      notes: coachingNotes.isNotEmpty ? coachingNotes : null,
      restDurationSeconds: customRestSeconds ?? defaultRestSeconds,
    );
  }

  /// Converts this library item into a WorkoutExercise model.
  WorkoutExercise toWorkoutExercise({
    int targetSets = 3,
    double defaultWeightKg = 60.0,
    int defaultReps = 10,
  }) {
    final sets = List.generate(
      targetSets,
      (index) => WorkoutSet(
        weightKg: defaultWeightKg,
        reps: defaultReps,
      ),
    );

    return WorkoutExercise(
      exerciseId: id,
      exerciseName: name,
      muscleGroup: category,
      sets: sets,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'sub_category': subCategory,
        'description': description,
        'primary_muscles': primaryMuscles,
        'secondary_muscles': secondaryMuscles,
        'equipment': equipment,
        'primary_equipment': primaryEquipment,
        'movement_pattern': movementPattern,
        'exercise_type': exerciseType,
        'difficulty': difficulty,
        'tags': tags,
        'instructions': instructions,
        'coaching_notes': coachingNotes,
        'safety_notes': safetyNotes,
        'logging_suggestions': loggingSuggestions,
        'default_rest_seconds': defaultRestSeconds,
        'is_custom': isCustom,
        'alternatives': alternatives,
      };

  factory ExerciseLibraryItem.fromJson(Map<String, dynamic> json) {
    return ExerciseLibraryItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      subCategory: json['sub_category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      primaryMuscles: (json['primary_muscles'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      secondaryMuscles: (json['secondary_muscles'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      equipment: (json['equipment'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      primaryEquipment: json['primary_equipment'] as String? ?? 'barbell',
      movementPattern: json['movement_pattern'] as String? ?? 'general',
      exerciseType: json['exercise_type'] as String? ?? 'compound',
      difficulty: json['difficulty'] as String? ?? 'beginner to intermediate',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      instructions: (json['instructions'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      coachingNotes: json['coaching_notes'] as String? ?? '',
      safetyNotes: json['safety_notes'] as String? ?? '',
      loggingSuggestions: json['logging_suggestions'] as String? ?? '',
      defaultRestSeconds: (json['default_rest_seconds'] as num?)?.toInt() ?? 90,
      isCustom: json['is_custom'] as bool? ?? false,
      alternatives: (json['alternatives'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  ExerciseLibraryItem copyWith({
    String? id,
    String? name,
    String? category,
    String? subCategory,
    String? description,
    List<String>? primaryMuscles,
    List<String>? secondaryMuscles,
    List<String>? equipment,
    String? primaryEquipment,
    String? movementPattern,
    String? exerciseType,
    String? difficulty,
    List<String>? tags,
    List<String>? instructions,
    String? coachingNotes,
    String? safetyNotes,
    String? loggingSuggestions,
    int? defaultRestSeconds,
    bool? isCustom,
    List<String>? alternatives,
  }) {
    return ExerciseLibraryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      description: description ?? this.description,
      primaryMuscles: primaryMuscles ?? this.primaryMuscles,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      equipment: equipment ?? this.equipment,
      primaryEquipment: primaryEquipment ?? this.primaryEquipment,
      movementPattern: movementPattern ?? this.movementPattern,
      exerciseType: exerciseType ?? this.exerciseType,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      instructions: instructions ?? this.instructions,
      coachingNotes: coachingNotes ?? this.coachingNotes,
      safetyNotes: safetyNotes ?? this.safetyNotes,
      loggingSuggestions: loggingSuggestions ?? this.loggingSuggestions,
      defaultRestSeconds: defaultRestSeconds ?? this.defaultRestSeconds,
      isCustom: isCustom ?? this.isCustom,
      alternatives: alternatives ?? this.alternatives,
    );
  }
}
