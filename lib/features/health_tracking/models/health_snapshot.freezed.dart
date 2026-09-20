// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'health_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HealthSnapshot {

/// When this snapshot was recorded / last synced.
 DateTime get recordedAt;/// Total step count for the current day.
 int? get steps;/// Most recent resting/active heart rate in BPM.
 int? get heartRateBpm;/// Hours of sleep for the most recent sleep session.
 double? get sleepHours;/// Active (exercise) calories burned today.
 int? get activeCalories;
/// Create a copy of HealthSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HealthSnapshotCopyWith<HealthSnapshot> get copyWith => _$HealthSnapshotCopyWithImpl<HealthSnapshot>(this as HealthSnapshot, _$identity);

  /// Serializes this HealthSnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HealthSnapshot&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.steps, steps) || other.steps == steps)&&(identical(other.heartRateBpm, heartRateBpm) || other.heartRateBpm == heartRateBpm)&&(identical(other.sleepHours, sleepHours) || other.sleepHours == sleepHours)&&(identical(other.activeCalories, activeCalories) || other.activeCalories == activeCalories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,recordedAt,steps,heartRateBpm,sleepHours,activeCalories);

@override
String toString() {
  return 'HealthSnapshot(recordedAt: $recordedAt, steps: $steps, heartRateBpm: $heartRateBpm, sleepHours: $sleepHours, activeCalories: $activeCalories)';
}


}

/// @nodoc
abstract mixin class $HealthSnapshotCopyWith<$Res>  {
  factory $HealthSnapshotCopyWith(HealthSnapshot value, $Res Function(HealthSnapshot) _then) = _$HealthSnapshotCopyWithImpl;
@useResult
$Res call({
 DateTime recordedAt, int? steps, int? heartRateBpm, double? sleepHours, int? activeCalories
});




}
/// @nodoc
class _$HealthSnapshotCopyWithImpl<$Res>
    implements $HealthSnapshotCopyWith<$Res> {
  _$HealthSnapshotCopyWithImpl(this._self, this._then);

  final HealthSnapshot _self;
  final $Res Function(HealthSnapshot) _then;

/// Create a copy of HealthSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? recordedAt = null,Object? steps = freezed,Object? heartRateBpm = freezed,Object? sleepHours = freezed,Object? activeCalories = freezed,}) {
  return _then(_self.copyWith(
recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,steps: freezed == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as int?,heartRateBpm: freezed == heartRateBpm ? _self.heartRateBpm : heartRateBpm // ignore: cast_nullable_to_non_nullable
as int?,sleepHours: freezed == sleepHours ? _self.sleepHours : sleepHours // ignore: cast_nullable_to_non_nullable
as double?,activeCalories: freezed == activeCalories ? _self.activeCalories : activeCalories // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [HealthSnapshot].
extension HealthSnapshotPatterns on HealthSnapshot {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HealthSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HealthSnapshot() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HealthSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _HealthSnapshot():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HealthSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _HealthSnapshot() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime recordedAt,  int? steps,  int? heartRateBpm,  double? sleepHours,  int? activeCalories)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HealthSnapshot() when $default != null:
return $default(_that.recordedAt,_that.steps,_that.heartRateBpm,_that.sleepHours,_that.activeCalories);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime recordedAt,  int? steps,  int? heartRateBpm,  double? sleepHours,  int? activeCalories)  $default,) {final _that = this;
switch (_that) {
case _HealthSnapshot():
return $default(_that.recordedAt,_that.steps,_that.heartRateBpm,_that.sleepHours,_that.activeCalories);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime recordedAt,  int? steps,  int? heartRateBpm,  double? sleepHours,  int? activeCalories)?  $default,) {final _that = this;
switch (_that) {
case _HealthSnapshot() when $default != null:
return $default(_that.recordedAt,_that.steps,_that.heartRateBpm,_that.sleepHours,_that.activeCalories);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _HealthSnapshot extends HealthSnapshot {
  const _HealthSnapshot({required this.recordedAt, this.steps, this.heartRateBpm, this.sleepHours, this.activeCalories}): super._();
  factory _HealthSnapshot.fromJson(Map<String, dynamic> json) => _$HealthSnapshotFromJson(json);

/// When this snapshot was recorded / last synced.
@override final  DateTime recordedAt;
/// Total step count for the current day.
@override final  int? steps;
/// Most recent resting/active heart rate in BPM.
@override final  int? heartRateBpm;
/// Hours of sleep for the most recent sleep session.
@override final  double? sleepHours;
/// Active (exercise) calories burned today.
@override final  int? activeCalories;

/// Create a copy of HealthSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HealthSnapshotCopyWith<_HealthSnapshot> get copyWith => __$HealthSnapshotCopyWithImpl<_HealthSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HealthSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HealthSnapshot&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.steps, steps) || other.steps == steps)&&(identical(other.heartRateBpm, heartRateBpm) || other.heartRateBpm == heartRateBpm)&&(identical(other.sleepHours, sleepHours) || other.sleepHours == sleepHours)&&(identical(other.activeCalories, activeCalories) || other.activeCalories == activeCalories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,recordedAt,steps,heartRateBpm,sleepHours,activeCalories);

@override
String toString() {
  return 'HealthSnapshot(recordedAt: $recordedAt, steps: $steps, heartRateBpm: $heartRateBpm, sleepHours: $sleepHours, activeCalories: $activeCalories)';
}


}

/// @nodoc
abstract mixin class _$HealthSnapshotCopyWith<$Res> implements $HealthSnapshotCopyWith<$Res> {
  factory _$HealthSnapshotCopyWith(_HealthSnapshot value, $Res Function(_HealthSnapshot) _then) = __$HealthSnapshotCopyWithImpl;
@override @useResult
$Res call({
 DateTime recordedAt, int? steps, int? heartRateBpm, double? sleepHours, int? activeCalories
});




}
/// @nodoc
class __$HealthSnapshotCopyWithImpl<$Res>
    implements _$HealthSnapshotCopyWith<$Res> {
  __$HealthSnapshotCopyWithImpl(this._self, this._then);

  final _HealthSnapshot _self;
  final $Res Function(_HealthSnapshot) _then;

/// Create a copy of HealthSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? recordedAt = null,Object? steps = freezed,Object? heartRateBpm = freezed,Object? sleepHours = freezed,Object? activeCalories = freezed,}) {
  return _then(_HealthSnapshot(
recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,steps: freezed == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as int?,heartRateBpm: freezed == heartRateBpm ? _self.heartRateBpm : heartRateBpm // ignore: cast_nullable_to_non_nullable
as int?,sleepHours: freezed == sleepHours ? _self.sleepHours : sleepHours // ignore: cast_nullable_to_non_nullable
as double?,activeCalories: freezed == activeCalories ? _self.activeCalories : activeCalories // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
