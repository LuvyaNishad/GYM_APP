// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'split_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SplitModel {

 String get id; String get name; String get description; List<String> get dayLabels; List<List<String>> get dayExerciseIds; DateTime get createdAt;
/// Create a copy of SplitModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SplitModelCopyWith<SplitModel> get copyWith => _$SplitModelCopyWithImpl<SplitModel>(this as SplitModel, _$identity);

  /// Serializes this SplitModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SplitModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.dayLabels, dayLabels)&&const DeepCollectionEquality().equals(other.dayExerciseIds, dayExerciseIds)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,const DeepCollectionEquality().hash(dayLabels),const DeepCollectionEquality().hash(dayExerciseIds),createdAt);

@override
String toString() {
  return 'SplitModel(id: $id, name: $name, description: $description, dayLabels: $dayLabels, dayExerciseIds: $dayExerciseIds, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $SplitModelCopyWith<$Res>  {
  factory $SplitModelCopyWith(SplitModel value, $Res Function(SplitModel) _then) = _$SplitModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, List<String> dayLabels, List<List<String>> dayExerciseIds, DateTime createdAt
});




}
/// @nodoc
class _$SplitModelCopyWithImpl<$Res>
    implements $SplitModelCopyWith<$Res> {
  _$SplitModelCopyWithImpl(this._self, this._then);

  final SplitModel _self;
  final $Res Function(SplitModel) _then;

/// Create a copy of SplitModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? dayLabels = null,Object? dayExerciseIds = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,dayLabels: null == dayLabels ? _self.dayLabels : dayLabels // ignore: cast_nullable_to_non_nullable
as List<String>,dayExerciseIds: null == dayExerciseIds ? _self.dayExerciseIds : dayExerciseIds // ignore: cast_nullable_to_non_nullable
as List<List<String>>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SplitModel].
extension SplitModelPatterns on SplitModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SplitModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SplitModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SplitModel value)  $default,){
final _that = this;
switch (_that) {
case _SplitModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SplitModel value)?  $default,){
final _that = this;
switch (_that) {
case _SplitModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  List<String> dayLabels,  List<List<String>> dayExerciseIds,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SplitModel() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.dayLabels,_that.dayExerciseIds,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  List<String> dayLabels,  List<List<String>> dayExerciseIds,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _SplitModel():
return $default(_that.id,_that.name,_that.description,_that.dayLabels,_that.dayExerciseIds,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  List<String> dayLabels,  List<List<String>> dayExerciseIds,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _SplitModel() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.dayLabels,_that.dayExerciseIds,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SplitModel implements SplitModel {
  const _SplitModel({required this.id, required this.name, required this.description, final  List<String> dayLabels = const [], final  List<List<String>> dayExerciseIds = const [], required this.createdAt}): _dayLabels = dayLabels,_dayExerciseIds = dayExerciseIds;
  factory _SplitModel.fromJson(Map<String, dynamic> json) => _$SplitModelFromJson(json);

@override final  String id;
@override final  String name;
@override final  String description;
 final  List<String> _dayLabels;
@override@JsonKey() List<String> get dayLabels {
  if (_dayLabels is EqualUnmodifiableListView) return _dayLabels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dayLabels);
}

 final  List<List<String>> _dayExerciseIds;
@override@JsonKey() List<List<String>> get dayExerciseIds {
  if (_dayExerciseIds is EqualUnmodifiableListView) return _dayExerciseIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dayExerciseIds);
}

@override final  DateTime createdAt;

/// Create a copy of SplitModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SplitModelCopyWith<_SplitModel> get copyWith => __$SplitModelCopyWithImpl<_SplitModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SplitModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SplitModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._dayLabels, _dayLabels)&&const DeepCollectionEquality().equals(other._dayExerciseIds, _dayExerciseIds)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,const DeepCollectionEquality().hash(_dayLabels),const DeepCollectionEquality().hash(_dayExerciseIds),createdAt);

@override
String toString() {
  return 'SplitModel(id: $id, name: $name, description: $description, dayLabels: $dayLabels, dayExerciseIds: $dayExerciseIds, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$SplitModelCopyWith<$Res> implements $SplitModelCopyWith<$Res> {
  factory _$SplitModelCopyWith(_SplitModel value, $Res Function(_SplitModel) _then) = __$SplitModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, List<String> dayLabels, List<List<String>> dayExerciseIds, DateTime createdAt
});




}
/// @nodoc
class __$SplitModelCopyWithImpl<$Res>
    implements _$SplitModelCopyWith<$Res> {
  __$SplitModelCopyWithImpl(this._self, this._then);

  final _SplitModel _self;
  final $Res Function(_SplitModel) _then;

/// Create a copy of SplitModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? dayLabels = null,Object? dayExerciseIds = null,Object? createdAt = null,}) {
  return _then(_SplitModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,dayLabels: null == dayLabels ? _self._dayLabels : dayLabels // ignore: cast_nullable_to_non_nullable
as List<String>,dayExerciseIds: null == dayExerciseIds ? _self._dayExerciseIds : dayExerciseIds // ignore: cast_nullable_to_non_nullable
as List<List<String>>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
