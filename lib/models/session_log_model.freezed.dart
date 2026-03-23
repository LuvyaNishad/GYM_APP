// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_log_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SessionLogModel _$SessionLogModelFromJson(Map<String, dynamic> json) {
  return _SessionLogModel.fromJson(json);
}

/// @nodoc
mixin _$SessionLogModel {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get workoutId => throw _privateConstructorUsedError;
  String get workoutName => throw _privateConstructorUsedError;
  DateTime get startedAt => throw _privateConstructorUsedError;
  DateTime get completedAt => throw _privateConstructorUsedError;
  int get totalVolumeKg => throw _privateConstructorUsedError;
  int get totalSets => throw _privateConstructorUsedError;
  List<String> get exerciseIds => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Serializes this SessionLogModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SessionLogModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SessionLogModelCopyWith<SessionLogModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SessionLogModelCopyWith<$Res> {
  factory $SessionLogModelCopyWith(
          SessionLogModel value, $Res Function(SessionLogModel) then) =
      _$SessionLogModelCopyWithImpl<$Res, SessionLogModel>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String workoutId,
      String workoutName,
      DateTime startedAt,
      DateTime completedAt,
      int totalVolumeKg,
      int totalSets,
      List<String> exerciseIds,
      String? notes});
}

/// @nodoc
class _$SessionLogModelCopyWithImpl<$Res, $Val extends SessionLogModel>
    implements $SessionLogModelCopyWith<$Res> {
  _$SessionLogModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SessionLogModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? workoutId = null,
    Object? workoutName = null,
    Object? startedAt = null,
    Object? completedAt = null,
    Object? totalVolumeKg = null,
    Object? totalSets = null,
    Object? exerciseIds = null,
    Object? notes = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      workoutId: null == workoutId
          ? _value.workoutId
          : workoutId // ignore: cast_nullable_to_non_nullable
              as String,
      workoutName: null == workoutName
          ? _value.workoutName
          : workoutName // ignore: cast_nullable_to_non_nullable
              as String,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      completedAt: null == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      totalVolumeKg: null == totalVolumeKg
          ? _value.totalVolumeKg
          : totalVolumeKg // ignore: cast_nullable_to_non_nullable
              as int,
      totalSets: null == totalSets
          ? _value.totalSets
          : totalSets // ignore: cast_nullable_to_non_nullable
              as int,
      exerciseIds: null == exerciseIds
          ? _value.exerciseIds
          : exerciseIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SessionLogModelImplCopyWith<$Res>
    implements $SessionLogModelCopyWith<$Res> {
  factory _$$SessionLogModelImplCopyWith(_$SessionLogModelImpl value,
          $Res Function(_$SessionLogModelImpl) then) =
      __$$SessionLogModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String workoutId,
      String workoutName,
      DateTime startedAt,
      DateTime completedAt,
      int totalVolumeKg,
      int totalSets,
      List<String> exerciseIds,
      String? notes});
}

/// @nodoc
class __$$SessionLogModelImplCopyWithImpl<$Res>
    extends _$SessionLogModelCopyWithImpl<$Res, _$SessionLogModelImpl>
    implements _$$SessionLogModelImplCopyWith<$Res> {
  __$$SessionLogModelImplCopyWithImpl(
      _$SessionLogModelImpl _value, $Res Function(_$SessionLogModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of SessionLogModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? workoutId = null,
    Object? workoutName = null,
    Object? startedAt = null,
    Object? completedAt = null,
    Object? totalVolumeKg = null,
    Object? totalSets = null,
    Object? exerciseIds = null,
    Object? notes = freezed,
  }) {
    return _then(_$SessionLogModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      workoutId: null == workoutId
          ? _value.workoutId
          : workoutId // ignore: cast_nullable_to_non_nullable
              as String,
      workoutName: null == workoutName
          ? _value.workoutName
          : workoutName // ignore: cast_nullable_to_non_nullable
              as String,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      completedAt: null == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      totalVolumeKg: null == totalVolumeKg
          ? _value.totalVolumeKg
          : totalVolumeKg // ignore: cast_nullable_to_non_nullable
              as int,
      totalSets: null == totalSets
          ? _value.totalSets
          : totalSets // ignore: cast_nullable_to_non_nullable
              as int,
      exerciseIds: null == exerciseIds
          ? _value._exerciseIds
          : exerciseIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SessionLogModelImpl implements _SessionLogModel {
  const _$SessionLogModelImpl(
      {required this.id,
      required this.userId,
      required this.workoutId,
      required this.workoutName,
      required this.startedAt,
      required this.completedAt,
      this.totalVolumeKg = 0,
      this.totalSets = 0,
      final List<String> exerciseIds = const [],
      this.notes})
      : _exerciseIds = exerciseIds;

  factory _$SessionLogModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SessionLogModelImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String workoutId;
  @override
  final String workoutName;
  @override
  final DateTime startedAt;
  @override
  final DateTime completedAt;
  @override
  @JsonKey()
  final int totalVolumeKg;
  @override
  @JsonKey()
  final int totalSets;
  final List<String> _exerciseIds;
  @override
  @JsonKey()
  List<String> get exerciseIds {
    if (_exerciseIds is EqualUnmodifiableListView) return _exerciseIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_exerciseIds);
  }

  @override
  final String? notes;

  @override
  String toString() {
    return 'SessionLogModel(id: $id, userId: $userId, workoutId: $workoutId, workoutName: $workoutName, startedAt: $startedAt, completedAt: $completedAt, totalVolumeKg: $totalVolumeKg, totalSets: $totalSets, exerciseIds: $exerciseIds, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionLogModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.workoutId, workoutId) ||
                other.workoutId == workoutId) &&
            (identical(other.workoutName, workoutName) ||
                other.workoutName == workoutName) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.totalVolumeKg, totalVolumeKg) ||
                other.totalVolumeKg == totalVolumeKg) &&
            (identical(other.totalSets, totalSets) ||
                other.totalSets == totalSets) &&
            const DeepCollectionEquality()
                .equals(other._exerciseIds, _exerciseIds) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      workoutId,
      workoutName,
      startedAt,
      completedAt,
      totalVolumeKg,
      totalSets,
      const DeepCollectionEquality().hash(_exerciseIds),
      notes);

  /// Create a copy of SessionLogModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionLogModelImplCopyWith<_$SessionLogModelImpl> get copyWith =>
      __$$SessionLogModelImplCopyWithImpl<_$SessionLogModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SessionLogModelImplToJson(
      this,
    );
  }
}

abstract class _SessionLogModel implements SessionLogModel {
  const factory _SessionLogModel(
      {required final String id,
      required final String userId,
      required final String workoutId,
      required final String workoutName,
      required final DateTime startedAt,
      required final DateTime completedAt,
      final int totalVolumeKg,
      final int totalSets,
      final List<String> exerciseIds,
      final String? notes}) = _$SessionLogModelImpl;

  factory _SessionLogModel.fromJson(Map<String, dynamic> json) =
      _$SessionLogModelImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get workoutId;
  @override
  String get workoutName;
  @override
  DateTime get startedAt;
  @override
  DateTime get completedAt;
  @override
  int get totalVolumeKg;
  @override
  int get totalSets;
  @override
  List<String> get exerciseIds;
  @override
  String? get notes;

  /// Create a copy of SessionLogModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SessionLogModelImplCopyWith<_$SessionLogModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
