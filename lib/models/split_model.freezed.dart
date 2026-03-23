// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'split_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SplitModel _$SplitModelFromJson(Map<String, dynamic> json) {
  return _SplitModel.fromJson(json);
}

/// @nodoc
mixin _$SplitModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  List<String> get dayLabels => throw _privateConstructorUsedError;
  List<List<String>> get dayExerciseIds => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this SplitModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SplitModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SplitModelCopyWith<SplitModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SplitModelCopyWith<$Res> {
  factory $SplitModelCopyWith(
          SplitModel value, $Res Function(SplitModel) then) =
      _$SplitModelCopyWithImpl<$Res, SplitModel>;
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      List<String> dayLabels,
      List<List<String>> dayExerciseIds,
      DateTime createdAt});
}

/// @nodoc
class _$SplitModelCopyWithImpl<$Res, $Val extends SplitModel>
    implements $SplitModelCopyWith<$Res> {
  _$SplitModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SplitModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? dayLabels = null,
    Object? dayExerciseIds = null,
    Object? createdAt = null,
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
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      dayLabels: null == dayLabels
          ? _value.dayLabels
          : dayLabels // ignore: cast_nullable_to_non_nullable
              as List<String>,
      dayExerciseIds: null == dayExerciseIds
          ? _value.dayExerciseIds
          : dayExerciseIds // ignore: cast_nullable_to_non_nullable
              as List<List<String>>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SplitModelImplCopyWith<$Res>
    implements $SplitModelCopyWith<$Res> {
  factory _$$SplitModelImplCopyWith(
          _$SplitModelImpl value, $Res Function(_$SplitModelImpl) then) =
      __$$SplitModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      List<String> dayLabels,
      List<List<String>> dayExerciseIds,
      DateTime createdAt});
}

/// @nodoc
class __$$SplitModelImplCopyWithImpl<$Res>
    extends _$SplitModelCopyWithImpl<$Res, _$SplitModelImpl>
    implements _$$SplitModelImplCopyWith<$Res> {
  __$$SplitModelImplCopyWithImpl(
      _$SplitModelImpl _value, $Res Function(_$SplitModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of SplitModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? dayLabels = null,
    Object? dayExerciseIds = null,
    Object? createdAt = null,
  }) {
    return _then(_$SplitModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      dayLabels: null == dayLabels
          ? _value._dayLabels
          : dayLabels // ignore: cast_nullable_to_non_nullable
              as List<String>,
      dayExerciseIds: null == dayExerciseIds
          ? _value._dayExerciseIds
          : dayExerciseIds // ignore: cast_nullable_to_non_nullable
              as List<List<String>>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SplitModelImpl implements _SplitModel {
  const _$SplitModelImpl(
      {required this.id,
      required this.name,
      required this.description,
      final List<String> dayLabels = const [],
      final List<List<String>> dayExerciseIds = const [],
      required this.createdAt})
      : _dayLabels = dayLabels,
        _dayExerciseIds = dayExerciseIds;

  factory _$SplitModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SplitModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  final List<String> _dayLabels;
  @override
  @JsonKey()
  List<String> get dayLabels {
    if (_dayLabels is EqualUnmodifiableListView) return _dayLabels;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dayLabels);
  }

  final List<List<String>> _dayExerciseIds;
  @override
  @JsonKey()
  List<List<String>> get dayExerciseIds {
    if (_dayExerciseIds is EqualUnmodifiableListView) return _dayExerciseIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dayExerciseIds);
  }

  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'SplitModel(id: $id, name: $name, description: $description, dayLabels: $dayLabels, dayExerciseIds: $dayExerciseIds, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SplitModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other._dayLabels, _dayLabels) &&
            const DeepCollectionEquality()
                .equals(other._dayExerciseIds, _dayExerciseIds) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      description,
      const DeepCollectionEquality().hash(_dayLabels),
      const DeepCollectionEquality().hash(_dayExerciseIds),
      createdAt);

  /// Create a copy of SplitModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SplitModelImplCopyWith<_$SplitModelImpl> get copyWith =>
      __$$SplitModelImplCopyWithImpl<_$SplitModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SplitModelImplToJson(
      this,
    );
  }
}

abstract class _SplitModel implements SplitModel {
  const factory _SplitModel(
      {required final String id,
      required final String name,
      required final String description,
      final List<String> dayLabels,
      final List<List<String>> dayExerciseIds,
      required final DateTime createdAt}) = _$SplitModelImpl;

  factory _SplitModel.fromJson(Map<String, dynamic> json) =
      _$SplitModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get description;
  @override
  List<String> get dayLabels;
  @override
  List<List<String>> get dayExerciseIds;
  @override
  DateTime get createdAt;

  /// Create a copy of SplitModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SplitModelImplCopyWith<_$SplitModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
