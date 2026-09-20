// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_log_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SessionLogModel {

 String get id; String get userId; String get workoutId; String get workoutName; DateTime get startedAt; DateTime get completedAt; int get totalVolumeKg; int get totalSets; List<String> get exerciseIds; String? get notes;
/// Create a copy of SessionLogModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionLogModelCopyWith<SessionLogModel> get copyWith => _$SessionLogModelCopyWithImpl<SessionLogModel>(this as SessionLogModel, _$identity);

  /// Serializes this SessionLogModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionLogModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.workoutId, workoutId) || other.workoutId == workoutId)&&(identical(other.workoutName, workoutName) || other.workoutName == workoutName)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.totalVolumeKg, totalVolumeKg) || other.totalVolumeKg == totalVolumeKg)&&(identical(other.totalSets, totalSets) || other.totalSets == totalSets)&&const DeepCollectionEquality().equals(other.exerciseIds, exerciseIds)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,workoutId,workoutName,startedAt,completedAt,totalVolumeKg,totalSets,const DeepCollectionEquality().hash(exerciseIds),notes);

@override
String toString() {
  return 'SessionLogModel(id: $id, userId: $userId, workoutId: $workoutId, workoutName: $workoutName, startedAt: $startedAt, completedAt: $completedAt, totalVolumeKg: $totalVolumeKg, totalSets: $totalSets, exerciseIds: $exerciseIds, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $SessionLogModelCopyWith<$Res>  {
  factory $SessionLogModelCopyWith(SessionLogModel value, $Res Function(SessionLogModel) _then) = _$SessionLogModelCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String workoutId, String workoutName, DateTime startedAt, DateTime completedAt, int totalVolumeKg, int totalSets, List<String> exerciseIds, String? notes
});




}
/// @nodoc
class _$SessionLogModelCopyWithImpl<$Res>
    implements $SessionLogModelCopyWith<$Res> {
  _$SessionLogModelCopyWithImpl(this._self, this._then);

  final SessionLogModel _self;
  final $Res Function(SessionLogModel) _then;

/// Create a copy of SessionLogModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? workoutId = null,Object? workoutName = null,Object? startedAt = null,Object? completedAt = null,Object? totalVolumeKg = null,Object? totalSets = null,Object? exerciseIds = null,Object? notes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,workoutId: null == workoutId ? _self.workoutId : workoutId // ignore: cast_nullable_to_non_nullable
as String,workoutName: null == workoutName ? _self.workoutName : workoutName // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime,totalVolumeKg: null == totalVolumeKg ? _self.totalVolumeKg : totalVolumeKg // ignore: cast_nullable_to_non_nullable
as int,totalSets: null == totalSets ? _self.totalSets : totalSets // ignore: cast_nullable_to_non_nullable
as int,exerciseIds: null == exerciseIds ? _self.exerciseIds : exerciseIds // ignore: cast_nullable_to_non_nullable
as List<String>,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionLogModel].
extension SessionLogModelPatterns on SessionLogModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionLogModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionLogModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionLogModel value)  $default,){
final _that = this;
switch (_that) {
case _SessionLogModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionLogModel value)?  $default,){
final _that = this;
switch (_that) {
case _SessionLogModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String workoutId,  String workoutName,  DateTime startedAt,  DateTime completedAt,  int totalVolumeKg,  int totalSets,  List<String> exerciseIds,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionLogModel() when $default != null:
return $default(_that.id,_that.userId,_that.workoutId,_that.workoutName,_that.startedAt,_that.completedAt,_that.totalVolumeKg,_that.totalSets,_that.exerciseIds,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String workoutId,  String workoutName,  DateTime startedAt,  DateTime completedAt,  int totalVolumeKg,  int totalSets,  List<String> exerciseIds,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _SessionLogModel():
return $default(_that.id,_that.userId,_that.workoutId,_that.workoutName,_that.startedAt,_that.completedAt,_that.totalVolumeKg,_that.totalSets,_that.exerciseIds,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String workoutId,  String workoutName,  DateTime startedAt,  DateTime completedAt,  int totalVolumeKg,  int totalSets,  List<String> exerciseIds,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _SessionLogModel() when $default != null:
return $default(_that.id,_that.userId,_that.workoutId,_that.workoutName,_that.startedAt,_that.completedAt,_that.totalVolumeKg,_that.totalSets,_that.exerciseIds,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionLogModel implements SessionLogModel {
  const _SessionLogModel({required this.id, required this.userId, required this.workoutId, required this.workoutName, required this.startedAt, required this.completedAt, this.totalVolumeKg = 0, this.totalSets = 0, final  List<String> exerciseIds = const [], this.notes}): _exerciseIds = exerciseIds;
  factory _SessionLogModel.fromJson(Map<String, dynamic> json) => _$SessionLogModelFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String workoutId;
@override final  String workoutName;
@override final  DateTime startedAt;
@override final  DateTime completedAt;
@override@JsonKey() final  int totalVolumeKg;
@override@JsonKey() final  int totalSets;
 final  List<String> _exerciseIds;
@override@JsonKey() List<String> get exerciseIds {
  if (_exerciseIds is EqualUnmodifiableListView) return _exerciseIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_exerciseIds);
}

@override final  String? notes;

/// Create a copy of SessionLogModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionLogModelCopyWith<_SessionLogModel> get copyWith => __$SessionLogModelCopyWithImpl<_SessionLogModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionLogModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionLogModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.workoutId, workoutId) || other.workoutId == workoutId)&&(identical(other.workoutName, workoutName) || other.workoutName == workoutName)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.totalVolumeKg, totalVolumeKg) || other.totalVolumeKg == totalVolumeKg)&&(identical(other.totalSets, totalSets) || other.totalSets == totalSets)&&const DeepCollectionEquality().equals(other._exerciseIds, _exerciseIds)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,workoutId,workoutName,startedAt,completedAt,totalVolumeKg,totalSets,const DeepCollectionEquality().hash(_exerciseIds),notes);

@override
String toString() {
  return 'SessionLogModel(id: $id, userId: $userId, workoutId: $workoutId, workoutName: $workoutName, startedAt: $startedAt, completedAt: $completedAt, totalVolumeKg: $totalVolumeKg, totalSets: $totalSets, exerciseIds: $exerciseIds, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$SessionLogModelCopyWith<$Res> implements $SessionLogModelCopyWith<$Res> {
  factory _$SessionLogModelCopyWith(_SessionLogModel value, $Res Function(_SessionLogModel) _then) = __$SessionLogModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String workoutId, String workoutName, DateTime startedAt, DateTime completedAt, int totalVolumeKg, int totalSets, List<String> exerciseIds, String? notes
});




}
/// @nodoc
class __$SessionLogModelCopyWithImpl<$Res>
    implements _$SessionLogModelCopyWith<$Res> {
  __$SessionLogModelCopyWithImpl(this._self, this._then);

  final _SessionLogModel _self;
  final $Res Function(_SessionLogModel) _then;

/// Create a copy of SessionLogModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? workoutId = null,Object? workoutName = null,Object? startedAt = null,Object? completedAt = null,Object? totalVolumeKg = null,Object? totalSets = null,Object? exerciseIds = null,Object? notes = freezed,}) {
  return _then(_SessionLogModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,workoutId: null == workoutId ? _self.workoutId : workoutId // ignore: cast_nullable_to_non_nullable
as String,workoutName: null == workoutName ? _self.workoutName : workoutName // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime,totalVolumeKg: null == totalVolumeKg ? _self.totalVolumeKg : totalVolumeKg // ignore: cast_nullable_to_non_nullable
as int,totalSets: null == totalSets ? _self.totalSets : totalSets // ignore: cast_nullable_to_non_nullable
as int,exerciseIds: null == exerciseIds ? _self._exerciseIds : exerciseIds // ignore: cast_nullable_to_non_nullable
as List<String>,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
