// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ExerciseModel _$ExerciseModelFromJson(Map<String, dynamic> json) {
  return _ExerciseModel.fromJson(json);
}

/// @nodoc
mixin _$ExerciseModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get primaryMuscleGroup => throw _privateConstructorUsedError;
  List<String> get secondaryMuscleGroups => throw _privateConstructorUsedError;
  String get equipment => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String? get videoUrl => throw _privateConstructorUsedError;
  String? get instructions => throw _privateConstructorUsedError;
  bool get isCustom =>
      throw _privateConstructorUsedError; // ── New fields ──────────────────────────────────────────────────────────
  /// Links this exercise to a superset group (shared ID across exercises).
  String? get supersetGroupId => throw _privateConstructorUsedError;

  /// Rate of Perceived Exertion for this exercise definition (1–10).
  int? get rpe => throw _privateConstructorUsedError;

  /// Whether this exercise is designated as a warm-up movement.
  bool get isWarmup => throw _privateConstructorUsedError;

  /// Serializes this ExerciseModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExerciseModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExerciseModelCopyWith<ExerciseModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExerciseModelCopyWith<$Res> {
  factory $ExerciseModelCopyWith(
          ExerciseModel value, $Res Function(ExerciseModel) then) =
      _$ExerciseModelCopyWithImpl<$Res, ExerciseModel>;
  @useResult
  $Res call(
      {String id,
      String name,
      String primaryMuscleGroup,
      List<String> secondaryMuscleGroups,
      String equipment,
      String type,
      String? videoUrl,
      String? instructions,
      bool isCustom,
      String? supersetGroupId,
      int? rpe,
      bool isWarmup});
}

/// @nodoc
class _$ExerciseModelCopyWithImpl<$Res, $Val extends ExerciseModel>
    implements $ExerciseModelCopyWith<$Res> {
  _$ExerciseModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExerciseModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? primaryMuscleGroup = null,
    Object? secondaryMuscleGroups = null,
    Object? equipment = null,
    Object? type = null,
    Object? videoUrl = freezed,
    Object? instructions = freezed,
    Object? isCustom = null,
    Object? supersetGroupId = freezed,
    Object? rpe = freezed,
    Object? isWarmup = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      primaryMuscleGroup: null == primaryMuscleGroup
          ? _value.primaryMuscleGroup
          : primaryMuscleGroup // ignore: cast_nullable_to_non_nullable
              as String,
      secondaryMuscleGroups: null == secondaryMuscleGroups
          ? _value.secondaryMuscleGroups
          : secondaryMuscleGroups // ignore: cast_nullable_to_non_nullable
              as List<String>,
      equipment: null == equipment
          ? _value.equipment
          : equipment // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      videoUrl: freezed == videoUrl
          ? _value.videoUrl
          : videoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      instructions: freezed == instructions
          ? _value.instructions
          : instructions // ignore: cast_nullable_to_non_nullable
              as String?,
      isCustom: null == isCustom
          ? _value.isCustom
          : isCustom // ignore: cast_nullable_to_non_nullable
              as bool,
      supersetGroupId: freezed == supersetGroupId
          ? _value.supersetGroupId
          : supersetGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      rpe: freezed == rpe
          ? _value.rpe
          : rpe // ignore: cast_nullable_to_non_nullable
              as int?,
      isWarmup: null == isWarmup
          ? _value.isWarmup
          : isWarmup // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExerciseModelImplCopyWith<$Res>
    implements $ExerciseModelCopyWith<$Res> {
  factory _$$ExerciseModelImplCopyWith(
          _$ExerciseModelImpl value, $Res Function(_$ExerciseModelImpl) then) =
      __$$ExerciseModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String primaryMuscleGroup,
      List<String> secondaryMuscleGroups,
      String equipment,
      String type,
      String? videoUrl,
      String? instructions,
      bool isCustom,
      String? supersetGroupId,
      int? rpe,
      bool isWarmup});
}

/// @nodoc
class __$$ExerciseModelImplCopyWithImpl<$Res>
    extends _$ExerciseModelCopyWithImpl<$Res, _$ExerciseModelImpl>
    implements _$$ExerciseModelImplCopyWith<$Res> {
  __$$ExerciseModelImplCopyWithImpl(
      _$ExerciseModelImpl _value, $Res Function(_$ExerciseModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExerciseModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? primaryMuscleGroup = null,
    Object? secondaryMuscleGroups = null,
    Object? equipment = null,
    Object? type = null,
    Object? videoUrl = freezed,
    Object? instructions = freezed,
    Object? isCustom = null,
    Object? supersetGroupId = freezed,
    Object? rpe = freezed,
    Object? isWarmup = null,
  }) {
    return _then(_$ExerciseModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      primaryMuscleGroup: null == primaryMuscleGroup
          ? _value.primaryMuscleGroup
          : primaryMuscleGroup // ignore: cast_nullable_to_non_nullable
              as String,
      secondaryMuscleGroups: null == secondaryMuscleGroups
          ? _value._secondaryMuscleGroups
          : secondaryMuscleGroups // ignore: cast_nullable_to_non_nullable
              as List<String>,
      equipment: null == equipment
          ? _value.equipment
          : equipment // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      videoUrl: freezed == videoUrl
          ? _value.videoUrl
          : videoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      instructions: freezed == instructions
          ? _value.instructions
          : instructions // ignore: cast_nullable_to_non_nullable
              as String?,
      isCustom: null == isCustom
          ? _value.isCustom
          : isCustom // ignore: cast_nullable_to_non_nullable
              as bool,
      supersetGroupId: freezed == supersetGroupId
          ? _value.supersetGroupId
          : supersetGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      rpe: freezed == rpe
          ? _value.rpe
          : rpe // ignore: cast_nullable_to_non_nullable
              as int?,
      isWarmup: null == isWarmup
          ? _value.isWarmup
          : isWarmup // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _$ExerciseModelImpl implements _ExerciseModel {
  const _$ExerciseModelImpl(
      {required this.id,
      required this.name,
      required this.primaryMuscleGroup,
      final List<String> secondaryMuscleGroups = const [],
      this.equipment = 'barbell',
      this.type = 'compound',
      this.videoUrl,
      this.instructions,
      this.isCustom = false,
      this.supersetGroupId,
      this.rpe,
      this.isWarmup = false})
      : _secondaryMuscleGroups = secondaryMuscleGroups;

  factory _$ExerciseModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExerciseModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String primaryMuscleGroup;
  final List<String> _secondaryMuscleGroups;
  @override
  @JsonKey()
  List<String> get secondaryMuscleGroups {
    if (_secondaryMuscleGroups is EqualUnmodifiableListView)
      return _secondaryMuscleGroups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_secondaryMuscleGroups);
  }

  @override
  @JsonKey()
  final String equipment;
  @override
  @JsonKey()
  final String type;
  @override
  final String? videoUrl;
  @override
  final String? instructions;
  @override
  @JsonKey()
  final bool isCustom;
// ── New fields ──────────────────────────────────────────────────────────
  /// Links this exercise to a superset group (shared ID across exercises).
  @override
  final String? supersetGroupId;

  /// Rate of Perceived Exertion for this exercise definition (1–10).
  @override
  final int? rpe;

  /// Whether this exercise is designated as a warm-up movement.
  @override
  @JsonKey()
  final bool isWarmup;

  @override
  String toString() {
    return 'ExerciseModel(id: $id, name: $name, primaryMuscleGroup: $primaryMuscleGroup, secondaryMuscleGroups: $secondaryMuscleGroups, equipment: $equipment, type: $type, videoUrl: $videoUrl, instructions: $instructions, isCustom: $isCustom, supersetGroupId: $supersetGroupId, rpe: $rpe, isWarmup: $isWarmup)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExerciseModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.primaryMuscleGroup, primaryMuscleGroup) ||
                other.primaryMuscleGroup == primaryMuscleGroup) &&
            const DeepCollectionEquality()
                .equals(other._secondaryMuscleGroups, _secondaryMuscleGroups) &&
            (identical(other.equipment, equipment) ||
                other.equipment == equipment) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.videoUrl, videoUrl) ||
                other.videoUrl == videoUrl) &&
            (identical(other.instructions, instructions) ||
                other.instructions == instructions) &&
            (identical(other.isCustom, isCustom) ||
                other.isCustom == isCustom) &&
            (identical(other.supersetGroupId, supersetGroupId) ||
                other.supersetGroupId == supersetGroupId) &&
            (identical(other.rpe, rpe) || other.rpe == rpe) &&
            (identical(other.isWarmup, isWarmup) ||
                other.isWarmup == isWarmup));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      primaryMuscleGroup,
      const DeepCollectionEquality().hash(_secondaryMuscleGroups),
      equipment,
      type,
      videoUrl,
      instructions,
      isCustom,
      supersetGroupId,
      rpe,
      isWarmup);

  /// Create a copy of ExerciseModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExerciseModelImplCopyWith<_$ExerciseModelImpl> get copyWith =>
      __$$ExerciseModelImplCopyWithImpl<_$ExerciseModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExerciseModelImplToJson(
      this,
    );
  }
}

abstract class _ExerciseModel implements ExerciseModel {
  const factory _ExerciseModel(
      {required final String id,
      required final String name,
      required final String primaryMuscleGroup,
      final List<String> secondaryMuscleGroups,
      final String equipment,
      final String type,
      final String? videoUrl,
      final String? instructions,
      final bool isCustom,
      final String? supersetGroupId,
      final int? rpe,
      final bool isWarmup}) = _$ExerciseModelImpl;

  factory _ExerciseModel.fromJson(Map<String, dynamic> json) =
      _$ExerciseModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get primaryMuscleGroup;
  @override
  List<String> get secondaryMuscleGroups;
  @override
  String get equipment;
  @override
  String get type;
  @override
  String? get videoUrl;
  @override
  String? get instructions;
  @override
  bool
      get isCustom; // ── New fields ──────────────────────────────────────────────────────────
  /// Links this exercise to a superset group (shared ID across exercises).
  @override
  String? get supersetGroupId;

  /// Rate of Perceived Exertion for this exercise definition (1–10).
  @override
  int? get rpe;

  /// Whether this exercise is designated as a warm-up movement.
  @override
  bool get isWarmup;

  /// Create a copy of ExerciseModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExerciseModelImplCopyWith<_$ExerciseModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
