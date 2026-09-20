// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExerciseModel {

 String get id; String get name; String get primaryMuscleGroup; List<String> get secondaryMuscleGroups; String get equipment; String get type; String? get videoUrl; String? get instructions; bool get isCustom;// ── New fields ──────────────────────────────────────────────────────────
/// Links this exercise to a superset group (shared ID across exercises).
 String? get supersetGroupId;/// Rate of Perceived Exertion for this exercise definition (1–10).
 int? get rpe;/// Whether this exercise is designated as a warm-up movement.
 bool get isWarmup;
/// Create a copy of ExerciseModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExerciseModelCopyWith<ExerciseModel> get copyWith => _$ExerciseModelCopyWithImpl<ExerciseModel>(this as ExerciseModel, _$identity);

  /// Serializes this ExerciseModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExerciseModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.primaryMuscleGroup, primaryMuscleGroup) || other.primaryMuscleGroup == primaryMuscleGroup)&&const DeepCollectionEquality().equals(other.secondaryMuscleGroups, secondaryMuscleGroups)&&(identical(other.equipment, equipment) || other.equipment == equipment)&&(identical(other.type, type) || other.type == type)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.instructions, instructions) || other.instructions == instructions)&&(identical(other.isCustom, isCustom) || other.isCustom == isCustom)&&(identical(other.supersetGroupId, supersetGroupId) || other.supersetGroupId == supersetGroupId)&&(identical(other.rpe, rpe) || other.rpe == rpe)&&(identical(other.isWarmup, isWarmup) || other.isWarmup == isWarmup));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,primaryMuscleGroup,const DeepCollectionEquality().hash(secondaryMuscleGroups),equipment,type,videoUrl,instructions,isCustom,supersetGroupId,rpe,isWarmup);

@override
String toString() {
  return 'ExerciseModel(id: $id, name: $name, primaryMuscleGroup: $primaryMuscleGroup, secondaryMuscleGroups: $secondaryMuscleGroups, equipment: $equipment, type: $type, videoUrl: $videoUrl, instructions: $instructions, isCustom: $isCustom, supersetGroupId: $supersetGroupId, rpe: $rpe, isWarmup: $isWarmup)';
}


}

/// @nodoc
abstract mixin class $ExerciseModelCopyWith<$Res>  {
  factory $ExerciseModelCopyWith(ExerciseModel value, $Res Function(ExerciseModel) _then) = _$ExerciseModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, String primaryMuscleGroup, List<String> secondaryMuscleGroups, String equipment, String type, String? videoUrl, String? instructions, bool isCustom, String? supersetGroupId, int? rpe, bool isWarmup
});




}
/// @nodoc
class _$ExerciseModelCopyWithImpl<$Res>
    implements $ExerciseModelCopyWith<$Res> {
  _$ExerciseModelCopyWithImpl(this._self, this._then);

  final ExerciseModel _self;
  final $Res Function(ExerciseModel) _then;

/// Create a copy of ExerciseModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? primaryMuscleGroup = null,Object? secondaryMuscleGroups = null,Object? equipment = null,Object? type = null,Object? videoUrl = freezed,Object? instructions = freezed,Object? isCustom = null,Object? supersetGroupId = freezed,Object? rpe = freezed,Object? isWarmup = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,primaryMuscleGroup: null == primaryMuscleGroup ? _self.primaryMuscleGroup : primaryMuscleGroup // ignore: cast_nullable_to_non_nullable
as String,secondaryMuscleGroups: null == secondaryMuscleGroups ? _self.secondaryMuscleGroups : secondaryMuscleGroups // ignore: cast_nullable_to_non_nullable
as List<String>,equipment: null == equipment ? _self.equipment : equipment // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,instructions: freezed == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String?,isCustom: null == isCustom ? _self.isCustom : isCustom // ignore: cast_nullable_to_non_nullable
as bool,supersetGroupId: freezed == supersetGroupId ? _self.supersetGroupId : supersetGroupId // ignore: cast_nullable_to_non_nullable
as String?,rpe: freezed == rpe ? _self.rpe : rpe // ignore: cast_nullable_to_non_nullable
as int?,isWarmup: null == isWarmup ? _self.isWarmup : isWarmup // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ExerciseModel].
extension ExerciseModelPatterns on ExerciseModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExerciseModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExerciseModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExerciseModel value)  $default,){
final _that = this;
switch (_that) {
case _ExerciseModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExerciseModel value)?  $default,){
final _that = this;
switch (_that) {
case _ExerciseModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String primaryMuscleGroup,  List<String> secondaryMuscleGroups,  String equipment,  String type,  String? videoUrl,  String? instructions,  bool isCustom,  String? supersetGroupId,  int? rpe,  bool isWarmup)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExerciseModel() when $default != null:
return $default(_that.id,_that.name,_that.primaryMuscleGroup,_that.secondaryMuscleGroups,_that.equipment,_that.type,_that.videoUrl,_that.instructions,_that.isCustom,_that.supersetGroupId,_that.rpe,_that.isWarmup);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String primaryMuscleGroup,  List<String> secondaryMuscleGroups,  String equipment,  String type,  String? videoUrl,  String? instructions,  bool isCustom,  String? supersetGroupId,  int? rpe,  bool isWarmup)  $default,) {final _that = this;
switch (_that) {
case _ExerciseModel():
return $default(_that.id,_that.name,_that.primaryMuscleGroup,_that.secondaryMuscleGroups,_that.equipment,_that.type,_that.videoUrl,_that.instructions,_that.isCustom,_that.supersetGroupId,_that.rpe,_that.isWarmup);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String primaryMuscleGroup,  List<String> secondaryMuscleGroups,  String equipment,  String type,  String? videoUrl,  String? instructions,  bool isCustom,  String? supersetGroupId,  int? rpe,  bool isWarmup)?  $default,) {final _that = this;
switch (_that) {
case _ExerciseModel() when $default != null:
return $default(_that.id,_that.name,_that.primaryMuscleGroup,_that.secondaryMuscleGroups,_that.equipment,_that.type,_that.videoUrl,_that.instructions,_that.isCustom,_that.supersetGroupId,_that.rpe,_that.isWarmup);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _ExerciseModel implements ExerciseModel {
  const _ExerciseModel({required this.id, required this.name, required this.primaryMuscleGroup, final  List<String> secondaryMuscleGroups = const [], this.equipment = 'barbell', this.type = 'compound', this.videoUrl, this.instructions, this.isCustom = false, this.supersetGroupId, this.rpe, this.isWarmup = false}): _secondaryMuscleGroups = secondaryMuscleGroups;
  factory _ExerciseModel.fromJson(Map<String, dynamic> json) => _$ExerciseModelFromJson(json);

@override final  String id;
@override final  String name;
@override final  String primaryMuscleGroup;
 final  List<String> _secondaryMuscleGroups;
@override@JsonKey() List<String> get secondaryMuscleGroups {
  if (_secondaryMuscleGroups is EqualUnmodifiableListView) return _secondaryMuscleGroups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_secondaryMuscleGroups);
}

@override@JsonKey() final  String equipment;
@override@JsonKey() final  String type;
@override final  String? videoUrl;
@override final  String? instructions;
@override@JsonKey() final  bool isCustom;
// ── New fields ──────────────────────────────────────────────────────────
/// Links this exercise to a superset group (shared ID across exercises).
@override final  String? supersetGroupId;
/// Rate of Perceived Exertion for this exercise definition (1–10).
@override final  int? rpe;
/// Whether this exercise is designated as a warm-up movement.
@override@JsonKey() final  bool isWarmup;

/// Create a copy of ExerciseModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExerciseModelCopyWith<_ExerciseModel> get copyWith => __$ExerciseModelCopyWithImpl<_ExerciseModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExerciseModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExerciseModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.primaryMuscleGroup, primaryMuscleGroup) || other.primaryMuscleGroup == primaryMuscleGroup)&&const DeepCollectionEquality().equals(other._secondaryMuscleGroups, _secondaryMuscleGroups)&&(identical(other.equipment, equipment) || other.equipment == equipment)&&(identical(other.type, type) || other.type == type)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.instructions, instructions) || other.instructions == instructions)&&(identical(other.isCustom, isCustom) || other.isCustom == isCustom)&&(identical(other.supersetGroupId, supersetGroupId) || other.supersetGroupId == supersetGroupId)&&(identical(other.rpe, rpe) || other.rpe == rpe)&&(identical(other.isWarmup, isWarmup) || other.isWarmup == isWarmup));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,primaryMuscleGroup,const DeepCollectionEquality().hash(_secondaryMuscleGroups),equipment,type,videoUrl,instructions,isCustom,supersetGroupId,rpe,isWarmup);

@override
String toString() {
  return 'ExerciseModel(id: $id, name: $name, primaryMuscleGroup: $primaryMuscleGroup, secondaryMuscleGroups: $secondaryMuscleGroups, equipment: $equipment, type: $type, videoUrl: $videoUrl, instructions: $instructions, isCustom: $isCustom, supersetGroupId: $supersetGroupId, rpe: $rpe, isWarmup: $isWarmup)';
}


}

/// @nodoc
abstract mixin class _$ExerciseModelCopyWith<$Res> implements $ExerciseModelCopyWith<$Res> {
  factory _$ExerciseModelCopyWith(_ExerciseModel value, $Res Function(_ExerciseModel) _then) = __$ExerciseModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String primaryMuscleGroup, List<String> secondaryMuscleGroups, String equipment, String type, String? videoUrl, String? instructions, bool isCustom, String? supersetGroupId, int? rpe, bool isWarmup
});




}
/// @nodoc
class __$ExerciseModelCopyWithImpl<$Res>
    implements _$ExerciseModelCopyWith<$Res> {
  __$ExerciseModelCopyWithImpl(this._self, this._then);

  final _ExerciseModel _self;
  final $Res Function(_ExerciseModel) _then;

/// Create a copy of ExerciseModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? primaryMuscleGroup = null,Object? secondaryMuscleGroups = null,Object? equipment = null,Object? type = null,Object? videoUrl = freezed,Object? instructions = freezed,Object? isCustom = null,Object? supersetGroupId = freezed,Object? rpe = freezed,Object? isWarmup = null,}) {
  return _then(_ExerciseModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,primaryMuscleGroup: null == primaryMuscleGroup ? _self.primaryMuscleGroup : primaryMuscleGroup // ignore: cast_nullable_to_non_nullable
as String,secondaryMuscleGroups: null == secondaryMuscleGroups ? _self._secondaryMuscleGroups : secondaryMuscleGroups // ignore: cast_nullable_to_non_nullable
as List<String>,equipment: null == equipment ? _self.equipment : equipment // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,instructions: freezed == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String?,isCustom: null == isCustom ? _self.isCustom : isCustom // ignore: cast_nullable_to_non_nullable
as bool,supersetGroupId: freezed == supersetGroupId ? _self.supersetGroupId : supersetGroupId // ignore: cast_nullable_to_non_nullable
as String?,rpe: freezed == rpe ? _self.rpe : rpe // ignore: cast_nullable_to_non_nullable
as int?,isWarmup: null == isWarmup ? _self.isWarmup : isWarmup // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
