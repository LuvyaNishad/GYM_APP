// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise_filter_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExerciseFilterModel {

/// e.g. `'push'`, `'pull'`, `'legs'`, `'core'`
 String? get muscleGroup;/// e.g. `'barbell'`, `'dumbbell'`, `'cable'`, `'bodyweight'`
 String? get equipment;/// e.g. `'compound'`, `'isolation'`
 String? get type;/// When true, only warm-up exercises are shown.
 bool get showWarmupOnly;
/// Create a copy of ExerciseFilterModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExerciseFilterModelCopyWith<ExerciseFilterModel> get copyWith => _$ExerciseFilterModelCopyWithImpl<ExerciseFilterModel>(this as ExerciseFilterModel, _$identity);

  /// Serializes this ExerciseFilterModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExerciseFilterModel&&(identical(other.muscleGroup, muscleGroup) || other.muscleGroup == muscleGroup)&&(identical(other.equipment, equipment) || other.equipment == equipment)&&(identical(other.type, type) || other.type == type)&&(identical(other.showWarmupOnly, showWarmupOnly) || other.showWarmupOnly == showWarmupOnly));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,muscleGroup,equipment,type,showWarmupOnly);

@override
String toString() {
  return 'ExerciseFilterModel(muscleGroup: $muscleGroup, equipment: $equipment, type: $type, showWarmupOnly: $showWarmupOnly)';
}


}

/// @nodoc
abstract mixin class $ExerciseFilterModelCopyWith<$Res>  {
  factory $ExerciseFilterModelCopyWith(ExerciseFilterModel value, $Res Function(ExerciseFilterModel) _then) = _$ExerciseFilterModelCopyWithImpl;
@useResult
$Res call({
 String? muscleGroup, String? equipment, String? type, bool showWarmupOnly
});




}
/// @nodoc
class _$ExerciseFilterModelCopyWithImpl<$Res>
    implements $ExerciseFilterModelCopyWith<$Res> {
  _$ExerciseFilterModelCopyWithImpl(this._self, this._then);

  final ExerciseFilterModel _self;
  final $Res Function(ExerciseFilterModel) _then;

/// Create a copy of ExerciseFilterModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? muscleGroup = freezed,Object? equipment = freezed,Object? type = freezed,Object? showWarmupOnly = null,}) {
  return _then(_self.copyWith(
muscleGroup: freezed == muscleGroup ? _self.muscleGroup : muscleGroup // ignore: cast_nullable_to_non_nullable
as String?,equipment: freezed == equipment ? _self.equipment : equipment // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,showWarmupOnly: null == showWarmupOnly ? _self.showWarmupOnly : showWarmupOnly // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ExerciseFilterModel].
extension ExerciseFilterModelPatterns on ExerciseFilterModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExerciseFilterModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExerciseFilterModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExerciseFilterModel value)  $default,){
final _that = this;
switch (_that) {
case _ExerciseFilterModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExerciseFilterModel value)?  $default,){
final _that = this;
switch (_that) {
case _ExerciseFilterModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? muscleGroup,  String? equipment,  String? type,  bool showWarmupOnly)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExerciseFilterModel() when $default != null:
return $default(_that.muscleGroup,_that.equipment,_that.type,_that.showWarmupOnly);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? muscleGroup,  String? equipment,  String? type,  bool showWarmupOnly)  $default,) {final _that = this;
switch (_that) {
case _ExerciseFilterModel():
return $default(_that.muscleGroup,_that.equipment,_that.type,_that.showWarmupOnly);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? muscleGroup,  String? equipment,  String? type,  bool showWarmupOnly)?  $default,) {final _that = this;
switch (_that) {
case _ExerciseFilterModel() when $default != null:
return $default(_that.muscleGroup,_that.equipment,_that.type,_that.showWarmupOnly);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _ExerciseFilterModel extends ExerciseFilterModel {
  const _ExerciseFilterModel({this.muscleGroup, this.equipment, this.type, this.showWarmupOnly = false}): super._();
  factory _ExerciseFilterModel.fromJson(Map<String, dynamic> json) => _$ExerciseFilterModelFromJson(json);

/// e.g. `'push'`, `'pull'`, `'legs'`, `'core'`
@override final  String? muscleGroup;
/// e.g. `'barbell'`, `'dumbbell'`, `'cable'`, `'bodyweight'`
@override final  String? equipment;
/// e.g. `'compound'`, `'isolation'`
@override final  String? type;
/// When true, only warm-up exercises are shown.
@override@JsonKey() final  bool showWarmupOnly;

/// Create a copy of ExerciseFilterModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExerciseFilterModelCopyWith<_ExerciseFilterModel> get copyWith => __$ExerciseFilterModelCopyWithImpl<_ExerciseFilterModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExerciseFilterModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExerciseFilterModel&&(identical(other.muscleGroup, muscleGroup) || other.muscleGroup == muscleGroup)&&(identical(other.equipment, equipment) || other.equipment == equipment)&&(identical(other.type, type) || other.type == type)&&(identical(other.showWarmupOnly, showWarmupOnly) || other.showWarmupOnly == showWarmupOnly));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,muscleGroup,equipment,type,showWarmupOnly);

@override
String toString() {
  return 'ExerciseFilterModel(muscleGroup: $muscleGroup, equipment: $equipment, type: $type, showWarmupOnly: $showWarmupOnly)';
}


}

/// @nodoc
abstract mixin class _$ExerciseFilterModelCopyWith<$Res> implements $ExerciseFilterModelCopyWith<$Res> {
  factory _$ExerciseFilterModelCopyWith(_ExerciseFilterModel value, $Res Function(_ExerciseFilterModel) _then) = __$ExerciseFilterModelCopyWithImpl;
@override @useResult
$Res call({
 String? muscleGroup, String? equipment, String? type, bool showWarmupOnly
});




}
/// @nodoc
class __$ExerciseFilterModelCopyWithImpl<$Res>
    implements _$ExerciseFilterModelCopyWith<$Res> {
  __$ExerciseFilterModelCopyWithImpl(this._self, this._then);

  final _ExerciseFilterModel _self;
  final $Res Function(_ExerciseFilterModel) _then;

/// Create a copy of ExerciseFilterModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? muscleGroup = freezed,Object? equipment = freezed,Object? type = freezed,Object? showWarmupOnly = null,}) {
  return _then(_ExerciseFilterModel(
muscleGroup: freezed == muscleGroup ? _self.muscleGroup : muscleGroup // ignore: cast_nullable_to_non_nullable
as String?,equipment: freezed == equipment ? _self.equipment : equipment // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,showWarmupOnly: null == showWarmupOnly ? _self.showWarmupOnly : showWarmupOnly // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
