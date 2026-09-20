// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workout_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkoutModel {

 String get id; String get userId; String get name; DateTime get date; List<WorkoutExercise> get exercises; int get durationSeconds; String? get notes; double? get totalVolumeKg; double? get averageRpe;
/// Create a copy of WorkoutModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkoutModelCopyWith<WorkoutModel> get copyWith => _$WorkoutModelCopyWithImpl<WorkoutModel>(this as WorkoutModel, _$identity);

  /// Serializes this WorkoutModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkoutModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other.exercises, exercises)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.totalVolumeKg, totalVolumeKg) || other.totalVolumeKg == totalVolumeKg)&&(identical(other.averageRpe, averageRpe) || other.averageRpe == averageRpe));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,date,const DeepCollectionEquality().hash(exercises),durationSeconds,notes,totalVolumeKg,averageRpe);

@override
String toString() {
  return 'WorkoutModel(id: $id, userId: $userId, name: $name, date: $date, exercises: $exercises, durationSeconds: $durationSeconds, notes: $notes, totalVolumeKg: $totalVolumeKg, averageRpe: $averageRpe)';
}


}

/// @nodoc
abstract mixin class $WorkoutModelCopyWith<$Res>  {
  factory $WorkoutModelCopyWith(WorkoutModel value, $Res Function(WorkoutModel) _then) = _$WorkoutModelCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String name, DateTime date, List<WorkoutExercise> exercises, int durationSeconds, String? notes, double? totalVolumeKg, double? averageRpe
});




}
/// @nodoc
class _$WorkoutModelCopyWithImpl<$Res>
    implements $WorkoutModelCopyWith<$Res> {
  _$WorkoutModelCopyWithImpl(this._self, this._then);

  final WorkoutModel _self;
  final $Res Function(WorkoutModel) _then;

/// Create a copy of WorkoutModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? date = null,Object? exercises = null,Object? durationSeconds = null,Object? notes = freezed,Object? totalVolumeKg = freezed,Object? averageRpe = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,exercises: null == exercises ? _self.exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<WorkoutExercise>,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,totalVolumeKg: freezed == totalVolumeKg ? _self.totalVolumeKg : totalVolumeKg // ignore: cast_nullable_to_non_nullable
as double?,averageRpe: freezed == averageRpe ? _self.averageRpe : averageRpe // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkoutModel].
extension WorkoutModelPatterns on WorkoutModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkoutModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkoutModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkoutModel value)  $default,){
final _that = this;
switch (_that) {
case _WorkoutModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkoutModel value)?  $default,){
final _that = this;
switch (_that) {
case _WorkoutModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String name,  DateTime date,  List<WorkoutExercise> exercises,  int durationSeconds,  String? notes,  double? totalVolumeKg,  double? averageRpe)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkoutModel() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.date,_that.exercises,_that.durationSeconds,_that.notes,_that.totalVolumeKg,_that.averageRpe);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String name,  DateTime date,  List<WorkoutExercise> exercises,  int durationSeconds,  String? notes,  double? totalVolumeKg,  double? averageRpe)  $default,) {final _that = this;
switch (_that) {
case _WorkoutModel():
return $default(_that.id,_that.userId,_that.name,_that.date,_that.exercises,_that.durationSeconds,_that.notes,_that.totalVolumeKg,_that.averageRpe);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String name,  DateTime date,  List<WorkoutExercise> exercises,  int durationSeconds,  String? notes,  double? totalVolumeKg,  double? averageRpe)?  $default,) {final _that = this;
switch (_that) {
case _WorkoutModel() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.date,_that.exercises,_that.durationSeconds,_that.notes,_that.totalVolumeKg,_that.averageRpe);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _WorkoutModel implements WorkoutModel {
  const _WorkoutModel({required this.id, required this.userId, required this.name, required this.date, final  List<WorkoutExercise> exercises = const [], this.durationSeconds = 0, this.notes, this.totalVolumeKg, this.averageRpe}): _exercises = exercises;
  factory _WorkoutModel.fromJson(Map<String, dynamic> json) => _$WorkoutModelFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String name;
@override final  DateTime date;
 final  List<WorkoutExercise> _exercises;
@override@JsonKey() List<WorkoutExercise> get exercises {
  if (_exercises is EqualUnmodifiableListView) return _exercises;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_exercises);
}

@override@JsonKey() final  int durationSeconds;
@override final  String? notes;
@override final  double? totalVolumeKg;
@override final  double? averageRpe;

/// Create a copy of WorkoutModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkoutModelCopyWith<_WorkoutModel> get copyWith => __$WorkoutModelCopyWithImpl<_WorkoutModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkoutModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkoutModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other._exercises, _exercises)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.totalVolumeKg, totalVolumeKg) || other.totalVolumeKg == totalVolumeKg)&&(identical(other.averageRpe, averageRpe) || other.averageRpe == averageRpe));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,date,const DeepCollectionEquality().hash(_exercises),durationSeconds,notes,totalVolumeKg,averageRpe);

@override
String toString() {
  return 'WorkoutModel(id: $id, userId: $userId, name: $name, date: $date, exercises: $exercises, durationSeconds: $durationSeconds, notes: $notes, totalVolumeKg: $totalVolumeKg, averageRpe: $averageRpe)';
}


}

/// @nodoc
abstract mixin class _$WorkoutModelCopyWith<$Res> implements $WorkoutModelCopyWith<$Res> {
  factory _$WorkoutModelCopyWith(_WorkoutModel value, $Res Function(_WorkoutModel) _then) = __$WorkoutModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String name, DateTime date, List<WorkoutExercise> exercises, int durationSeconds, String? notes, double? totalVolumeKg, double? averageRpe
});




}
/// @nodoc
class __$WorkoutModelCopyWithImpl<$Res>
    implements _$WorkoutModelCopyWith<$Res> {
  __$WorkoutModelCopyWithImpl(this._self, this._then);

  final _WorkoutModel _self;
  final $Res Function(_WorkoutModel) _then;

/// Create a copy of WorkoutModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? date = null,Object? exercises = null,Object? durationSeconds = null,Object? notes = freezed,Object? totalVolumeKg = freezed,Object? averageRpe = freezed,}) {
  return _then(_WorkoutModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,exercises: null == exercises ? _self._exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<WorkoutExercise>,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,totalVolumeKg: freezed == totalVolumeKg ? _self.totalVolumeKg : totalVolumeKg // ignore: cast_nullable_to_non_nullable
as double?,averageRpe: freezed == averageRpe ? _self.averageRpe : averageRpe // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$WorkoutExercise {

 String get exerciseId; String get exerciseName; String get muscleGroup; List<WorkoutSet> get sets;// ── New fields ────────────────────────────────────────────────────────
/// Links this exercise to a superset group within this workout.
 String? get supersetGroupId;/// Rate of Perceived Exertion logged for this exercise (1–10).
 int? get rpe;/// Whether this exercise entry was performed as a warm-up.
 bool get isWarmup;
/// Create a copy of WorkoutExercise
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkoutExerciseCopyWith<WorkoutExercise> get copyWith => _$WorkoutExerciseCopyWithImpl<WorkoutExercise>(this as WorkoutExercise, _$identity);

  /// Serializes this WorkoutExercise to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkoutExercise&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.exerciseName, exerciseName) || other.exerciseName == exerciseName)&&(identical(other.muscleGroup, muscleGroup) || other.muscleGroup == muscleGroup)&&const DeepCollectionEquality().equals(other.sets, sets)&&(identical(other.supersetGroupId, supersetGroupId) || other.supersetGroupId == supersetGroupId)&&(identical(other.rpe, rpe) || other.rpe == rpe)&&(identical(other.isWarmup, isWarmup) || other.isWarmup == isWarmup));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,exerciseId,exerciseName,muscleGroup,const DeepCollectionEquality().hash(sets),supersetGroupId,rpe,isWarmup);

@override
String toString() {
  return 'WorkoutExercise(exerciseId: $exerciseId, exerciseName: $exerciseName, muscleGroup: $muscleGroup, sets: $sets, supersetGroupId: $supersetGroupId, rpe: $rpe, isWarmup: $isWarmup)';
}


}

/// @nodoc
abstract mixin class $WorkoutExerciseCopyWith<$Res>  {
  factory $WorkoutExerciseCopyWith(WorkoutExercise value, $Res Function(WorkoutExercise) _then) = _$WorkoutExerciseCopyWithImpl;
@useResult
$Res call({
 String exerciseId, String exerciseName, String muscleGroup, List<WorkoutSet> sets, String? supersetGroupId, int? rpe, bool isWarmup
});




}
/// @nodoc
class _$WorkoutExerciseCopyWithImpl<$Res>
    implements $WorkoutExerciseCopyWith<$Res> {
  _$WorkoutExerciseCopyWithImpl(this._self, this._then);

  final WorkoutExercise _self;
  final $Res Function(WorkoutExercise) _then;

/// Create a copy of WorkoutExercise
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? exerciseId = null,Object? exerciseName = null,Object? muscleGroup = null,Object? sets = null,Object? supersetGroupId = freezed,Object? rpe = freezed,Object? isWarmup = null,}) {
  return _then(_self.copyWith(
exerciseId: null == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as String,exerciseName: null == exerciseName ? _self.exerciseName : exerciseName // ignore: cast_nullable_to_non_nullable
as String,muscleGroup: null == muscleGroup ? _self.muscleGroup : muscleGroup // ignore: cast_nullable_to_non_nullable
as String,sets: null == sets ? _self.sets : sets // ignore: cast_nullable_to_non_nullable
as List<WorkoutSet>,supersetGroupId: freezed == supersetGroupId ? _self.supersetGroupId : supersetGroupId // ignore: cast_nullable_to_non_nullable
as String?,rpe: freezed == rpe ? _self.rpe : rpe // ignore: cast_nullable_to_non_nullable
as int?,isWarmup: null == isWarmup ? _self.isWarmup : isWarmup // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkoutExercise].
extension WorkoutExercisePatterns on WorkoutExercise {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkoutExercise value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkoutExercise() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkoutExercise value)  $default,){
final _that = this;
switch (_that) {
case _WorkoutExercise():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkoutExercise value)?  $default,){
final _that = this;
switch (_that) {
case _WorkoutExercise() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String exerciseId,  String exerciseName,  String muscleGroup,  List<WorkoutSet> sets,  String? supersetGroupId,  int? rpe,  bool isWarmup)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkoutExercise() when $default != null:
return $default(_that.exerciseId,_that.exerciseName,_that.muscleGroup,_that.sets,_that.supersetGroupId,_that.rpe,_that.isWarmup);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String exerciseId,  String exerciseName,  String muscleGroup,  List<WorkoutSet> sets,  String? supersetGroupId,  int? rpe,  bool isWarmup)  $default,) {final _that = this;
switch (_that) {
case _WorkoutExercise():
return $default(_that.exerciseId,_that.exerciseName,_that.muscleGroup,_that.sets,_that.supersetGroupId,_that.rpe,_that.isWarmup);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String exerciseId,  String exerciseName,  String muscleGroup,  List<WorkoutSet> sets,  String? supersetGroupId,  int? rpe,  bool isWarmup)?  $default,) {final _that = this;
switch (_that) {
case _WorkoutExercise() when $default != null:
return $default(_that.exerciseId,_that.exerciseName,_that.muscleGroup,_that.sets,_that.supersetGroupId,_that.rpe,_that.isWarmup);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _WorkoutExercise implements WorkoutExercise {
  const _WorkoutExercise({required this.exerciseId, required this.exerciseName, required this.muscleGroup, final  List<WorkoutSet> sets = const [], this.supersetGroupId, this.rpe, this.isWarmup = false}): _sets = sets;
  factory _WorkoutExercise.fromJson(Map<String, dynamic> json) => _$WorkoutExerciseFromJson(json);

@override final  String exerciseId;
@override final  String exerciseName;
@override final  String muscleGroup;
 final  List<WorkoutSet> _sets;
@override@JsonKey() List<WorkoutSet> get sets {
  if (_sets is EqualUnmodifiableListView) return _sets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sets);
}

// ── New fields ────────────────────────────────────────────────────────
/// Links this exercise to a superset group within this workout.
@override final  String? supersetGroupId;
/// Rate of Perceived Exertion logged for this exercise (1–10).
@override final  int? rpe;
/// Whether this exercise entry was performed as a warm-up.
@override@JsonKey() final  bool isWarmup;

/// Create a copy of WorkoutExercise
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkoutExerciseCopyWith<_WorkoutExercise> get copyWith => __$WorkoutExerciseCopyWithImpl<_WorkoutExercise>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkoutExerciseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkoutExercise&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.exerciseName, exerciseName) || other.exerciseName == exerciseName)&&(identical(other.muscleGroup, muscleGroup) || other.muscleGroup == muscleGroup)&&const DeepCollectionEquality().equals(other._sets, _sets)&&(identical(other.supersetGroupId, supersetGroupId) || other.supersetGroupId == supersetGroupId)&&(identical(other.rpe, rpe) || other.rpe == rpe)&&(identical(other.isWarmup, isWarmup) || other.isWarmup == isWarmup));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,exerciseId,exerciseName,muscleGroup,const DeepCollectionEquality().hash(_sets),supersetGroupId,rpe,isWarmup);

@override
String toString() {
  return 'WorkoutExercise(exerciseId: $exerciseId, exerciseName: $exerciseName, muscleGroup: $muscleGroup, sets: $sets, supersetGroupId: $supersetGroupId, rpe: $rpe, isWarmup: $isWarmup)';
}


}

/// @nodoc
abstract mixin class _$WorkoutExerciseCopyWith<$Res> implements $WorkoutExerciseCopyWith<$Res> {
  factory _$WorkoutExerciseCopyWith(_WorkoutExercise value, $Res Function(_WorkoutExercise) _then) = __$WorkoutExerciseCopyWithImpl;
@override @useResult
$Res call({
 String exerciseId, String exerciseName, String muscleGroup, List<WorkoutSet> sets, String? supersetGroupId, int? rpe, bool isWarmup
});




}
/// @nodoc
class __$WorkoutExerciseCopyWithImpl<$Res>
    implements _$WorkoutExerciseCopyWith<$Res> {
  __$WorkoutExerciseCopyWithImpl(this._self, this._then);

  final _WorkoutExercise _self;
  final $Res Function(_WorkoutExercise) _then;

/// Create a copy of WorkoutExercise
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? exerciseId = null,Object? exerciseName = null,Object? muscleGroup = null,Object? sets = null,Object? supersetGroupId = freezed,Object? rpe = freezed,Object? isWarmup = null,}) {
  return _then(_WorkoutExercise(
exerciseId: null == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as String,exerciseName: null == exerciseName ? _self.exerciseName : exerciseName // ignore: cast_nullable_to_non_nullable
as String,muscleGroup: null == muscleGroup ? _self.muscleGroup : muscleGroup // ignore: cast_nullable_to_non_nullable
as String,sets: null == sets ? _self._sets : sets // ignore: cast_nullable_to_non_nullable
as List<WorkoutSet>,supersetGroupId: freezed == supersetGroupId ? _self.supersetGroupId : supersetGroupId // ignore: cast_nullable_to_non_nullable
as String?,rpe: freezed == rpe ? _self.rpe : rpe // ignore: cast_nullable_to_non_nullable
as int?,isWarmup: null == isWarmup ? _self.isWarmup : isWarmup // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$WorkoutSet {

 int get reps; double get weightKg; double get rpe; bool get isWarmup; bool get isPr;
/// Create a copy of WorkoutSet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkoutSetCopyWith<WorkoutSet> get copyWith => _$WorkoutSetCopyWithImpl<WorkoutSet>(this as WorkoutSet, _$identity);

  /// Serializes this WorkoutSet to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkoutSet&&(identical(other.reps, reps) || other.reps == reps)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.rpe, rpe) || other.rpe == rpe)&&(identical(other.isWarmup, isWarmup) || other.isWarmup == isWarmup)&&(identical(other.isPr, isPr) || other.isPr == isPr));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reps,weightKg,rpe,isWarmup,isPr);

@override
String toString() {
  return 'WorkoutSet(reps: $reps, weightKg: $weightKg, rpe: $rpe, isWarmup: $isWarmup, isPr: $isPr)';
}


}

/// @nodoc
abstract mixin class $WorkoutSetCopyWith<$Res>  {
  factory $WorkoutSetCopyWith(WorkoutSet value, $Res Function(WorkoutSet) _then) = _$WorkoutSetCopyWithImpl;
@useResult
$Res call({
 int reps, double weightKg, double rpe, bool isWarmup, bool isPr
});




}
/// @nodoc
class _$WorkoutSetCopyWithImpl<$Res>
    implements $WorkoutSetCopyWith<$Res> {
  _$WorkoutSetCopyWithImpl(this._self, this._then);

  final WorkoutSet _self;
  final $Res Function(WorkoutSet) _then;

/// Create a copy of WorkoutSet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reps = null,Object? weightKg = null,Object? rpe = null,Object? isWarmup = null,Object? isPr = null,}) {
  return _then(_self.copyWith(
reps: null == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int,weightKg: null == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double,rpe: null == rpe ? _self.rpe : rpe // ignore: cast_nullable_to_non_nullable
as double,isWarmup: null == isWarmup ? _self.isWarmup : isWarmup // ignore: cast_nullable_to_non_nullable
as bool,isPr: null == isPr ? _self.isPr : isPr // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkoutSet].
extension WorkoutSetPatterns on WorkoutSet {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkoutSet value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkoutSet() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkoutSet value)  $default,){
final _that = this;
switch (_that) {
case _WorkoutSet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkoutSet value)?  $default,){
final _that = this;
switch (_that) {
case _WorkoutSet() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int reps,  double weightKg,  double rpe,  bool isWarmup,  bool isPr)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkoutSet() when $default != null:
return $default(_that.reps,_that.weightKg,_that.rpe,_that.isWarmup,_that.isPr);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int reps,  double weightKg,  double rpe,  bool isWarmup,  bool isPr)  $default,) {final _that = this;
switch (_that) {
case _WorkoutSet():
return $default(_that.reps,_that.weightKg,_that.rpe,_that.isWarmup,_that.isPr);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int reps,  double weightKg,  double rpe,  bool isWarmup,  bool isPr)?  $default,) {final _that = this;
switch (_that) {
case _WorkoutSet() when $default != null:
return $default(_that.reps,_that.weightKg,_that.rpe,_that.isWarmup,_that.isPr);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _WorkoutSet implements WorkoutSet {
  const _WorkoutSet({required this.reps, required this.weightKg, this.rpe = 0.0, this.isWarmup = false, this.isPr = false});
  factory _WorkoutSet.fromJson(Map<String, dynamic> json) => _$WorkoutSetFromJson(json);

@override final  int reps;
@override final  double weightKg;
@override@JsonKey() final  double rpe;
@override@JsonKey() final  bool isWarmup;
@override@JsonKey() final  bool isPr;

/// Create a copy of WorkoutSet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkoutSetCopyWith<_WorkoutSet> get copyWith => __$WorkoutSetCopyWithImpl<_WorkoutSet>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkoutSetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkoutSet&&(identical(other.reps, reps) || other.reps == reps)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.rpe, rpe) || other.rpe == rpe)&&(identical(other.isWarmup, isWarmup) || other.isWarmup == isWarmup)&&(identical(other.isPr, isPr) || other.isPr == isPr));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reps,weightKg,rpe,isWarmup,isPr);

@override
String toString() {
  return 'WorkoutSet(reps: $reps, weightKg: $weightKg, rpe: $rpe, isWarmup: $isWarmup, isPr: $isPr)';
}


}

/// @nodoc
abstract mixin class _$WorkoutSetCopyWith<$Res> implements $WorkoutSetCopyWith<$Res> {
  factory _$WorkoutSetCopyWith(_WorkoutSet value, $Res Function(_WorkoutSet) _then) = __$WorkoutSetCopyWithImpl;
@override @useResult
$Res call({
 int reps, double weightKg, double rpe, bool isWarmup, bool isPr
});




}
/// @nodoc
class __$WorkoutSetCopyWithImpl<$Res>
    implements _$WorkoutSetCopyWith<$Res> {
  __$WorkoutSetCopyWithImpl(this._self, this._then);

  final _WorkoutSet _self;
  final $Res Function(_WorkoutSet) _then;

/// Create a copy of WorkoutSet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reps = null,Object? weightKg = null,Object? rpe = null,Object? isWarmup = null,Object? isPr = null,}) {
  return _then(_WorkoutSet(
reps: null == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int,weightKg: null == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double,rpe: null == rpe ? _self.rpe : rpe // ignore: cast_nullable_to_non_nullable
as double,isWarmup: null == isWarmup ? _self.isWarmup : isWarmup // ignore: cast_nullable_to_non_nullable
as bool,isPr: null == isPr ? _self.isPr : isPr // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
