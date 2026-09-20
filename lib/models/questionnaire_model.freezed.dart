// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'questionnaire_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QuestionnaireModel {

 String get userId; String get fitnessGoal; String get experienceLevel; List<String> get availableEquipmentIds; int get trainingDaysPerWeek; int get sessionDurationMinutes; String? get preferredSplit; String? get injuryNotes;
/// Create a copy of QuestionnaireModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionnaireModelCopyWith<QuestionnaireModel> get copyWith => _$QuestionnaireModelCopyWithImpl<QuestionnaireModel>(this as QuestionnaireModel, _$identity);

  /// Serializes this QuestionnaireModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionnaireModel&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fitnessGoal, fitnessGoal) || other.fitnessGoal == fitnessGoal)&&(identical(other.experienceLevel, experienceLevel) || other.experienceLevel == experienceLevel)&&const DeepCollectionEquality().equals(other.availableEquipmentIds, availableEquipmentIds)&&(identical(other.trainingDaysPerWeek, trainingDaysPerWeek) || other.trainingDaysPerWeek == trainingDaysPerWeek)&&(identical(other.sessionDurationMinutes, sessionDurationMinutes) || other.sessionDurationMinutes == sessionDurationMinutes)&&(identical(other.preferredSplit, preferredSplit) || other.preferredSplit == preferredSplit)&&(identical(other.injuryNotes, injuryNotes) || other.injuryNotes == injuryNotes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,fitnessGoal,experienceLevel,const DeepCollectionEquality().hash(availableEquipmentIds),trainingDaysPerWeek,sessionDurationMinutes,preferredSplit,injuryNotes);

@override
String toString() {
  return 'QuestionnaireModel(userId: $userId, fitnessGoal: $fitnessGoal, experienceLevel: $experienceLevel, availableEquipmentIds: $availableEquipmentIds, trainingDaysPerWeek: $trainingDaysPerWeek, sessionDurationMinutes: $sessionDurationMinutes, preferredSplit: $preferredSplit, injuryNotes: $injuryNotes)';
}


}

/// @nodoc
abstract mixin class $QuestionnaireModelCopyWith<$Res>  {
  factory $QuestionnaireModelCopyWith(QuestionnaireModel value, $Res Function(QuestionnaireModel) _then) = _$QuestionnaireModelCopyWithImpl;
@useResult
$Res call({
 String userId, String fitnessGoal, String experienceLevel, List<String> availableEquipmentIds, int trainingDaysPerWeek, int sessionDurationMinutes, String? preferredSplit, String? injuryNotes
});




}
/// @nodoc
class _$QuestionnaireModelCopyWithImpl<$Res>
    implements $QuestionnaireModelCopyWith<$Res> {
  _$QuestionnaireModelCopyWithImpl(this._self, this._then);

  final QuestionnaireModel _self;
  final $Res Function(QuestionnaireModel) _then;

/// Create a copy of QuestionnaireModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? fitnessGoal = null,Object? experienceLevel = null,Object? availableEquipmentIds = null,Object? trainingDaysPerWeek = null,Object? sessionDurationMinutes = null,Object? preferredSplit = freezed,Object? injuryNotes = freezed,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fitnessGoal: null == fitnessGoal ? _self.fitnessGoal : fitnessGoal // ignore: cast_nullable_to_non_nullable
as String,experienceLevel: null == experienceLevel ? _self.experienceLevel : experienceLevel // ignore: cast_nullable_to_non_nullable
as String,availableEquipmentIds: null == availableEquipmentIds ? _self.availableEquipmentIds : availableEquipmentIds // ignore: cast_nullable_to_non_nullable
as List<String>,trainingDaysPerWeek: null == trainingDaysPerWeek ? _self.trainingDaysPerWeek : trainingDaysPerWeek // ignore: cast_nullable_to_non_nullable
as int,sessionDurationMinutes: null == sessionDurationMinutes ? _self.sessionDurationMinutes : sessionDurationMinutes // ignore: cast_nullable_to_non_nullable
as int,preferredSplit: freezed == preferredSplit ? _self.preferredSplit : preferredSplit // ignore: cast_nullable_to_non_nullable
as String?,injuryNotes: freezed == injuryNotes ? _self.injuryNotes : injuryNotes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [QuestionnaireModel].
extension QuestionnaireModelPatterns on QuestionnaireModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuestionnaireModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuestionnaireModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuestionnaireModel value)  $default,){
final _that = this;
switch (_that) {
case _QuestionnaireModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuestionnaireModel value)?  $default,){
final _that = this;
switch (_that) {
case _QuestionnaireModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String fitnessGoal,  String experienceLevel,  List<String> availableEquipmentIds,  int trainingDaysPerWeek,  int sessionDurationMinutes,  String? preferredSplit,  String? injuryNotes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuestionnaireModel() when $default != null:
return $default(_that.userId,_that.fitnessGoal,_that.experienceLevel,_that.availableEquipmentIds,_that.trainingDaysPerWeek,_that.sessionDurationMinutes,_that.preferredSplit,_that.injuryNotes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String fitnessGoal,  String experienceLevel,  List<String> availableEquipmentIds,  int trainingDaysPerWeek,  int sessionDurationMinutes,  String? preferredSplit,  String? injuryNotes)  $default,) {final _that = this;
switch (_that) {
case _QuestionnaireModel():
return $default(_that.userId,_that.fitnessGoal,_that.experienceLevel,_that.availableEquipmentIds,_that.trainingDaysPerWeek,_that.sessionDurationMinutes,_that.preferredSplit,_that.injuryNotes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String fitnessGoal,  String experienceLevel,  List<String> availableEquipmentIds,  int trainingDaysPerWeek,  int sessionDurationMinutes,  String? preferredSplit,  String? injuryNotes)?  $default,) {final _that = this;
switch (_that) {
case _QuestionnaireModel() when $default != null:
return $default(_that.userId,_that.fitnessGoal,_that.experienceLevel,_that.availableEquipmentIds,_that.trainingDaysPerWeek,_that.sessionDurationMinutes,_that.preferredSplit,_that.injuryNotes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuestionnaireModel implements QuestionnaireModel {
  const _QuestionnaireModel({required this.userId, required this.fitnessGoal, required this.experienceLevel, final  List<String> availableEquipmentIds = const [], this.trainingDaysPerWeek = 4, this.sessionDurationMinutes = 60, this.preferredSplit, this.injuryNotes}): _availableEquipmentIds = availableEquipmentIds;
  factory _QuestionnaireModel.fromJson(Map<String, dynamic> json) => _$QuestionnaireModelFromJson(json);

@override final  String userId;
@override final  String fitnessGoal;
@override final  String experienceLevel;
 final  List<String> _availableEquipmentIds;
@override@JsonKey() List<String> get availableEquipmentIds {
  if (_availableEquipmentIds is EqualUnmodifiableListView) return _availableEquipmentIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableEquipmentIds);
}

@override@JsonKey() final  int trainingDaysPerWeek;
@override@JsonKey() final  int sessionDurationMinutes;
@override final  String? preferredSplit;
@override final  String? injuryNotes;

/// Create a copy of QuestionnaireModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuestionnaireModelCopyWith<_QuestionnaireModel> get copyWith => __$QuestionnaireModelCopyWithImpl<_QuestionnaireModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuestionnaireModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuestionnaireModel&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fitnessGoal, fitnessGoal) || other.fitnessGoal == fitnessGoal)&&(identical(other.experienceLevel, experienceLevel) || other.experienceLevel == experienceLevel)&&const DeepCollectionEquality().equals(other._availableEquipmentIds, _availableEquipmentIds)&&(identical(other.trainingDaysPerWeek, trainingDaysPerWeek) || other.trainingDaysPerWeek == trainingDaysPerWeek)&&(identical(other.sessionDurationMinutes, sessionDurationMinutes) || other.sessionDurationMinutes == sessionDurationMinutes)&&(identical(other.preferredSplit, preferredSplit) || other.preferredSplit == preferredSplit)&&(identical(other.injuryNotes, injuryNotes) || other.injuryNotes == injuryNotes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,fitnessGoal,experienceLevel,const DeepCollectionEquality().hash(_availableEquipmentIds),trainingDaysPerWeek,sessionDurationMinutes,preferredSplit,injuryNotes);

@override
String toString() {
  return 'QuestionnaireModel(userId: $userId, fitnessGoal: $fitnessGoal, experienceLevel: $experienceLevel, availableEquipmentIds: $availableEquipmentIds, trainingDaysPerWeek: $trainingDaysPerWeek, sessionDurationMinutes: $sessionDurationMinutes, preferredSplit: $preferredSplit, injuryNotes: $injuryNotes)';
}


}

/// @nodoc
abstract mixin class _$QuestionnaireModelCopyWith<$Res> implements $QuestionnaireModelCopyWith<$Res> {
  factory _$QuestionnaireModelCopyWith(_QuestionnaireModel value, $Res Function(_QuestionnaireModel) _then) = __$QuestionnaireModelCopyWithImpl;
@override @useResult
$Res call({
 String userId, String fitnessGoal, String experienceLevel, List<String> availableEquipmentIds, int trainingDaysPerWeek, int sessionDurationMinutes, String? preferredSplit, String? injuryNotes
});




}
/// @nodoc
class __$QuestionnaireModelCopyWithImpl<$Res>
    implements _$QuestionnaireModelCopyWith<$Res> {
  __$QuestionnaireModelCopyWithImpl(this._self, this._then);

  final _QuestionnaireModel _self;
  final $Res Function(_QuestionnaireModel) _then;

/// Create a copy of QuestionnaireModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? fitnessGoal = null,Object? experienceLevel = null,Object? availableEquipmentIds = null,Object? trainingDaysPerWeek = null,Object? sessionDurationMinutes = null,Object? preferredSplit = freezed,Object? injuryNotes = freezed,}) {
  return _then(_QuestionnaireModel(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fitnessGoal: null == fitnessGoal ? _self.fitnessGoal : fitnessGoal // ignore: cast_nullable_to_non_nullable
as String,experienceLevel: null == experienceLevel ? _self.experienceLevel : experienceLevel // ignore: cast_nullable_to_non_nullable
as String,availableEquipmentIds: null == availableEquipmentIds ? _self._availableEquipmentIds : availableEquipmentIds // ignore: cast_nullable_to_non_nullable
as List<String>,trainingDaysPerWeek: null == trainingDaysPerWeek ? _self.trainingDaysPerWeek : trainingDaysPerWeek // ignore: cast_nullable_to_non_nullable
as int,sessionDurationMinutes: null == sessionDurationMinutes ? _self.sessionDurationMinutes : sessionDurationMinutes // ignore: cast_nullable_to_non_nullable
as int,preferredSplit: freezed == preferredSplit ? _self.preferredSplit : preferredSplit // ignore: cast_nullable_to_non_nullable
as String?,injuryNotes: freezed == injuryNotes ? _self.injuryNotes : injuryNotes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
