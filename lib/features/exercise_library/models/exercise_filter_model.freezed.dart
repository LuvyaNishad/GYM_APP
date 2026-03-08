// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise_filter_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ExerciseFilterModel _$ExerciseFilterModelFromJson(Map<String, dynamic> json) {
  return _ExerciseFilterModel.fromJson(json);
}

/// @nodoc
mixin _$ExerciseFilterModel {
  /// e.g. `'push'`, `'pull'`, `'legs'`, `'core'`
  String? get muscleGroup => throw _privateConstructorUsedError;

  /// e.g. `'barbell'`, `'dumbbell'`, `'cable'`, `'bodyweight'`
  String? get equipment => throw _privateConstructorUsedError;

  /// e.g. `'compound'`, `'isolation'`
  String? get type => throw _privateConstructorUsedError;

  /// When true, only warm-up exercises are shown.
  bool get showWarmupOnly => throw _privateConstructorUsedError;

  /// Serializes this ExerciseFilterModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExerciseFilterModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExerciseFilterModelCopyWith<ExerciseFilterModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExerciseFilterModelCopyWith<$Res> {
  factory $ExerciseFilterModelCopyWith(
          ExerciseFilterModel value, $Res Function(ExerciseFilterModel) then) =
      _$ExerciseFilterModelCopyWithImpl<$Res, ExerciseFilterModel>;
  @useResult
  $Res call(
      {String? muscleGroup,
      String? equipment,
      String? type,
      bool showWarmupOnly});
}

/// @nodoc
class _$ExerciseFilterModelCopyWithImpl<$Res, $Val extends ExerciseFilterModel>
    implements $ExerciseFilterModelCopyWith<$Res> {
  _$ExerciseFilterModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExerciseFilterModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? muscleGroup = freezed,
    Object? equipment = freezed,
    Object? type = freezed,
    Object? showWarmupOnly = null,
  }) {
    return _then(_value.copyWith(
      muscleGroup: freezed == muscleGroup
          ? _value.muscleGroup
          : muscleGroup // ignore: cast_nullable_to_non_nullable
              as String?,
      equipment: freezed == equipment
          ? _value.equipment
          : equipment // ignore: cast_nullable_to_non_nullable
              as String?,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
      showWarmupOnly: null == showWarmupOnly
          ? _value.showWarmupOnly
          : showWarmupOnly // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExerciseFilterModelImplCopyWith<$Res>
    implements $ExerciseFilterModelCopyWith<$Res> {
  factory _$$ExerciseFilterModelImplCopyWith(_$ExerciseFilterModelImpl value,
          $Res Function(_$ExerciseFilterModelImpl) then) =
      __$$ExerciseFilterModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? muscleGroup,
      String? equipment,
      String? type,
      bool showWarmupOnly});
}

/// @nodoc
class __$$ExerciseFilterModelImplCopyWithImpl<$Res>
    extends _$ExerciseFilterModelCopyWithImpl<$Res, _$ExerciseFilterModelImpl>
    implements _$$ExerciseFilterModelImplCopyWith<$Res> {
  __$$ExerciseFilterModelImplCopyWithImpl(_$ExerciseFilterModelImpl _value,
      $Res Function(_$ExerciseFilterModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExerciseFilterModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? muscleGroup = freezed,
    Object? equipment = freezed,
    Object? type = freezed,
    Object? showWarmupOnly = null,
  }) {
    return _then(_$ExerciseFilterModelImpl(
      muscleGroup: freezed == muscleGroup
          ? _value.muscleGroup
          : muscleGroup // ignore: cast_nullable_to_non_nullable
              as String?,
      equipment: freezed == equipment
          ? _value.equipment
          : equipment // ignore: cast_nullable_to_non_nullable
              as String?,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
      showWarmupOnly: null == showWarmupOnly
          ? _value.showWarmupOnly
          : showWarmupOnly // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _$ExerciseFilterModelImpl extends _ExerciseFilterModel {
  const _$ExerciseFilterModelImpl(
      {this.muscleGroup,
      this.equipment,
      this.type,
      this.showWarmupOnly = false})
      : super._();

  factory _$ExerciseFilterModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExerciseFilterModelImplFromJson(json);

  /// e.g. `'push'`, `'pull'`, `'legs'`, `'core'`
  @override
  final String? muscleGroup;

  /// e.g. `'barbell'`, `'dumbbell'`, `'cable'`, `'bodyweight'`
  @override
  final String? equipment;

  /// e.g. `'compound'`, `'isolation'`
  @override
  final String? type;

  /// When true, only warm-up exercises are shown.
  @override
  @JsonKey()
  final bool showWarmupOnly;

  @override
  String toString() {
    return 'ExerciseFilterModel(muscleGroup: $muscleGroup, equipment: $equipment, type: $type, showWarmupOnly: $showWarmupOnly)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExerciseFilterModelImpl &&
            (identical(other.muscleGroup, muscleGroup) ||
                other.muscleGroup == muscleGroup) &&
            (identical(other.equipment, equipment) ||
                other.equipment == equipment) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.showWarmupOnly, showWarmupOnly) ||
                other.showWarmupOnly == showWarmupOnly));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, muscleGroup, equipment, type, showWarmupOnly);

  /// Create a copy of ExerciseFilterModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExerciseFilterModelImplCopyWith<_$ExerciseFilterModelImpl> get copyWith =>
      __$$ExerciseFilterModelImplCopyWithImpl<_$ExerciseFilterModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExerciseFilterModelImplToJson(
      this,
    );
  }
}

abstract class _ExerciseFilterModel extends ExerciseFilterModel {
  const factory _ExerciseFilterModel(
      {final String? muscleGroup,
      final String? equipment,
      final String? type,
      final bool showWarmupOnly}) = _$ExerciseFilterModelImpl;
  const _ExerciseFilterModel._() : super._();

  factory _ExerciseFilterModel.fromJson(Map<String, dynamic> json) =
      _$ExerciseFilterModelImpl.fromJson;

  /// e.g. `'push'`, `'pull'`, `'legs'`, `'core'`
  @override
  String? get muscleGroup;

  /// e.g. `'barbell'`, `'dumbbell'`, `'cable'`, `'bodyweight'`
  @override
  String? get equipment;

  /// e.g. `'compound'`, `'isolation'`
  @override
  String? get type;

  /// When true, only warm-up exercises are shown.
  @override
  bool get showWarmupOnly;

  /// Create a copy of ExerciseFilterModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExerciseFilterModelImplCopyWith<_$ExerciseFilterModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
