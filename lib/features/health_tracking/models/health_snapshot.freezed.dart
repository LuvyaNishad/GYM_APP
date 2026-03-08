// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'health_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

HealthSnapshot _$HealthSnapshotFromJson(Map<String, dynamic> json) {
  return _HealthSnapshot.fromJson(json);
}

/// @nodoc
mixin _$HealthSnapshot {
  /// When this snapshot was recorded / last synced.
  DateTime get recordedAt => throw _privateConstructorUsedError;

  /// Total step count for the current day.
  int? get steps => throw _privateConstructorUsedError;

  /// Most recent resting/active heart rate in BPM.
  int? get heartRateBpm => throw _privateConstructorUsedError;

  /// Hours of sleep for the most recent sleep session.
  double? get sleepHours => throw _privateConstructorUsedError;

  /// Active (exercise) calories burned today.
  int? get activeCalories => throw _privateConstructorUsedError;

  /// Serializes this HealthSnapshot to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HealthSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HealthSnapshotCopyWith<HealthSnapshot> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HealthSnapshotCopyWith<$Res> {
  factory $HealthSnapshotCopyWith(
          HealthSnapshot value, $Res Function(HealthSnapshot) then) =
      _$HealthSnapshotCopyWithImpl<$Res, HealthSnapshot>;
  @useResult
  $Res call(
      {DateTime recordedAt,
      int? steps,
      int? heartRateBpm,
      double? sleepHours,
      int? activeCalories});
}

/// @nodoc
class _$HealthSnapshotCopyWithImpl<$Res, $Val extends HealthSnapshot>
    implements $HealthSnapshotCopyWith<$Res> {
  _$HealthSnapshotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HealthSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recordedAt = null,
    Object? steps = freezed,
    Object? heartRateBpm = freezed,
    Object? sleepHours = freezed,
    Object? activeCalories = freezed,
  }) {
    return _then(_value.copyWith(
      recordedAt: null == recordedAt
          ? _value.recordedAt
          : recordedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      steps: freezed == steps
          ? _value.steps
          : steps // ignore: cast_nullable_to_non_nullable
              as int?,
      heartRateBpm: freezed == heartRateBpm
          ? _value.heartRateBpm
          : heartRateBpm // ignore: cast_nullable_to_non_nullable
              as int?,
      sleepHours: freezed == sleepHours
          ? _value.sleepHours
          : sleepHours // ignore: cast_nullable_to_non_nullable
              as double?,
      activeCalories: freezed == activeCalories
          ? _value.activeCalories
          : activeCalories // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HealthSnapshotImplCopyWith<$Res>
    implements $HealthSnapshotCopyWith<$Res> {
  factory _$$HealthSnapshotImplCopyWith(_$HealthSnapshotImpl value,
          $Res Function(_$HealthSnapshotImpl) then) =
      __$$HealthSnapshotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DateTime recordedAt,
      int? steps,
      int? heartRateBpm,
      double? sleepHours,
      int? activeCalories});
}

/// @nodoc
class __$$HealthSnapshotImplCopyWithImpl<$Res>
    extends _$HealthSnapshotCopyWithImpl<$Res, _$HealthSnapshotImpl>
    implements _$$HealthSnapshotImplCopyWith<$Res> {
  __$$HealthSnapshotImplCopyWithImpl(
      _$HealthSnapshotImpl _value, $Res Function(_$HealthSnapshotImpl) _then)
      : super(_value, _then);

  /// Create a copy of HealthSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recordedAt = null,
    Object? steps = freezed,
    Object? heartRateBpm = freezed,
    Object? sleepHours = freezed,
    Object? activeCalories = freezed,
  }) {
    return _then(_$HealthSnapshotImpl(
      recordedAt: null == recordedAt
          ? _value.recordedAt
          : recordedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      steps: freezed == steps
          ? _value.steps
          : steps // ignore: cast_nullable_to_non_nullable
              as int?,
      heartRateBpm: freezed == heartRateBpm
          ? _value.heartRateBpm
          : heartRateBpm // ignore: cast_nullable_to_non_nullable
              as int?,
      sleepHours: freezed == sleepHours
          ? _value.sleepHours
          : sleepHours // ignore: cast_nullable_to_non_nullable
              as double?,
      activeCalories: freezed == activeCalories
          ? _value.activeCalories
          : activeCalories // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _$HealthSnapshotImpl extends _HealthSnapshot {
  const _$HealthSnapshotImpl(
      {required this.recordedAt,
      this.steps,
      this.heartRateBpm,
      this.sleepHours,
      this.activeCalories})
      : super._();

  factory _$HealthSnapshotImpl.fromJson(Map<String, dynamic> json) =>
      _$$HealthSnapshotImplFromJson(json);

  /// When this snapshot was recorded / last synced.
  @override
  final DateTime recordedAt;

  /// Total step count for the current day.
  @override
  final int? steps;

  /// Most recent resting/active heart rate in BPM.
  @override
  final int? heartRateBpm;

  /// Hours of sleep for the most recent sleep session.
  @override
  final double? sleepHours;

  /// Active (exercise) calories burned today.
  @override
  final int? activeCalories;

  @override
  String toString() {
    return 'HealthSnapshot(recordedAt: $recordedAt, steps: $steps, heartRateBpm: $heartRateBpm, sleepHours: $sleepHours, activeCalories: $activeCalories)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HealthSnapshotImpl &&
            (identical(other.recordedAt, recordedAt) ||
                other.recordedAt == recordedAt) &&
            (identical(other.steps, steps) || other.steps == steps) &&
            (identical(other.heartRateBpm, heartRateBpm) ||
                other.heartRateBpm == heartRateBpm) &&
            (identical(other.sleepHours, sleepHours) ||
                other.sleepHours == sleepHours) &&
            (identical(other.activeCalories, activeCalories) ||
                other.activeCalories == activeCalories));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, recordedAt, steps, heartRateBpm, sleepHours, activeCalories);

  /// Create a copy of HealthSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HealthSnapshotImplCopyWith<_$HealthSnapshotImpl> get copyWith =>
      __$$HealthSnapshotImplCopyWithImpl<_$HealthSnapshotImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HealthSnapshotImplToJson(
      this,
    );
  }
}

abstract class _HealthSnapshot extends HealthSnapshot {
  const factory _HealthSnapshot(
      {required final DateTime recordedAt,
      final int? steps,
      final int? heartRateBpm,
      final double? sleepHours,
      final int? activeCalories}) = _$HealthSnapshotImpl;
  const _HealthSnapshot._() : super._();

  factory _HealthSnapshot.fromJson(Map<String, dynamic> json) =
      _$HealthSnapshotImpl.fromJson;

  /// When this snapshot was recorded / last synced.
  @override
  DateTime get recordedAt;

  /// Total step count for the current day.
  @override
  int? get steps;

  /// Most recent resting/active heart rate in BPM.
  @override
  int? get heartRateBpm;

  /// Hours of sleep for the most recent sleep session.
  @override
  double? get sleepHours;

  /// Active (exercise) calories burned today.
  @override
  int? get activeCalories;

  /// Create a copy of HealthSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HealthSnapshotImplCopyWith<_$HealthSnapshotImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
