// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserModel {

 String get id; String get email; String get displayName; String? get avatarUrl; String get weightUnit; int get totalWorkouts; int get totalVolumeKg; DateTime? get createdAt; DateTime? get lastActiveAt;// ── New fields ──────────────────────────────────────────────────────────
/// Current body weight in the user's preferred [weightUnit].
 double? get currentWeight;/// Goal body weight in the user's preferred [weightUnit].
 double? get targetWeight;/// User's preferred training split — e.g. `'PPL'`, `'Upper/Lower'`.
 String? get preferredSplit;/// Biological sex, used to unlock cycle-aware recovery. One of
/// `'male'`, `'female'`, or null (unset / prefer not to say).
 String? get sex;/// Whether the user has opted into menstrual-cycle tracking. Gates the
/// cycle module and the `CyclePhaseFactor` in recovery scoring.
 bool get cyclesEnabled;
/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserModelCopyWith<UserModel> get copyWith => _$UserModelCopyWithImpl<UserModel>(this as UserModel, _$identity);

  /// Serializes this UserModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserModel&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.weightUnit, weightUnit) || other.weightUnit == weightUnit)&&(identical(other.totalWorkouts, totalWorkouts) || other.totalWorkouts == totalWorkouts)&&(identical(other.totalVolumeKg, totalVolumeKg) || other.totalVolumeKg == totalVolumeKg)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt)&&(identical(other.currentWeight, currentWeight) || other.currentWeight == currentWeight)&&(identical(other.targetWeight, targetWeight) || other.targetWeight == targetWeight)&&(identical(other.preferredSplit, preferredSplit) || other.preferredSplit == preferredSplit)&&(identical(other.sex, sex) || other.sex == sex)&&(identical(other.cyclesEnabled, cyclesEnabled) || other.cyclesEnabled == cyclesEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,email,displayName,avatarUrl,weightUnit,totalWorkouts,totalVolumeKg,createdAt,lastActiveAt,currentWeight,targetWeight,preferredSplit,sex,cyclesEnabled);

@override
String toString() {
  return 'UserModel(id: $id, email: $email, displayName: $displayName, avatarUrl: $avatarUrl, weightUnit: $weightUnit, totalWorkouts: $totalWorkouts, totalVolumeKg: $totalVolumeKg, createdAt: $createdAt, lastActiveAt: $lastActiveAt, currentWeight: $currentWeight, targetWeight: $targetWeight, preferredSplit: $preferredSplit, sex: $sex, cyclesEnabled: $cyclesEnabled)';
}


}

/// @nodoc
abstract mixin class $UserModelCopyWith<$Res>  {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) _then) = _$UserModelCopyWithImpl;
@useResult
$Res call({
 String id, String email, String displayName, String? avatarUrl, String weightUnit, int totalWorkouts, int totalVolumeKg, DateTime? createdAt, DateTime? lastActiveAt, double? currentWeight, double? targetWeight, String? preferredSplit, String? sex, bool cyclesEnabled
});




}
/// @nodoc
class _$UserModelCopyWithImpl<$Res>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._self, this._then);

  final UserModel _self;
  final $Res Function(UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? email = null,Object? displayName = null,Object? avatarUrl = freezed,Object? weightUnit = null,Object? totalWorkouts = null,Object? totalVolumeKg = null,Object? createdAt = freezed,Object? lastActiveAt = freezed,Object? currentWeight = freezed,Object? targetWeight = freezed,Object? preferredSplit = freezed,Object? sex = freezed,Object? cyclesEnabled = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,weightUnit: null == weightUnit ? _self.weightUnit : weightUnit // ignore: cast_nullable_to_non_nullable
as String,totalWorkouts: null == totalWorkouts ? _self.totalWorkouts : totalWorkouts // ignore: cast_nullable_to_non_nullable
as int,totalVolumeKg: null == totalVolumeKg ? _self.totalVolumeKg : totalVolumeKg // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastActiveAt: freezed == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime?,currentWeight: freezed == currentWeight ? _self.currentWeight : currentWeight // ignore: cast_nullable_to_non_nullable
as double?,targetWeight: freezed == targetWeight ? _self.targetWeight : targetWeight // ignore: cast_nullable_to_non_nullable
as double?,preferredSplit: freezed == preferredSplit ? _self.preferredSplit : preferredSplit // ignore: cast_nullable_to_non_nullable
as String?,sex: freezed == sex ? _self.sex : sex // ignore: cast_nullable_to_non_nullable
as String?,cyclesEnabled: null == cyclesEnabled ? _self.cyclesEnabled : cyclesEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UserModel].
extension UserModelPatterns on UserModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserModel value)  $default,){
final _that = this;
switch (_that) {
case _UserModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String email,  String displayName,  String? avatarUrl,  String weightUnit,  int totalWorkouts,  int totalVolumeKg,  DateTime? createdAt,  DateTime? lastActiveAt,  double? currentWeight,  double? targetWeight,  String? preferredSplit,  String? sex,  bool cyclesEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.id,_that.email,_that.displayName,_that.avatarUrl,_that.weightUnit,_that.totalWorkouts,_that.totalVolumeKg,_that.createdAt,_that.lastActiveAt,_that.currentWeight,_that.targetWeight,_that.preferredSplit,_that.sex,_that.cyclesEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String email,  String displayName,  String? avatarUrl,  String weightUnit,  int totalWorkouts,  int totalVolumeKg,  DateTime? createdAt,  DateTime? lastActiveAt,  double? currentWeight,  double? targetWeight,  String? preferredSplit,  String? sex,  bool cyclesEnabled)  $default,) {final _that = this;
switch (_that) {
case _UserModel():
return $default(_that.id,_that.email,_that.displayName,_that.avatarUrl,_that.weightUnit,_that.totalWorkouts,_that.totalVolumeKg,_that.createdAt,_that.lastActiveAt,_that.currentWeight,_that.targetWeight,_that.preferredSplit,_that.sex,_that.cyclesEnabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String email,  String displayName,  String? avatarUrl,  String weightUnit,  int totalWorkouts,  int totalVolumeKg,  DateTime? createdAt,  DateTime? lastActiveAt,  double? currentWeight,  double? targetWeight,  String? preferredSplit,  String? sex,  bool cyclesEnabled)?  $default,) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.id,_that.email,_that.displayName,_that.avatarUrl,_that.weightUnit,_that.totalWorkouts,_that.totalVolumeKg,_that.createdAt,_that.lastActiveAt,_that.currentWeight,_that.targetWeight,_that.preferredSplit,_that.sex,_that.cyclesEnabled);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _UserModel implements UserModel {
  const _UserModel({required this.id, required this.email, required this.displayName, this.avatarUrl, this.weightUnit = 'kg', this.totalWorkouts = 0, this.totalVolumeKg = 0, this.createdAt, this.lastActiveAt, this.currentWeight, this.targetWeight, this.preferredSplit, this.sex, this.cyclesEnabled = false});
  factory _UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

@override final  String id;
@override final  String email;
@override final  String displayName;
@override final  String? avatarUrl;
@override@JsonKey() final  String weightUnit;
@override@JsonKey() final  int totalWorkouts;
@override@JsonKey() final  int totalVolumeKg;
@override final  DateTime? createdAt;
@override final  DateTime? lastActiveAt;
// ── New fields ──────────────────────────────────────────────────────────
/// Current body weight in the user's preferred [weightUnit].
@override final  double? currentWeight;
/// Goal body weight in the user's preferred [weightUnit].
@override final  double? targetWeight;
/// User's preferred training split — e.g. `'PPL'`, `'Upper/Lower'`.
@override final  String? preferredSplit;
/// Biological sex, used to unlock cycle-aware recovery. One of
/// `'male'`, `'female'`, or null (unset / prefer not to say).
@override final  String? sex;
/// Whether the user has opted into menstrual-cycle tracking. Gates the
/// cycle module and the `CyclePhaseFactor` in recovery scoring.
@override@JsonKey() final  bool cyclesEnabled;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserModelCopyWith<_UserModel> get copyWith => __$UserModelCopyWithImpl<_UserModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserModel&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.weightUnit, weightUnit) || other.weightUnit == weightUnit)&&(identical(other.totalWorkouts, totalWorkouts) || other.totalWorkouts == totalWorkouts)&&(identical(other.totalVolumeKg, totalVolumeKg) || other.totalVolumeKg == totalVolumeKg)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt)&&(identical(other.currentWeight, currentWeight) || other.currentWeight == currentWeight)&&(identical(other.targetWeight, targetWeight) || other.targetWeight == targetWeight)&&(identical(other.preferredSplit, preferredSplit) || other.preferredSplit == preferredSplit)&&(identical(other.sex, sex) || other.sex == sex)&&(identical(other.cyclesEnabled, cyclesEnabled) || other.cyclesEnabled == cyclesEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,email,displayName,avatarUrl,weightUnit,totalWorkouts,totalVolumeKg,createdAt,lastActiveAt,currentWeight,targetWeight,preferredSplit,sex,cyclesEnabled);

@override
String toString() {
  return 'UserModel(id: $id, email: $email, displayName: $displayName, avatarUrl: $avatarUrl, weightUnit: $weightUnit, totalWorkouts: $totalWorkouts, totalVolumeKg: $totalVolumeKg, createdAt: $createdAt, lastActiveAt: $lastActiveAt, currentWeight: $currentWeight, targetWeight: $targetWeight, preferredSplit: $preferredSplit, sex: $sex, cyclesEnabled: $cyclesEnabled)';
}


}

/// @nodoc
abstract mixin class _$UserModelCopyWith<$Res> implements $UserModelCopyWith<$Res> {
  factory _$UserModelCopyWith(_UserModel value, $Res Function(_UserModel) _then) = __$UserModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String email, String displayName, String? avatarUrl, String weightUnit, int totalWorkouts, int totalVolumeKg, DateTime? createdAt, DateTime? lastActiveAt, double? currentWeight, double? targetWeight, String? preferredSplit, String? sex, bool cyclesEnabled
});




}
/// @nodoc
class __$UserModelCopyWithImpl<$Res>
    implements _$UserModelCopyWith<$Res> {
  __$UserModelCopyWithImpl(this._self, this._then);

  final _UserModel _self;
  final $Res Function(_UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? email = null,Object? displayName = null,Object? avatarUrl = freezed,Object? weightUnit = null,Object? totalWorkouts = null,Object? totalVolumeKg = null,Object? createdAt = freezed,Object? lastActiveAt = freezed,Object? currentWeight = freezed,Object? targetWeight = freezed,Object? preferredSplit = freezed,Object? sex = freezed,Object? cyclesEnabled = null,}) {
  return _then(_UserModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,weightUnit: null == weightUnit ? _self.weightUnit : weightUnit // ignore: cast_nullable_to_non_nullable
as String,totalWorkouts: null == totalWorkouts ? _self.totalWorkouts : totalWorkouts // ignore: cast_nullable_to_non_nullable
as int,totalVolumeKg: null == totalVolumeKg ? _self.totalVolumeKg : totalVolumeKg // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastActiveAt: freezed == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime?,currentWeight: freezed == currentWeight ? _self.currentWeight : currentWeight // ignore: cast_nullable_to_non_nullable
as double?,targetWeight: freezed == targetWeight ? _self.targetWeight : targetWeight // ignore: cast_nullable_to_non_nullable
as double?,preferredSplit: freezed == preferredSplit ? _self.preferredSplit : preferredSplit // ignore: cast_nullable_to_non_nullable
as String?,sex: freezed == sex ? _self.sex : sex // ignore: cast_nullable_to_non_nullable
as String?,cyclesEnabled: null == cyclesEnabled ? _self.cyclesEnabled : cyclesEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
